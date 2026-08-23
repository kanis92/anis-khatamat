import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/bootstrap/firebase_bootstrap.dart';
import 'package:anis_khatamat/core/bootstrap/firebase_options_loader.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F1 — bootstrap sans config Firebase', () {
    test('resolveFirebaseOptionsFromEnvironment retourne null sans dart-define', () {
      expect(resolveFirebaseOptionsFromEnvironment(), isNull);
      expect(hasFirebaseBuildConfig, isFalse);
    });

    test('bootstrapFirebase atteint unavailable sans crash', () async {
      final result = await bootstrapFirebase();
      expect(result.state, FirebaseRuntimeState.unavailable);
      expect(result.isConfigured, isFalse);
      expect(result.resolveAppMode(demoModeActive: false), AnisRuntimeMode.configMissing);
    });

    test('auto-demo via resolveAppMode quand demoModeActive', () {
      const result = FirebaseBootstrapResult(state: FirebaseRuntimeState.unavailable);
      expect(result.resolveAppMode(demoModeActive: true), AnisRuntimeMode.demo);
    });
  });

  group('F2 — auth provider sans accès eager FirebaseAuth', () {
    test('authStateProvider émet null quand Firebase non initialisé', () async {
      const bootstrap = FirebaseBootstrapResult(state: FirebaseRuntimeState.unavailable);
      final container = ProviderContainer(
        overrides: [
          firebaseBootstrapProvider.overrideWithValue(bootstrap),
          demoModeProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      expect(tryFirebaseAuth(), isNull);
      expect(container.read(authStateProvider).valueOrNull, isNull);
      expect(container.read(currentUserProvider), isNull);
    });
  });

  group('F7 — chemin production attend une config build-time', () {
    test('hasFirebaseBuildConfig false sans dart-define', () {
      expect(hasFirebaseBuildConfig, isFalse);
    });

    test('initializationFailed distinct de configMissing', () {
      const failed = FirebaseBootstrapResult(state: FirebaseRuntimeState.failed);
      expect(
        failed.resolveAppMode(demoModeActive: false),
        AnisRuntimeMode.initializationFailed,
      );
    });
  });
}
