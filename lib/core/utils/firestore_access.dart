import 'package:flutter/foundation.dart';

/// Codes stables pour les erreurs Auth/Firestore du parcours Khatma.
///
/// Journalisation volontairement sans email, uid ni identifiant de document :
/// assez pour diagnostiquer en développement, rien d'identifiant en production.
enum FirestoreAccessCode {
  authRequired,
  khatmaAccessDenied,
  khatmaNotFound,
  reservationConflict,
  networkError,
  unknown,
}

/// Classifie une exception Firebase/réseau sans exposer de PII.
FirestoreAccessCode classifyFirestoreError(Object error) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('permission-denied') || raw.contains('permission_denied')) {
    if (raw.contains('unauthenticated') || raw.contains('auth')) {
      // Le SDK Flutter n'ajoute pas toujours « unauthenticated » : un
      // permission-denied sans session est AUTH_REQUIRED côté appelant.
      return FirestoreAccessCode.khatmaAccessDenied;
    }
    return FirestoreAccessCode.khatmaAccessDenied;
  }
  if (raw.contains('unauthenticated') || raw.contains('auth-required')) {
    return FirestoreAccessCode.authRequired;
  }
  if (raw.contains('not-found') || raw.contains('not_found')) {
    return FirestoreAccessCode.khatmaNotFound;
  }
  if (raw.contains('already-exists') || raw.contains('aborted')) {
    return FirestoreAccessCode.reservationConflict;
  }
  if (raw.contains('unavailable') ||
      raw.contains('deadline-exceeded') ||
      raw.contains('network-request-failed') ||
      raw.contains('socket') ||
      raw.contains('connection')) {
    return FirestoreAccessCode.networkError;
  }
  return FirestoreAccessCode.unknown;
}

/// permission-denied sans utilisateur Firebase = AUTH_REQUIRED.
FirestoreAccessCode classifyFirestoreErrorWithAuth(
  Object error, {
  required bool hasFirebaseAuth,
}) {
  final code = classifyFirestoreError(error);
  if (code == FirestoreAccessCode.khatmaAccessDenied && !hasFirebaseAuth) {
    return FirestoreAccessCode.authRequired;
  }
  return code;
}

void logFirestoreAccess(
  String source,
  Object error, {
  required bool hasFirebaseAuth,
}) {
  if (!kDebugMode) return;
  final code = classifyFirestoreErrorWithAuth(
    error,
    hasFirebaseAuth: hasFirebaseAuth,
  );
  debugPrint('[FirestoreAccess] $source ${code.name}');
}
