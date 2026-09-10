import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/bootstrap/firebase_bootstrap.dart';

void main() {
  setUp(() {
    FirebaseBootstrapGuard.resetForTests();
  });

  group('FirebaseBootstrapGuard startup ordering', () {
    test('Firestore is not ready before bootstrap completes', () {
      expect(FirebaseBootstrapGuard.isFirestoreReady, isFalse);
      expect(FirebaseBootstrapGuard.developmentVerified, isFalse);
      expect(FirebaseBootstrapGuard.result, isNull);
    });

    test('production configured bootstrap allows Firestore access', () {
      const result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.configured,
      );
      FirebaseBootstrapGuard.register(result);

      expect(FirebaseBootstrapGuard.isFirestoreReady, isTrue);
      expect(result.isFirestoreAccessAllowed, isTrue);
    });

    test('development bootstrap without verification blocks Firestore access', () {
      const result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.configured,
        developmentRuntime: FirebaseDevelopmentRuntime(
          envMode: 'development',
          firebaseInitialized: true,
          emulatorConfigured: false,
          developmentVerified: false,
          unsafeExistingRuntime: true,
          persistenceEnabled: false,
        ),
      );
      FirebaseBootstrapGuard.register(result);

      expect(FirebaseBootstrapGuard.isFirestoreReady, isFalse);
      expect(result.isFirestoreAccessAllowed, isFalse);
    });

    test('verified development bootstrap allows Firestore access', () {
      const result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.configured,
        developmentRuntime: FirebaseDevelopmentRuntime(
          envMode: 'development',
          firebaseInitialized: true,
          emulatorConfigured: true,
          developmentVerified: true,
          unsafeExistingRuntime: false,
          persistenceEnabled: false,
          firestoreHost: '127.0.0.1',
          firestorePort: 8080,
          authHost: '127.0.0.1',
          authPort: 9099,
        ),
      );
      FirebaseBootstrapGuard.register(result);

      expect(FirebaseBootstrapGuard.isFirestoreReady, isTrue);
      expect(FirebaseBootstrapGuard.developmentVerified, isTrue);
    });

    test('failed bootstrap blocks Firestore access', () {
      final result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.failed,
        error: StateError(kUnsafeDevelopmentRuntimeMessage),
      );
      FirebaseBootstrapGuard.register(result);

      expect(FirebaseBootstrapGuard.isFirestoreReady, isFalse);
    });
  });
}
