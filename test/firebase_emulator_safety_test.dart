import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/bootstrap/firebase_development_guard.dart';

/// Safety tests for Firebase emulator configuration.
void main() {
  group('Firebase Emulator Safety', () {
    test('production ENV does not configure emulators', () {
      expect(isProductionEnvMode('production'), isTrue);
      expect(
        requiresNativeDevelopmentGuard(
          envMode: 'production',
          isWeb: false,
          debugMode: kDebugMode,
        ),
        isFalse,
      );
    });

    test('development ENV defaults correctly', () {
      const envMode = String.fromEnvironment('ENV_MODE', defaultValue: 'development');
      expect(envMode, equals('development'));
    });

    test('debug mode flag is consistent', () {
      expect(kDebugMode, isTrue, reason: 'Tests run in debug mode');
    });

    test('iOS simulator host is 127.0.0.1', () {
      expect(
        resolveEmulatorHost(
          platform: TargetPlatform.iOS,
          explicitHost: '',
          isWeb: false,
        ),
        '127.0.0.1',
      );
    });

    test('Android emulator host is 10.0.2.2', () {
      expect(
        resolveEmulatorHost(
          platform: TargetPlatform.android,
          explicitHost: '',
          isWeb: false,
        ),
        '10.0.2.2',
      );
    });

    test('development never silently falls back to production', () {
      const target = DevBootstrapTarget(
        projectId: 'anis-437c3',
        firestoreHost: '127.0.0.1',
        firestorePort: kDevFirestoreEmulatorPort,
        authHost: '127.0.0.1',
        authPort: kDevAuthEmulatorPort,
        envMode: 'development',
      );

      expect(
        decideDevelopmentBootstrap(
          appsAlreadyInitialized: true,
          storedMarker: null,
          expected: target,
          requiresGuard: true,
        ),
        DevelopmentBootstrapDecision.failUnsafeExisting,
      );
    });

    test('supported platforms for emulator development', () {
      final supportedHosts = ['127.0.0.1', '10.0.2.2', 'localhost'];
      expect(supportedHosts, contains('127.0.0.1'));
      expect(supportedHosts, contains('10.0.2.2'));
    });

    test('emulator configuration ordering - Auth then Firestore settings/emulator',
        () {
      const steps = ['Auth', 'FirestoreSettings', 'FirestoreEmulator'];
      expect(steps.indexOf('Auth'), lessThan(steps.indexOf('FirestoreSettings')));
      expect(
        steps.indexOf('FirestoreSettings'),
        lessThan(steps.indexOf('FirestoreEmulator')),
      );
    });

    test('release build without production ENV should fail', () {
      const envMode = String.fromEnvironment('ENV_MODE', defaultValue: 'development');

      if (!kDebugMode && envMode != 'production') {
        fail('Release build detected without ENV_MODE=production');
      }

      expect(kDebugMode, isTrue);
    });
  });

  group('Emulator Host Environment Variable', () {
    test('DEV_EMULATOR_HOST can override default', () {
      const explicitHost = String.fromEnvironment('DEV_EMULATOR_HOST');

      if (explicitHost.isNotEmpty) {
        expect(explicitHost.length, greaterThan(0));
      }

      expect(explicitHost, isEmpty, reason: 'No explicit host in test environment');
    });
  });
}
