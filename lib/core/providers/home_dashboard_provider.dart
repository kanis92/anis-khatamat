import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_dashboard_state.dart';
import '../services/guest_service.dart';
import '../utils/home_dashboard_utils.dart';
import '../../features/formations/providers/formations_providers.dart';
import 'auth_provider.dart';
import 'prayer_times_provider.dart';
import 'reading_provider.dart';

/// Dashboard Home Khatamat — sources réelles uniquement.
///
/// Coût Firestore typique (réutilise [khatmatWithStatusProvider]) :
/// - 3–4 queries khatmat + 1 reading_progress (via Mes Khatmas)
/// - +1 collection group hizb_reservations (réservations actives user)
/// - prefs locales pour legacy guest id (pas de lecture cloud)
final homeDashboardProvider = FutureProvider<HomeDashboardState>((ref) async {
  // Session démo : état Home local uniquement — aucune requête Firestore / réseau.
  if (ref.watch(demoModeProvider)) {
    return HomeDashboardState.empty;
  }

  final identity = ref.watch(myKhatmatIdentityProvider);
  if (identity.progressUserId.isEmpty) {
    return HomeDashboardState.empty;
  }

  final statuses = await ref.watch(khatmatWithStatusProvider.future);
  final service = ref.read(readingServiceProvider);
  final progressMap = await service.getProgressMapForUser(
    identity.progressUserId,
  );

  final active = statuses.where((s) => !s.isCompleted).toList();
  final guestService = GuestService();
  final legacyByKhatma = <String, String>{};
  for (final s in active) {
    final legacy = await guestService.getLegacyGuestIdForKhatma(s.khatma.id);
    if (legacy != null && legacy.isNotEmpty) {
      legacyByKhatma[s.khatma.id] = legacy;
    }
  }

  final legacyReservations = findLegacyUserReservations(
    active,
    identity.progressUserId,
    legacyGuestIdFor: (id) => legacyByKhatma[id],
  );

  final subcollectionReservations = await service
      .fetchUserActiveReservationsFromSubcollection(identity.progressUserId);

  final userReservations = mergeUserReservations(
    legacyReservations,
    subcollectionReservations,
  );

  return buildHomeDashboardState(
    allStatuses: statuses,
    progressMap: progressMap,
    userReservations: userReservations,
  );
});

/// Infos de la prière suivante pour la home
class NextPrayerInfo {
  final String name;
  final DateTime time;
  final String inStr;

  const NextPrayerInfo({
    required this.name,
    required this.time,
    required this.inStr,
  });

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}min';
  }

  static NextPrayerInfo? fromPrayerTimes(PrayerTimes? pt) {
    if (pt == null) return null;
    const times = [
      ('Fajr', 'Fajr'),
      ('Dhuhr', 'Dhuhr'),
      ('Asr', 'Asr'),
      ('Maghrib', 'Maghrib'),
      ('Isha', 'Isha'),
    ];
    final now = DateTime.now();
    for (final pair in times) {
      final t = switch (pair.$1) {
        'Fajr' => pt.fajr,
        'Dhuhr' => pt.dhuhr,
        'Asr' => pt.asr,
        'Maghrib' => pt.maghrib,
        'Isha' => pt.isha,
        _ => pt.fajr,
      };
      if (t.isAfter(now)) {
        final diff = t.difference(now);
        return NextPrayerInfo(
          name: pair.$2,
          time: t,
          inStr: 'dans ${_formatDuration(diff)}',
        );
      }
    }
    return null;
  }
}

final nextPrayerProvider = Provider<NextPrayerInfo?>((ref) {
  final state = ref.watch(prayerTimesProvider).valueOrNull;
  return NextPrayerInfo.fromPrayerTimes(state?.prayerTimes);
});

/// Formation en cours (Firestore formations)
class FormationProgressInfo {
  final String courseTitle;
  final String lessonTitle;

  const FormationProgressInfo({
    required this.courseTitle,
    required this.lessonTitle,
  });
}

final formationProgressProvider = FutureProvider<FormationProgressInfo?>((
  ref,
) async {
  final coursesAsync = ref.watch(publishedCoursesProvider);
  final courses = coursesAsync.valueOrNull ?? [];
  final user = ref.watch(currentUserProvider);
  final uid = user?.uid;
  if (uid == null || courses.isEmpty) return null;
  final repo = ref.read(formationsRepositoryProvider);
  for (final c in courses) {
    final progress = await repo.getProgress(uid, c.id);
    final totalLessons = c.totalLessons > 0 ? c.totalLessons : 1;
    if (progress != null && !progress.isCompleted(totalLessons)) {
      String lessonTitle = 'Reprendre';
      if (progress.currentLessonId != null) {
        final modules = await repo.getModules(c.id);
        for (final m in modules) {
          final lessons = await repo.getLessonsForModule(c.id, m.id);
          try {
            final lesson = lessons.firstWhere(
              (l) => l.id == progress.currentLessonId,
            );
            lessonTitle = lesson.title;
            break;
          } catch (_) {}
        }
      }
      return FormationProgressInfo(
        courseTitle: c.title,
        lessonTitle: lessonTitle,
      );
    }
  }
  return null;
});
