import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/user_progress.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/presentation/formation_resume_resolver.dart';
import 'package:anis_khatamat/features/formations/providers/formation_learning_providers.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/screens/training_screen.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';

/// Test helper to wrap widgets with necessary providers and localization
Widget _wrapWidget(
  Widget child, {
  Locale locale = const Locale('fr'),
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      home: child,
    ),
  );
}

Course _testCourse({
  String id = 'c1',
  String title = 'Test Course',
  String description = 'Test description',
  CourseLevel level = CourseLevel.beginner,
  CourseCategory category = CourseCategory.tajweed,
  int totalLessons = 10,
  Map<String, CourseTranslation>? translations,
}) {
  return Course(
    id: id,
    title: title,
    description: description,
    level: level,
    category: category,
    instructor: 'Test Instructor',
    totalLessons: totalLessons,
    createdAt: DateTime(2024, 1, 1),
    translations: translations,
  );
}

UserCourseProgress _testProgress({
  String courseId = 'c1',
  Set<String> completedLessonIds = const {},
  String? currentLessonId,
  DateTime? lastAccessedAt,
}) {
  return UserCourseProgress(
    userId: 'user1',
    courseId: courseId,
    completedLessonIds: completedLessonIds,
    currentLessonId: currentLessonId,
    lastAccessedAt: lastAccessedAt ?? DateTime.now(),
  );
}

void main() {
  group('TrainingScreen - Basic States', () {
    testWidgets('Loading state shows progress indicator', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Empty state shows appropriate message', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucune formation disponible pour le moment'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    });

    testWidgets('Error state shows retry button', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            authReadinessProvider.overrideWith(
              (ref) => const AuthReadiness.signedIn('test-uid'),
            ),
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.error(Exception('Test error')),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            myLearningStateProvider.overrideWith(
              (ref) => Future.value(const MyLearningState(display: MyLearningDisplayState.empty)),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Erreur lors du chargement des formations'), findsWidgets);
      expect(find.text('Réessayer'), findsWidgets);
      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });
  });

  group('TrainingScreen - Course Display', () {
    testWidgets('Displays single course correctly', (tester) async {
      final course = _testCourse(
        title: 'Tajweed Basics',
        description: 'Learn the basics of Tajweed',
        category: CourseCategory.tajweed,
        level: CourseLevel.beginner,
        totalLessons: 10,
      );

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tajweed Basics'), findsOneWidget);
      expect(find.text('Learn the basics of Tajweed'), findsOneWidget);
      expect(find.text('Tajweed'), findsWidgets); // Category (appears in filter and card)
      expect(find.text('Débutant'), findsOneWidget); // Level in French
      expect(find.text('10 leçons'), findsOneWidget);
    });

    testWidgets('Displays multiple courses', (tester) async {
      final courses = [
        _testCourse(id: 'c1', title: 'Course 1'),
        _testCourse(id: 'c2', title: 'Course 2'),
        _testCourse(id: 'c3', title: 'Course 3'),
      ];

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value(courses),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            ...courses.map((c) => courseProgressProvider(c.id).overrideWith(
                  (ref) => Future.value(null),
                )),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Course 1'), findsOneWidget);
      expect(find.text('Course 2'), findsOneWidget);
      expect(find.text('Course 3'), findsOneWidget);
    });

    testWidgets('Shows progress indicator on course card when in progress', (tester) async {
      final course = _testCourse(
        id: 'c1',
        title: 'Test Course',
        totalLessons: 10,
      );

      final progress = _testProgress(
        courseId: 'c1',
        completedLessonIds: {'lesson1', 'lesson2', 'lesson3'},
      );

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(progress),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsWidgets);
      expect(find.text('30% complété'), findsOneWidget);
    });
  });

  group('TrainingScreen - Category Filter', () {
    testWidgets('Category filter chips are displayed', (tester) async {
      final course = _testCourse();

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Check "Tous" chip exists
      expect(find.text('Tous'), findsOneWidget);
      
      // Check pedagogical pillar chips exist (V1 taxonomy)
      expect(find.text('Bases & pratique'), findsOneWidget);
      expect(find.text("Qur'an & lecture"), findsOneWidget);
    });

    testWidgets('Category filter is horizontally scrollable', (tester) async {
      final course = _testCourse();

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Check that category filter is horizontally scrollable
      // The filter section contains a SingleChildScrollView for horizontal scrolling
      final filterScrollView = find.descendant(
        of: find.byType(Padding),
        matching: find.byType(SingleChildScrollView),
      );
      expect(filterScrollView, findsWidgets); // At least one horizontal scroll view exists
    });
  });

  group('TrainingScreen - Mon apprentissage', () {
    testWidgets('shows empty Mon apprentissage when no progress', (tester) async {
      final course = _testCourse();

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            authReadinessProvider.overrideWith(
              (ref) => const AuthReadiness.signedIn('test-uid'),
            ),
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
            courseLessonsProvider(course.id).overrideWith(
              (ref) => Future.value([]),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mon apprentissage'), findsOneWidget);
      expect(find.text('Commencez votre premier parcours'), findsOneWidget);
      expect(find.text('Reprendre votre parcours'), findsNothing);
    });
  });

  group('TrainingScreen - Localization', () {
    testWidgets('French localization works', (tester) async {
      final course = _testCourse(
        translations: {
          'fr': const CourseTranslation(
            title: 'Bases du Tajweed',
            description: 'Apprenez les bases',
          ),
        },
      );

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          locale: const Locale('fr'),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('FORMATIONS'), findsWidgets); // Hero in uppercase
      expect(find.text('Bases du Tajweed'), findsOneWidget);
      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('Débutant'), findsOneWidget);
    });

    testWidgets('English localization works', (tester) async {
      final course = _testCourse(
        translations: {
          'en': const CourseTranslation(
            title: 'Tajweed Basics',
            description: 'Learn the basics',
          ),
        },
      );

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          locale: const Locale('en'),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('TRAINING'), findsWidgets); // Hero in uppercase
      expect(find.text('Tajweed Basics'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
    });

    testWidgets('Arabic localization works', (tester) async {
      final course = _testCourse(
        translations: {
          'ar': const CourseTranslation(
            title: 'أساسيات التجويد',
            description: 'تعلم الأساسيات',
          ),
        },
      );

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          locale: const Locale('ar'),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Hero is in uppercase, check for formation-related text
      expect(find.text('أساسيات التجويد'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('مبتدئ'), findsOneWidget);
    });

    testWidgets('RTL layout for Arabic', (tester) async {
      final course = _testCourse();

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          locale: const Locale('ar'),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );
      expect(materialApp.locale?.languageCode, 'ar');
      
      // Verify RTL by checking Directionality
      final directionalityFinder = find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(Directionality),
      );
      
      if (directionalityFinder.evaluate().isNotEmpty) {
        final directionality = tester.widget<Directionality>(
          directionalityFinder.first,
        );
        expect(directionality.textDirection, TextDirection.rtl);
      }
    });
  });

  group('TrainingScreen - iPhone SE Constraints', () {
    testWidgets('No overflow on iPhone SE width', (tester) async {
      // iPhone SE (3rd gen): 375 x 667 logical pixels
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final course = _testCourse(
        title: 'Very Long Course Title That Should Not Overflow',
        description: 'Very long description that should wrap properly without causing overflow issues on small screens',
      );

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow by checking for RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mon apprentissage fits on iPhone SE', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final course = _testCourse(
        translations: const {
          'fr': CourseTranslation(
            title: 'Découvrir les formations ANIS',
            description: 'Description',
          ),
        },
      );

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            myLearningStateProvider.overrideWith(
              (ref) async => MyLearningState(
                display: MyLearningDisplayState.active,
                active: ResolvedActiveLearning(
                  course: course,
                  progress: _testProgress(
                    courseId: course.id,
                    currentLessonId: 'l2',
                    completedLessonIds: {'l1'},
                  ),
                  lessons: const [
                    Lesson(
                      id: 'l1',
                      moduleId: 'm1',
                      courseId: 'c1',
                      title: 'Lesson 1',
                      type: LessonType.text,
                      order: 1,
                    ),
                    Lesson(
                      id: 'l2',
                      moduleId: 'm1',
                      courseId: 'c1',
                      title: 'Lesson 2',
                      type: LessonType.text,
                      order: 2,
                    ),
                  ],
                  currentLesson: const Lesson(
                    id: 'l2',
                    moduleId: 'm1',
                    courseId: 'c1',
                    title: 'Lesson 2',
                    type: LessonType.text,
                    order: 2,
                  ),
                  module: const CourseModule(
                    id: 'm1',
                    courseId: 'c1',
                    title: 'Module',
                    order: 1,
                    lessonIds: ['l1', 'l2'],
                  ),
                  resumeLessonId: 'l2',
                ),
              ),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mon apprentissage'), findsOneWidget);
      expect(find.text('Reprendre'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TrainingScreen - Premium Features', () {
    testWidgets('Live card renders in teaser state', (tester) async {
      final course = _testCourse();

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lives ANIS'), findsOneWidget);
      expect(find.text('PROCHAINEMENT'), findsOneWidget); // Live card status (uppercase)
    });

    testWidgets('Questions card renders in teaser state', (tester) async {
      final course = _testCourse();

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Questions privées & publiques'), findsOneWidget);
      expect(find.text('Bientôt'), findsWidgets); // At least one for Questions card
    });

    testWidgets('Premium header renders correctly', (tester) async {
      final course = _testCourse();

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('FORMATIONS'), findsWidgets);
      expect(find.text('Apprendre.\nComprendre.\nMettre en pratique.'), findsOneWidget);
    });

    testWidgets('"Formations disponibles" section renders', (tester) async {
      final course = _testCourse();

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Check for section titles
      expect(find.text('Parcours à découvrir'), findsOneWidget);
    });

    testWidgets('Feature cards adapt on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(375, 667); // iPhone SE
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final course = _testCourse();

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Future.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Both cards should render on iPhone SE without overflow
      expect(find.text('Lives ANIS'), findsOneWidget);
      expect(find.text('Questions privées & publiques'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
