import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/models/hizb_reservation.dart';
import 'package:anis_khatamat/core/utils/khatma_participant_id.dart';

void main() {
  group('KhatmaParticipantId', () {
    test('isLegacyGuestId détecte guest_*', () {
      expect(KhatmaParticipantId.isLegacyGuestId('guest_abc'), true);
      expect(KhatmaParticipantId.isLegacyGuestId('firebase_uid_xyz'), false);
    });

    test('ownsReservation avec uid canonique', () {
      const r = HizbReservation(
        status: HizbReservationStatus.reserved,
        reservedBy: 'uid123',
      );
      expect(KhatmaParticipantId.ownsReservation(r, 'uid123'), true);
      expect(KhatmaParticipantId.ownsReservation(r, 'other'), false);
    });

    test('ownsReservation compat legacy guest_xxx', () {
      const r = HizbReservation(
        status: HizbReservationStatus.reserved,
        reservedBy: 'guest_old',
      );
      expect(
        KhatmaParticipantId.ownsReservation(
          r,
          'uid_new',
          legacyGuestId: 'guest_old',
        ),
        true,
      );
    });

    test('displayNameFromKhatma uid puis legacy', () {
      final guests = {
        'uid_new': 'Ahmed',
        'guest_old': 'Fatima',
      };
      expect(
        KhatmaParticipantId.displayNameFromKhatma(
          guestParticipants: guests,
          participantId: 'uid_new',
        ),
        'Ahmed',
      );
      expect(
        KhatmaParticipantId.displayNameFromKhatma(
          guestParticipants: guests,
          participantId: 'uid_new',
          legacyGuestId: 'guest_old',
        ),
        'Ahmed',
      );
      expect(
        KhatmaParticipantId.displayNameFromKhatma(
          guestParticipants: {'guest_old': 'Fatima'},
          participantId: 'uid_new',
          legacyGuestId: 'guest_old',
        ),
        'Fatima',
      );
    });
  });
}
