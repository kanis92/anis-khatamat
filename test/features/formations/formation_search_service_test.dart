import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/services/formation_search_service.dart';
import 'package:anis_khatamat/features/formations/models/formation_search_result.dart';

void main() {
  group('FormationSearchService', () {
    late List<Course> courses;
    late Map<String, List<CourseModule>> courseModules;
    late Map<String, List<Lesson>> courseLessons;

    setUp(() {
      // Setup test data
      courses = [
        Course(
          id: 'course-1',
          title: 'Les ablutions',
          description: 'Apprendre les ablutions correctement',
          instructor: 'Test',
          createdAt: DateTime.now(),
          isPublished: true,
        ),
        Course(
          id: 'course-2',
          title: 'La prière quotidienne',
          description: 'Comment prier au quotidien',
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
            title: 'Introduction aux ablutions',
            order: 0,
          ),
        ],
        'course-2': [
          CourseModule(
            id: 'module-2',
            courseId: 'course-2',
            title: 'Les horaires de prière',
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
            title: 'Le comportement pendant les ablutions',
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
            title: 'La prière de Fajr',
            type: LessonType.text,
            durationMinutes: 15,
            order: 0,
          ),
        ],
      };
    });

    test('normalizeText removes accents', () {
      expect(
        FormationSearchService.normalizeText('été'),
        'ete',
      );
      expect(
        FormationSearchService.normalizeText('à voir'),
        'a voir',
      );
    });

    test('normalizeText is case-insensitive', () {
      expect(
        FormationSearchService.normalizeText('FORMATION'),
        'formation',
      );
    });

    test('exact course title match returns high score', () {
      final results = FormationSearchService.search(
        query: 'Les ablutions',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      expect(results.length, greaterThan(0));
      expect(results.first.type, FormationSearchResultType.course);
      expect(results.first.title, 'Les ablutions');
      expect(results.first.score, greaterThan(90.0));
    });

    test('lesson title query finds exact lesson', () {
      final results = FormationSearchService.search(
        query: 'comportement',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      expect(results.isNotEmpty, true);
      final lessonResult = results.firstWhere(
        (r) => r.type == FormationSearchResultType.lesson,
      );
      expect(lessonResult.title, contains('comportement'));
    });

    test('module title query finds module', () {
      final results = FormationSearchService.search(
        query: 'horaires',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      expect(results.isNotEmpty, true);
      final moduleResult = results.firstWhere(
        (r) => r.type == FormationSearchResultType.module,
      );
      expect(moduleResult.title, contains('horaires'));
    });

    test('case-insensitive match works', () {
      final resultsLower = FormationSearchService.search(
        query: 'ablutions',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      final resultsUpper = FormationSearchService.search(
        query: 'ABLUTIONS',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      expect(resultsLower.length, equals(resultsUpper.length));
      expect(resultsLower.first.score, equals(resultsUpper.first.score));
    });

    test('accent normalization works', () {
      final resultsAccented = FormationSearchService.search(
        query: 'prière',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      final resultsNormalized = FormationSearchService.search(
        query: 'priere',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      expect(resultsAccented.length, equals(resultsNormalized.length));
      expect(resultsAccented.first.score, equals(resultsNormalized.first.score));
    });

    test('title match ranks higher than description match', () {
      final results = FormationSearchService.search(
        query: 'prière',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      // "La prière quotidienne" (title match) should rank higher
      // than "comment prier" (description match)
      expect(results.isNotEmpty, true);
      final topResult = results.first;
      expect(topResult.title, contains('prière'));
    });

    test('zero results for nonsense query', () {
      final results = FormationSearchService.search(
        query: 'xyzabc123',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      expect(results.isEmpty, true);
    });

    test('short query returns empty results', () {
      final results = FormationSearchService.search(
        query: 'a',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      expect(results.isEmpty, true);
    });

    test('results are sorted by score descending', () {
      final results = FormationSearchService.search(
        query: 'les',
        courses: courses,
        courseModules: courseModules,
        courseLessons: courseLessons,
        locale: 'fr',
      );

      for (int i = 0; i < results.length - 1; i++) {
        expect(
          results[i].score,
          greaterThanOrEqualTo(results[i + 1].score),
        );
      }
    });
  });
}
