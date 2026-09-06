import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/models/assignee_kind.dart';
import 'package:anis_khatamat/core/models/hizb_reservation.dart';
import 'package:anis_khatamat/core/utils/reservation_assignee_label.dart';

void main() {
  test('offline Fatima is displayed without a Firebase UID', () {
    const r = HizbReservation(
      status: HizbReservationStatus.reserved,
      reservedBy: 'jaouad@test.com',
      assigneeKind: AssigneeKind.offline,
      assigneeDisplayName: 'Fatima',
    );
    expect(r.assigneeUserId, isNull);
    final label = ReservationAssigneeLabel.fromReservation(
      r,
      actorDisplayName: 'Jaouad',
      reservedForPerson: (n) => 'Réservé pour $n',
      reservedByPerson: (n) => 'par $n',
      selfLabel: 'Moi',
      reservedFallback: 'Réservé',
    );
    expect(label.primary, 'Réservé pour Fatima');
    expect(label.secondary, 'par Jaouad');
    expect(label.offlineName, 'Fatima');
  });

  test('self reservation is not completed', () {
    const r = HizbReservation(
      status: HizbReservationStatus.reserved,
      reservedBy: 'jaouad@test.com',
      assigneeKind: AssigneeKind.self,
      assigneeUserId: 'jaouad@test.com',
    );
    expect(r.isCompleted, isFalse);
    expect(r.isReserved, isTrue);
    final label = ReservationAssigneeLabel.fromReservation(
      r,
      actorDisplayName: 'Jaouad',
      reservedForPerson: (n) => 'Réservé pour $n',
      reservedByPerson: (n) => 'par $n',
      selfLabel: 'Moi',
      reservedFallback: 'Réservé',
    );
    expect(label.primary, 'Moi');
    expect(label.offlineName, isNull);
  });
}
