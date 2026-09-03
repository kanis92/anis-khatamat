import '../models/wird.dart';
import '../resolvers/subdivision_definition_resolver.dart';
import './wird_rub_tracker.dart';

/// Service de tracking Wird avec résolution de définition runtime.
///
/// **Responsabilité:**
/// - Transformer Wird.subdivisionDefinitionId en SubdivisionDefinition concrète
/// - Créer WirdRubTracker avec la définition correcte
/// - Déléguer toutes opérations de tracking au tracker
///
/// **Principes:**
/// - Un seul tracker engine (WirdRubTracker)
/// - Résolution explicite avec erreur si définition inconnue
/// - Namespace automatiquement dérivé de definition.id par le tracker
class WirdTrackingService {
  final SubdivisionDefinitionResolver _resolver;

  WirdTrackingService(this._resolver);

  /// Service avec resolver production (Hafs 240 Rub' uniquement).
  factory WirdTrackingService.production() {
    return WirdTrackingService(SubdivisionDefinitionResolver.production());
  }

  /// Crée un tracker pour un Wird donné.
  ///
  /// Résout Wird.subdivisionDefinitionId en SubdivisionDefinition.
  /// Throw [UnknownSubdivisionDefinitionException] si l'ID n'est pas enregistré.
  WirdRubTracker createTracker(Wird wird) {
    final definition = _resolver.resolve(wird.subdivisionDefinitionId);
    return WirdRubTracker(definition: definition);
  }

  /// Vérifie si le Wird utilise une définition enregistrée.
  bool isDefinitionSupported(Wird wird) {
    return _resolver.isRegistered(wird.subdivisionDefinitionId);
  }

  /// Liste toutes les définitions disponibles.
  List<String> get availableDefinitions => _resolver.availableDefinitions;
}
