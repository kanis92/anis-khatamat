/// Version du schéma de persistance des réservations collaboratives.
/// v1 : map embarquée `khatmat.hizbReservations`
/// v2 : sous-collection `khatmat/{id}/hizb_reservations/{hizbNumber}`
class ReservationSchema {
  ReservationSchema._();

  static const int legacyMap = 1;
  static const int subcollection = 2;

  static const String subcollectionName = 'hizb_reservations';
}
