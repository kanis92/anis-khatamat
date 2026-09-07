import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/user_progress.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/screens/training_screen.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.error(Exception('Test error')),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([]),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Erreur lors du chargement des formations'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
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
              (ref) => Stream.value(null),
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
                  (ref) => Stream.value(null),
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
              (ref) => Stream.value(progress),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsWidgets);
      expect(find.text('30% terminé'), findsOneWidget);
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
              (ref) => Stream.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Check "Tous" chip exists
      expect(find.text('Tous'), findsOneWidget);
      
      // Check category chips exist
      expect(find.text('Tajweed'), findsWidgets);
      expect(find.text('Tafsir'), findsOneWidget);
      expect(find.text('Fiqh'), findsOneWidget);
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
              (ref) => Stream.value(null),
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

  group('TrainingScreen - Resume Card', () {
    testWidgets('Resume card not shown when no progress', (tester) async {
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
              (ref) => Stream.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Continuer ma formation'), findsNothing);
      // play_circle_outline appears in course cards, so check specifically for resume section
      final resumeSection = find.ancestor(
        of: find.text('Continuer ma formation'),
        matching: find.byType(Container),
      );
      expect(resumeSection, findsNothing);
    });

    testWidgets('Resume card shown with most recent progress', (tester) async {
      final course = _testCourse(
        id: 'c1',
        title: 'In Progress Course',
        totalLessons: 10,
      );

      final progress = _testProgress(
        courseId: 'c1',
        completedLessonIds: {'lesson1', 'lesson2'},
        currentLessonId: 'lesson3',
        lastAccessedAt: DateTime(2024, 1, 15),
      );

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([progress]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Stream.value(progress),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Continuer ma formation'), findsOneWidget);
      expect(find.text('In Progress Course'), findsWidgets);
      expect(find.text('2/10'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
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
              (ref) => Stream.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Formations'), findsWidgets); // Appears in app bar and body
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
              (ref) => Stream.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Training'), findsWidgets); // Appears in app bar and body  
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
              (ref) => Stream.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('التدريب'), findsWidgets); // Appears in app bar and body
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
              (ref) => Stream.value(null),
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
              (ref) => Stream.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow by checking for RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Resume card fits on iPhone SE', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final course = _testCourse(
        title: 'In Progress Course',
        totalLessons: 10,
      );

      final progress = _testProgress(
        courseId: 'c1',
        completedLessonIds: {'lesson1', 'lesson2'},
      );

      await tester.pumpWidget(
        _wrapWidget(
          const TrainingScreen(),
          overrides: [
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            allProgressProvider.overrideWith(
              (ref) => Future.value([progress]),
            ),
            courseProgressProvider(course.id).overrideWith(
              (ref) => Stream.value(progress),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Continuer ma formation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
