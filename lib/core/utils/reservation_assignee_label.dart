import '../models/assignee_kind.dart';
import '../models/hizb_reservation.dart';

/// Libellés d'affichage pour une réservation (self / offline / participant).
class ReservationAssigneeLabel {
  const ReservationAssigneeLabel({
    required this.primary,
    this.secondary,
    this.offlineName,
  });

  final String primary;
  final String? secondary;
  final String? offlineName;

  static ReservationAssigneeLabel fromReservation(
    HizbReservation r, {
    required String actorDisplayName,
    required String Function(String name) reservedForPerson,
    required String Function(String name) reservedByPerson,
    required String selfLabel,
    required String reservedFallback,
  }) {
    final kind = r.assigneeKind ?? AssigneeKind.self;
    final offline = (r.assigneeDisplayName ?? r.reservedForName)?.trim();

    if (kind == AssigneeKind.offline && offline != null && offline.isNotEmpty) {
      return ReservationAssigneeLabel(
        primary: reservedForPerson(offline),
        secondary: reservedByPerson(actorDisplayName),
        offlineName: offline,
      );
    }

    if (kind == AssigneeKind.participant) {
      return ReservationAssigneeLabel(
        primary: reservedFallback,
        secondary: reservedByPerson(actorDisplayName),
      );
    }

    return ReservationAssigneeLabel(primary: selfLabel);
  }
}
