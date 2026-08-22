import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/constants/hizb_definitions.dart';
import 'package:anis_khatamat/core/constants/reservation_schema.dart';
import 'package:anis_khatamat/core/models/hizb_reservation.dart';
import 'package:anis_khatamat/core/models/khatma.dart';
import 'package:anis_khatamat/core/models/mushaf_open_target.dart';
import 'package:anis_khatamat/core/repositories/hizb_index_repository.dart';
import 'package:anis_khatamat/core/services/hizb_navigation_service.dart';

void main() {
  const definitionId = HizbDefinitions.quranFoundationHafsV1;

  Khatma newCanonicalKhatma({String id = 'local_test'}) => Khatma(
        id: id,
        title: 'Canonical test',
        isGroup: true,
        createdBy: 'user@test.com',
        createdAt: DateTime(2026, 8, 22),
        reservationMode: true,
        reservationSchemaVersion: ReservationSchema.subcollection,
        hizbDefinitionId: definitionId,
      );

  group('Création Khatma canonique', () {
    test('nouvelle Khatma écrit quran_foundation_hafs_v1', () {
      final k = newCanonicalKhatma();
      expect(k.hizbDefinitionId, definitionId);
      expect(k.hasSupportedHizbDefinition, isTrue);
      expect(k.toMap()['hizbDefinitionId'], definitionId);
    });

    test('Khatma sans définition n’est pas interprétée comme canonical', () {
      final k = Khatma(
        id: 'legacy',
        title: 'Legacy',
        isGroup: true,
        createdBy: 'user@test.com',
        createdAt: DateTime(2026, 8, 22),
        reservationMode: true,
      );
      expect(k.hasSupportedHizbDefinition, isFalse);
      expect(k.hizbDefinitionId, isNull);
      expect(
        () => HizbIndexRepository.getByDefinition(44, definitionId: null),
        throwsA(isA<UnsupportedHizbDefinitionException>()),
      );
    });
  });

  group('Snapshots réservation', () {
    test('60 réservations ont définition canonical', () {
      for (var i = 1; i <= 60; i++) {
        final snap = HizbIndexRepository.reservationSnapshot(
          i,
          definitionId: definitionId,
        );
        expect(snap.hizbDefinitionId, definitionId);
        expect(snap.hasCompleteSnapshot, isTrue);
      }
    });

    test('H44 snapshot = 34:24 → 36:27, pages 431–441', () {
      final snap = HizbIndexRepository.reservationSnapshot(
        44,
        definitionId: definitionId,
      );
      expect(snap.startVerseKey, '34:24');
      expect(snap.endVerseKey, '36:27');
      expect(snap.startPageHafs, 431);
      expect(snap.endPageHafs, 441);
    });

    test('H58 canonical', () {
      final snap = HizbIndexRepository.reservationSnapshot(
        58,
        definitionId: definitionId,
      );
      expect(snap.startVerseKey, '72:1');
      expect(snap.endVerseKey, '77:50');
      expect(snap.startPageHafs, 572);
      expect(snap.endPageHafs, 581);
    });

    test('H59 canonical', () {
      final snap = HizbIndexRepository.reservationSnapshot(
        59,
        definitionId: definitionId,
      );
      expect(snap.startVerseKey, '78:1');
      expect(snap.endVerseKey, '86:17');
      expect(snap.startPageHafs, 582);
      expect(snap.endPageHafs, 591);
    });

    test('H60 canonical', () {
      final snap = HizbIndexRepository.reservationSnapshot(
        60,
        definitionId: definitionId,
      );
      expect(snap.startVerseKey, '87:1');
      expect(snap.endVerseKey, '114:6');
      expect(snap.startPageHafs, 591);
      expect(snap.endPageHafs, 604);
    });

    test('transitionTo préserve le snapshot immuable', () {
      final base = HizbIndexRepository.reservationSnapshot(
        44,
        definitionId: definitionId,
      );
      final reserved = base.transitionTo(
        status: HizbReservationStatus.reserved,
        reservedBy: 'user@test.com',
      );
      expect(reserved.startVerseKey, '34:24');
      expect(reserved.endVerseKey, '36:27');
      expect(reserved.hizbDefinitionId, definitionId);
      expect(reserved.startPageHafs, 431);
      expect(reserved.endPageHafs, 441);
    });
  });

  group('Navigation Mushaf', () {
    test('Lire H44 → page 431', () {
      expect(
        HizbNavigationService.startPageForDefinition(
          44,
          definitionId: definitionId,
        ),
        431,
      );
    });

    test('Continuer reste dans H44 canonical', () {
      final resumed = HizbNavigationService.openResumeForDefinition(
        44,
        436,
        definitionId: definitionId,
      );
      expect(resumed, 436);
      expect(
        HizbNavigationService.displayedHizbForDefinition(
          resumed,
          definitionId: definitionId,
          reservedHizb: 44,
        ),
        44,
      );

      final fallback = HizbNavigationService.openResumeForDefinition(
        44,
        12,
        definitionId: definitionId,
      );
      expect(fallback, 431);
    });

    test('libre navigation Mushaf utilise canonical par défaut', () {
      expect(HizbNavigationService.startPage(44), 431);
      final target = MushafOpenTarget.fromRoute(
        null,
        Uri.parse('/mushaf/hafs?hizb=44'),
      );
      expect(target.hizb, 44);
      expect(target.hizbDefinitionId, isNull);
    });

    test('navigation Khatma exige définition explicite via extra', () {
      final target = MushafOpenTarget.fromRoute(
        {'hizb': 44, 'hizbDefinitionId': definitionId},
        Uri.parse('/mushaf/hafs'),
      );
      expect(target.hizb, 44);
      expect(target.hizbDefinitionId, definitionId);
      expect(
        HizbNavigationService.startPageForDefinition(
          target.hizb!,
          definitionId: target.hizbDefinitionId,
        ),
        431,
      );
    });
  });
}
