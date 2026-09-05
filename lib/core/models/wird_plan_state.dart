/// État runtime d'un plan de lecture personnel.
///
/// Déterminé dynamiquement en fonction de:
/// - Présence d'un plan actif dans Wird
/// - Dates du plan vs aujourd'hui
/// - Progression complétée vs objectif
enum WirdPlanState {
  /// Aucun plan actif (mode libre)
  none,

  /// Plan existe mais sa date de début est dans le futur
  scheduled,

  /// Plan en cours (entre baselineDate et endDate, non complété)
  active,

  /// Plan complété (tous les Rub' terminés)
  completed,

  /// Plan expiré (endDate dépassée, non complété)
  expired,
}
