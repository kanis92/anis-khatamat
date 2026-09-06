/// État du cycle de création d'une Khatma collaborative V2.
///
/// Utilisé uniquement pour les nouvelles Khatmat avec sous-collection.
/// Les Khatmat legacy sans ce champ sont considérées comme `ready` par défaut.
enum KhatmaCreationState {
  /// Création en cours : document parent créé, initialisation sous-collection en attente.
  initializing('initializing'),

  /// Création terminée : sous-collection initialisée, Khatma utilisable.
  ready('ready');

  final String value;
  const KhatmaCreationState(this.value);

  static KhatmaCreationState fromString(String? value) {
    if (value == null) return ready; // Legacy Khatmat sans ce champ
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => ready, // Fallback sûr pour valeurs inconnues
    );
  }

  bool get isReady => this == ready;
  bool get isInitializing => this == initializing;
}
