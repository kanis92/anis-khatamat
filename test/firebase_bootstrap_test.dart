import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/bootstrap/firebase_bootstrap.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F1 — bootstrap Firebase', () {
    test('bootstrapFirebase completes without crash', () async {
      // May succeed or fail depending on test environment
      final result = await bootstrapFirebase();
      expect(result.state, isIn([
        FirebaseRuntimeState.configured,
        FirebaseRuntimeState.failed,
      ]));
    });

    test('installCrashlyticsHandlers completes', () async {
      await expectLater(installCrashlyticsHandlers(), completes);
    });

    test('auto-demo via resolveAppMode quand demoModeActive', () {
      const result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.unavailable,
      );
      expect(result.resolveAppMode(demoModeActive: true), AnisRuntimeMode.demo);
    });
  });

  group('F2 — auth provider sans accès eager FirebaseAuth', () {
    test('authStateProvider gère bootstrap unavailable', () async {
      const bootstrap = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.unavailable,
      );
      final container = ProviderContainer(
        overrides: [
          firebaseBootstrapProvider.overrideWithValue(bootstrap),
          demoModeProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authStateProvider).valueOrNull, isNull);
      expect(container.read(currentUserProvider), isNull);
    });
  });

  group('F7 — états de bootstrap', () {
    test('configured état', () {
      const result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.configured,
      );
      expect(result.isConfigured, isTrue);
      expect(
        result.resolveAppMode(demoModeActive: false),
        AnisRuntimeMode.productionConfigured,
      );
    });

    test('initializationFailed distinct de configMissing', () {
      const failed = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.failed,
      );
      expect(
        failed.resolveAppMode(demoModeActive: false),
        AnisRuntimeMode.initializationFailed,
      );
    });
  });

  group('F8 — diagnostic messages production-safe', () {
    test('configured diagnostic', () {
      const result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.configured,
      );
      expect(result.diagnosticMessage, 'Firebase configured');
    });

    test('unavailable diagnostic explains missing config', () {
      const result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.unavailable,
      );
      expect(
        result.diagnosticMessage,
        contains('configuration missing'),
      );
      expect(result.diagnosticMessage, contains('firebase_options.dart'));
    });

    test('failed diagnostic sanitizes error', () {
      const result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.failed,
        error: 'Some internal error with API key xyz123',
      );
      // Should NOT expose sensitive data
      expect(result.diagnosticMessage, isNot(contains('xyz123')));
      expect(result.diagnosticMessage, contains('Firebase error'));
    });

    test('failed diagnostic extracts duplicate-app', () {
      const result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.failed,
        error: 'FirebaseException: duplicate-app detected',
      );
      expect(result.diagnosticMessage, contains('duplicate-app'));
    });
  });
}
