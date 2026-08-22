import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/constants/reservation_schema.dart';
import 'package:anis_khatamat/core/models/hizb_reservation.dart';
import 'package:anis_khatamat/core/models/khatma.dart';

void main() {
  group('Migration v1 → v2 (logique modèle)', () {
    test('completedReservationCount utilise completedHizbCount dénormalisé', () {
      final k = Khatma(
        id: 'k2',
        title: 'T',
        isGroup: true,
        createdBy: 'a@test.com',
        createdAt: DateTime.now(),
        reservationMode: true,
        reservationSchemaVersion: ReservationSchema.subcollection,
        completedHizbCount: 42,
        hizbReservations: {},
      );
      expect(k.completedReservationCount, 42);
      expect(k.usesSubcollectionReservations, true);
    });

    test('legacy map v1 conserve reservedBy guest_*', () {
      final k = Khatma(
        id: 'legacy',
        title: 'Legacy',
        isGroup: true,
        createdBy: 'c@test.com',
        createdAt: DateTime.now(),
        reservationMode: true,
        hizbReservations: {
          5: HizbReservation(
            status: HizbReservationStatus.reserved,
            reservedBy: 'guest_abc',
            reservedForName: 'Ahmed',
          ),
          8: HizbReservation(
            status: HizbReservationStatus.completed,
            reservedBy: 'guest_abc',
            completedAt: DateTime.now(),
          ),
        },
      );
      expect(k.usesSubcollectionReservations, false);
      expect(k.hizbReservations[5]!.reservedBy, 'guest_abc');
      expect(k.hizbReservations[8]!.isCompleted, true);
    });

    test('HizbReservation.toMap inclut hizbNumber pour sous-collection', () {
      final map = HizbReservation(
        status: HizbReservationStatus.reserved,
        reservedBy: 'uid123',
        hizbNumber: 24,
      ).toMap(hizbNumberOverride: 24);
      expect(map['hizbNumber'], 24);
      expect(map['status'], 'reserved');
      expect(map['reservedBy'], 'uid123');
    });
  });
}
