import '../models/course.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';

enum MyLearningDisplayState {
  empty,
  active,
  allCompleted,
}

/// Resolved resume context for the primary "Mon apprentissage" card.
class ResolvedActiveLearning {
  const ResolvedActiveLearning({
    required this.course,
    required this.progress,
    required this.lessons,
    required this.currentLesson,
    required this.module,
    required this.resumeLessonId,
  });

  final Course course;
  final UserCourseProgress progress;
  final List<Lesson> lessons;
  final Lesson currentLesson;
  final CourseModule module;
  final String resumeLessonId;

  int get totalLessons => lessons.length;

  int get completedLessons => lessons
      .where((lesson) => progress.completedLessonIds.contains(lesson.id))
      .length;

  double get progressFraction =>
      FormationResumeResolver.progressFraction(progress, lessons);
}

/// Pure resume / completion rules shared by UI and tests.
class FormationResumeResolver {
  const FormationResumeResolver._();

  static bool hasLearningActivity(UserCourseProgress progress) {
    return progress.lastAccessedAt != null ||
        progress.currentLessonId != null ||
        progress.completedLessonIds.isNotEmpty;
  }

  static bool isCourseCompleted(
    UserCourseProgress progress,
    List<Lesson> publishedLessons,
  ) {
    if (publishedLessons.isEmpty) return false;
    final publishedIds = publishedLessons.map((lesson) => lesson.id).toSet();
    return publishedIds.every(progress.completedLessonIds.contains);
  }

  static double progressFraction(
    UserCourseProgress progress,
    List<Lesson> publishedLessons,
  ) {
    if (publishedLessons.isEmpty) return 0;
    final publishedIds = publishedLessons.map((lesson) => lesson.id).toSet();
    final completed = progress.completedLessonIds
        .where(publishedIds.contains)
        .length;
    return (completed / publishedIds.length).clamp(0.0, 1.0);
  }

  /// Most recently accessed course that still has real incomplete lessons.
  static UserCourseProgress? selectMostRecentInProgress({
    required List<UserCourseProgress> allProgress,
    required Map<String, Course> coursesById,
    required Map<String, List<Lesson>> lessonsByCourseId,
  }) {
    final candidates = allProgress.where((progress) {
      if (!coursesById.containsKey(progress.courseId)) return false;
      if (!hasLearningActivity(progress)) return false;
      final lessons = lessonsByCourseId[progress.courseId] ?? const [];
      return !isCourseCompleted(progress, lessons);
    }).toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final aTime =
          a.lastAccessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.lastAccessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return candidates.first;
  }

  static MyLearningDisplayState resolveDisplayState({
    required List<UserCourseProgress> allProgress,
    required Map<String, Course> coursesById,
    required Map<String, List<Lesson>> lessonsByCourseId,
  }) {
    final relevant = allProgress
        .where(
          (progress) =>
              coursesById.containsKey(progress.courseId) &&
              hasLearningActivity(progress),
        )
        .toList();

    if (relevant.isEmpty) {
      return MyLearningDisplayState.empty;
    }

    final inProgress = selectMostRecentInProgress(
      allProgress: allProgress,
      coursesById: coursesById,
      lessonsByCourseId: lessonsByCourseId,
    );

    if (inProgress != null) {
      return MyLearningDisplayState.active;
    }

    final allCompleted = relevant.every((progress) {
      final lessons = lessonsByCourseId[progress.courseId] ?? const [];
      return isCourseCompleted(progress, lessons);
    });

    return allCompleted
        ? MyLearningDisplayState.allCompleted
        : MyLearningDisplayState.empty;
  }

  /// Resume target: currentLessonId when valid, otherwise first incomplete lesson.
  static String? resolveResumeLessonId({
    required UserCourseProgress progress,
    required List<Lesson> publishedLessons,
  }) {
    if (publishedLessons.isEmpty) return null;

    final sorted = [...publishedLessons]
      ..sort((a, b) => a.order.compareTo(b.order));

    final currentId = progress.currentLessonId;
    if (currentId != null && sorted.any((lesson) => lesson.id == currentId)) {
      return currentId;
    }

    for (final lesson in sorted) {
      if (!progress.completedLessonIds.contains(lesson.id)) {
        return lesson.id;
      }
    }

    return null;
  }

  static CourseModule? findModuleForLesson({
    required List<CourseModule> modules,
    required Lesson lesson,
  }) {
    for (final module in modules) {
      if (module.id == lesson.moduleId || module.lessonIds.contains(lesson.id)) {
        return module;
      }
    }
    return null;
  }

  static Lesson? findLessonById(List<Lesson> lessons, String lessonId) {
    for (final lesson in lessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }
}
