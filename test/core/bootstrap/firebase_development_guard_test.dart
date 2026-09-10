import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/bootstrap/firebase_development_guard.dart';

void main() {
  group('Firebase development guard — pure decisions', () {
    const target = DevBootstrapTarget(
      projectId: 'anis-437c3',
      firestoreHost: '127.0.0.1',
      firestorePort: kDevFirestoreEmulatorPort,
      authHost: '127.0.0.1',
      authPort: kDevAuthEmulatorPort,
      envMode: 'development',
    );

    const validMarker = DevBootstrapMarker(
      projectId: 'anis-437c3',
      firestoreHost: '127.0.0.1',
      firestorePort: kDevFirestoreEmulatorPort,
      authHost: '127.0.0.1',
      authPort: kDevAuthEmulatorPort,
      envMode: 'development',
      configuredAtEpochMs: 1,
    );

    test('production mode does not require native development guard', () {
      expect(
        decideDevelopmentBootstrap(
          appsAlreadyInitialized: true,
          storedMarker: null,
          expected: target.copyWithEnv('production'),
          requiresGuard: false,
        ),
        DevelopmentBootstrapDecision.productionPath,
      );
    });

    test('fresh development start configures emulators before reads', () {
      expect(
        decideDevelopmentBootstrap(
          appsAlreadyInitialized: false,
          storedMarker: null,
          expected: target,
          requiresGuard: true,
        ),
        DevelopmentBootstrapDecision.freshConfigure,
      );
    });

    test('development never silently accepts unsafe existing runtime', () {
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

    test('verified marker accepts hot restart runtime safely', () {
      expect(
        decideDevelopmentBootstrap(
          appsAlreadyInitialized: true,
          storedMarker: validMarker,
          expected: target,
          requiresGuard: true,
        ),
        DevelopmentBootstrapDecision.acceptVerifiedExisting,
      );
    });

    test('marker host mismatch fails closed', () {
      const mismatchedMarker = DevBootstrapMarker(
        projectId: 'anis-437c3',
        firestoreHost: '10.0.2.2',
        firestorePort: kDevFirestoreEmulatorPort,
        authHost: '10.0.2.2',
        authPort: kDevAuthEmulatorPort,
        envMode: 'development',
        configuredAtEpochMs: 1,
      );

      expect(
        decideDevelopmentBootstrap(
          appsAlreadyInitialized: true,
          storedMarker: mismatchedMarker,
          expected: target,
          requiresGuard: true,
        ),
        DevelopmentBootstrapDecision.failUnsafeExisting,
      );
    });

    test('development cache policy does not affect production env mode', () {
      expect(isProductionEnvMode('production'), isTrue);
      expect(
        requiresNativeDevelopmentGuard(
          envMode: 'production',
          isWeb: false,
          debugMode: true,
        ),
        isFalse,
      );
    });
  });

  group('Emulator host resolution', () {
    test('iOS simulator uses 127.0.0.1', () {
      expect(
        resolveEmulatorHost(
          platform: TargetPlatform.iOS,
          explicitHost: '',
          isWeb: false,
        ),
        '127.0.0.1',
      );
    });

    test('Android emulator uses 10.0.2.2', () {
      expect(
        resolveEmulatorHost(
          platform: TargetPlatform.android,
          explicitHost: '',
          isWeb: false,
        ),
        '10.0.2.2',
      );
    });

    test('web uses localhost', () {
      expect(
        resolveEmulatorHost(
          platform: TargetPlatform.iOS,
          explicitHost: '',
          isWeb: true,
        ),
        'localhost',
      );
    });

    test('explicit LAN host override wins', () {
      expect(
        resolveEmulatorHost(
          platform: TargetPlatform.iOS,
          explicitHost: '192.168.1.42',
          isWeb: false,
        ),
        '192.168.1.42',
      );
    });
  });

  group('DevBootstrapMarker serialization', () {
    test('round-trip preserves verification fields', () {
      const marker = DevBootstrapMarker(
        projectId: 'anis-437c3',
        firestoreHost: '127.0.0.1',
        firestorePort: 8080,
        authHost: '127.0.0.1',
        authPort: 9099,
        envMode: 'development',
        configuredAtEpochMs: 42,
      );

      final restored = DevBootstrapMarker.fromJson(marker.toJson());
      expect(restored, isNotNull);
      expect(restored!.matches(const DevBootstrapTarget(
        projectId: 'anis-437c3',
        firestoreHost: '127.0.0.1',
        firestorePort: 8080,
        authHost: '127.0.0.1',
        authPort: 9099,
        envMode: 'development',
      )), isTrue);
    });
  });
}

extension on DevBootstrapTarget {
  DevBootstrapTarget copyWithEnv(String envMode) {
    return DevBootstrapTarget(
      projectId: projectId,
      firestoreHost: firestoreHost,
      firestorePort: firestorePort,
      authHost: authHost,
      authPort: authPort,
      envMode: envMode,
    );
  }
}
