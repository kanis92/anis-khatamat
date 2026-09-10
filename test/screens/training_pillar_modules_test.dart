import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anis_khatamat/app/router.dart';
import 'package:anis_khatamat/core/api/anis_api_client.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/features/formations/repositories/formations_repository.dart';
import 'package:anis_khatamat/features/formations/services/formations_api_service.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/models/pedagogical_pillar.dart';
import 'package:anis_khatamat/features/formations/presentation/formation_resume_resolver.dart';
import 'package:anis_khatamat/features/formations/providers/formation_learning_providers.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/lesson_screen.dart';

class MockAnisApiClient extends Mock implements AnisApiClient {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

const _canonicalCourseId = 'course-foundations_practice';

Course _foundationsCourse() => Course(
      id: _canonicalCourseId,
      title: 'Legacy English',
      description: 'Description',
      instructor: 'ANIS',
      pillarId: PedagogicalPillar.foundationsPractice.id,
      createdAt: DateTime(2024, 1, 1),
      translations: const {
        'fr': CourseTranslation(
          title: 'Bases & pratique',
          description: 'Parcours structuré',
        ),
      },
    );

Course _legacyCourse() => Course(
      id: 'demo-formation-basics',
      title: 'Formation Basics Demo',
      description: 'Legacy preview',
      instructor: 'ANIS',
      pillarId: PedagogicalPillar.foundationsPractice.id,
      createdAt: DateTime(2023, 1, 1),
    );

List<CourseModule> _foundationsModules() {
  const titles = [
    'Bien démarrer',
    'Comprendre les fondamentaux',
    'La prière au quotidien',
    'Les ablutions et la préparation',
    'Organiser sa pratique avec constance',
  ];

  return [
    for (var i = 0; i < titles.length; i++)
      CourseModule(
        id: '$_canonicalCourseId-module-${i + 1}',
        courseId: _canonicalCourseId,
        title: 'Legacy ${titles[i]}',
        order: i + 1,
        lessonIds: i == 0
            ? ['$_canonicalCourseId-module-1-lesson-1', '$_canonicalCourseId-module-1-lesson-2']
            : ['$_canonicalCourseId-module-${i + 1}-lesson-1', '$_canonicalCourseId-module-${i + 1}-lesson-2'],
        translations: {
          'fr': ModuleTranslation(title: titles[i], description: titles[i]),
        },
      ),
  ];
}

List<Lesson> _foundationsLessons() {
  return const [
    Lesson(
      id: 'course-foundations_practice-module-1-lesson-1',
      moduleId: 'course-foundations_practice-module-1',
      courseId: _canonicalCourseId,
      title: 'Legacy welcome',
      type: LessonType.text,
      order: 1,
      translations: {
        'fr': LessonTranslation(
          title: 'Bienvenue dans les formations',
          description: 'Intro',
        ),
      },
    ),
    Lesson(
      id: 'course-foundations_practice-module-1-lesson-2',
      moduleId: 'course-foundations_practice-module-1',
      courseId: _canonicalCourseId,
      title: 'Legacy progress',
      type: LessonType.text,
      order: 2,
      translations: {
        'fr': LessonTranslation(
          title: 'Suivre sa progression',
          description: 'Progress',
        ),
      },
    ),
  ];
}

List<Lesson> _allFoundationsLessons() {
  final lessons = <Lesson>[..._foundationsLessons()];
  for (var moduleIndex = 2; moduleIndex <= 5; moduleIndex++) {
    for (var lessonIndex = 1; lessonIndex <= 2; lessonIndex++) {
      lessons.add(
        Lesson(
          id: '$_canonicalCourseId-module-$moduleIndex-lesson-$lessonIndex',
          moduleId: '$_canonicalCourseId-module-$moduleIndex',
          courseId: _canonicalCourseId,
          title: 'Lesson $lessonIndex',
          type: LessonType.text,
          order: lessonIndex,
          translations: {
            'fr': LessonTranslation(
              title: 'Leçon $moduleIndex.$lessonIndex',
              description: 'Preview',
            ),
          },
        ),
      );
    }
  }
  return lessons;
}

List<Override> _pillarOverrides({
  required List<Course> courses,
  required List<CourseModule> modules,
  List<Lesson> lessons = const [],
}) {
  final course = courses.firstWhere(
    (item) => item.pillarId == PedagogicalPillar.foundationsPractice.id,
    orElse: () => courses.first,
  );

  return [
    publishedCoursesProvider.overrideWith((ref) => Stream.value(courses)),
    coursesByPillarProvider(PedagogicalPillar.foundationsPractice.id)
        .overrideWith((ref) => Stream.value(courses)),
    courseModulesProvider(course.id).overrideWith((ref) async => modules),
    courseLessonsProvider(course.id).overrideWith((ref) async => lessons),
    allProgressProvider.overrideWith((ref) async => []),
    myLearningStateProvider.overrideWith(
      (ref) async => const MyLearningState(
        display: MyLearningDisplayState.empty,
      ),
    ),
  ];
}

Future<ProviderContainer> _pumpPillarTrainingScreen(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  final container = ProviderContainer(
    overrides: [
      demoModeProvider.overrideWith((ref) => true),
      ...overrides,
    ],
  );
  container.read(selectedPillarProvider.notifier).state =
      PedagogicalPillar.foundationsPractice;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: container.read(goRouterProvider),
      ),
    ),
  );

  container.read(goRouterProvider).go('/training');
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('Bases & pratique pillar modules', () {
    testWidgets('canonical course resolves 5 real modules', (tester) async {
      await _pumpPillarTrainingScreen(
        tester,
        overrides: _pillarOverrides(
          courses: [_foundationsCourse()],
          modules: _foundationsModules(),
        ),
      );

      expect(find.text('Modules   5'), findsOneWidget);
      expect(find.text('Bien démarrer'), findsOneWidget);
      expect(find.text('Comprendre les fondamentaux'), findsOneWidget);
      expect(find.text('La prière au quotidien'), findsOneWidget);
      expect(find.text('Les ablutions et la préparation'), findsOneWidget);
      expect(find.text('Organiser sa pratique avec constance'), findsOneWidget);
      expect(find.text('Mettre en pratique'), findsNothing);
    });

    testWidgets('legacy demo course alone is not the canonical 5-module path',
        (tester) async {
      const legacyModules = [
        CourseModule(
          id: 'module-1-intro',
          courseId: 'demo-formation-basics',
          title: 'Getting started',
          order: 1,
          lessonIds: ['lesson-1'],
          translations: {
            'fr': ModuleTranslation(title: 'Bien démarrer', description: 'Intro'),
          },
        ),
        CourseModule(
          id: 'module-2-practice',
          courseId: 'demo-formation-basics',
          title: 'Practice',
          order: 2,
          translations: {
            'fr': ModuleTranslation(title: 'Mettre en pratique', description: 'Practice'),
          },
        ),
      ];

      await _pumpPillarTrainingScreen(
        tester,
        overrides: [
          publishedCoursesProvider.overrideWith(
            (ref) => Stream.value([_legacyCourse()]),
          ),
          coursesByPillarProvider(PedagogicalPillar.foundationsPractice.id)
              .overrideWith((ref) => Stream.value([_legacyCourse()])),
          courseModulesProvider('demo-formation-basics')
              .overrideWith((ref) async => legacyModules),
          courseLessonsProvider('demo-formation-basics')
              .overrideWith((ref) async => const []),
          allProgressProvider.overrideWith((ref) async => []),
          myLearningStateProvider.overrideWith(
            (ref) async => const MyLearningState(
              display: MyLearningDisplayState.empty,
            ),
          ),
        ],
      );

      expect(find.text('Modules   2'), findsOneWidget);
      expect(find.text('Mettre en pratique'), findsOneWidget);
      expect(find.text('Comprendre les fondamentaux'), findsNothing);
    });

    testWidgets('tapping a module expands real lessons', (tester) async {
      await _pumpPillarTrainingScreen(
        tester,
        overrides: _pillarOverrides(
          courses: [_foundationsCourse()],
          modules: _foundationsModules(),
          lessons: _foundationsLessons(),
        ),
      );

      expect(find.text('Modules   5'), findsOneWidget);
      expect(find.text('Bienvenue dans les formations'), findsNothing);

      await tester.ensureVisible(find.text('Bien démarrer'));
      await tester.tap(find.text('Bien démarrer'));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue dans les formations'), findsOneWidget);
      expect(find.text('Suivre sa progression'), findsOneWidget);
    });

    testWidgets('tapping a lesson opens existing lesson route', (tester) async {
      final course = _foundationsCourse();
      const lessonId = 'course-foundations_practice-module-1-lesson-1';
      final mockApiClient = MockAnisApiClient();
      final mockFirestore = MockFirebaseFirestore();
      final testRepository = FormationsRepository(
        db: mockFirestore,
        apiService: FormationsApiService(mockApiClient),
      );
      when(
        () => mockApiClient.post(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          demoModeProvider.overrideWith((ref) => true),
          formationsRepositoryProvider.overrideWith((ref) => testRepository),
          courseProgressProvider.overrideWith((ref, id) => Future.value(null)),
          ..._pillarOverrides(
            courses: [course],
            modules: _foundationsModules(),
            lessons: _foundationsLessons(),
          ),
          lessonDetailProvider.overrideWith(
            (ref, params) async => _foundationsLessons().first,
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(selectedPillarProvider.notifier).state =
          PedagogicalPillar.foundationsPractice;
      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      router.go('/training');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Bien démarrer'));
      await tester.tap(find.text('Bien démarrer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bienvenue dans les formations'));
      await tester.tap(find.text('Bienvenue dans les formations'));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.path,
        '/formations/$_canonicalCourseId/lessons/$lessonId',
      );
      expect(find.byType(LessonScreen), findsOneWidget);
    });

    testWidgets('module with zero lessons shows calm coming-soon without chevron',
        (tester) async {
      const emptyModule = CourseModule(
        id: 'empty-module',
        courseId: _canonicalCourseId,
        title: 'Empty module',
        order: 6,
        translations: {
          'fr': ModuleTranslation(title: 'Module vide', description: 'Soon'),
        },
      );

      await _pumpPillarTrainingScreen(
        tester,
        overrides: _pillarOverrides(
          courses: [_foundationsCourse()],
          modules: [..._foundationsModules(), emptyModule],
          lessons: _allFoundationsLessons(),
        ),
      );

      expect(find.text('Module vide'), findsOneWidget);
      expect(find.text('Contenu à venir'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNWidgets(5));
    });

    testWidgets('no overflow on iPhone SE pillar modules view', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpPillarTrainingScreen(
        tester,
        overrides: _pillarOverrides(
          courses: [_foundationsCourse()],
          modules: _foundationsModules(),
          lessons: _foundationsLessons(),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
