import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/firebase_bootstrap.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/api_client_provider.dart';
import '../models/course.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../models/pedagogical_pillar.dart';
import '../repositories/formations_repository.dart';
import '../services/formations_api_service.dart';
import 'formations_access.dart';
import 'formation_learning_providers.dart';

// ─── Services ────────────────────────────────────────────────────────────────

final formationsApiServiceProvider = Provider<FormationsApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FormationsApiService(apiClient);
});

// ─── Repository ──────────────────────────────────────────────────────────────

final formationsRepositoryProvider = Provider<FormationsRepository>((ref) {
  ref.watch(firebaseBootstrapProvider);
  final apiService = ref.watch(formationsApiServiceProvider);
  final db = tryFirestore();
  if (db == null) {
    throw StateError(
      'FormationsRepository requested before verified Firebase bootstrap completed.',
    );
  }
  return FormationsRepository(db: db, apiService: apiService);
});

// ─── Courses ─────────────────────────────────────────────────────────────────
//
// Tous les providers ci-dessous sont en aval de `authReadinessProvider` : ils
// se reconstruisent automatiquement à chaque changement d'authentification et
// n'émettent aucune requête Firestore tant que les credentials ne sont pas
// disponibles.

final publishedCoursesProvider = StreamProvider<List<Course>>((ref) {
  return guardedFormationStream(
    ref,
    () => ref.watch(formationsRepositoryProvider).watchPublishedCourses(),
  );
});

final coursesByCategoryProvider =
    StreamProvider.family<List<Course>, CourseCategory>((ref, category) {
      return guardedFormationStream(
        ref,
        () => ref
            .watch(formationsRepositoryProvider)
            .watchCoursesByCategory(category),
      );
    });

final coursesByPillarProvider =
    StreamProvider.family<List<Course>, String>((ref, pillarId) {
      return guardedFormationStream(
        ref,
        () => ref
            .watch(formationsRepositoryProvider)
            .watchCoursesByPillar(pillarId),
      );
    });

final courseDetailProvider = FutureProvider.family<Course?, String>((
  ref,
  courseId,
) {
  return guardedFormationRead(
    ref,
    () => ref.watch(formationsRepositoryProvider).getCourse(courseId),
  );
});

// ─── Modules ─────────────────────────────────────────────────────────────────

final courseModulesProvider = FutureProvider.family<List<CourseModule>, String>(
  (ref, courseId) {
    return guardedFormationRead(
      ref,
      () => ref.watch(formationsRepositoryProvider).getModules(courseId),
    );
  },
);

// ─── Lessons ─────────────────────────────────────────────────────────────────

final courseLessonsProvider = FutureProvider.family<List<Lesson>, String>((
  ref,
  courseId,
) {
  return guardedFormationRead(
    ref,
    () => ref.watch(formationsRepositoryProvider).getLessons(courseId),
  );
});

class LessonParams {
  final String courseId;
  final String lessonId;
  const LessonParams(this.courseId, this.lessonId);

  @override
  bool operator ==(Object other) =>
      other is LessonParams &&
      other.courseId == courseId &&
      other.lessonId == lessonId;

  @override
  int get hashCode => Object.hash(courseId, lessonId);
}

final lessonDetailProvider = FutureProvider.family<Lesson?, LessonParams>((
  ref,
  params,
) {
  return guardedFormationRead(
    ref,
    () => ref
        .watch(formationsRepositoryProvider)
        .getLesson(params.courseId, params.lessonId),
  );
});

// ─── Progress ─────────────────────────────────────────────────────────────────

/// User's progress for a specific course (server-authoritative via API)
/// Returns null if no progress exists yet or user not authenticated
final courseProgressProvider =
    FutureProvider.family<UserCourseProgress?, String>((ref, courseId) async {
  final user = ref.watch(currentUserProvider);
  final uid = user?.uid;
  if (uid == null) return null;

  return ref.read(formationsRepositoryProvider).getProgress(courseId);
});

final allProgressProvider = FutureProvider<List<UserCourseProgress>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  final uid = user?.uid;
  if (uid == null) return [];
  return ref.watch(formationsRepositoryProvider).getAllProgress(uid);
});

// ─── Selected pillar filter (V1 taxonomy) ─────────────────────────────────────

final selectedPillarProvider = StateProvider<PedagogicalPillar?>((ref) => null);

// ─── Filtered courses (catalogue) ────────────────────────────────────────────

final filteredCoursesProvider = Provider<AsyncValue<List<Course>>>((ref) {
  final pillar = ref.watch(selectedPillarProvider);
  if (pillar == null) {
    return ref.watch(publishedCoursesProvider);
  }
  return ref.watch(coursesByPillarProvider(pillar.id));
});

// ─── Actions ─────────────────────────────────────────────────────────────────

class FormationsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markLessonCompleted({
    required String courseId,
    required String lessonId,
  }) async {
    await ref
        .read(formationsRepositoryProvider)
        .markLessonCompleted(
          courseId: courseId,
          lessonId: lessonId,
        );

    // Refresh all progress-dependent state
    ref.invalidate(courseProgressProvider(courseId));
    ref.invalidate(allProgressProvider);
    ref.invalidate(myLearningStateProvider);
  }

  /// Quiz scoring: REMOVED — violates server-authoritative progress contract.
  /// If quiz functionality is needed, implement via REST API endpoint.

  Future<void> updateCurrentLesson({
    required String courseId,
    required String lessonId,
  }) async {
    await ref
        .read(formationsRepositoryProvider)
        .updateCurrentLesson(
          courseId: courseId,
          lessonId: lessonId,
        );

    // Refresh all progress-dependent state
    ref.invalidate(courseProgressProvider(courseId));
    ref.invalidate(allProgressProvider);
    ref.invalidate(myLearningStateProvider);
  }
}

final formationsNotifierProvider =
    AsyncNotifierProvider<FormationsNotifier, void>(FormationsNotifier.new);
