import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anis_khatamat/app/router.dart';
import 'package:anis_khatamat/core/api/anis_api_client.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/design_system/components/anis_bottom_navigation.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/features/formations/repositories/formations_repository.dart';
import 'package:anis_khatamat/features/formations/services/formations_api_service.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/course_detail_screen.dart';
import 'package:anis_khatamat/screens/lesson_screen.dart';
import 'package:anis_khatamat/screens/training_screen.dart';

class MockAnisApiClient extends Mock implements AnisApiClient {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  const courseId = 'course-test';
  const lessonId = 'lesson-test';

  final testCourse = Course(
    id: courseId,
    title: 'Formation test',
    description: 'Description test',
    instructor: 'ANIS',
    createdAt: DateTime(2024, 1, 1),
  );

  final testLesson = Lesson(
    id: lessonId,
    moduleId: 'module-test',
    courseId: courseId,
    title: 'Leçon test',
    type: LessonType.text,
    order: 1,
    contentText: 'Contenu de la leçon',
  );

  late MockAnisApiClient mockApiClient;
  late MockFirebaseFirestore mockFirestore;
  late FormationsRepository testRepository;

  setUp(() {
    mockApiClient = MockAnisApiClient();
    mockFirestore = MockFirebaseFirestore();
    testRepository = FormationsRepository(
      db: mockFirestore,
      apiService: FormationsApiService(mockApiClient),
    );
    when(
      () => mockApiClient.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => {});
  });

  List<Override> formationNavigationOverrides() => [
        demoModeProvider.overrideWith((ref) => true),
        publishedCoursesProvider.overrideWith((ref) => Stream.value([])),
        formationsRepositoryProvider.overrideWith((ref) => testRepository),
        lessonDetailProvider.overrideWith((ref, params) async => testLesson),
        courseProgressProvider.overrideWith((ref, id) => Future.value(null)),
      ];

  group('Formations nested navigation', () {
    testWidgets('LessonScreen exposes valid back navigation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: formationNavigationOverrides(),
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LessonScreen(courseId: courseId, lessonId: lessonId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Leçon test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Reselecting Formations tab returns to TrainingScreen root', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: formationNavigationOverrides(),
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.binding.setSurfaceSize(const Size(750, 1334));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('fr'),
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/formations/$courseId/lessons/$lessonId');
      await tester.pumpAndSettle();

      expect(find.byType(LessonScreen), findsOneWidget);
      expect(router.state.uri.path, '/formations/$courseId/lessons/$lessonId');

      await tester.tap(find.text('Formations').last);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/training');
      expect(find.byType(TrainingScreen), findsOneWidget);
      expect(find.byType(LessonScreen), findsNothing);
    });

    testWidgets('Shell keeps a single bottom navigation bar', (tester) async {
      final container = ProviderContainer(
        overrides: formationNavigationOverrides(),
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.binding.setSurfaceSize(const Size(750, 1334));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('fr'),
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/formations/$courseId/lessons/$lessonId');
      await tester.pumpAndSettle();

      expect(find.byType(AnisBottomNavigation), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('Course to lesson navigation remains functional', (tester) async {
      final container = ProviderContainer(
        overrides: [
          ...formationNavigationOverrides(),
          courseModulesProvider.overrideWith((ref, id) async => []),
          courseLessonsProvider.overrideWith((ref, id) async => [testLesson]),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/course',
        routes: [
          GoRoute(
            path: '/course',
            builder: (context, state) =>
                CourseDetailScreen(course: testCourse),
          ),
          GoRoute(
            path: '/formations/:courseId/lessons/:lessonId',
            builder: (context, state) => LessonScreen(
              courseId: state.pathParameters['courseId']!,
              lessonId: state.pathParameters['lessonId']!,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('fr'),
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CourseDetailScreen), findsOneWidget);

      router.push('/formations/$courseId/lessons/$lessonId');
      await tester.pumpAndSettle();

      expect(find.byType(LessonScreen), findsOneWidget);
      expect(find.byType(CourseDetailScreen), findsNothing);
    });
  });
}
