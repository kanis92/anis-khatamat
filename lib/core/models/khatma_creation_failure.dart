import 'package:firebase_core/firebase_core.dart';

/// Échec typé de création de Khatma.
///
/// Permet de surfacer les erreurs sans exposer les exceptions Firebase brutes.
sealed class KhatmaCreationFailure implements Exception {
  const KhatmaCreationFailure({this.khatmaId});

  /// ID pré-alloué si le parent a déjà été écrit (retry doit le réutiliser).
  final String? khatmaId;

  /// Message localisé pour l'utilisateur (doit être fourni par l'UI avec l10n).
  String userMessageKey();

  /// Raison technique pour logging/debug (sanitizé, pas de données sensibles).
  String get technicalReason;

  KhatmaCreationFailure withKhatmaId(String id);
}

/// Authentification requise (email Firebase nécessaire).
class AuthenticationRequired extends KhatmaCreationFailure {
  const AuthenticationRequired({super.khatmaId});

  @override
  String userMessageKey() => 'khatmaCreationAuthRequired';

  @override
  String get technicalReason => 'No authenticated user with email';

  @override
  AuthenticationRequired withKhatmaId(String id) =>
      AuthenticationRequired(khatmaId: id);
}

/// Permission refusée par les règles Firestore.
class PermissionDenied extends KhatmaCreationFailure {
  const PermissionDenied({super.khatmaId});

  @override
  String userMessageKey() => 'khatmaCreationPermissionDenied';

  @override
  String get technicalReason => 'Firestore rules rejected write';

  @override
  PermissionDenied withKhatmaId(String id) => PermissionDenied(khatmaId: id);
}

/// Erreur réseau ou service indisponible.
class NetworkError extends KhatmaCreationFailure {
  const NetworkError({super.khatmaId});

  @override
  String userMessageKey() => 'khatmaCreationNetworkError';

  @override
  String get technicalReason => 'Network unavailable or timeout';

  @override
  NetworkError withKhatmaId(String id) => NetworkError(khatmaId: id);
}

/// Échec d'initialisation de la sous-collection.
class InitializationFailed extends KhatmaCreationFailure {
  const InitializationFailed(this.reason, {super.khatmaId});

  final String reason;

  @override
  String userMessageKey() => 'khatmaCreationInitFailed';

  @override
  String get technicalReason => 'Subcollection init failed: $reason';

  @override
  InitializationFailed withKhatmaId(String id) =>
      InitializationFailed(reason, khatmaId: id);
}

/// Erreur inconnue.
class UnknownCreationError extends KhatmaCreationFailure {
  const UnknownCreationError(this.message, {super.khatmaId});

  final String message;

  @override
  String userMessageKey() => 'khatmaCreationUnknown';

  @override
  String get technicalReason => 'Unknown error: $message';

  @override
  UnknownCreationError withKhatmaId(String id) =>
      UnknownCreationError(message, khatmaId: id);
}

/// Helper pour convertir une FirebaseException en KhatmaCreationFailure.
KhatmaCreationFailure fromFirebaseException(
  FirebaseException e, {
  String? khatmaId,
}) {
  switch (e.code) {
    case 'permission-denied':
    case 'unauthenticated':
      return PermissionDenied(khatmaId: khatmaId);
    case 'unavailable':
    case 'deadline-exceeded':
    case 'cancelled':
    case 'network-request-failed':
      return NetworkError(khatmaId: khatmaId);
    default:
      return UnknownCreationError('${e.plugin}/${e.code}', khatmaId: khatmaId);
  }
}
