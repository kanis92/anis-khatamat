import '../constants/app_constants.dart';
import '../models/hizb_reservation.dart';

/// Compteurs collectifs : terminés + réservés + disponibles = 60.
class KhatmaCollectiveCounters {
  const KhatmaCollectiveCounters({
    required this.completed,
    required this.reserved,
    required this.available,
  });

  final int completed;
  final int reserved;
  final int available;

  int get total => completed + reserved + available;

  bool get isValid => total == AppConstants.totalHizb;

  static KhatmaCollectiveCounters fromReservations(
    Map<int, HizbReservation> reservations,
  ) {
    var completed = 0;
    var reserved = 0;
    for (var i = 1; i <= AppConstants.totalHizb; i++) {
      final r = reservations[i];
      if (r == null || r.isAvailable) continue;
      if (r.isCompleted) {
        completed++;
      } else {
        reserved++;
      }
    }
    return KhatmaCollectiveCounters(
      completed: completed,
      reserved: reserved,
      available: AppConstants.totalHizb - completed - reserved,
    );
  }
}

/// Premier Hizb available dans l'ordre canonique 1..60.
int? findNextAvailableHizb(Map<int, HizbReservation> reservations) {
  for (var i = 1; i <= AppConstants.totalHizb; i++) {
    final r = reservations[i];
    if (r == null || r.isAvailable) return i;
  }
  return null;
}
