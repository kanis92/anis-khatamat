import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/models/khatma.dart';
import 'package:anis_khatamat/core/models/khatma_load_result.dart';
import 'package:anis_khatamat/core/services/khatma_link_service.dart';
import 'package:anis_khatamat/core/utils/khatma_navigation_utils.dart';

Khatma _k({
  required String id,
  String title = 'Test',
  bool reservationMode = false,
  String createdBy = 'a@test.com',
  List<String> members = const [],
  Map<String, String> guests = const {},
  List<String> participantIds = const [],
}) {
  return Khatma(
    id: id,
    title: title,
    createdBy: createdBy,
    createdAt: DateTime(2026, 1, 1),
    isGroup: true,
    reservationMode: reservationMode,
    members: members,
    guestParticipants: guests,
    participantIds: participantIds,
  );
}

void main() {
  group('KhatmaLinkService', () {
    test('11. URL invitation hash Web canonique', () {
      expect(
        KhatmaLinkService.joinUrl('abc123'),
        'https://anis-437c3.web.app/#/join/abc123',
      );
    });

    test('11b. chemins in-app', () {
      expect(KhatmaLinkService.joinPath('x'), '/join/x');
      expect(KhatmaLinkService.detailPath('x'), '/khatma/x');
      expect(KhatmaLinkService.webDetailUrl('x'), 'https://anis-437c3.web.app/#/khatma/x');
      expect(KhatmaLinkService.myKhatmasPath, '/khatma');
      expect(KhatmaLinkService.myKhatmasCreatePath, '/khatma?create=1');
      expect(KhatmaLinkService.completionPath('x'), '/khatma/x/completion');
    });
  });

  group('validatePreloadedKhatma / extra', () {
    test('1. extra valide si même id', () {
      final k = _k(id: 'id1', reservationMode: true);
      expect(validatePreloadedKhatma(k, 'id1'), k);
    });

    test('12. extra ignoré si id différent', () {
      final k = _k(id: 'other');
      expect(validatePreloadedKhatma(k, 'expected'), isNull);
    });

    test('2. sans extra → null seed', () {
      expect(validatePreloadedKhatma(null, 'id1'), isNull);
    });
  });

  group('resolveKhatmaSnapshot', () {
    test('2. fetch remplace absence d\'extra', () {
      final fetched = _k(id: 'k1');
      final resolved = resolveKhatmaSnapshot(
        khatmaId: 'k1',
        fetched: fetched,
      );
      expect(resolved?.id, 'k1');
    });

    test('stream prioritaire sur fetch', () {
      final fetched = _k(id: 'k1', title: 'old');
      final streamed = _k(id: 'k1', title: 'live');
      final resolved = resolveKhatmaSnapshot(
        khatmaId: 'k1',
        fetched: fetched,
        streamed: streamed,
      );
      expect(resolved?.title, 'live');
    });
  });

  group('khatmaExperienceFor', () {
    test('8. collaborative → HizbReservationScreen', () {
      expect(
        khatmaExperienceFor(_k(id: 'c', reservationMode: true)),
        KhatmaExperience.collaborative,
      );
    });

    test('9. classique → KhatmaDetailScreen', () {
      expect(
        khatmaExperienceFor(_k(id: 'c', reservationMode: false)),
        KhatmaExperience.classic,
      );
    });
  });

  group('userAlreadyInKhatma / join', () {
    test('7. membre existant détecté', () {
      final k = _k(id: 'k1', members: ['m@test.com'], participantIds: ['m@test.com']);
      expect(userAlreadyInKhatma(k, email: 'm@test.com'), isTrue);
    });

    test('6. invité anon détecté', () {
      final k = _k(id: 'k1', guests: {'uid_guest': 'Inv'}, participantIds: ['uid_guest']);
      expect(userAlreadyInKhatma(k, authUid: 'uid_guest'), isTrue);
    });

    test('5. outsider non membre', () {
      final k = _k(id: 'k1');
      expect(userAlreadyInKhatma(k, email: 'x@test.com'), isFalse);
    });
  });

  group('KhatmaLoadResult', () {
    test('4. notFound explicite', () {
      const r = KhatmaLoadResult.failure(KhatmaLoadFailure.notFound);
      expect(r.khatma, isNull);
      expect(r.failure, KhatmaLoadFailure.notFound);
    });

    test('5b. accessDenied explicite', () {
      const r = KhatmaLoadResult.failure(KhatmaLoadFailure.accessDenied);
      expect(r.failure, KhatmaLoadFailure.accessDenied);
    });
    test('3. deep link route détectée', () {
      expect(isKhatmaDeepLinkRoute('/khatma/abc'), isTrue);
      expect(isKhatmaDeepLinkRoute('/khatma'), isFalse);
      expect(isKhatmaDeepLinkRoute('/khatma/distribute'), isFalse);
    });
  });
}
