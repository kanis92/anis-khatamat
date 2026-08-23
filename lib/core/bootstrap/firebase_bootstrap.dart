import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options_loader.dart';

/// État bas niveau du bootstrap Firebase Core.
enum FirebaseRuntimeState {
  configured,
  unavailable,
  failed,
}

/// Mode applicatif dérivé — source unique pour UI/providers.
enum AnisRuntimeMode {
  productionConfigured,
  demo,
  configMissing,
  initializationFailed,
}

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.state,
    this.error,
  });

  final FirebaseRuntimeState state;
  final Object? error;

  AnisRuntimeMode resolveAppMode({required bool demoModeActive}) {
    if (demoModeActive) return AnisRuntimeMode.demo;
    return switch (state) {
      FirebaseRuntimeState.configured => AnisRuntimeMode.productionConfigured,
      FirebaseRuntimeState.unavailable => AnisRuntimeMode.configMissing,
      FirebaseRuntimeState.failed => AnisRuntimeMode.initializationFailed,
    };
  }

  bool get isConfigured => state == FirebaseRuntimeState.configured;
}

/// Résultat global du bootstrap — injecté via [ProviderScope.overrides] dans [main].
late FirebaseBootstrapResult anisFirebaseBootstrapResult = const FirebaseBootstrapResult(
  state: FirebaseRuntimeState.unavailable,
);

Future<FirebaseBootstrapResult> bootstrapFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    return const FirebaseBootstrapResult(state: FirebaseRuntimeState.configured);
  }

  final options = resolveFirebaseOptionsFromEnvironment();
  if (options == null) {
    if (kDebugMode) {
      debugPrint(
        '[FirebaseBootstrap] CONFIG_MISSING on ${firebasePlatformLabel} — '
        'demo/unconfigured mode',
      );
    }
    return const FirebaseBootstrapResult(state: FirebaseRuntimeState.unavailable);
  }

  try {
    await Firebase.initializeApp(options: options);
    if (kDebugMode) {
      debugPrint('[FirebaseBootstrap] CONFIGURED on ${firebasePlatformLabel}');
    }
    return const FirebaseBootstrapResult(state: FirebaseRuntimeState.configured);
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('[FirebaseBootstrap] FAILED on ${firebasePlatformLabel}: $error');
      debugPrint('$stackTrace');
    }
    return FirebaseBootstrapResult(state: FirebaseRuntimeState.failed, error: error);
  }
}

bool get isFirebaseCoreReady => Firebase.apps.isNotEmpty;

FirebaseAuth? tryFirebaseAuth() {
  if (!isFirebaseCoreReady) return null;
  try {
    return FirebaseAuth.instance;
  } catch (_) {
    return null;
  }
}

FirebaseFirestore? tryFirestore() {
  if (!isFirebaseCoreReady) return null;
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
}
