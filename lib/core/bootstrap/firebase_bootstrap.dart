import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options_loader.dart';

/// État bas niveau du bootstrap Firebase Core.
enum FirebaseRuntimeState { configured, unavailable, failed }

/// Mode applicatif dérivé — source unique pour UI/providers.
enum AnisRuntimeMode {
  productionConfigured,
  demo,
  configMissing,
  initializationFailed,
}

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({required this.state, this.error});

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
late FirebaseBootstrapResult anisFirebaseBootstrapResult =
    const FirebaseBootstrapResult(state: FirebaseRuntimeState.unavailable);

Future<FirebaseBootstrapResult> bootstrapFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    await installCrashlyticsHandlers();
    return const FirebaseBootstrapResult(
      state: FirebaseRuntimeState.configured,
    );
  }

  final options = resolveFirebaseOptionsFromEnvironment();
  if (options == null) {
    if (kDebugMode) {
      debugPrint(
        '[FirebaseBootstrap] CONFIG_MISSING on ${firebasePlatformLabel} — '
        'demo/unconfigured mode',
      );
    }
    return const FirebaseBootstrapResult(
      state: FirebaseRuntimeState.unavailable,
    );
  }

  try {
    await Firebase.initializeApp(options: options);
    await installCrashlyticsHandlers();
    if (kDebugMode) {
      debugPrint('[FirebaseBootstrap] CONFIGURED on ${firebasePlatformLabel}');
    }
    return const FirebaseBootstrapResult(
      state: FirebaseRuntimeState.configured,
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint(
        '[FirebaseBootstrap] FAILED on ${firebasePlatformLabel}: $error',
      );
      debugPrint('$stackTrace');
    }
    return FirebaseBootstrapResult(
      state: FirebaseRuntimeState.failed,
      error: error,
    );
  }
}

/// Branche Crashlytics après un Firebase Core prêt.
///
/// Ne s'active pas sur le web, ni en mode démo / config manquante.
/// N'envoie pas d'identifiant utilisateur, d'e-mail, de localisation,
/// ni de contenu de Khatma — uniquement stack traces techniques.
Future<void> installCrashlyticsHandlers() async {
  if (kIsWeb || !isFirebaseCoreReady) return;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      break;
    default:
      return;
  }

  try {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = (details) {
      crashlytics.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    Isolate.current.addErrorListener(
      RawReceivePort((pair) {
        final List<dynamic> errorAndStack = pair as List<dynamic>;
        final error = errorAndStack.first;
        final rawStack = errorAndStack.length > 1 ? errorAndStack[1] : null;
        final stack =
            rawStack is StackTrace
                ? rawStack
                : rawStack is String
                ? StackTrace.fromString(rawStack)
                : StackTrace.empty;
        crashlytics.recordError(error, stack, fatal: true);
      }).sendPort,
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('[FirebaseBootstrap] Crashlytics skipped: $error');
      debugPrint('$stackTrace');
    }
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
