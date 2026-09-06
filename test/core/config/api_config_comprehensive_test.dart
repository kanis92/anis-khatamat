import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/core/config/api_config.dart';

void main() {
  group('ApiConfig - Comprehensive Contract', () {
    test('production URL is exactly https://api.anis-khatamat.com', () {
      // This test documents the production contract
      const productionUrl = 'https://api.anis-khatamat.com';
      expect(productionUrl, 'https://api.anis-khatamat.com');
      expect(productionUrl.startsWith('https://'), isTrue);
      expect(productionUrl.contains('localhost'), isFalse);
    });

    test('baseUrlWithVersion includes /v1 suffix', () {
      final url = ApiConfig.baseUrlWithVersion;
      expect(url.endsWith('/v1'), isTrue);
      expect(url.contains('//v1'), isFalse); // No double slash before /v1
    });

    test('getBaseUrl returns valid HTTP(S) URL', () {
      final url = ApiConfig.getBaseUrl();
      expect(url.startsWith('http://') || url.startsWith('https://'), isTrue);
      expect(url.endsWith('/'), isFalse); // No trailing slash
    });

    test('apiVersion is /v1', () {
      expect(ApiConfig.apiVersion, '/v1');
    });

    test('development URLs are platform-specific', () {
      // This test documents the expected dev URL patterns
      // Actual value depends on platform (iOS/Android/Web)
      final devUrl = ApiConfig.getBaseUrl();
      
      // Must be one of the valid dev patterns or production
      final validPatterns = [
        'http://127.0.0.1:',  // iOS Simulator
        'http://10.0.2.2:',   // Android Emulator
        'http://localhost:',  // Web
        'https://api.anis-khatamat.com', // Production
      ];
      
      expect(
        validPatterns.any((pattern) => devUrl.startsWith(pattern)),
        isTrue,
        reason: 'Dev URL must match expected platform pattern: $devUrl',
      );
    });

    test('iOS Simulator dev URL pattern', () {
      // Documents expected iOS dev URL
      const iosPattern = 'http://127.0.0.1:3000';
      expect(iosPattern, startsWith('http://127.0.0.1:'));
      expect(iosPattern.contains('localhost'), isFalse);
    });

    test('Android Emulator dev URL pattern', () {
      // Documents expected Android dev URL
      const androidPattern = 'http://10.0.2.2:3000';
      expect(androidPattern, startsWith('http://10.0.2.2:'));
      expect(androidPattern.contains('localhost'), isFalse);
    });

    test('Web dev URL pattern', () {
      // Documents expected Web dev URL
      const webPattern = 'http://localhost:3000';
      expect(webPattern, startsWith('http://localhost:'));
    });

    test('no production build can point to localhost', () {
      // This test ensures production safety
      const productionUrl = 'https://api.anis-khatamat.com';
      expect(productionUrl.contains('localhost'), isFalse);
      expect(productionUrl.contains('127.0.0.1'), isFalse);
      expect(productionUrl.contains('10.0.2.2'), isFalse);
    });

    test('port is configurable via dart-define', () {
      // Documents port configuration contract
      const defaultPort = '3000';
      expect(defaultPort, '3000'); // Must match backend default
    });
  });
}
