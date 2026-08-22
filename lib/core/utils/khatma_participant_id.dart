import 'package:firebase_auth/firebase_auth.dart';

import '../models/hizb_reservation.dart';

/// Identifiant canonique d'un participant Khatma côté Firestore.
/// - Compte email : email Firebase
/// - Invité anonyme : request.auth.uid (PAS guest_{uuid})
class KhatmaParticipantId {
  KhatmaParticipantId._();

  /// Identifiant utilisé dans reservedBy / softLockedBy / guestParticipants.
  static String? fromFirebaseUser(User? user) {
    if (user == null) return null;
    if (user.isAnonymous) return user.uid;
    final email = user.email?.trim();
    if (email == null || email.isEmpty) return null;
    return email;
  }

  /// Ancien format legacy (guest_{uuid}) encore présent dans les docs existants.
  static bool isLegacyGuestId(String id) => id.startsWith('guest_');

  /// L'utilisateur est-il propriétaire de cette réservation ?
  static bool ownsReservation(
    HizbReservation reservation,
    String participantId, {
    String? legacyGuestId,
  }) {
    final rb = reservation.reservedBy;
    final sl = reservation.softLockedBy;
    if (rb == participantId || sl == participantId) return true;
    if (legacyGuestId != null &&
        legacyGuestId.isNotEmpty &&
        isLegacyGuestId(legacyGuestId)) {
      if (rb == legacyGuestId || sl == legacyGuestId) return true;
    }
    return false;
  }

  /// Nom affiché dans guestParticipants (uid ou legacy guest_xxx).
  static String displayNameFromKhatma({
    required Map<String, String> guestParticipants,
    required String participantId,
    String? legacyGuestId,
  }) {
    if (guestParticipants.containsKey(participantId)) {
      return guestParticipants[participantId]!;
    }
    if (legacyGuestId != null &&
        legacyGuestId.isNotEmpty &&
        guestParticipants.containsKey(legacyGuestId)) {
      return guestParticipants[legacyGuestId]!;
    }
    return 'Anonyme';
  }
}
