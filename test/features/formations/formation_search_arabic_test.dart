import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/services/formation_search_service.dart';
import 'package:anis_khatamat/features/formations/models/formation_search_result.dart';

void main() {
  group('Formation Search Arabic Normalization', () {
    late List<Course> courses;
    late Map<String, List<CourseModule>> courseModules;
    late Map<String, List<Lesson>> courseLessons;

    setUp(() {
      // Setup test data with realistic Arabic titles
      courses = [
        Course(
          id: 'course-1',
          title: 'الوضوء', // Al-Wudu (ablution) without harakat
          description: 'تعلم الوضوء الصحيح',
          instructor: 'Test',
          createdAt: DateTime.now(),
          isPublished: true,
        ),
        Course(
          id: 'course-2',
          title: 'الصلاة اليومية', // Daily prayer without harakat
          description: 'كيف تصلي في اليوم',
          instructor: 'Test',
          createdAt: DateTime.now(),
          isPublished: true,
        ),
      ];

      courseModules = {
        'course-1': [
          CourseModule(
            id: 'module-1',
            courseId: 'course-1',
            title: 'مقدمة في الوضوء',
            order: 0,
          ),
        ],
        'course-2': [
          CourseModule(
            id: 'module-2',
            courseId: 'course-2',
            title: 'أوقات الصلاة',
            order: 0,
          ),
        ],
      };

      courseLessons = {
        'course-1': [
          Lesson(
            id: 'lesson-1',
            moduleId: 'module-1',
            courseId: 'course-1',
            title: 'السلوك أثناء الوضوء',
            type: LessonType.text,
            durationMinutes: 10,
            order: 0,
          ),
        ],
        'course-2': [
          Lesson(
            id: 'lesson-2',
            moduleId: 'module-2',
            courseId: 'course-2',
            title: 'صلاة الفجر',
            type: LessonType.text,
            durationMinutes: 15,
            order: 0,
          ),
        ],
      };
    });

    test('Arabic harakat (diacritics) are normalized', () {
      // الْوُضُوءُ with harakat (Fatha, Damma, Kasra, Sukun, Shadda)
      final textWithHarakat = 'الْوُضُوءُ';
      // الوضوء without harakat
      final textWithoutHarakat = 'الوضوء';

      final normalizedWithHarakat = FormationSearchService.normalizeText(textWithHarakat);
      final normalizedWithoutHarakat = FormationSearchService.normalizeText(textWithoutHarakat);

      // After normalization, both should be identical
      expect(normalizedWithHarakat, equals(normalizedWithoutHarakat));
    });

    test('Arabic base letters are preserved during normalization', () {
      // Verify that removing harakat doesn't remove the actual letters
      final arabicText = 'الصلاة';
      final normalized = FormationSearchService.normalizeText(arabicText);

      // Base letters should remain
      expect(normalized, contains('ا'));
      expect(normalized, contains('ل'));
      expect(normalized, contains('ص'));
      expect(normalized, contains('ة'));
      
      // Normalized text should not be empty
      expect(normalized.isNotEmpty, true);
      expect(normalized.length, greaterThanOrEqualTo(5)); // الصلاة has 5+ chars
    });

    test('search works with Arabic text with harakat', () {
      // Search with harakat
      final resultsWithHarakat = FormationSearchService.search(
        query: 'الْوُضُوءُ', // With harakat
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'ar',
      );

      expect(resultsWithHarakat.isNotEmpty, true);
      final courseResult = resultsWithHarakat.firstWhere(
        (r) => r.type == FormationSearchResultType.course,
      );
      expect(courseResult.title, 'الوضوء');
    });

    test('search works with Arabic text without harakat', () {
      // Search without harakat
      final resultsWithoutHarakat = FormationSearchService.search(
        query: 'الوضوء', // Without harakat
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'ar',
      );

      expect(resultsWithoutHarakat.isNotEmpty, true);
      final courseResult = resultsWithoutHarakat.firstWhere(
        (r) => r.type == FormationSearchResultType.course,
      );
      expect(courseResult.title, 'الوضوء');
    });

    test('Arabic text with and without harakat produce same results', () {
      final resultsWithHarakat = FormationSearchService.search(
        query: 'الصَّلَاةُ', // With harakat
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'ar',
      );

      final resultsWithoutHarakat = FormationSearchService.search(
        query: 'الصلاة', // Without harakat
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'ar',
      );

      // Should return same number of results with same scores
      expect(resultsWithHarakat.length, equals(resultsWithoutHarakat.length));
      
      if (resultsWithHarakat.isNotEmpty && resultsWithoutHarakat.isNotEmpty) {
        expect(
          resultsWithHarakat.first.score,
          equals(resultsWithoutHarakat.first.score),
        );
      }
    });

    test('Arabic whitespace normalization works', () {
      final textWithExtraSpaces = '  الصلاة    اليومية  ';
      final normalized = FormationSearchService.normalizeText(textWithExtraSpaces);

      // Should trim and collapse whitespace
      expect(normalized, 'الصلاة اليومية');
      expect(normalized.startsWith(' '), false);
      expect(normalized.endsWith(' '), false);
      expect(normalized.contains('  '), false); // No double spaces
    });

    test('specific harakat Unicode ranges are removed', () {
      // Test specific harakat characters (U+064B to U+065F)
      const fatha = '\u064B'; // ً
      const damma = '\u064C'; // ٌ
      const kasra = '\u064D'; // ٍ
      const sukun = '\u0652'; // ْ
      const shadda = '\u0651'; // ّ
      const tanweenFath = '\u064B'; // ً

      final textWithHarakat = 'كتاب${fatha}${damma}${kasra}${sukun}${shadda}${tanweenFath}';
      final normalized = FormationSearchService.normalizeText(textWithHarakat);

      // Harakat should be removed, base letters preserved
      expect(normalized, 'كتاب');
      expect(normalized, isNot(contains(fatha)));
      expect(normalized, isNot(contains(damma)));
      expect(normalized, isNot(contains(kasra)));
      expect(normalized, isNot(contains(sukun)));
      expect(normalized, isNot(contains(shadda)));
    });

    test('Arabic search finds lesson by title', () {
      final results = FormationSearchService.search(
        query: 'الفجر',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'ar',
      );

      expect(results.isNotEmpty, true);
      final lessonResult = results.firstWhere(
        (r) => r.type == FormationSearchResultType.lesson,
      );
      expect(lessonResult.title, contains('الفجر'));
    });
  });
}
