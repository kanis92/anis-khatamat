import '../services/reservation_service.dart';

/// Utilitaires pour afficher des messages d'erreur conviviaux à l'utilisateur.
/// Évite d'afficher des détails techniques bruts (ex: "Erreur: $e").
class ErrorUtils {
  ErrorUtils._();

  /// Retourne un message lisible pour l'utilisateur selon le type d'erreur.
  static String userMessage(Object error, {String? fallback}) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
      return 'Vérifiez votre connexion internet et réessayez.';
    }
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Accès refusé. Vérifiez vos autorisations.';
    }
    if (msg.contains('firebase') || msg.contains('firestore')) {
      return 'Erreur de synchronisation. Réessayez dans quelques instants.';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'La requête a expiré. Réessayez.';
    }
    return fallback ?? 'Une erreur est survenue. Réessayez.';
  }

  /// Message pour création Khatma
  static String creationMessage(Object error) =>
      userMessage(error, fallback: 'Impossible de créer la Khatma. Réessayez.');

  /// Message pour enregistrement / sauvegarde
  static String saveMessage(Object error) =>
      userMessage(error, fallback: 'Impossible d\'enregistrer. Réessayez.');

  /// Message pour réservation (ReservationException ou réseau).
  static String reservationMessage(Object error) {
    if (error is ReservationException) {
      switch (error.code) {
        case ReservationErrorCode.alreadyReserved:
          return error.message;
        case ReservationErrorCode.limitReached:
          return error.message;
        case ReservationErrorCode.expired:
          return 'Cette réservation a expiré.';
        case ReservationErrorCode.notYours:
          return 'Ce Hizb ne vous appartient pas.';
        case ReservationErrorCode.alreadyExtended:
          return 'Prolongation déjà utilisée.';
        case ReservationErrorCode.invalidState:
          return error.message;
        case ReservationErrorCode.softLockExpired:
          return 'Délai de confirmation dépassé. Réessayez.';
      }
    }
    return userMessage(error, fallback: 'Erreur lors de la réservation. Réessayez.');
  }
}
