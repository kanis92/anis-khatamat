import '../constants/app_constants.dart';
import '../models/khatma.dart';
import '../models/khatma_with_status.dart';
import '../models/reading_progress.dart';

/// Plan des requêtes Firestore « Mes Khatmas ».
///
/// Firestore refuse une query `list` dès qu'un document *pouvant* matcher
/// n'est pas lisible par les rules. Les contraintes doivent donc être
/// exactement celles que les rules savent prouver :
/// - createdBy == token.email
/// - members array-contains token.email
/// - participantIds array-contains token.email ou auth.uid
///
/// Sans session Firebase, aucune de ces queries n'est autorisée
/// (`request.auth != null`). Les envoyer produit `permission-denied`.
class MyKhatmatQueryPlan {
  const MyKhatmatQueryPlan({
    required this.skipRemote,
    this.email,
    this.authUid,
  });

  /// Mode démo ou absence de token : cache local uniquement.
  final bool skipRemote;

  /// Email du token Firebase (jamais une adresse synthétique).
  final String? email;

  /// `request.auth.uid`.
  final String? authUid;

  bool get queryCreatedBy => !skipRemote && email != null && email!.isNotEmpty;
  bool get queryMembers => queryCreatedBy;
  bool get queryParticipantEmail => queryCreatedBy;
  bool get queryParticipantUid =>
      !skipRemote && authUid != null && authUid!.isNotEmpty;
}

/// Construit le plan à partir de l'état Auth réel — pas du mode démo UI.
MyKhatmatQueryPlan planMyKhatmatQueries({
  required bool isDemo,
  required bool hasFirebaseAuth,
  required bool isAnonymous,
  String? tokenEmail,
  String? authUid,
}) {
  if (isDemo || !hasFirebaseAuth) {
    return const MyKhatmatQueryPlan(skipRemote: true);
  }
  final email = isAnonymous ? null : tokenEmail?.trim();
  final uid = authUid?.trim();
  return MyKhatmatQueryPlan(
    skipRemote: false,
    email: (email != null && email.isNotEmpty) ? email : null,
    authUid: (uid != null && uid.isNotEmpty) ? uid : null,
  );
}

/// Fusionne et déduplique les résultats de requêtes Firestore « Mes Khatmas ».
List<Khatma> mergeMyKhatmatQueries(Iterable<List<Khatma>> queryResults) {
  final byId = <String, Khatma>{};
  for (final list in queryResults) {
    for (final k in list) {
      if (k.id.isEmpty) continue;
      byId[k.id] = k;
    }
  }
  return byId.values.toList();
}

/// Vérifie que l'utilisateur appartient réellement à la Khatma (post-fusion).
bool userBelongsToKhatma(
  Khatma k, {
  String? email,
  String? authUid,
}) {
  if (email != null && email.isNotEmpty) {
    if (k.createdBy == email) return true;
    if (k.members.contains(email)) return true;
    if (k.participantIds.contains(email)) return true;
  }
  if (authUid != null && authUid.isNotEmpty) {
    if (k.guestParticipants.containsKey(authUid)) return true;
    if (k.participantIds.contains(authUid)) return true;
  }
  return false;
}

bool isKhatmaCompleted(Khatma k, ReadingProgress? progress) {
  if (k.reservationMode) {
    return k.completedReservationCount >= AppConstants.totalHizb;
  }
  return (progress?.completedCount ?? 0) >= AppConstants.totalHizb;
}

KhatmaWithStatus buildKhatmaWithStatus(
  Khatma k,
  ReadingProgress? progress,
) {
  final completed = isKhatmaCompleted(k, progress);
  DateTime? lastActivity = progress?.lastUpdated;

  if (completed && k.completedAt != null) {
    lastActivity = k.completedAt;
  } else if (k.reservationMode && k.hizbReservations.isNotEmpty) {
    final latest = k.hizbReservations.values
        .where((r) => r.completedAt != null)
        .map((r) => r.completedAt!)
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    if (latest != null && (lastActivity == null || latest.isAfter(lastActivity))) {
      lastActivity = latest;
    }
  }

  return KhatmaWithStatus(
    khatma: k,
    isCompleted: completed,
    lastActivity: lastActivity,
  );
}

int compareKhatmaWithStatus(KhatmaWithStatus a, KhatmaWithStatus b) {
  if (a.isCompleted != b.isCompleted) {
    return a.isCompleted ? 1 : -1;
  }
  if (!a.isCompleted) {
    return _compareActivityThenCreated(a, b);
  }
  return _compareActivityThenCreated(a, b);
}

int _compareActivityThenCreated(KhatmaWithStatus a, KhatmaWithStatus b) {
  final aAct = a.lastActivity;
  final bAct = b.lastActivity;
  if (aAct != null && bAct != null) {
    final cmp = bAct.compareTo(aAct);
    if (cmp != 0) return cmp;
  } else if (aAct != null) {
    return -1;
  } else if (bAct != null) {
    return 1;
  }
  return b.khatma.createdAt.compareTo(a.khatma.createdAt);
}

List<KhatmaWithStatus> sortMyKhatmatStatuses(List<KhatmaWithStatus> list) {
  final copy = List<KhatmaWithStatus>.from(list);
  copy.sort(compareKhatmaWithStatus);
  return copy;
}
