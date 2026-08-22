import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/models/hizb_reservation.dart';
import 'package:anis_khatamat/core/models/mushaf_open_target.dart';
import 'package:anis_khatamat/core/services/hizb_navigation_service.dart';
import 'package:anis_khatamat/core/utils/firestore_access.dart';
import 'package:anis_khatamat/core/utils/khatma_participant_id.dart';

/// Chaîne AUTH → réservation → navigation Mushaf, sans Firebase live.
/// Verrouille les identifiants transmis pour le Hizb 44.
void main() {
  test('Hizb 44 : réservation → cible → page 431 → displayedHizb 44', () {
    const reservation = HizbReservation(
      status: HizbReservationStatus.reserved,
      reservedBy: 'member@test.com',
      hizbNumber: 44,
    );
    expect(reservation.hizbNumber, 44);
    expect(reservation.reservedBy, 'member@test.com');

    const extra = {'hizb': 44};
    final target = MushafOpenTarget.fromRoute(
      extra,
      Uri.parse('/mushaf/hafs?hizb=44'),
    );
    expect(target.hizb, 44);

    final page = HizbNavigationService.startPage(44);
    expect(page, 431);
    expect(HizbNavigationService.displayedHizb(page, reservedHizb: 44), 44);
    expect(HizbNavigationService.displayedHizb(page), isNot(43));
  });

  test(
    'Hizb 44 : Continuer dans le Hizb conserve 44, hors Hizb replie sur 431',
    () {
      final start = HizbNavigationService.startPage(44);
      expect(start, 431);
      final resumed = HizbNavigationService.openResume(44, 436);
      expect(
        HizbNavigationService.displayedHizb(resumed, reservedHizb: 44),
        44,
      );

      final fallback = HizbNavigationService.openResume(44, 12);
      expect(fallback, 431);
      expect(
        HizbNavigationService.displayedHizb(fallback, reservedHizb: 44),
        44,
      );
    },
  );

  test('identifiant membre = email, invité = uid, legacy guest_ reconnu', () {
    expect(KhatmaParticipantId.isLegacyGuestId('guest_abc'), isTrue);
    expect(KhatmaParticipantId.isLegacyGuestId('anonUid123'), isFalse);

    const mine = HizbReservation(
      status: HizbReservationStatus.reserved,
      reservedBy: 'member@test.com',
      hizbNumber: 44,
    );
    expect(
      KhatmaParticipantId.ownsReservation(mine, 'member@test.com'),
      isTrue,
    );
    expect(
      KhatmaParticipantId.ownsReservation(mine, 'other@test.com'),
      isFalse,
    );

    const legacy = HizbReservation(
      status: HizbReservationStatus.reserved,
      reservedBy: 'guest_old',
      hizbNumber: 44,
    );
    expect(
      KhatmaParticipantId.ownsReservation(
        legacy,
        'firebaseUid',
        legacyGuestId: 'guest_old',
      ),
      isTrue,
    );
  });

  test('classification permission-denied sans session = AUTH_REQUIRED', () {
    const err =
        '[cloud_firestore/permission-denied] The caller does not have permission';
    expect(
      classifyFirestoreErrorWithAuth(err, hasFirebaseAuth: false),
      FirestoreAccessCode.authRequired,
    );
    expect(
      classifyFirestoreErrorWithAuth(err, hasFirebaseAuth: true),
      FirestoreAccessCode.khatmaAccessDenied,
    );
    expect(
      classifyFirestoreError('socket exception'),
      FirestoreAccessCode.networkError,
    );
    expect(
      classifyFirestoreError('not-found'),
      FirestoreAccessCode.khatmaNotFound,
    );
  });
}
