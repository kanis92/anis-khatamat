import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../models/course.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../repositories/formations_repository.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

final formationsRepositoryProvider = Provider<FormationsRepository>((ref) {
  return FormationsRepository();
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

// ─── Selected category filter ─────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<CourseCategory?>((ref) => null);

// ─── Filtered courses (catalogue) ────────────────────────────────────────────

final filteredCoursesProvider = Provider<AsyncValue<List<Course>>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  if (category == null) {
    return ref.watch(publishedCoursesProvider);
  }
  return ref.watch(coursesByCategoryProvider(category));
});

// ─── Actions ─────────────────────────────────────────────────────────────────

class FormationsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markLessonCompleted({
    required String courseId,
    required String lessonId,
  }) async {
    final user = ref.read(currentUserProvider);
    final uid = user?.uid;
    if (uid == null) return;
    await ref
        .read(formationsRepositoryProvider)
        .markLessonCompleted(
          userId: uid,
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
    final user = ref.read(currentUserProvider);
    final uid = user?.uid;
    if (uid == null) return;
    await ref
        .read(formationsRepositoryProvider)
        .updateCurrentLesson(
          userId: uid,
          courseId: courseId,
          lessonId: lessonId,
        );
  }
}

final formationsNotifierProvider =
    AsyncNotifierProvider<FormationsNotifier, void>(FormationsNotifier.new);
