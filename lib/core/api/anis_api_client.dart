/// ANIS REST API Client
/// 
/// Platform-neutral HTTP client for ANIS backend
/// 
/// Features:
/// - Firebase ID token authentication
/// - Automatic token refresh on 401
/// - Typed error mapping
/// - Request timeout handling
/// - Secure logging (no tokens/credentials)

import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

class AnisApiClient {
  final http.Client _httpClient;
  final FirebaseAuth _auth;
  
  /// Request timeout duration
  static const _timeout = Duration(seconds: 30);
  
  AnisApiClient({
    http.Client? httpClient,
    FirebaseAuth? auth,
  }) : _httpClient = httpClient ?? http.Client(),
       _auth = auth ?? FirebaseAuth.instance;

  /// GET request
  Future<Map<String, dynamic>> get(String path) async {
    return _request('GET', path);
  }

  /// POST request
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    return _request('POST', path, body: body);
  }

  /// PUT request
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    return _request('PUT', path, body: body);
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String path) async {
    return _request('DELETE', path);
  }

  /// Internal request handler with token refresh retry
  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    try {
      // Get Firebase ID token
      final token = await _getIdToken(forceRefresh: false);
      
      // Build request
      final url = Uri.parse('${ApiConfig.baseUrlWithVersion}$path');
      final headers = _buildHeaders(token);
      
      // Log request (no sensitive data)
      _logRequest(method, path, body);
      
      // Execute request with timeout
      final response = await _executeRequest(method, url, headers, body)
          .timeout(_timeout);
      
      // Log response (no sensitive data)
      _logResponse(response);
      
      // Handle response
      return _handleResponse(response, method, path, body, isRetry);
      
    } on TimeoutException {
      throw ApiException.timeout();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e.toString());
    }
  }

  /// Execute HTTP request based on method
  Future<http.Response> _executeRequest(
    String method,
    Uri url,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    final encodedBody = body != null ? jsonEncode(body) : null;
    
    switch (method) {
      case 'GET':
        return _httpClient.get(url, headers: headers);
      case 'POST':
        return _httpClient.post(url, headers: headers, body: encodedBody);
      case 'PUT':
        return _httpClient.put(url, headers: headers, body: encodedBody);
      case 'DELETE':
        return _httpClient.delete(url, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Handle HTTP response
  Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
    String method,
    String path,
    Map<String, dynamic>? body,
    bool isRetry,
  ) async {
    final requestId = response.headers['x-request-id'];
    
    // Success (2xx)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    
    // Parse error response
    Map<String, dynamic> errorBody = {};
    try {
      errorBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Malformed error response
    }
    
    final exception = ApiException.fromResponse(
      response.statusCode,
      errorBody,
      requestId,
    );
    
    // Handle authentication errors with token refresh retry
    if (exception.isAuthError && !isRetry) {
      debugPrint('[AnisApiClient] Auth error, refreshing token and retrying');
      
      // Force refresh token
      await _getIdToken(forceRefresh: true);
      
      // Retry request ONCE
      return _request(method, path, body: body, isRetry: true);
    }
    
    throw exception;
  }

  /// Get Firebase ID token
  Future<String> _getIdToken({required bool forceRefresh}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ApiException(
        code: ApiErrorCode.authRequired,
        message: 'User not authenticated',
      );
    }
    
    final token = await user.getIdToken(forceRefresh);
    if (token == null) {
      throw ApiException(
        code: ApiErrorCode.authRequired,
        message: 'Failed to get ID token',
      );
    }
    
    return token;
  }

  /// Build request headers
  Map<String, String> _buildHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Log request (NO SENSITIVE DATA)
  void _logRequest(String method, String path, Map<String, dynamic>? body) {
    if (!kDebugMode) return;
    
    debugPrint('[AnisApiClient] → $method $path');
    if (body != null) {
      // Log sanitized body (remove sensitive fields if any)
      final sanitized = Map<String, dynamic>.from(body);
      sanitized.remove('password');
      sanitized.remove('token');
      debugPrint('[AnisApiClient] Body: $sanitized');
    }
  }

  /// Log response (NO SENSITIVE DATA)
  void _logResponse(http.Response response) {
    if (!kDebugMode) return;
    
    final requestId = response.headers['x-request-id'] ?? 'unknown';
    debugPrint('[AnisApiClient] ← ${response.statusCode} (requestId: $requestId)');
  }

  /// Dispose HTTP client
  void dispose() {
    _httpClient.close();
  }
}
