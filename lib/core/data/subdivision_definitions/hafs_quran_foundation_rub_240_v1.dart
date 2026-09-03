import '../../abstractions/subdivision_definition.dart';
import '../../data/quran_subdivision_data.dart';
import '../../models/subdivision_marker.dart';

/// Implémentation Hafs des 240 Rub' al-Hizb.
///
/// Source: Quran Foundation Content API v4
/// Données: QuranSubdivisionData (240 marqueurs Rub', 4 par Hizb)
///
/// Cette implémentation est un wrapper transparent autour des données
/// de production actuelles pour préserver la compatibilité totale.
class HafsQuranFoundationRub240V1Definition implements SubdivisionDefinition {
  HafsQuranFoundationRub240V1Definition._();

  static final HafsQuranFoundationRub240V1Definition _instance =
      HafsQuranFoundationRub240V1Definition._();

  factory HafsQuranFoundationRub240V1Definition() => _instance;

  @override
  String get id => 'hafs_quran_foundation_rub_240_v1';

  @override
  String get riwaya => 'hafs';

  @override
  String get sourceAttribution =>
      'Quran Foundation Content API v4 — Mushaf Al-Madina';

  @override
  int get totalSegments => 240;

  @override
  SubdivisionGranularity get primaryGranularity => SubdivisionGranularity.rub;

  // Cache pour éviter de recréer les marqueurs
  List<SubdivisionMarker>? _cachedMarkers;

  @override
  SubdivisionMarker getMarker(int segmentId) {
    if (segmentId < 0 || segmentId >= totalSegments) {
      throw RangeError.range(segmentId, 0, totalSegments - 1, 'segmentId');
    }
    return getAllMarkers()[segmentId];
  }

  @override
  List<SubdivisionMarker> getAllMarkers() {
    if (_cachedMarkers != null) return _cachedMarkers!;

    final markers = <SubdivisionMarker>[];
    final allQuarters = QuranSubdivisionData.getAllQuarters();

    for (var i = 0; i < allQuarters.length; i++) {
      final quarter = allQuarters[i];

      // Déterminer le type selon subdivisionIndex
      // 0 = Hizb, 2 = premier Rub', 4 = Nisf, 6 = second Rub'
      final SubdivisionType type;
      final int indexInHizb;

      if (quarter.subdivisionIndex == 0) {
        type = SubdivisionType.hizb;
        indexInHizb = 0;
      } else if (quarter.subdivisionIndex == 4) {
        type = SubdivisionType.nisf;
        indexInHizb = 2;
      } else {
        type = SubdivisionType.rub;
        // subdivisionIndex 2 → indexInHizb 1, subdivisionIndex 6 → indexInHizb 3
        indexInHizb = quarter.subdivisionIndex == 2 ? 1 : 3;
      }

      markers.add(
        SubdivisionMarker(
          segmentId: i,
          hizbNumber: quarter.hizbNumber,
          type: type,
          indexInHizb: indexInHizb,
          surah: quarter.surah,
          ayah: quarter.ayah,
        ),
      );
    }

    _cachedMarkers = List.unmodifiable(markers);
    return _cachedMarkers!;
  }

  @override
  List<SubdivisionMarker> getHizbMarkers() {
    return getAllMarkers()
        .where((m) => m.type == SubdivisionType.hizb)
        .toList();
  }

  @override
  List<SubdivisionMarker> getRubMarkers() {
    // Toutes les 240 sont des marqueurs Rub' ou supérieurs
    return getAllMarkers();
  }

  @override
  List<SubdivisionMarker> getNisfMarkers() {
    return getAllMarkers()
        .where((m) =>
            m.type == SubdivisionType.hizb || m.type == SubdivisionType.nisf)
        .toList();
  }

  @override
  List<SubdivisionMarker> getThumunMarkers() {
    throw UnsupportedError(
      'Thumun (480 segments) not available in $id. '
      'Only Rub\' (240 segments) are defined.',
    );
  }

  @override
  bool supportsGranularity(SubdivisionGranularity granularity) {
    switch (granularity) {
      case SubdivisionGranularity.hizb:
      case SubdivisionGranularity.nisf:
      case SubdivisionGranularity.rub:
        return true;
      case SubdivisionGranularity.thumun:
        return false;
    }
  }

  @override
  SubdivisionMarker? getActiveMarkerAt(
    int surah,
    int ayah, {
    required SubdivisionGranularity granularity,
  }) {
    if (!supportsGranularity(granularity)) {
      throw UnsupportedError('Granularity $granularity not supported by $id');
    }

    final candidates = _getMarkersForGranularity(granularity);
    SubdivisionMarker? active;

    for (final marker in candidates) {
      if (_isBeforeOrAt(marker.surah, marker.ayah, surah, ayah)) {
        active = marker;
      } else {
        break; // Markers are sorted, no need to continue
      }
    }

    return active;
  }

  @override
  Set<int> getMarkersCrossedBetween({
    required int fromSurah,
    required int fromAyah,
    required int toSurah,
    required int toAyah,
    required SubdivisionGranularity granularity,
  }) {
    if (!supportsGranularity(granularity)) {
      throw UnsupportedError('Granularity $granularity not supported by $id');
    }

    // Trouver tous les marqueurs franchis à chaque position
    final crossedAtTo = _findCrossedAt(toSurah, toAyah, granularity);
    final crossedAtFrom = _findCrossedAt(fromSurah, fromAyah, granularity);

    // Retourner les marqueurs nouvellement franchis
    return crossedAtTo.difference(crossedAtFrom);
  }

  /// Trouve tous les marqueurs franchis (strictement avant) une position
  Set<int> _findCrossedAt(
    int surah,
    int ayah,
    SubdivisionGranularity granularity,
  ) {
    final crossed = <int>{};
    final candidates = _getMarkersForGranularity(granularity);

    for (final marker in candidates) {
      // Un marqueur est franchi s'il est STRICTEMENT AVANT la position
      if (_isAfter(surah, ayah, marker.surah, marker.ayah)) {
        crossed.add(marker.segmentId);
      }
    }

    return crossed;
  }

  // Helpers

  List<SubdivisionMarker> _getMarkersForGranularity(
      SubdivisionGranularity granularity) {
    switch (granularity) {
      case SubdivisionGranularity.hizb:
        return getHizbMarkers();
      case SubdivisionGranularity.nisf:
        return getNisfMarkers();
      case SubdivisionGranularity.rub:
        return getRubMarkers();
      case SubdivisionGranularity.thumun:
        throw UnsupportedError('Thumun not supported');
    }
  }

  /// Vrai si (surah1, ayah1) est strictement après (surah2, ayah2)
  bool _isAfter(int surah1, int ayah1, int surah2, int ayah2) {
    if (surah1 > surah2) return true;
    if (surah1 < surah2) return false;
    return ayah1 > ayah2;
  }

  /// Vrai si (surah1, ayah1) est avant ou égal à (surah2, ayah2)
  /// Utilisé pour getActiveMarkerAt (trouve le dernier marqueur avant ou à la position)
  bool _isBeforeOrAt(int surah1, int ayah1, int surah2, int ayah2) {
    return !_isAfter(surah1, ayah1, surah2, ayah2);
  }
}
