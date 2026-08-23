import '../constants/app_constants.dart';
import '../models/home_dashboard_state.dart';
import '../models/khatma.dart';
import '../models/khatma_with_status.dart';
import '../models/reading_progress.dart';
import '../utils/khatma_participant_id.dart';

const int _maxCollectiveOnHome = 3;

/// Réservations actives lues depuis la map legacy (v1 / local).
Map<String, UserKhatmaReservationInfo> findLegacyUserReservations(
  Iterable<KhatmaWithStatus> activeKhatmas,
  String participantId, {
  String? Function(String khatmaId)? legacyGuestIdFor,
}) {
  final map = <String, UserKhatmaReservationInfo>{};
  for (final s in activeKhatmas) {
    final k = s.khatma;
    if (!k.reservationMode) continue;
    if (k.reservationSchemaVersion >= 2 && !k.id.startsWith('local_')) {
      continue;
    }
    final legacyGuestId = legacyGuestIdFor?.call(k.id);
    UserKhatmaReservationInfo? best;
    for (final entry in k.hizbReservations.entries) {
      final r = entry.value;
      if (!r.isReserved) continue;
      if (!KhatmaParticipantId.ownsReservation(
        r,
        participantId,
        legacyGuestId: legacyGuestId,
      )) {
        continue;
      }
      final candidate = UserKhatmaReservationInfo(
        khatmaId: k.id,
        hizbNumber: entry.key,
        reservedAt: r.reservedAt,
        inProgress: r.isInProgress,
      );
      if (best == null ||
          (candidate.reservedAt != null &&
              (best.reservedAt == null ||
                  candidate.reservedAt!.isAfter(best.reservedAt!)))) {
        best = candidate;
      }
    }
    if (best != null) {
      map[k.id] = best;
    }
  }
  return map;
}

/// Fusionne réservations v2 (collection group) + legacy map.
Map<String, UserKhatmaReservationInfo> mergeUserReservations(
  Map<String, UserKhatmaReservationInfo> legacy,
  Map<String, UserKhatmaReservationInfo> fromSubcollection,
) {
  final merged = Map<String, UserKhatmaReservationInfo>.from(legacy);
  for (final entry in fromSubcollection.entries) {
    final existing = merged[entry.key];
    if (existing == null) {
      merged[entry.key] = entry.value;
      continue;
    }
    final a = entry.value.reservedAt;
    final b = existing.reservedAt;
    if (a != null && (b == null || a.isAfter(b))) {
      merged[entry.key] = entry.value;
    }
  }
  return merged;
}

/// Règle déterministe : réservation active → sinon activité récente → sinon création.
KhatmaWithStatus? selectPrimaryKhatma(
  List<KhatmaWithStatus> active,
  Map<String, UserKhatmaReservationInfo> userReservations,
) {
  if (active.isEmpty) return null;

  KhatmaWithStatus? reservedBest;
  DateTime? reservedBestTime;
  for (final s in active) {
    final res = userReservations[s.khatma.id];
    if (res == null) continue;
    final t = res.reservedAt ?? s.lastActivity ?? s.khatma.createdAt;
    if (reservedBest == null ||
        reservedBestTime == null ||
        t.isAfter(reservedBestTime)) {
      reservedBest = s;
      reservedBestTime = t;
    }
  }
  if (reservedBest != null) return reservedBest;

  final sorted = List<KhatmaWithStatus>.from(active);
  sorted.sort(_compareByActivity);
  return sorted.first;
}

int _compareByActivity(KhatmaWithStatus a, KhatmaWithStatus b) {
  final aTime = a.lastActivity ?? a.khatma.createdAt;
  final bTime = b.lastActivity ?? b.khatma.createdAt;
  return bTime.compareTo(aTime);
}

PrimaryKhatmaHighlight buildPrimaryHighlight(
  KhatmaWithStatus status,
  ReadingProgress? progress,
  UserKhatmaReservationInfo? userReservation,
) {
  final k = status.khatma;
  final globalDone = k.reservationMode
      ? k.completedReservationCount
      : (progress?.completedCount ?? 0);
  final globalPercent =
      ((globalDone / AppConstants.totalHizb) * 100).round().clamp(0, 100);

  return PrimaryKhatmaHighlight(
    status: status,
    globalCompletedHizb: globalDone.clamp(0, AppConstants.totalHizb),
    globalPercent: globalPercent,
    userPersonalCompleted:
        k.reservationMode ? null : progress?.completedCount,
    userReservation: userReservation,
    participantCount: _participantCount(k),
  );
}

int _participantCount(Khatma k) {
  final ids = <String>{};
  if (k.createdBy.isNotEmpty) ids.add(k.createdBy);
  ids.addAll(k.members);
  ids.addAll(k.guestParticipants.keys);
  ids.addAll(k.participantIds);
  return ids.length;
}

List<KhatmaWithStatus> selectCollectiveActive(List<KhatmaWithStatus> active) {
  final list = active
      .where((s) => s.khatma.isGroup || s.khatma.reservationMode)
      .toList();
  list.sort(_compareByActivity);
  if (list.length <= _maxCollectiveOnHome) return list;
  return list.sublist(0, _maxCollectiveOnHome);
}

HomeLastActivity? buildLastActivity(
  List<KhatmaWithStatus> all,
  Map<String, ReadingProgress> progressMap,
) {
  DateTime? bestTime;
  KhatmaWithStatus? bestStatus;

  for (final s in all) {
    final t = s.lastActivity;
    if (t != null && (bestTime == null || t.isAfter(bestTime))) {
      bestTime = t;
      bestStatus = s;
    }
  }

  for (final p in progressMap.values) {
    if (bestTime == null || p.lastUpdated.isAfter(bestTime)) {
      bestTime = p.lastUpdated;
      for (final s in all) {
        if (s.khatma.id == p.khatmaId) {
          bestStatus = s;
          break;
        }
      }
    }
  }

  if (bestTime == null || bestStatus == null) return null;

  if (bestStatus.isCompleted) {
    return HomeLastActivity(
      label: 'Khatma terminée : ${bestStatus.khatma.title}',
      at: bestTime,
    );
  }
  return HomeLastActivity(
    label: 'Activité sur ${bestStatus.khatma.title}',
    at: bestTime,
  );
}

int sumUserCompletedHizb(Map<String, ReadingProgress> progressMap) {
  var total = 0;
  for (final p in progressMap.values) {
    total += p.completedCount;
  }
  return total;
}

HomeDashboardState buildHomeDashboardState({
  required List<KhatmaWithStatus> allStatuses,
  required Map<String, ReadingProgress> progressMap,
  required Map<String, UserKhatmaReservationInfo> userReservations,
}) {
  final active = allStatuses.where((s) => !s.isCompleted).toList();
  final completed = allStatuses.where((s) => s.isCompleted).toList();

  final primaryStatus = selectPrimaryKhatma(active, userReservations);
  PrimaryKhatmaHighlight? primary;
  if (primaryStatus != null) {
    primary = buildPrimaryHighlight(
      primaryStatus,
      progressMap[primaryStatus.khatma.id],
      userReservations[primaryStatus.khatma.id],
    );
  }

  return HomeDashboardState(
    activeKhatmas: active,
    completedKhatmas: completed,
    primary: primary,
    collectiveActive: selectCollectiveActive(active),
    summary: HomeDashboardSummary(
      activeCount: active.length,
      completedCount: completed.length,
      userCompletedHizb: sumUserCompletedHizb(progressMap),
    ),
    lastActivity: buildLastActivity(allStatuses, progressMap),
  );
}
