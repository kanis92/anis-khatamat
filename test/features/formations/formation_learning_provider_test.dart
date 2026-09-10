import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/models/user_progress.dart';
import 'package:anis_khatamat/features/formations/presentation/formation_resume_resolver.dart';
import 'package:anis_khatamat/features/formations/providers/formation_learning_providers.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';

void main() {
  group('myLearningStateProvider', () {
    test('resolves active course, module and lesson from API progress', () async {
      const courseId = 'c1';
      final course = Course(
        id: courseId,
        title: 'Course',
        description: 'Description',
        instructor: 'ANIS',
        createdAt: DateTime(2024, 1, 1),
      );
      const module = CourseModule(
        id: 'm1',
        courseId: courseId,
        title: 'Module',
        order: 1,
        lessonIds: ['l1', 'l2'],
      );
      const lessons = [
        Lesson(
          id: 'l1',
          moduleId: 'm1',
          courseId: courseId,
          title: 'Lesson 1',
          type: LessonType.text,
          order: 1,
        ),
        Lesson(
          id: 'l2',
          moduleId: 'm1',
          courseId: courseId,
          title: 'Lesson 2',
          type: LessonType.text,
          order: 2,
        ),
      ];
      final progress = UserCourseProgress(
        userId: 'u1',
        courseId: courseId,
        currentLessonId: 'l2',
        completedLessonIds: {'l1'},
        lastAccessedAt: DateTime(2024, 2, 1),
      );

      final container = ProviderContainer(
        overrides: [
          // Mon apprentissage lit du contenu protégé : il exige un
          // utilisateur Firebase authentifié.
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
          publishedCoursesProvider.overrideWith((ref) => Stream.value([course])),
          allProgressProvider.overrideWith((ref) => Future.value([progress])),
          courseLessonsProvider(courseId)
              .overrideWith((ref) async => lessons),
          courseModulesProvider(courseId)
              .overrideWith((ref) async => [module]),
        ],
      );
      addTearDown(container.dispose);
      // Comme l'UI : on s'abonne, sinon le provider ne se reconstruit pas
      // quand l'état d'authentification passe de « initializing » à « signed in ».
      container.listen(myLearningStateProvider, (_, __) {});

      final state = await container.read(myLearningStateProvider.future);

      expect(state.display, MyLearningDisplayState.active);
      expect(state.active?.course.id, courseId);
      expect(state.active?.module.id, 'm1');
      expect(state.active?.resumeLessonId, 'l2');
      expect(state.active?.completedLessons, 1);
      expect(state.active?.totalLessons, 2);
    });
  });
}

class _FakeUser extends Mock implements User {
  @override
  String get uid => 'u1';
}
