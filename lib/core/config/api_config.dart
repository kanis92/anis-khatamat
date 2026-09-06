/// API Configuration for ANIS REST API
/// 
/// Platform-neutral URL resolution:
/// - Production: https://api.anis-khatamat.com
/// - Development iOS Simulator: http://127.0.0.1:3000
/// - Development Android Emulator: http://10.0.2.2:3000
/// - Development Flutter Web: http://localhost:3000
///
/// Configuration via --dart-define or defaults

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Get API base URL based on environment and platform
  static String getBaseUrl() {
    // Check for explicit override via --dart-define
    const envApiUrl = String.fromEnvironment('API_BASE_URL');
    if (envApiUrl.isNotEmpty) {
      return _normalizeUrl(envApiUrl);
    }

    // Production detection (customize based on your build configuration)
    const envMode = String.fromEnvironment('ENV_MODE', defaultValue: 'development');
    
    if (envMode == 'production') {
      return 'https://api.anis-khatamat.com';
    }

    // Development: platform-specific localhost
    return _getDevUrl();
  }

  /// Get development URL based on platform
  /// Port must match backend API server (default: 3000)
  static String _getDevUrl() {
    const devPort = String.fromEnvironment('API_DEV_PORT', defaultValue: '3000');
    
    if (kIsWeb) {
      // Flutter Web: use localhost
      return 'http://localhost:$devPort';
    }

    // Mobile platforms
    if (Platform.isAndroid) {
      // Android Emulator: 10.0.2.2 maps to host machine localhost
      return 'http://10.0.2.2:$devPort';
    }

    // iOS Simulator and other platforms: use 127.0.0.1
    return 'http://127.0.0.1:$devPort';
  }

  /// Normalize URL (remove trailing slash)
  static String _normalizeUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Get API version prefix
  static String get apiVersion => '/v1';

  /// Get full base URL with version
  static String get baseUrlWithVersion => '${getBaseUrl()}$apiVersion';

  /// Check if running in production
  static bool get isProduction {
    const envMode = String.fromEnvironment('ENV_MODE', defaultValue: 'development');
    return envMode == 'production';
  }
}
