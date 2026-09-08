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

/// Configure Firebase emulators in development mode.
/// 
/// FAIL-CLOSED SAFETY:
/// - Production mode (ENV_MODE=production): Uses real Firebase, never emulators
/// - Development mode (default): Uses emulators ONLY, throws if unavailable
/// - NO silent fallback to production in development mode
/// 
/// Platform-aware emulator hosts:
/// - iOS Simulator: localhost / 127.0.0.1
/// - Android Emulator: 10.0.2.2 (maps to host machine)
/// - Flutter Web: localhost (N/A - web doesn't use this code path)
/// - Physical device: Requires explicit DEV_EMULATOR_HOST override
Future<void> _configureEmulatorsInDevelopment() async {
  // Production mode: always use real Firebase, never emulators
  const envMode = String.fromEnvironment('ENV_MODE', defaultValue: 'development');
  if (envMode == 'production') {
    debugPrint('[FirebaseBootstrap] Production mode - using real Firebase');
    return;
  }

  // Web doesn't need emulator configuration (uses different connection method)
  if (kIsWeb) {
    debugPrint('[FirebaseBootstrap] Web mode - Firebase config via JS SDK');
    return;
  }

  // Development mode: MUST use emulators (fail-closed)
  if (!kDebugMode) {
    // Release build without ENV_MODE=production is misconfigured
    throw StateError(
      'Release build detected without ENV_MODE=production. '
      'Either run in debug mode or set ENV_MODE=production.',
    );
  }

  // Determine emulator host based on platform
  final emulatorHost = _getEmulatorHost();
  
  debugPrint('[FirebaseBootstrap] Development mode - configuring emulators');
  debugPrint('[FirebaseBootstrap] Emulator host: $emulatorHost');

  // Configure Firestore emulator (MUST succeed in development)
  try {
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    debugPrint('[FirebaseBootstrap] ✅ Firestore emulator configured ($emulatorHost:8080)');
  } catch (error) {
    debugPrint('[FirebaseBootstrap] ❌ Firestore emulator configuration failed: $error');
    throw StateError(
      'Failed to configure Firestore emulator in development mode. '
      'Ensure emulators are running: firebase emulators:start --only firestore '
      'ERROR: $error',
    );
  }

  // Configure Auth emulator (MUST succeed in development)
  try {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    debugPrint('[FirebaseBootstrap] ✅ Auth emulator configured ($emulatorHost:9099)');
  } catch (error) {
    debugPrint('[FirebaseBootstrap] ❌ Auth emulator configuration failed: $error');
    throw StateError(
      'Failed to configure Auth emulator in development mode. '
      'Ensure emulators are running: firebase emulators:start --only auth '
      'ERROR: $error',
    );
  }

  debugPrint('[FirebaseBootstrap] ✅ Development emulators configured successfully');
}

/// Get platform-appropriate emulator host.
/// 
/// iOS Simulator: localhost works
/// Android Emulator: 10.0.2.2 (special alias for host machine)
/// Physical device: Requires DEV_EMULATOR_HOST env var (LAN IP)
String _getEmulatorHost() {
  // Explicit override for physical devices (e.g., --dart-define=DEV_EMULATOR_HOST=192.168.1.100)
  const explicitHost = String.fromEnvironment('DEV_EMULATOR_HOST');
  if (explicitHost.isNotEmpty) {
    return explicitHost;
  }

  // Platform detection
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Android emulator: 10.0.2.2 maps to host machine's localhost
    return '10.0.2.2';
  }

  // iOS simulator, macOS, Linux, Windows: localhost works
  return 'localhost';
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
