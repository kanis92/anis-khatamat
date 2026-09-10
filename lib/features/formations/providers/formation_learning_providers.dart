import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../models/lesson.dart';
import '../presentation/formation_resume_resolver.dart';
import 'formations_access.dart';
import 'formations_providers.dart';

class MyLearningState {
  const MyLearningState({
    required this.display,
    this.active,
  });

  final MyLearningDisplayState display;
  final ResolvedActiveLearning? active;
}

final myLearningStateProvider = FutureProvider<MyLearningState>((ref) async {
  // « Mon apprentissage » agrège du contenu protégé : il doit suivre le même
  // contrat de readiness que le reste des providers Formation, sinon les
  // lectures lancées avant la restauration de session restent orphelines.
  switch (ref.watch(authReadinessProvider).status) {
    case AuthStatus.initializing:
      return Completer<MyLearningState>().future;
    case AuthStatus.signedOut:
      throw const FormationsAuthRequiredException();
    case AuthStatus.signedIn:
      break;
  }

  final courses = await ref.watch(publishedCoursesProvider.future);
  final allProgress = await ref.watch(allProgressProvider.future);

  final coursesById = {for (final course in courses) course.id: course};
  final lessonsByCourseId = <String, List<Lesson>>{};

  for (final course in courses) {
    lessonsByCourseId[course.id] =
        await ref.read(courseLessonsProvider(course.id).future);
  }

  final display = FormationResumeResolver.resolveDisplayState(
    allProgress: allProgress,
    coursesById: coursesById,
    lessonsByCourseId: lessonsByCourseId,
  );

  if (display != MyLearningDisplayState.active) {
    return MyLearningState(display: display);
  }

  final progress = FormationResumeResolver.selectMostRecentInProgress(
    allProgress: allProgress,
    coursesById: coursesById,
    lessonsByCourseId: lessonsByCourseId,
  );

  if (progress == null) {
    return MyLearningState(display: MyLearningDisplayState.allCompleted);
  }

  final course = coursesById[progress.courseId]!;
  final lessons = lessonsByCourseId[course.id] ?? const <Lesson>[];
  final resumeLessonId = FormationResumeResolver.resolveResumeLessonId(
    progress: progress,
    publishedLessons: lessons,
  );

  if (resumeLessonId == null) {
    return MyLearningState(display: MyLearningDisplayState.allCompleted);
  }

  final currentLesson =
      FormationResumeResolver.findLessonById(lessons, resumeLessonId);
  if (currentLesson == null) {
    return MyLearningState(display: MyLearningDisplayState.allCompleted);
  }

  final modules = await ref.read(courseModulesProvider(course.id).future);
  final module = FormationResumeResolver.findModuleForLesson(
    modules: modules,
    lesson: currentLesson,
  );

  if (module == null) {
    return MyLearningState(display: MyLearningDisplayState.allCompleted);
  }

  return MyLearningState(
    display: MyLearningDisplayState.active,
    active: ResolvedActiveLearning(
      course: course,
      progress: progress,
      lessons: lessons,
      currentLesson: currentLesson,
      module: module,
      resumeLessonId: resumeLessonId,
    ),
  );
});
