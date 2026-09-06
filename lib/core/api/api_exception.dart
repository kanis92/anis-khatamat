/// API Exception Types
/// 
/// Maps stable REST API error codes to typed Flutter exceptions
/// Supports localization via l10n (does not expose raw server messages)

enum ApiErrorCode {
  /// Authentication required (401)
  authRequired,
  
  /// Authentication invalid/expired (401)
  authInvalid,
  
  /// Permission denied (403)
  forbidden,
  
  /// Invalid request arguments (400)
  invalidArgument,
  
  /// Resource not found (404)
  notFound,
  
  /// State conflict (409)
  conflict,
  
  /// Rate limited (429)
  rateLimited,
  
  /// Internal server error (500)
  internal,
  
  /// Network connectivity failure
  networkError,
  
  /// Request timeout
  timeout,
  
  /// Unknown/unmapped error
  unknown,
}

class ApiException implements Exception {
  final ApiErrorCode code;
  final String? message;
  final String? requestId;
  final int? statusCode;

  ApiException({
    required this.code,
    this.message,
    this.requestId,
    this.statusCode,
  });

  /// Create from HTTP response
  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> body, String? requestId) {
    final errorData = body['error'] as Map<String, dynamic>?;
    final errorCode = errorData?['code'] as String?;
    final errorMessage = errorData?['message'] as String?;

    final code = _mapErrorCode(statusCode, errorCode);
    
    return ApiException(
      code: code,
      message: errorMessage,
      requestId: requestId,
      statusCode: statusCode,
    );
  }

  /// Create network error
  factory ApiException.networkError([String? message]) {
    return ApiException(
      code: ApiErrorCode.networkError,
      message: message ?? 'Network connection failed',
    );
  }

  /// Create timeout error
  factory ApiException.timeout([String? message]) {
    return ApiException(
      code: ApiErrorCode.timeout,
      message: message ?? 'Request timed out',
    );
  }

  /// Map API error code string to enum
  static ApiErrorCode _mapErrorCode(int statusCode, String? errorCode) {
    switch (errorCode) {
      case 'AUTH_REQUIRED':
        return ApiErrorCode.authRequired;
      case 'AUTH_INVALID':
        return ApiErrorCode.authInvalid;
      case 'FORBIDDEN':
        return ApiErrorCode.forbidden;
      case 'INVALID_ARGUMENT':
        return ApiErrorCode.invalidArgument;
      case 'NOT_FOUND':
        return ApiErrorCode.notFound;
      case 'CONFLICT':
        return ApiErrorCode.conflict;
      case 'RATE_LIMITED':
        return ApiErrorCode.rateLimited;
      case 'INTERNAL':
      case 'INTERNAL_ERROR':
        return ApiErrorCode.internal;
      default:
        // Fallback based on HTTP status code
        if (statusCode == 401) return ApiErrorCode.authInvalid;
        if (statusCode == 403) return ApiErrorCode.forbidden;
        if (statusCode == 404) return ApiErrorCode.notFound;
        if (statusCode == 409) return ApiErrorCode.conflict;
        if (statusCode == 429) return ApiErrorCode.rateLimited;
        if (statusCode >= 500) return ApiErrorCode.internal;
        return ApiErrorCode.unknown;
    }
  }

  /// Check if this is an authentication error requiring token refresh
  bool get isAuthError => 
    code == ApiErrorCode.authRequired || 
    code == ApiErrorCode.authInvalid;

  /// Check if this is a conflict error
  bool get isConflict => code == ApiErrorCode.conflict;

  /// Check if this is a forbidden error
  bool get isForbidden => code == ApiErrorCode.forbidden;

  /// Check if this is a rate limit error
  bool get isRateLimited => code == ApiErrorCode.rateLimited;

  @override
  String toString() {
    final parts = ['ApiException($code'];
    if (message != null) parts.add('message: $message');
    if (statusCode != null) parts.add('status: $statusCode');
    if (requestId != null) parts.add('requestId: $requestId');
    return '${parts.join(', ')})';
  }
}
