import 'dart:convert';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import 'firebase_development_guard.dart';

export 'firebase_development_guard.dart'
    show
        DevBootstrapMarker,
        DevBootstrapTarget,
        DevelopmentBootstrapDecision,
        FirebaseDevelopmentRuntime,
        decideDevelopmentBootstrap,
        isProductionEnvMode,
        kDevAuthEmulatorPort,
        kDevBootstrapMarkerKey,
        kDevEmulatorHostOverride,
        kDevFirestoreEmulatorPort,
        kFirebaseEnvMode,
        kUnsafeDevelopmentRuntimeMessage,
        requiresNativeDevelopmentGuard,
        resolveEmulatorHost;

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
  const FirebaseBootstrapResult({
    required this.state,
    this.error,
    this.developmentRuntime,
  });

  final FirebaseRuntimeState state;
  final Object? error;
  final FirebaseDevelopmentRuntime? developmentRuntime;

  AnisRuntimeMode resolveAppMode({required bool demoModeActive}) {
    if (demoModeActive) return AnisRuntimeMode.demo;
    return switch (state) {
      FirebaseRuntimeState.configured => AnisRuntimeMode.productionConfigured,
      FirebaseRuntimeState.unavailable => AnisRuntimeMode.configMissing,
      FirebaseRuntimeState.failed => AnisRuntimeMode.initializationFailed,
    };
  }

  bool get isConfigured => state == FirebaseRuntimeState.configured;

  /// Firestore reads are allowed only after bootstrap verified the target runtime.
  bool get isFirestoreAccessAllowed {
    if (state != FirebaseRuntimeState.configured) return false;
    final runtime = developmentRuntime;
    if (runtime == null) return true;
    return runtime.allowsFirestoreAccess;
  }

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
    if (errorStr.contains('duplicate-app')) {
      return 'Firebase error: duplicate-app';
    }
    if (errorStr.contains('FirebaseException')) {
      final pluginMatch = RegExp(r'plugin:\s*(\w+)').firstMatch(errorStr);
      final codeMatch = RegExp(r'code:\s*([a-z-]+)').firstMatch(errorStr);
      if (pluginMatch != null && codeMatch != null) {
        return 'Firebase error: ${pluginMatch.group(1)}/${codeMatch.group(1)}';
      }
      return 'Firebase error: initialization-failed';
    }
    return 'Firebase error: ${error.runtimeType}';
  }
}

/// Completed bootstrap snapshot — set before [runApp] returns control to providers.
class FirebaseBootstrapGuard {
  static FirebaseBootstrapResult? _result;

  static FirebaseBootstrapResult? get result => _result;

  static bool get isFirestoreReady => _result?.isFirestoreAccessAllowed ?? false;

  static bool get developmentVerified =>
      _result?.developmentRuntime?.developmentVerified ?? false;

  static void register(FirebaseBootstrapResult result) {
    _result = result;
  }

  @visibleForTesting
  static void resetForTests() {
    _result = null;
  }
}

/// Résultat global du bootstrap — injecté via [ProviderScope.overrides] dans [main].
late FirebaseBootstrapResult anisFirebaseBootstrapResult =
    const FirebaseBootstrapResult(state: FirebaseRuntimeState.unavailable);

Future<FirebaseBootstrapResult> bootstrapFirebase() async {
  const envMode = kFirebaseEnvMode;
  final requiresGuard = requiresNativeDevelopmentGuard(
    envMode: envMode,
    isWeb: kIsWeb,
    debugMode: kDebugMode,
  );

  try {
    if (isProductionEnvMode(envMode)) {
      await _clearDevBootstrapMarker();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await installCrashlyticsHandlers();
      final result = const FirebaseBootstrapResult(
        state: FirebaseRuntimeState.configured,
      );
      _finalizeBootstrap(result, envMode: envMode);
      return result;
    }

    if (kIsWeb) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await installCrashlyticsHandlers();
      final result = FirebaseBootstrapResult(
        state: FirebaseRuntimeState.configured,
        developmentRuntime: FirebaseDevelopmentRuntime(
          envMode: envMode,
          firebaseInitialized: Firebase.apps.isNotEmpty,
          emulatorConfigured: false,
          developmentVerified: true,
          unsafeExistingRuntime: false,
          persistenceEnabled: true,
        ),
      );
      _finalizeBootstrap(result, envMode: envMode);
      return result;
    }

    if (!kDebugMode) {
      throw StateError(
        'Release build detected without ENV_MODE=production. '
        'Either run in debug mode or set ENV_MODE=production.',
      );
    }

    final emulatorHost = resolveEmulatorHost(
      platform: defaultTargetPlatform,
      explicitHost: kDevEmulatorHostOverride,
      isWeb: kIsWeb,
    );
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    final target = DevBootstrapTarget(
      projectId: projectId,
      firestoreHost: emulatorHost,
      firestorePort: kDevFirestoreEmulatorPort,
      authHost: emulatorHost,
      authPort: kDevAuthEmulatorPort,
      envMode: envMode,
    );

    final storedMarker = await _readDevBootstrapMarker();
    final decision = decideDevelopmentBootstrap(
      appsAlreadyInitialized: Firebase.apps.isNotEmpty,
      storedMarker: storedMarker,
      expected: target,
      requiresGuard: requiresGuard,
    );

    switch (decision) {
      case DevelopmentBootstrapDecision.failUnsafeExisting:
        throw StateError(kUnsafeDevelopmentRuntimeMessage);

      case DevelopmentBootstrapDecision.acceptVerifiedExisting:
        final runtime = FirebaseDevelopmentRuntime(
          envMode: envMode,
          firebaseInitialized: true,
          emulatorConfigured: true,
          developmentVerified: true,
          unsafeExistingRuntime: false,
          persistenceEnabled: false,
          firestoreHost: emulatorHost,
          firestorePort: kDevFirestoreEmulatorPort,
          authHost: emulatorHost,
          authPort: kDevAuthEmulatorPort,
        );
        await _discardInvalidDevelopmentSession(envMode);
        _logDevelopmentBootstrap(
          projectId: projectId,
          envMode: envMode,
          runtime: runtime,
          resumedFromHotRestart: true,
        );
        await installCrashlyticsHandlers();
        final resumed = FirebaseBootstrapResult(
          state: FirebaseRuntimeState.configured,
          developmentRuntime: runtime,
        );
        _finalizeBootstrap(resumed, envMode: envMode);
        return resumed;

      case DevelopmentBootstrapDecision.freshConfigure:
        await _clearDevBootstrapMarker();
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }

        await _configureAuthEmulator(emulatorHost);
        _applyDevelopmentFirestoreCachePolicy(FirebaseFirestore.instance);
        await _configureFirestoreEmulator(emulatorHost);

        final marker = DevBootstrapMarker(
          projectId: projectId,
          firestoreHost: emulatorHost,
          firestorePort: kDevFirestoreEmulatorPort,
          authHost: emulatorHost,
          authPort: kDevAuthEmulatorPort,
          envMode: envMode,
          configuredAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        );
        await _persistDevBootstrapMarker(marker);
        await _discardInvalidDevelopmentSession(envMode);

        final runtime = FirebaseDevelopmentRuntime(
          envMode: envMode,
          firebaseInitialized: true,
          emulatorConfigured: true,
          developmentVerified: true,
          unsafeExistingRuntime: false,
          persistenceEnabled: false,
          firestoreHost: emulatorHost,
          firestorePort: kDevFirestoreEmulatorPort,
          authHost: emulatorHost,
          authPort: kDevAuthEmulatorPort,
        );
        _logDevelopmentBootstrap(
          projectId: projectId,
          envMode: envMode,
          runtime: runtime,
          resumedFromHotRestart: false,
        );
        await installCrashlyticsHandlers();
        final fresh = FirebaseBootstrapResult(
          state: FirebaseRuntimeState.configured,
          developmentRuntime: runtime,
        );
        _finalizeBootstrap(fresh, envMode: envMode);
        return fresh;

      case DevelopmentBootstrapDecision.productionPath:
      case DevelopmentBootstrapDecision.webDevelopmentPath:
        throw StateError('Unexpected development bootstrap decision: $decision');
    }
  } catch (error, stackTrace) {
    final result = FirebaseBootstrapResult(
      state: FirebaseRuntimeState.failed,
      error: error,
    );
    FirebaseBootstrapGuard.register(result);
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

void _finalizeBootstrap(
  FirebaseBootstrapResult result, {
  required String envMode,
}) {
  FirebaseBootstrapGuard.register(result);
  anisFirebaseBootstrapResult = result;
  if (kDebugMode && !isProductionEnvMode(envMode)) {
    debugPrint(
      '[FirebaseBootstrap] Firestore access allowed: '
      '${result.isFirestoreAccessAllowed}',
    );
  }
}

void _logDevelopmentBootstrap({
  required String projectId,
  required String envMode,
  required FirebaseDevelopmentRuntime runtime,
  required bool resumedFromHotRestart,
}) {
  if (!kDebugMode) return;
  debugPrint('[FirebaseBootstrap] CONFIGURED (development)');
  debugPrint('[FirebaseBootstrap] projectId: $projectId');
  debugPrint('[FirebaseBootstrap] ENV_MODE: $envMode');
  debugPrint(
    '[FirebaseBootstrap] Firestore emulator: '
    '${runtime.firestoreHost}:${runtime.firestorePort}',
  );
  debugPrint(
    '[FirebaseBootstrap] Auth emulator: '
    '${runtime.authHost}:${runtime.authPort}',
  );
  debugPrint(
    '[FirebaseBootstrap] Firestore persistence: '
    '${runtime.persistenceEnabled ? 'enabled' : 'disabled (development)'}',
  );
  debugPrint(
    '[FirebaseBootstrap] developmentVerified: ${runtime.developmentVerified}',
  );
  if (resumedFromHotRestart) {
    debugPrint(
      '[FirebaseBootstrap] Resumed verified development runtime (hot restart)',
    );
  }
}

Future<void> _configureAuthEmulator(String host) async {
  try {
    await FirebaseAuth.instance.useAuthEmulator(host, kDevAuthEmulatorPort);
    debugPrint(
      '[FirebaseBootstrap] Auth emulator configured ($host:$kDevAuthEmulatorPort)',
    );
  } catch (error) {
    throw StateError(
      'Failed to configure Auth emulator in development mode. '
      'Ensure emulators are running: firebase emulators:start --only auth '
      'ERROR: $error',
    );
  }
}

Future<void> _configureFirestoreEmulator(String host) async {
  try {
    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      kDevFirestoreEmulatorPort,
    );
    debugPrint(
      '[FirebaseBootstrap] Firestore emulator configured '
      '($host:$kDevFirestoreEmulatorPort)',
    );
  } catch (error) {
    throw StateError(
      'Failed to configure Firestore emulator in development mode. '
      'Ensure emulators are running: firebase emulators:start --only firestore '
      'ERROR: $error',
    );
  }
}

/// DEVELOPMENT ONLY — drop a restored FirebaseAuth session that the Auth
/// emulator no longer recognises.
///
/// Restarting the Auth emulator wipes its user store while the device keeps a
/// persisted session on disk. Without this check the app boots with a
/// `currentUser` whose token can never be refreshed, and every protected
/// Firestore read fails with `permission-denied` for no visible reason.
///
/// Production authentication lifecycle is untouched: this runs only after the
/// development emulator path has been configured.
Future<void> _discardInvalidDevelopmentSession(String envMode) async {
  final user = FirebaseAuth.instance.currentUser;
  final decision = decideRestoredSessionValidation(
    envMode: envMode,
    hasRestoredUser: user != null,
    isWeb: kIsWeb,
    debugMode: kDebugMode,
  );
  if (decision != RestoredSessionDecision.validateAgainstEmulator) return;

  var tokenRefreshSucceeded = true;
  try {
    await user!.getIdToken(true);
  } catch (error) {
    tokenRefreshSucceeded = false;
    debugPrint(
      '[FirebaseBootstrap] Restored development session rejected by the Auth '
      'emulator ($error)',
    );
  }

  if (!shouldDiscardRestoredSession(
    tokenRefreshSucceeded: tokenRefreshSucceeded,
  )) {
    return;
  }

  try {
    await FirebaseAuth.instance.signOut();
    debugPrint(
      '[FirebaseBootstrap] Stale development session signed out locally',
    );
  } catch (signOutError) {
    debugPrint(
      '[FirebaseBootstrap] Local development sign-out failed: $signOutError',
    );
  }
}

/// Disable local persistence before the first Firestore read in development.
/// Production keeps the SDK default (persistence enabled on mobile).
void _applyDevelopmentFirestoreCachePolicy(FirebaseFirestore firestore) {
  firestore.settings = const Settings(
    persistenceEnabled: false,
  );
  debugPrint(
    '[FirebaseBootstrap] Development Firestore cache policy applied '
    '(persistenceEnabled: false)',
  );
}

Future<DevBootstrapMarker?> _readDevBootstrapMarker() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(kDevBootstrapMarkerKey);
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return DevBootstrapMarker.fromJson(decoded);
  } catch (_) {
    return null;
  }
}

Future<void> _persistDevBootstrapMarker(DevBootstrapMarker marker) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kDevBootstrapMarkerKey, jsonEncode(marker.toJson()));
}

Future<void> _clearDevBootstrapMarker() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(kDevBootstrapMarkerKey);
}

/// Branche Crashlytics après un Firebase Core prêt.
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
  if (!FirebaseBootstrapGuard.isFirestoreReady) return null;
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
}
