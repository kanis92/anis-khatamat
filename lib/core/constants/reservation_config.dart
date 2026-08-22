import '../config/app_config.dart';

/// Configuration du module de réservation collaborative
/// Voir README_RESERVATION.md pour la documentation
class ReservationConfig {
  ReservationConfig._();

  /// Pré-réservation (soft lock) : durée pendant que l'utilisateur confirme
  static const int softLockSeconds = 30;

  /// Expiration réservation confirmée (heures)
  static const int reservationExpirationHours = 48;

  /// Prolongation possible 1 fois (+ heures)
  static const int extensionHours = 24;

  /// Limite max Hizb par personne (quand beaucoup libres)
  static const int maxHizbPerUserDefault = 3;

  /// Limite augmentée quand presque fini (>= completedCount)
  static const int completedThresholdForHigherLimit = 55;

  /// Limite max quand presque fini
  static const int maxHizbPerUserWhenAlmostDone = 6;

  /// Durée cache idempotency (éviter double tap)
  static const int idempotencyCacheMinutes = 5;

  /// URL base pour le lien web invité (PWA).
  /// Utilise AppConfig.webJoinBaseUrl (env + fallback Firebase Hosting).
  static String get webJoinBaseUrl => AppConfig.webJoinBaseUrl;
}
