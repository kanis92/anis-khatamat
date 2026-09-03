import '../abstractions/subdivision_definition.dart';
import '../data/subdivision_definitions/hafs_quran_foundation_rub_240_v1.dart';

/// Exception levée lorsqu'une définition de subdivision demandée n'existe pas.
class UnknownSubdivisionDefinitionException implements Exception {
  final String definitionId;

  UnknownSubdivisionDefinitionException(this.definitionId);

  @override
  String toString() =>
      'Unknown subdivision definition: "$definitionId". '
      'Only registered definitions can be resolved. '
      'Available: hafs_quran_foundation_rub_240_v1';
}

/// Résolveur de définitions de subdivision canoniques.
///
/// Transforme un identifiant de définition (ex: 'hafs_quran_foundation_rub_240_v1')
/// en instance concrète de SubdivisionDefinition.
///
/// **Principes:**
/// - Seules les définitions explicitement enregistrées sont supportées
/// - ID inconnu → exception explicite (JAMAIS de fallback silencieux)
/// - Registry immuable après construction
///
/// **Production:** Actuellement seule Hafs 240 Rub' est enregistrée.
class SubdivisionDefinitionResolver {
  final Map<String, SubdivisionDefinition Function()> _registry;

  /// Crée un resolver avec un registry de définitions.
  ///
  /// [registry] map definitionId → factory function
  SubdivisionDefinitionResolver(this._registry);

  /// Resolver par défaut avec uniquement Hafs 240 Rub' V1.
  factory SubdivisionDefinitionResolver.production() {
    return SubdivisionDefinitionResolver({
      'hafs_quran_foundation_rub_240_v1': () =>
          HafsQuranFoundationRub240V1Definition(),
    });
  }

  /// Résout une définition par son ID.
  ///
  /// Throw [UnknownSubdivisionDefinitionException] si l'ID n'est pas enregistré.
  SubdivisionDefinition resolve(String definitionId) {
    final factory = _registry[definitionId];
    if (factory == null) {
      throw UnknownSubdivisionDefinitionException(definitionId);
    }
    return factory();
  }

  /// Vérifie si une définition est enregistrée.
  bool isRegistered(String definitionId) => _registry.containsKey(definitionId);

  /// Liste tous les IDs enregistrés.
  List<String> get availableDefinitions => _registry.keys.toList();
}
