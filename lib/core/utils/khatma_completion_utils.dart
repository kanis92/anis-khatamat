import '../constants/app_constants.dart';
import '../models/khatma.dart';
import '../models/reading_progress.dart';

/// Logique pure de clôture Khatma (WOW 01) — testable sans UI.
class KhatmaCompletionUtils {
  KhatmaCompletionUtils._();

  static bool isFullyCompleted(Khatma k, {ReadingProgress? progress}) {
    if (k.reservationMode) {
      return k.completedReservationCount >= AppConstants.totalHizb;
    }
    return (progress?.completedCount ?? 0) >= AppConstants.totalHizb;
  }

  /// Nombre réel de participants (sans doublon).
  static int participantCount(Khatma k) {
    if (k.participantIds.isNotEmpty) return k.participantIds.length;
    final ids = <String>{};
    if (k.createdBy.isNotEmpty) ids.add(k.createdBy);
    ids.addAll(k.members);
    ids.addAll(k.guestParticipants.keys);
    return ids.length;
  }

  /// Durée entre création et clôture, en jours entiers (null si dates manquantes).
  static int? durationInDays(Khatma k) {
    final end = k.completedAt;
    if (end == null) return null;
    final diff = end.difference(k.createdAt);
    if (diff.isNegative) return null;
    return diff.inDays;
  }

  /// Quelques noms de participants pour affichage sobre (max [limit]).
  static List<String> sampleParticipantNames(Khatma k, {int limit = 4}) {
    final names = <String>[];
    for (final name in k.guestParticipants.values) {
      if (name.trim().isNotEmpty) names.add(name.trim());
    }
    for (final email in k.members) {
      if (email.isNotEmpty && !names.contains(email)) {
        names.add(_displayFromEmail(email));
      }
    }
    if (names.length < limit && k.createdBy.isNotEmpty) {
      final creator = _displayFromEmail(k.createdBy);
      if (!names.contains(creator)) names.insert(0, creator);
    }
    return names.take(limit).toList();
  }

  static String _displayFromEmail(String email) {
    if (email.contains('@')) return email.split('@').first;
    return email;
  }

  /// Indique si la transition célébration doit être jouée (première fois locale).
  static bool shouldPlayCelebration({
    required bool showCelebrationFlag,
    required bool alreadySeenLocally,
  }) {
    return showCelebrationFlag && !alreadySeenLocally;
  }
}
