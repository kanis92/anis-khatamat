import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/api_client_provider.dart';
import '../models/course.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../models/pedagogical_pillar.dart';
import '../repositories/formations_repository.dart';
import '../services/formations_api_service.dart';

// ─── Services ────────────────────────────────────────────────────────────────

final formationsApiServiceProvider = Provider<FormationsApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FormationsApiService(apiClient);
});

// ─── Repository ──────────────────────────────────────────────────────────────

final formationsRepositoryProvider = Provider<FormationsRepository>((ref) {
  final apiService = ref.watch(formationsApiServiceProvider);
  return FormationsRepository(apiService: apiService);
});

// ─── Courses ─────────────────────────────────────────────────────────────────

final publishedCoursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(formationsRepositoryProvider).watchPublishedCourses();
});

final coursesByCategoryProvider =
    StreamProvider.family<List<Course>, CourseCategory>((ref, category) {
      return ref
          .watch(formationsRepositoryProvider)
          .watchCoursesByCategory(category);
    });

final coursesByPillarProvider =
    StreamProvider.family<List<Course>, String>((ref, pillarId) {
      return ref
          .watch(formationsRepositoryProvider)
          .watchCoursesByPillar(pillarId);
    });

final courseDetailProvider = FutureProvider.family<Course?, String>((
  ref,
  courseId,
) {
  return ref.watch(formationsRepositoryProvider).getCourse(courseId);
});

// ─── Modules ─────────────────────────────────────────────────────────────────

final courseModulesProvider = FutureProvider.family<List<CourseModule>, String>(
  (ref, courseId) {
    return ref.watch(formationsRepositoryProvider).getModules(courseId);
  },
);

// ─── Lessons ─────────────────────────────────────────────────────────────────

final courseLessonsProvider = FutureProvider.family<List<Lesson>, String>((
  ref,
  courseId,
) {
  return ref.watch(formationsRepositoryProvider).getLessons(courseId);
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
  return ref
      .watch(formationsRepositoryProvider)
      .getLesson(params.courseId, params.lessonId);
});

// ─── Progress ─────────────────────────────────────────────────────────────────

final courseProgressProvider =
    StreamProvider.family<UserCourseProgress?, String>((ref, courseId) {
      final user = ref.watch(currentUserProvider);
      final uid = user?.uid;
      if (uid == null) return Stream.value(null);
      return ref
          .watch(formationsRepositoryProvider)
          .watchProgress(uid, courseId);
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
    ref.invalidate(courseProgressProvider(courseId));
  }

  Future<void> saveQuizScore({
    required String courseId,
    required String lessonId,
    required int score,
  }) async {
    final user = ref.read(currentUserProvider);
    final uid = user?.uid;
    if (uid == null) return;
    await ref
        .read(formationsRepositoryProvider)
        .saveQuizScore(
          userId: uid,
          courseId: courseId,
          lessonId: lessonId,
          score: score,
        );
  }

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
  }
}

final formationsNotifierProvider =
    AsyncNotifierProvider<FormationsNotifier, void>(FormationsNotifier.new);
