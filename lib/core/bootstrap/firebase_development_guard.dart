import 'package:flutter/foundation.dart';

/// Compile-time application environment.
const String kFirebaseEnvMode = String.fromEnvironment(
  'ENV_MODE',
  defaultValue: 'development',
);

/// Optional LAN override for physical devices.
const String kDevEmulatorHostOverride = String.fromEnvironment(
  'DEV_EMULATOR_HOST',
);

const int kDevFirestoreEmulatorPort = 8080;
const int kDevAuthEmulatorPort = 9099;
const String kDevBootstrapMarkerKey = 'anis_dev_firebase_bootstrap_v1';

const String kUnsafeDevelopmentRuntimeMessage =
    'Firebase development runtime was already initialized without verified '
    'emulator configuration. Perform a full app restart.';

/// Explicit development bootstrap lifecycle states.
enum DevelopmentBootstrapDecision {
  /// Fresh process — configure emulators before any Firestore read.
  freshConfigure,

  /// Hot restart — native Firebase kept emulator wiring; marker proves cold start.
  acceptVerifiedExisting,

  /// Hot restart or stale runtime without verifiable emulator configuration.
  failUnsafeExisting,

  /// Production build — real Firebase only.
  productionPath,

  /// Web development — JS SDK path (no native emulator wiring here).
  webDevelopmentPath,
}

/// What to do with a FirebaseAuth session restored from disk at startup.
enum RestoredSessionDecision {
  /// Production: the authentication lifecycle is never altered.
  keepProductionSession,

  /// Nothing was restored — nothing to validate.
  noRestoredSession,

  /// Development: the session must be proven against the Auth emulator.
  validateAgainstEmulator,
}

/// Restarting the Auth emulator wipes its user store while the device keeps a
/// persisted session. Only development revalidates that session, so production
/// authentication behaviour stays untouched.
RestoredSessionDecision decideRestoredSessionValidation({
  required String envMode,
  required bool hasRestoredUser,
  required bool isWeb,
  required bool debugMode,
}) {
  if (!requiresNativeDevelopmentGuard(
    envMode: envMode,
    isWeb: isWeb,
    debugMode: debugMode,
  )) {
    return RestoredSessionDecision.keepProductionSession;
  }
  return hasRestoredUser
      ? RestoredSessionDecision.validateAgainstEmulator
      : RestoredSessionDecision.noRestoredSession;
}

/// A session the emulator can no longer vouch for must never survive: the app
/// falls back to the normal signed-out state instead of failing every
/// protected read with `permission-denied`.
bool shouldDiscardRestoredSession({required bool tokenRefreshSucceeded}) =>
    !tokenRefreshSucceeded;

/// Expected emulator target for the current development session.
class DevBootstrapTarget {
  const DevBootstrapTarget({
    required this.projectId,
    required this.firestoreHost,
    required this.firestorePort,
    required this.authHost,
    required this.authPort,
    required this.envMode,
  });

  final String projectId;
  final String firestoreHost;
  final int firestorePort;
  final String authHost;
  final int authPort;
  final String envMode;
}

/// Persisted marker written after a successful development cold start.
class DevBootstrapMarker {
  const DevBootstrapMarker({
    required this.projectId,
    required this.firestoreHost,
    required this.firestorePort,
    required this.authHost,
    required this.authPort,
    required this.envMode,
    required this.configuredAtEpochMs,
  });

  final String projectId;
  final String firestoreHost;
  final int firestorePort;
  final String authHost;
  final int authPort;
  final String envMode;
  final int configuredAtEpochMs;

  bool matches(DevBootstrapTarget target) {
    return projectId == target.projectId &&
        firestoreHost == target.firestoreHost &&
        firestorePort == target.firestorePort &&
        authHost == target.authHost &&
        authPort == target.authPort &&
        envMode == target.envMode &&
        envMode == 'development';
  }

  Map<String, Object> toJson() => {
        'projectId': projectId,
        'firestoreHost': firestoreHost,
        'firestorePort': firestorePort,
        'authHost': authHost,
        'authPort': authPort,
        'envMode': envMode,
        'configuredAtEpochMs': configuredAtEpochMs,
      };

  static DevBootstrapMarker? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final projectId = json['projectId'];
    final firestoreHost = json['firestoreHost'];
    final firestorePort = json['firestorePort'];
    final authHost = json['authHost'];
    final authPort = json['authPort'];
    final envMode = json['envMode'];
    final configuredAtEpochMs = json['configuredAtEpochMs'];
    if (projectId is! String ||
        firestoreHost is! String ||
        firestorePort is! int ||
        authHost is! String ||
        authPort is! int ||
        envMode is! String ||
        configuredAtEpochMs is! int) {
      return null;
    }
    return DevBootstrapMarker(
      projectId: projectId,
      firestoreHost: firestoreHost,
      firestorePort: firestorePort,
      authHost: authHost,
      authPort: authPort,
      envMode: envMode,
      configuredAtEpochMs: configuredAtEpochMs,
    );
  }
}

/// Explicit runtime flags surfaced after bootstrap completes.
class FirebaseDevelopmentRuntime {
  const FirebaseDevelopmentRuntime({
    required this.envMode,
    required this.firebaseInitialized,
    required this.emulatorConfigured,
    required this.developmentVerified,
    required this.unsafeExistingRuntime,
    required this.persistenceEnabled,
    this.firestoreHost,
    this.firestorePort,
    this.authHost,
    this.authPort,
  });

  final String envMode;
  final bool firebaseInitialized;
  final bool emulatorConfigured;
  final bool developmentVerified;
  final bool unsafeExistingRuntime;
  final bool persistenceEnabled;
  final String? firestoreHost;
  final int? firestorePort;
  final String? authHost;
  final int? authPort;

  bool get allowsFirestoreAccess =>
      developmentVerified && !unsafeExistingRuntime && emulatorConfigured;
}

bool isProductionEnvMode([String envMode = kFirebaseEnvMode]) =>
    envMode == 'production';

bool requiresNativeDevelopmentGuard({
  required String envMode,
  required bool isWeb,
  required bool debugMode,
}) {
  return !isProductionEnvMode(envMode) && !isWeb && debugMode;
}

/// Resolve emulator host for the current platform.
String resolveEmulatorHost({
  required TargetPlatform platform,
  required String explicitHost,
  required bool isWeb,
}) {
  if (explicitHost.isNotEmpty) return explicitHost;
  if (isWeb) return 'localhost';
  if (platform == TargetPlatform.android) return '10.0.2.2';
  return '127.0.0.1';
}

DevelopmentBootstrapDecision decideDevelopmentBootstrap({
  required bool appsAlreadyInitialized,
  required DevBootstrapMarker? storedMarker,
  required DevBootstrapTarget expected,
  required bool requiresGuard,
}) {
  if (!requiresGuard) {
    if (isProductionEnvMode(expected.envMode)) {
      return DevelopmentBootstrapDecision.productionPath;
    }
    return DevelopmentBootstrapDecision.webDevelopmentPath;
  }

  if (appsAlreadyInitialized) {
    if (storedMarker != null && storedMarker.matches(expected)) {
      return DevelopmentBootstrapDecision.acceptVerifiedExisting;
    }
    return DevelopmentBootstrapDecision.failUnsafeExisting;
  }

  return DevelopmentBootstrapDecision.freshConfigure;
}
