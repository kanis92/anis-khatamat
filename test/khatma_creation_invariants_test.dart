import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/core/constants/hizb_definitions.dart';
import 'package:anis_khatamat/core/models/assignee_kind.dart';
import 'package:anis_khatamat/core/models/hizb_reservation.dart';
import 'package:anis_khatamat/core/models/khatma.dart';
import 'package:anis_khatamat/core/models/khatma_creation_failure.dart';
import 'package:anis_khatamat/core/models/khatma_creation_state.dart';
import 'package:anis_khatamat/core/repositories/hizb_index_repository.dart';
import 'package:anis_khatamat/core/ui/anis_hero_focal.dart';
import 'package:anis_khatamat/core/utils/khatma_collective.dart';

void main() {
  group('KhatmaCreationState', () {
    test('missing creationState is ready (legacy)', () {
      expect(KhatmaCreationState.fromString(null), KhatmaCreationState.ready);
    });

    test('initializing and ready parse', () {
      expect(
        KhatmaCreationState.fromString('initializing'),
        KhatmaCreationState.initializing,
      );
      expect(KhatmaCreationState.fromString('ready'), KhatmaCreationState.ready);
    });
  });

  group('Khatma.fromMap legacy', () {
    test('legacy document without creationState remains readable as ready', () {
      final k = Khatma.fromMap({
        'id': 'legacy-1',
        'title': 'Ancienne',
        'createdBy': 'a@test.com',
        'createdAt': DateTime.now().toIso8601String(),
        'isGroup': true,
      });
      expect(k.id, 'legacy-1');
      expect(k.isReadyForUse, isTrue);
    });
  });

  group('KhatmaCreationFailure', () {
    test('withKhatmaId preserves retry identity', () {
      const failure = NetworkError();
      final tagged = failure.withKhatmaId('abc123');
      expect(tagged.khatmaId, 'abc123');
      expect(tagged.userMessageKey(), 'khatmaCreationNetworkError');
    });
  });

  group('Canonical 60 Hizb', () {
    test('IDs and snapshots are exactly 1..60', () {
      const def = HizbDefinitions.quranFoundationHafsV1;
      for (var i = 1; i <= 60; i++) {
        final snap = HizbIndexRepository.reservationSnapshot(
          i,
          definitionId: def,
        );
        expect(snap.hizbNumber, i);
        expect(snap.hizbDefinitionId, def);
        expect(snap.startVerseKey, isNotEmpty);
        expect(snap.endVerseKey, isNotEmpty);
        expect(snap.startPageHafs, isNotNull);
        expect(snap.endPageHafs, isNotNull);
      }
    });
  });

  group('Collective counters and next available', () {
    test('empty map is 0+0+60 and next is 1', () {
      final c = KhatmaCollectiveCounters.fromReservations({});
      expect(c.completed, 0);
      expect(c.reserved, 0);
      expect(c.available, 60);
      expect(c.isValid, isTrue);
      expect(findNextAvailableHizb({}), 1);
    });

    test('skips reserved and completed', () {
      final map = <int, HizbReservation>{
        1: const HizbReservation(
          status: HizbReservationStatus.reserved,
          reservedBy: 'u',
        ),
        2: const HizbReservation(status: HizbReservationStatus.completed),
        3: const HizbReservation(status: HizbReservationStatus.available),
      };
      expect(findNextAvailableHizb(map), 3);
      final c = KhatmaCollectiveCounters.fromReservations(map);
      expect(c.completed, 1);
      expect(c.reserved, 1);
      expect(c.available, 58);
    });
  });

  group('Assignee semantics', () {
    test('self reservation has no display name', () {
      final r = HizbReservation(
        status: HizbReservationStatus.reserved,
        reservedBy: 'me@test.com',
        assigneeKind: AssigneeKind.self,
        assigneeUserId: 'me@test.com',
      );
      expect(r.assigneeDisplayName, isNull);
      expect(r.assignedByUserId, isNull);
    });

    test('offline reservation keeps display name only', () {
      final r = HizbReservation(
        status: HizbReservationStatus.reserved,
        reservedBy: 'me@test.com',
        assigneeKind: AssigneeKind.offline,
        assigneeDisplayName: 'Fatima',
      );
      expect(r.assigneeUserId, isNull);
      expect(r.assigneeDisplayName, 'Fatima');
    });
  });

  group('Hero composition', () {
    test('Arabic uses split panes, FR/EN keep cover', () {
      expect(AnisHeroFocal.usesSplitComposition('ar'), isTrue);
      expect(AnisHeroFocal.usesSplitComposition('fr'), isFalse);
      expect(AnisHeroFocal.usesSplitComposition('en'), isFalse);
      expect(AnisHeroFocal.arabicLogoFlex, greaterThan(0));
      expect(AnisHeroFocal.arabicCopyFlex, greaterThan(0));
    });
  });

  group('Collective all unavailable', () {
    test('next available is null when all reserved or completed', () {
      final map = <int, HizbReservation>{
        for (var i = 1; i <= 60; i++)
          i: HizbReservation(
            status: i.isEven
                ? HizbReservationStatus.reserved
                : HizbReservationStatus.completed,
            reservedBy: 'u',
          ),
      };
      expect(findNextAvailableHizb(map), isNull);
      final c = KhatmaCollectiveCounters.fromReservations(map);
      expect(c.total, 60);
      expect(c.available, 0);
      expect(c.isValid, isTrue);
    });
  });
}
