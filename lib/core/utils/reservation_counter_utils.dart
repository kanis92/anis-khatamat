import '../constants/app_constants.dart';
import '../models/hizb_reservation.dart';

/// Logique pure de compteur completedHizbCount (testable, mode collaboratif v2).
class ReservationCounterUtils {
  ReservationCounterUtils._();

  static int countCompleted(Map<int, HizbReservation> map) {
    return map.values.where((r) => r.isCompleted).length
        .clamp(0, AppConstants.totalHizb);
  }

  /// Indique si [done] doit être ignoré (idempotent / non autorisé).
  static bool shouldSkipDone(HizbReservation r, String userId) {
    if (r.reservedBy != userId) return true;
    if (r.isCompleted) return true;
    if (!r.isReserved && !r.isInProgress) return true;
    return false;
  }

  /// Incrément sécurisé du compteur parent (+1 max, plafond 60).
  /// Retourne null si le parent ne doit pas être modifié (déjà à 60).
  static int? nextCompletedCount(int currentCount) {
    if (currentCount >= AppConstants.totalHizb) return null;
    return (currentCount + 1).clamp(0, AppConstants.totalHizb);
  }

  static Map<int, HizbReservation> applyRelease(
    Map<int, HizbReservation> map,
    int hizbNumber,
  ) {
    final copy = Map<int, HizbReservation>.from(map);
    copy[hizbNumber] = HizbReservation(
      status: HizbReservationStatus.available,
      hizbNumber: hizbNumber,
    );
    return copy;
  }
}
