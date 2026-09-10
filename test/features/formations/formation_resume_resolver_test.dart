import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/models/user_progress.dart';
import 'package:anis_khatamat/features/formations/presentation/formation_resume_resolver.dart';

UserCourseProgress _progress({
  required String courseId,
  String? currentLessonId,
  Set<String> completedLessonIds = const {},
  DateTime? lastAccessedAt,
}) {
  return UserCourseProgress(
    userId: 'user-1',
    courseId: courseId,
    currentLessonId: currentLessonId,
    completedLessonIds: completedLessonIds,
    lastAccessedAt: lastAccessedAt,
  );
}

Course _course(String id) => Course(
      id: id,
      title: 'Course $id',
      description: 'Description',
      instructor: 'ANIS',
      createdAt: DateTime(2024, 1, 1),
    );

List<Lesson> _lessons(String courseId, List<String> ids) {
  return [
    for (var i = 0; i < ids.length; i++)
      Lesson(
        id: ids[i],
        moduleId: 'module-1',
        courseId: courseId,
        title: 'Lesson ${ids[i]}',
        type: LessonType.text,
        order: i + 1,
      ),
  ];
}

void main() {
  group('FormationResumeResolver', () {
    test('selectMostRecentInProgress uses lastAccessedAt descending', () {
      final courses = {
        'c1': _course('c1'),
        'c2': _course('c2'),
      };
      final lessonsByCourse = {
        'c1': _lessons('c1', ['l1', 'l2', 'l3']),
        'c2': _lessons('c2', ['l1', 'l2']),
      };

      final allProgress = [
        _progress(
          courseId: 'c1',
          currentLessonId: 'l2',
          completedLessonIds: {'l1'},
          lastAccessedAt: DateTime(2024, 1, 10),
        ),
        _progress(
          courseId: 'c2',
          currentLessonId: 'l2',
          completedLessonIds: {'l1'},
          lastAccessedAt: DateTime(2024, 1, 20),
        ),
      ];

      final selected = FormationResumeResolver.selectMostRecentInProgress(
        allProgress: allProgress,
        coursesById: courses,
        lessonsByCourseId: lessonsByCourse,
      );

      expect(selected?.courseId, 'c2');
    });

    test('completed course is not selected as in-progress', () {
      final courses = {'c1': _course('c1')};
      final lessons = {'c1': _lessons('c1', ['l1', 'l2'])};
      final allProgress = [
        _progress(
          courseId: 'c1',
          currentLessonId: 'l2',
          completedLessonIds: {'l1', 'l2'},
          lastAccessedAt: DateTime(2024, 1, 20),
        ),
      ];

      final selected = FormationResumeResolver.selectMostRecentInProgress(
        allProgress: allProgress,
        coursesById: courses,
        lessonsByCourseId: lessons,
      );

      expect(selected, isNull);
      expect(
        FormationResumeResolver.resolveDisplayState(
          allProgress: allProgress,
          coursesById: courses,
          lessonsByCourseId: lessons,
        ),
        MyLearningDisplayState.allCompleted,
      );
    });

    test('in-progress course wins over older completed course', () {
      final courses = {
        'completed': _course('completed'),
        'active': _course('active'),
      };
      final lessons = {
        'completed': _lessons('completed', ['l1', 'l2']),
        'active': _lessons('active', ['a1', 'a2', 'a3']),
      };
      final allProgress = [
        _progress(
          courseId: 'completed',
          currentLessonId: 'l2',
          completedLessonIds: {'l1', 'l2'},
          lastAccessedAt: DateTime(2024, 2, 1),
        ),
        _progress(
          courseId: 'active',
          currentLessonId: 'a2',
          completedLessonIds: {'a1'},
          lastAccessedAt: DateTime(2024, 1, 15),
        ),
      ];

      final selected = FormationResumeResolver.selectMostRecentInProgress(
        allProgress: allProgress,
        coursesById: courses,
        lessonsByCourseId: lessons,
      );

      expect(selected?.courseId, 'active');
    });

    test('resolveResumeLessonId prefers currentLessonId when valid', () {
      final lessons = _lessons('c1', ['l1', 'l2', 'l3']);
      final progress = _progress(
        courseId: 'c1',
        currentLessonId: 'l2',
        completedLessonIds: {'l1'},
      );

      expect(
        FormationResumeResolver.resolveResumeLessonId(
          progress: progress,
          publishedLessons: lessons,
        ),
        'l2',
      );
    });

    test('resolveResumeLessonId falls back to first incomplete lesson', () {
      final lessons = _lessons('c1', ['l1', 'l2', 'l3']);
      final progress = _progress(
        courseId: 'c1',
        currentLessonId: 'missing',
        completedLessonIds: {'l1'},
      );

      expect(
        FormationResumeResolver.resolveResumeLessonId(
          progress: progress,
          publishedLessons: lessons,
        ),
        'l2',
      );
    });

    test('findModuleForLesson resolves module from lesson.moduleId', () {
      const module = CourseModule(
        id: 'module-1',
        courseId: 'c1',
        title: 'Module 1',
        order: 1,
        lessonIds: ['l1', 'l2'],
      );
      final lesson = _lessons('c1', ['l1', 'l2']).first;

      expect(
        FormationResumeResolver.findModuleForLesson(
          modules: const [module],
          lesson: lesson,
        ),
        module,
      );
    });

    test('progressFraction uses real completed published lessons', () {
      final lessons = _lessons('c1', ['l1', 'l2', 'l3', 'l4']);
      final progress = _progress(
        courseId: 'c1',
        completedLessonIds: {'l1', 'l2'},
      );

      expect(
        FormationResumeResolver.progressFraction(progress, lessons),
        0.5,
      );
      expect(
        FormationResumeResolver.isCourseCompleted(progress, lessons),
        isFalse,
      );
    });

    test('isCourseCompleted when all published lessons are done', () {
      final lessons = _lessons('c1', ['l1', 'l2']);
      final progress = _progress(
        courseId: 'c1',
        completedLessonIds: {'l1', 'l2'},
      );

      expect(
        FormationResumeResolver.isCourseCompleted(progress, lessons),
        isTrue,
      );
    });

    test('activity with only lastAccessedAt counts as learning activity', () {
      final progress = _progress(
        courseId: 'c1',
        lastAccessedAt: DateTime(2024, 1, 1),
      );

      expect(FormationResumeResolver.hasLearningActivity(progress), isTrue);
    });
  });
}
