import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/core/data/subdivision_definitions/hafs_quran_foundation_rub_240_v1.dart';
import 'package:anis_khatamat/core/data/quran_subdivision_data.dart';
import 'package:anis_khatamat/core/models/subdivision_marker.dart';

/// Tests de régression Phase 0 : SubdivisionDefinition abstraction
///
/// Ces tests prouvent que la nouvelle abstraction SubdivisionDefinition
/// retourne EXACTEMENT les mêmes données que QuranSubdivisionData actuel.
///
/// **Invariants critiques:**
/// - 240 marqueurs Rub' identiques
/// - Coordonnées (surah:ayah) inchangées
/// - Ordre coranique préservé
/// - Comptage Hizb/Nisf/Rub' correct
void main() {
  group('Phase 0 Regression: HafsQuranFoundationRub240V1Definition', () {
    late HafsQuranFoundationRub240V1Definition definition;
    late List<HizbMarker> currentData;

    setUp(() {
      definition = HafsQuranFoundationRub240V1Definition();
      currentData = QuranSubdivisionData.getAllQuarters();
    });

    test('has correct metadata', () {
      expect(definition.id, 'hafs_quran_foundation_rub_240_v1');
      expect(definition.riwaya, 'hafs');
      expect(definition.totalSegments, 240);
      expect(definition.primaryGranularity, SubdivisionGranularity.rub);
      expect(
        definition.sourceAttribution,
        'Quran Foundation Content API v4 — Mushaf Al-Madina',
      );
    });

    test('returns exactly 240 markers', () {
      final markers = definition.getAllMarkers();
      expect(markers.length, 240);
      expect(currentData.length, 240);
    });

    test('all markers have identical (surah:ayah) coordinates', () {
      final markers = definition.getAllMarkers();

      for (var i = 0; i < 240; i++) {
        final newMarker = markers[i];
        final currentMarker = currentData[i];

        expect(
          newMarker.surah,
          currentMarker.surah,
          reason: 'Marker $i surah mismatch',
        );
        expect(
          newMarker.ayah,
          currentMarker.ayah,
          reason: 'Marker $i ayah mismatch',
        );
        expect(
          newMarker.hizbNumber,
          currentMarker.hizbNumber,
          reason: 'Marker $i hizbNumber mismatch',
        );
      }
    });

    test('segmentId matches original index (0-239)', () {
      final markers = definition.getAllMarkers();

      for (var i = 0; i < 240; i++) {
        expect(markers[i].segmentId, i);
      }
    });

    test('getMarker(id) returns correct marker', () {
      // Test premiers, milieu, derniers
      final testIds = [0, 1, 119, 120, 238, 239];

      for (final id in testIds) {
        final marker = definition.getMarker(id);
        final current = currentData[id];

        expect(marker.segmentId, id);
        expect(marker.surah, current.surah);
        expect(marker.ayah, current.ayah);
        expect(marker.hizbNumber, current.hizbNumber);
      }
    });

    test('getMarker throws RangeError for invalid IDs', () {
      expect(() => definition.getMarker(-1), throwsRangeError);
      expect(() => definition.getMarker(240), throwsRangeError);
      expect(() => definition.getMarker(999), throwsRangeError);
    });

    test('returns exactly 60 Hizb markers', () {
      final hizbMarkers = definition.getHizbMarkers();
      expect(hizbMarkers.length, 60);

      // Vérifier que ce sont bien les marqueurs de type Hizb
      for (final marker in hizbMarkers) {
        expect(marker.type, SubdivisionType.hizb);
      }

      // Vérifier les positions connues
      expect(hizbMarkers[0].surah, 1); // Hizb 1 = Al-Fatiha
      expect(hizbMarkers[0].ayah, 1);
      expect(hizbMarkers[0].hizbNumber, 1);

      expect(hizbMarkers[4].surah, 2); // Hizb 5
      expect(hizbMarkers[4].ayah, 253);
      expect(hizbMarkers[4].hizbNumber, 5);
    });

    test('returns exactly 120 Nisf markers (Hizb + Nisf)', () {
      final nisfMarkers = definition.getNisfMarkers();
      expect(nisfMarkers.length, 120); // 60 Hizb + 60 Nisf

      // Vérifier les types
      final types = nisfMarkers.map((m) => m.type).toSet();
      expect(types, {SubdivisionType.hizb, SubdivisionType.nisf});
    });

    test('getRubMarkers returns all 240 markers', () {
      final rubMarkers = definition.getRubMarkers();
      expect(rubMarkers.length, 240);

      // Doit être identique à getAllMarkers
      final allMarkers = definition.getAllMarkers();
      for (var i = 0; i < 240; i++) {
        expect(rubMarkers[i].segmentId, allMarkers[i].segmentId);
      }
    });

    test('getThumunMarkers throws UnsupportedError', () {
      expect(
        () => definition.getThumunMarkers(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('supportsGranularity correctly', () {
      expect(definition.supportsGranularity(SubdivisionGranularity.hizb), true);
      expect(definition.supportsGranularity(SubdivisionGranularity.nisf), true);
      expect(definition.supportsGranularity(SubdivisionGranularity.rub), true);
      expect(
          definition.supportsGranularity(SubdivisionGranularity.thumun), false);
    });

    test('markers are sorted in Quranic order', () {
      final markers = definition.getAllMarkers();

      for (var i = 1; i < markers.length; i++) {
        final prev = markers[i - 1];
        final curr = markers[i];

        // Current must be after previous
        final afterPrev = curr.surah > prev.surah ||
            (curr.surah == prev.surah && curr.ayah > prev.ayah);

        expect(
          afterPrev,
          true,
          reason: 'Markers not sorted at index $i: '
              '${prev.surah}:${prev.ayah} -> ${curr.surah}:${curr.ayah}',
        );
      }
    });

    test('getActiveMarkerAt returns correct marker', () {
      // Test cas connus
      
      // Position 1:1 (début Al-Fatiha) → Hizb 1
      final marker1 = definition.getActiveMarkerAt(
        1,
        1,
        granularity: SubdivisionGranularity.hizb,
      );
      expect(marker1, isNotNull);
      expect(marker1!.hizbNumber, 1);
      expect(marker1.type, SubdivisionType.hizb);

      // Position 2:253 (début Hizb 5) → Hizb 5
      final marker5 = definition.getActiveMarkerAt(
        2,
        253,
        granularity: SubdivisionGranularity.hizb,
      );
      expect(marker5, isNotNull);
      expect(marker5!.hizbNumber, 5);

      // Position 2:260 (entre Hizb 5 start et premier Rub') → Hizb 5
      final betweenMarker = definition.getActiveMarkerAt(
        2,
        260,
        granularity: SubdivisionGranularity.rub,
      );
      expect(betweenMarker, isNotNull);
      expect(betweenMarker!.hizbNumber, 5);
      expect(betweenMarker.type, SubdivisionType.hizb);
    });

    test('getMarkersCrossedBetween finds markers crossed', () {
      // Test franchissement Hizb 5 → 6
      // De 2:252 (juste avant Hizb 5 à 2:253)
      // À 3:20 (après début Hizb 6 à 3:15)
      final crossed = definition.getMarkersCrossedBetween(
        fromSurah: 2,
        fromAyah: 252,
        toSurah: 3,
        toAyah: 20,
        granularity: SubdivisionGranularity.hizb,
      );

      // Doit contenir Hizb 5 (id 16) et Hizb 6 (id 20)
      expect(crossed.length, 2);
      
      final markers = crossed.map((id) => definition.getMarker(id)).toList();
      final hizbNumbers = markers.map((m) => m.hizbNumber).toSet();
      expect(hizbNumbers, {5, 6});
    });

    test('getMarkersCrossedBetween with Rub granularity', () {
      // De 2:250 à 2:280 → devrait franchir plusieurs Rub' du Hizb 5
      final crossed = definition.getMarkersCrossedBetween(
        fromSurah: 2,
        fromAyah: 250,
        toSurah: 2,
        toAyah: 280,
        granularity: SubdivisionGranularity.rub,
      );

      // Hizb 5 commence à 2:253
      // Premier Rub' à 2:263
      // Nisf à 2:272
      // Devrait franchir au moins le Hizb 5 start et premier Rub'
      expect(crossed.length, greaterThanOrEqualTo(2));
    });

    test('getMarkersCrossedBetween returns empty if no markers crossed', () {
      // Même position
      final crossed1 = definition.getMarkersCrossedBetween(
        fromSurah: 2,
        fromAyah: 100,
        toSurah: 2,
        toAyah: 100,
        granularity: SubdivisionGranularity.hizb,
      );
      expect(crossed1, isEmpty);

      // Petit saut sans franchir de marqueur
      final crossed2 = definition.getMarkersCrossedBetween(
        fromSurah: 1,
        fromAyah: 2,
        toSurah: 1,
        toAyah: 5,
        granularity: SubdivisionGranularity.hizb,
      );
      expect(crossed2, isEmpty);
    });

    test('critical boundaries: Hizb 5 (2:253) validated', () {
      // Hizb 5 est à l'index 16 (4*4 = Hizb 5)
      final hizb5Marker = definition.getMarker(16);
      
      expect(hizb5Marker.hizbNumber, 5);
      expect(hizb5Marker.surah, 2);
      expect(hizb5Marker.ayah, 253);
      expect(hizb5Marker.type, SubdivisionType.hizb);
    });

    test('critical boundaries: last Hizb (60) exists', () {
      final hizb60Marker = definition.getMarker(236); // 59*4 = 236
      
      expect(hizb60Marker.hizbNumber, 60);
      expect(hizb60Marker.surah, 87);
      expect(hizb60Marker.ayah, 1);
      expect(hizb60Marker.type, SubdivisionType.hizb);
    });

    test('singleton pattern works', () {
      final instance1 = HafsQuranFoundationRub240V1Definition();
      final instance2 = HafsQuranFoundationRub240V1Definition();
      
      expect(identical(instance1, instance2), true);
    });

    group('SEMANTIC INVARIANTS — Marker Crossing', () {
      test('exact arrival on marker does NOT cross it', () {
        // Arriving EXACTLY at marker 1 (2:26) from 2:25
        final crossed = definition.getMarkersCrossedBetween(
          fromSurah: 2,
          fromAyah: 25,
          toSurah: 2,
          toAyah: 26, // Exact marker 1 position
          granularity: SubdivisionGranularity.rub,
        );

        // Must be EMPTY - exact arrival ≠ crossing
        expect(crossed, isEmpty,
            reason: 'Arriving at 2:26 (marker 1) does NOT cross it yet');
      });

      test('going beyond marker DOES cross it', () {
        // Going FROM 2:25 TO 2:27 crosses marker 1 (2:26)
        final crossed = definition.getMarkersCrossedBetween(
          fromSurah: 2,
          fromAyah: 25,
          toSurah: 2,
          toAyah: 27, // BEYOND marker 1
          granularity: SubdivisionGranularity.rub,
        );

        expect(crossed.length, 1);
        expect(crossed.contains(1), true,
            reason: 'Crossing beyond 2:26 crosses marker 1');
      });

      test('starting from marker 0 (1:1) crosses it when going beyond', () {
        // Starting FROM marker 0 (1:1) to 1:7
        // crossedAt(1:1) = {} (marker 0 at 1:1 is not STRICTLY before 1:1)
        // crossedAt(1:7) = {0} (marker 0 at 1:1 is STRICTLY before 1:7)
        // difference = {0}
        final crossed = definition.getMarkersCrossedBetween(
          fromSurah: 1,
          fromAyah: 1, // Exact marker 0
          toSurah: 1,
          toAyah: 7, // After marker 0
          granularity: SubdivisionGranularity.rub,
        );

        expect(crossed.contains(0), true,
            reason: 'Going from 1:1 to 1:7 crosses marker 0');
      });

      test('starting before marker 1 crosses it when going beyond', () {
        // From 2:25 (before marker 1 at 2:26) to 2:27 (after marker 1)
        final crossed = definition.getMarkersCrossedBetween(
          fromSurah: 2,
          fromAyah: 25,
          toSurah: 2,
          toAyah: 27,
          granularity: SubdivisionGranularity.rub,
        );

        expect(crossed.contains(1), true,
            reason: 'Crossing from 2:25 to 2:27 crosses marker 1 at 2:26');
      });

      test('marker 0 IS returned when crossed from before Quran start', () {
        // Conceptual test: reading from "nothing" to 1:5
        // In practice, first read is from implicit "nothing" state
        // findCrossedAt(1:5) includes marker 0
        final crossedAtPosition = <int>{};
        final markers = definition.getAllMarkers();
        
        for (final marker in markers) {
          if (marker.surah < 1 || (marker.surah == 1 && marker.ayah < 5)) {
            crossedAtPosition.add(marker.segmentId);
          }
        }
        
        // Marker 0 at 1:1 is before 1:5
        expect(crossedAtPosition.contains(0), true,
            reason: 'Marker 0 is included when position is after 1:1');
      });

      test('final marker to Quran end - no synthetic marker 240', () {
        // Reading from AFTER last defined marker (239) to Quran end (114:6)
        final lastMarker = definition.getMarker(239);

        // Start from position AFTER marker 239 (at its exact position + 1 ayah)
        final crossed = definition.getMarkersCrossedBetween(
          fromSurah: lastMarker.surah,
          fromAyah: lastMarker.ayah + 1, // AFTER marker 239, not AT it
          toSurah: 114,
          toAyah: 6, // Quran end
          granularity: SubdivisionGranularity.rub,
        );

        // No marker 240 exists in SubdivisionDefinition
        // Only 240 markers (0-239)
        // Starting AFTER marker 239, no new markers crossed
        expect(crossed, isEmpty,
            reason: 'No marker 240 exists - Quran-end handled by WirdRubTracker');
      });

      test('multiple markers crossed in one transition', () {
        // Large jump crossing multiple markers
        // From 2:25 (before marker 1) to 2:100 (after markers 1,2,3)
        final crossed = definition.getMarkersCrossedBetween(
          fromSurah: 2,
          fromAyah: 25,
          toSurah: 2,
          toAyah: 100,
          granularity: SubdivisionGranularity.rub,
        );

        // Should cross markers 1 (2:26), 2 (2:44), 3 (2:60)
        expect(crossed.length, greaterThanOrEqualTo(3));
        expect(crossed.contains(1), true);
        expect(crossed.contains(2), true);
        expect(crossed.contains(3), true);
      });

      test('backward movement returns empty', () {
        // Going backward should return empty (no new markers crossed)
        final crossed = definition.getMarkersCrossedBetween(
          fromSurah: 3,
          fromAyah: 50,
          toSurah: 2,
          toAyah: 100, // Backward
          granularity: SubdivisionGranularity.rub,
        );

        // Moving backward: crossedAt(to) is subset of crossedAt(from)
        // So difference is empty
        expect(crossed, isEmpty,
            reason: 'Backward movement crosses no new markers');
      });

      test('unsupported Thumun granularity rejected', () {
        expect(
          () => definition.getMarkersCrossedBetween(
            fromSurah: 1,
            fromAyah: 1,
            toSurah: 2,
            toAyah: 10,
            granularity: SubdivisionGranularity.thumun,
          ),
          throwsA(isA<UnsupportedError>()),
          reason: 'Thumun granularity not supported in Rub 240 definition',
        );
      });
    });
  });
}
