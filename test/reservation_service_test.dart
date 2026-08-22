import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/constants/reservation_config.dart';
import 'package:anis_khatamat/core/models/hizb_reservation.dart';
import 'package:anis_khatamat/core/models/khatma.dart';

void main() {
  group('ReservationConfig', () {
    test('paramètres ont des valeurs valides', () {
      expect(ReservationConfig.softLockSeconds, 30);
      expect(ReservationConfig.reservationExpirationHours, 48);
      expect(ReservationConfig.extensionHours, 24);
      expect(ReservationConfig.maxHizbPerUserDefault, 3);
      expect(ReservationConfig.maxHizbPerUserWhenAlmostDone, 6);
    });
  });

  group('HizbReservation', () {
    test('isAvailable inclut available et expired', () {
      expect(const HizbReservation(status: HizbReservationStatus.available).isAvailable, true);
      expect(const HizbReservation(status: HizbReservationStatus.expired).isAvailable, true);
      expect(const HizbReservation(status: HizbReservationStatus.reserved).isAvailable, false);
    });

    test('isReserved inclut reserved et inProgress', () {
      expect(
        HizbReservation(status: HizbReservationStatus.reserved, reservedBy: 'u1').isReserved,
        true,
      );
      expect(
        HizbReservation(status: HizbReservationStatus.inProgress, reservedBy: 'u1').isReserved,
        true,
      );
      expect(const HizbReservation(status: HizbReservationStatus.available).isReserved, false);
    });

    test('canExtend uniquement si extendedCount < 1', () {
      final r = HizbReservation(
        status: HizbReservationStatus.reserved,
        reservedBy: 'u1',
        extendedCount: 0,
      );
      expect(r.canExtend, true);

      final r2 = r.copyWith(extendedCount: 1);
      expect(r2.canExtend, false);
    });
  });

  group('Khatma reservedByUser', () {
    test('compte reserved et inProgress', () {
      final k = Khatma(
        id: '1',
        title: 'Test',
        isGroup: true,
        createdBy: 'admin',
        createdAt: DateTime.now(),
        reservationMode: true,
        hizbReservations: {
          1: HizbReservation(
            status: HizbReservationStatus.reserved,
            reservedBy: 'user1',
          ),
          2: HizbReservation(
            status: HizbReservationStatus.inProgress,
            reservedBy: 'user1',
          ),
          3: HizbReservation(
            status: HizbReservationStatus.completed,
            reservedBy: 'user1',
          ),
        },
      );
      expect(k.reservedByUser('user1'), 2);
    });
  });

  group('Simulation concurrence (logique)', () {
    test('deux réservations simultanées sur même Hizb : une seule doit gagner', () {
      final reservations = <int, HizbReservation>{
        1: const HizbReservation(status: HizbReservationStatus.available),
      };

      var r = reservations[1]!;
      final userA = 'userA';
      final userB = 'userB';

      r = HizbReservation(
        status: HizbReservationStatus.reserved,
        reservedBy: userA,
        reservedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 48)),
      );
      reservations[1] = r;

      final r2 = reservations[1]!;
      expect(r2.isAvailable, false);
      expect(r2.reservedBy, userA);

      if (r2.isAvailable) {
        reservations[1] = HizbReservation(
          status: HizbReservationStatus.reserved,
          reservedBy: userB,
          reservedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 48)),
        );
      }

      expect(reservations[1]!.reservedBy, userA);
    });
  });
}
