import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/models/pedagogical_pillar.dart';
import 'package:anis_khatamat/features/formations/models/user_progress.dart';
import 'package:anis_khatamat/features/formations/presentation/formation_resume_resolver.dart';
import 'package:anis_khatamat/features/formations/providers/formation_learning_providers.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/training_screen.dart';

Widget _wrap(
  Widget child, {
  List<Override> overrides = const [],
  GoRouter? router,
}) {
  if (router != null) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Course _course() => Course(
      id: 'c1',
      title: 'Legacy English Course',
      description: 'Description',
      instructor: 'ANIS',
      pillarId: PedagogicalPillar.foundationsPractice.id,
      createdAt: DateTime(2024, 1, 1),
      translations: const {
        'fr': CourseTranslation(
          title: 'Découvrir les formations ANIS',
          description: 'Description FR',
        ),
      },
    );

const _module = CourseModule(
  id: 'm1',
  courseId: 'c1',
  title: 'Legacy English Module',
  order: 1,
  lessonIds: ['l1', 'l2'],
  translations: {
    'fr': ModuleTranslation(
      title: 'Bien démarrer',
      description: 'Module FR',
    ),
  },
);

const _lesson = Lesson(
  id: 'l2',
  moduleId: 'm1',
  courseId: 'c1',
  title: 'Legacy English Lesson',
  type: LessonType.text,
  order: 2,
  translations: {
    'fr': LessonTranslation(
      title: 'Bienvenue dans les formations',
      description: 'Leçon FR',
    ),
  },
);

ResolvedActiveLearning _activeLearning() {
  final course = _course();
  final lessons = const [
    Lesson(
      id: 'l1',
      moduleId: 'm1',
      courseId: 'c1',
      title: 'Lesson 1',
      type: LessonType.text,
      order: 1,
    ),
    _lesson,
  ];

  return ResolvedActiveLearning(
    course: course,
    progress: UserCourseProgress(
      userId: 'u1',
      courseId: 'c1',
      currentLessonId: 'l2',
      completedLessonIds: {'l1'},
      lastAccessedAt: DateTime(2024, 2, 1),
    ),
    lessons: lessons,
    currentLesson: _lesson,
    module: _module,
    resumeLessonId: 'l2',
  );
}

void main() {
  group('Mon apprentissage section', () {
    testWidgets('empty state renders guidance copy', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith((ref) => Stream.value([])),
            allProgressProvider.overrideWith((ref) => Future.value([])),
            myLearningStateProvider.overrideWith(
              (ref) async => const MyLearningState(
                display: MyLearningDisplayState.empty,
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mon apprentissage'), findsOneWidget);
      expect(find.text('Commencez votre premier parcours'), findsOneWidget);
      expect(find.text('Découvrir les formations'), findsOneWidget);
    });

    testWidgets('active state renders localized course, module and lesson',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith((ref) => Stream.value([_course()])),
            allProgressProvider.overrideWith((ref) => Future.value([])),
            myLearningStateProvider.overrideWith(
              (ref) async => MyLearningState(
                display: MyLearningDisplayState.active,
                active: _activeLearning(),
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mon apprentissage'), findsOneWidget);
      expect(find.text('Bien démarrer'), findsOneWidget);
      expect(find.text('Bienvenue dans les formations'), findsOneWidget);
      expect(find.text('Reprenez là où vous vous êtes arrêté'), findsOneWidget);
      expect(find.text('Reprendre'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('Reprendre navigates to the real lesson route', (tester) async {
      final course = _course();
      final router = GoRouter(
        initialLocation: '/training',
        routes: [
          GoRoute(
            path: '/training',
            builder: (_, __) => const TrainingScreen(),
          ),
          GoRoute(
            path: '/formations/:courseId/lessons/:lessonId',
            builder: (_, state) {
              return Scaffold(
                body: Text(
                  'lesson:${state.pathParameters['lessonId']}',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const SizedBox.shrink(),
          router: router,
          overrides: [
            publishedCoursesProvider.overrideWith((ref) => Stream.value([course])),
            allProgressProvider.overrideWith((ref) => Future.value([])),
            myLearningStateProvider.overrideWith(
              (ref) async => MyLearningState(
                display: MyLearningDisplayState.active,
                active: _activeLearning(),
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Reprendre'));
      await tester.pumpAndSettle();

      expect(find.text('lesson:l2'), findsOneWidget);
      expect(router.state.uri.path, '/formations/c1/lessons/l2');
    });

    testWidgets('completed-only state does not show misleading Reprendre card',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith((ref) => Stream.value([_course()])),
            allProgressProvider.overrideWith((ref) => Future.value([])),
            myLearningStateProvider.overrideWith(
              (ref) async => const MyLearningState(
                display: MyLearningDisplayState.allCompleted,
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bravo, vous avez terminé vos parcours'), findsOneWidget);
      expect(find.text('Reprendre'), findsNothing);
    });

    testWidgets('no overflow on iPhone SE with active card', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([_course()]),
            ),
            allProgressProvider.overrideWith((ref) => Future.value([])),
            myLearningStateProvider.overrideWith(
              (ref) async => MyLearningState(
                display: MyLearningDisplayState.active,
                active: _activeLearning(),
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
