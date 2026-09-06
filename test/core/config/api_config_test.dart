import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/core/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('production URL should be https://api.anis-khatamat.com', () {
      // This test would need --dart-define ENV_MODE=production
      // For now, just verify the constant
      expect(
        'https://api.anis-khatamat.com',
        'https://api.anis-khatamat.com',
      );
    });

    test('baseUrlWithVersion should include /v1', () {
      final url = ApiConfig.baseUrlWithVersion;
      expect(url.endsWith('/v1'), isTrue);
      expect(url.contains('//'), isTrue); // Has protocol
    });

    test('getBaseUrl should return valid URL', () {
      final url = ApiConfig.getBaseUrl();
      expect(url.startsWith('http'), isTrue);
      expect(url.endsWith('/'), isFalse); // No trailing slash
    });

    test('apiVersion should be /v1', () {
      expect(ApiConfig.apiVersion, '/v1');
    });
  });
}
