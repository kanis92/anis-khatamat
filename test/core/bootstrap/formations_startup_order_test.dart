import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/bootstrap/firebase_bootstrap.dart';

void main() {
  setUp(() {
    FirebaseBootstrapGuard.resetForTests();
  });

  test('Firestore guard blocks access before verified bootstrap', () {
    expect(FirebaseBootstrapGuard.isFirestoreReady, isFalse);

    final bootstrap = FirebaseBootstrapResult(
      state: FirebaseRuntimeState.failed,
      error: StateError(kUnsafeDevelopmentRuntimeMessage),
    );
    FirebaseBootstrapGuard.register(bootstrap);

    expect(FirebaseBootstrapGuard.isFirestoreReady, isFalse);
    expect(bootstrap.isFirestoreAccessAllowed, isFalse);
  });

  test('Verified development bootstrap unlocks Firestore guard before providers',
      () {
    const bootstrap = FirebaseBootstrapResult(
      state: FirebaseRuntimeState.configured,
      developmentRuntime: FirebaseDevelopmentRuntime(
        envMode: 'development',
        firebaseInitialized: true,
        emulatorConfigured: true,
        developmentVerified: true,
        unsafeExistingRuntime: false,
        persistenceEnabled: false,
      ),
    );
    FirebaseBootstrapGuard.register(bootstrap);

    expect(FirebaseBootstrapGuard.isFirestoreReady, isTrue);
    expect(bootstrap.isFirestoreAccessAllowed, isTrue);
  });
}
