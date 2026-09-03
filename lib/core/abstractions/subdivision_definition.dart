import '../models/subdivision_marker.dart';

/// Définition canonique de subdivisions coraniques.
///
/// Une définition représente un ensemble cohérent de marqueurs de subdivision
/// provenant d'une source spécifique et versionnée.
///
/// **Principes:**
/// - Chaque définition a un ID immuable reflétant sa provenance
/// - Les coordonnées sont UNIQUEMENT coraniques (surah:ayah)
/// - Aucune pagination Mushaf n'est stockée ici
/// - Le nombre de segments dépend de la granularité de la définition
///
/// **Exemples:**
/// - `hafs_quran_foundation_rub_240_v1` : 240 Rub' Hafs (4 par Hizb)
/// - `warsh_wikisource_thumun_480_v1` : 480 Thumun Warsh (8 par Hizb)
abstract class SubdivisionDefinition {
  /// Identifiant unique et immuable.
  ///
  /// Format: `{riwaya}_{source}_{granularity}_{count}_v{version}`
  ///
  /// Exemples:
  /// - `hafs_quran_foundation_rub_240_v1`
  /// - `warsh_wikisource_thumun_480_v1`
  String get id;

  /// Riwaya (narration) du Quran
  /// Ex: "hafs", "warsh", "qalun"
  String get riwaya;

  /// Source des données avec attribution complète
  /// Ex: "Quran Foundation Content API v4"
  String get sourceAttribution;

  /// Nombre total de segments dans cette définition
  /// Ex: 240 pour Rub', 480 pour Thumun
  int get totalSegments;

  /// Granularité principale de cette définition
  /// Ex: SubdivisionGranularity.rub pour une définition de 240 Rub'
  SubdivisionGranularity get primaryGranularity;

  /// Retourne le marqueur par ID global (0-indexed)
  ///
  /// [segmentId] doit être dans [0, totalSegments)
  /// Throw [RangeError] si hors limites
  SubdivisionMarker getMarker(int segmentId);

  /// Retourne tous les marqueurs, triés par ordre coranique
  List<SubdivisionMarker> getAllMarkers();

  /// Retourne les marqueurs de début de Hizb (60 marqueurs)
  ///
  /// Toujours disponible quelle que soit la granularité primaire
  List<SubdivisionMarker> getHizbMarkers();

  /// Retourne les marqueurs Rub' (240 marqueurs, 4 par Hizb)
  ///
  /// Disponible si la définition supporte la granularité Rub' ou plus fine
  /// Throw [UnsupportedError] si non disponible
  List<SubdivisionMarker> getRubMarkers();

  /// Retourne les marqueurs Nisf (120 marqueurs, 2 par Hizb)
  ///
  /// Disponible si la définition supporte la granularité Nisf ou plus fine
  /// Throw [UnsupportedError] si non disponible
  List<SubdivisionMarker> getNisfMarkers();

  /// Retourne les marqueurs Thumun (480 marqueurs, 8 par Hizb)
  ///
  /// Disponible uniquement si la définition primaire est Thumun
  /// Throw [UnsupportedError] si non disponible
  List<SubdivisionMarker> getThumunMarkers();

  /// Vérifie si une granularité est supportée par cette définition
  bool supportsGranularity(SubdivisionGranularity granularity);

  /// Retourne le marqueur actif à une position coranique donnée
  ///
  /// Le marqueur "actif" est le dernier marqueur complété lorsqu'on atteint
  /// la position [surah]:[ayah].
  ///
  /// [granularity] détermine le niveau de détail recherché
  SubdivisionMarker? getActiveMarkerAt(
    int surah,
    int ayah, {
    required SubdivisionGranularity granularity,
  });

  /// Trouve les marqueurs franchis lors d'un déplacement entre deux positions
  ///
  /// Retourne l'ensemble des IDs de marqueurs qui deviennent "franchis"
  /// (crossed) lors du passage de la position FROM à la position TO.
  ///
  /// Un marqueur est "franchi" s'il devient strictement AVANT la position TO
  /// alors qu'il n'était pas strictement avant la position FROM.
  ///
  /// **Sémantique pure géométrique :**
  /// - Retourne `findCrossedAt(TO) - findCrossedAt(FROM)`
  /// - Où `findCrossedAt(pos)` = marqueurs strictement avant `pos`
  /// - Arrivée exacte sur un marqueur ne le franchit PAS
  /// - Aller au-delà le franchit
  ///
  /// **Aucune interprétation métier :**
  /// - Peut retourner marker 0 (début absolu)
  /// - Ne crée pas de marker 240 synthétique
  /// - La logique Wird (filtrage, ajouts) reste dans WirdRubTracker
  ///
  /// [granularity] détermine quels marqueurs sont considérés
  Set<int> getMarkersCrossedBetween({
    required int fromSurah,
    required int fromAyah,
    required int toSurah,
    required int toAyah,
    required SubdivisionGranularity granularity,
  });
}
