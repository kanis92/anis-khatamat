import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Charge les [FirebaseOptions] depuis `--dart-define` / `--dart-define-from-file`.
///
/// Aucune clé Firebase n'est embarquée dans le dépôt public.
/// Fournir un fichier privé (ex. `private/firebase/dart_defines.json`) en CI/local :
///
/// ```json
/// {
///   "FIREBASE_API_KEY": "...",
///   "FIREBASE_APP_ID": "...",
///   "FIREBASE_MESSAGING_SENDER_ID": "...",
///   "FIREBASE_PROJECT_ID": "...",
///   "FIREBASE_STORAGE_BUCKET": "...",
///   "FIREBASE_AUTH_DOMAIN": "...",
///   "FIREBASE_IOS_CLIENT_ID": "...",
///   "FIREBASE_IOS_BUNDLE_ID": "...",
///   "FIREBASE_MEASUREMENT_ID": "..."
/// }
/// ```
///
/// Champs requis minimum : API_KEY, APP_ID, MESSAGING_SENDER_ID, PROJECT_ID.
/// AUTH_DOMAIN requis pour Web ; IOS_CLIENT_ID / IOS_BUNDLE_ID recommandés pour iOS.
FirebaseOptions? resolveFirebaseOptionsFromEnvironment() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  if (apiKey.isEmpty || appId.isEmpty || messagingSenderId.isEmpty || projectId.isEmpty) {
    return null;
  }

  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const iosClientId = String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');
  const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    authDomain: authDomain.isEmpty ? null : authDomain,
    iosClientId: iosClientId.isEmpty ? null : iosClientId,
    iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
    measurementId: measurementId.isEmpty ? null : measurementId,
  );
}

/// Indique si la configuration build-time minimale est présente.
bool get hasFirebaseBuildConfig =>
    const String.fromEnvironment('FIREBASE_API_KEY').isNotEmpty &&
    const String.fromEnvironment('FIREBASE_APP_ID').isNotEmpty;

String get firebasePlatformLabel {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    default:
      return defaultTargetPlatform.name;
  }
}
