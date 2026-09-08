import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

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

  /// Production-safe diagnostic message (no sensitive data).
  String get diagnosticMessage {
    return switch (state) {
      FirebaseRuntimeState.configured => 'Firebase configured',
      FirebaseRuntimeState.unavailable => 
        'Firebase configuration missing (no firebase_options.dart or --dart-define)',
      FirebaseRuntimeState.failed => _sanitizeErrorMessage(error),
    };
  }

  static String _sanitizeErrorMessage(Object? error) {
    if (error == null) return 'Firebase initialization failed';
    
    final errorStr = error.toString();
    // Extract error type and code without exposing sensitive data
    if (errorStr.contains('duplicate-app')) {
      return 'Firebase error: duplicate-app';
    }
    if (errorStr.contains('FirebaseException')) {
      // Try to extract plugin and code
      final pluginMatch = RegExp(r'plugin:\s*(\w+)').firstMatch(errorStr);
      final codeMatch = RegExp(r'code:\s*([a-z-]+)').firstMatch(errorStr);
      if (pluginMatch != null && codeMatch != null) {
        return 'Firebase error: ${pluginMatch.group(1)}/${codeMatch.group(1)}';
      }
      return 'Firebase error: initialization-failed';
    }
    // Generic sanitized message
    return 'Firebase error: ${error.runtimeType}';
  }
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

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Development: Connect to Firebase emulators if available
    await _configureEmulatorsInDevelopment();
    
    await installCrashlyticsHandlers();
    debugPrint('[FirebaseBootstrap] CONFIGURED');
    return const FirebaseBootstrapResult(
      state: FirebaseRuntimeState.configured,
    );
  } catch (error, stackTrace) {
    // Always log failures (production-safe diagnostic)
    final result = FirebaseBootstrapResult(
      state: FirebaseRuntimeState.failed,
      error: error,
    );
    debugPrint(
      '[FirebaseBootstrap] FAILED\n'
      'Diagnostic: ${result.diagnosticMessage}\n'
      'Error type: ${error.runtimeType}',
    );
    if (kDebugMode) {
      debugPrint('Full error: $error');
      debugPrint('Stack trace: $stackTrace');
    }
    return result;
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

/// Configure Firebase emulators in development mode only.
/// 
/// This allows local preview of Formations and other features without
/// touching production data.
/// 
/// Emulators are ONLY used when:
/// - Running in debug mode (kDebugMode)
/// - NOT in production mode (ENV_MODE != production)
/// - NOT on web platform (emulators not needed for web dev)
Future<void> _configureEmulatorsInDevelopment() async {
  // Production mode: always use real Firebase
  const envMode = String.fromEnvironment('ENV_MODE', defaultValue: 'development');
  if (envMode == 'production') {
    debugPrint('[FirebaseBootstrap] Production mode - using real Firebase');
    return;
  }

  // Debug mode + development: try to connect to emulators
  if (kDebugMode && !kIsWeb) {
    try {
      // Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      debugPrint('[FirebaseBootstrap] ✅ Connected to Firestore emulator (localhost:8080)');
      
      // Auth emulator
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      debugPrint('[FirebaseBootstrap] ✅ Connected to Auth emulator (localhost:9099)');
    } catch (error) {
      // Emulators not available - fall back to production
      // This is expected if emulators aren't running
      debugPrint('[FirebaseBootstrap] ⚠️  Emulators not available: $error');
      debugPrint('[FirebaseBootstrap] Falling back to production Firebase');
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
