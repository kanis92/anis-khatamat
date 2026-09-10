import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';

import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/presentation/course_content_resolver.dart';

void main() {
  group('Multilingual Content Resolution', () {
    late Course testCourse;
    late CourseModule testModule;
    late Lesson testLesson;

    setUp(() {
      testCourse = Course(
        id: 'test-course',
        title: 'Legacy English Title',
        description: 'Legacy English Description',
        instructor: 'Test Instructor',
        createdAt: DateTime.now(),
        translations: {
          'fr': const CourseTranslation(
            title: 'Titre français',
            description: 'Description française',
          ),
          'en': const CourseTranslation(
            title: 'English Title',
            description: 'English Description',
          ),
          'ar': const CourseTranslation(
            title: 'عنوان عربي',
            description: 'وصف عربي',
          ),
        },
      );

      testModule = const CourseModule(
        id: 'test-module',
        courseId: 'test-course',
        title: 'Legacy English Module',
        description: 'Legacy module description',
        order: 1,
        translations: {
          'fr': ModuleTranslation(
            title: 'Module français',
            description: 'Description du module française',
          ),
          'en': ModuleTranslation(
            title: 'English Module',
            description: 'English module description',
          ),
          'ar': ModuleTranslation(
            title: 'وحدة عربية',
            description: 'وصف الوحدة العربية',
          ),
        },
      );

      testLesson = const Lesson(
        id: 'test-lesson',
        moduleId: 'test-module',
        courseId: 'test-course',
        title: 'Legacy English Lesson',
        description: 'Legacy lesson description',
        type: LessonType.text,
        contentText: 'Legacy content',
        summary: ['Legacy summary'],
        actionToApply: 'Legacy action',
        order: 1,
        translations: {
          'fr': LessonTranslation(
            title: 'Leçon française',
            description: 'Description de la leçon française',
            contentText: 'Contenu français',
            summary: ['Résumé français'],
            actionToApply: 'Action française',
          ),
          'en': LessonTranslation(
            title: 'English Lesson',
            description: 'English lesson description',
            contentText: 'English content',
            summary: ['English summary'],
            actionToApply: 'English action',
          ),
          'ar': LessonTranslation(
            title: 'درس عربي',
            description: 'وصف الدرس العربي',
            contentText: 'محتوى عربي',
            summary: ['ملخص عربي'],
            actionToApply: 'إجراء عربي',
          ),
        },
      );
    });

    group('Course Resolution', () {
      test('FR locale resolves French translation', () {
        final content = CourseContentResolver.resolve(
          testCourse,
          const Locale('fr'),
        );

        expect(content.title, 'Titre français');
        expect(content.description, 'Description française');
        expect(content.source, 'fr');
      });

      test('EN locale resolves English translation', () {
        final content = CourseContentResolver.resolve(
          testCourse,
          const Locale('en'),
        );

        expect(content.title, 'English Title');
        expect(content.description, 'English Description');
        expect(content.source, 'en');
      });

      test('AR locale resolves Arabic translation', () {
        final content = CourseContentResolver.resolve(
          testCourse,
          const Locale('ar'),
        );

        expect(content.title, 'عنوان عربي');
        expect(content.description, 'وصف عربي');
        expect(content.source, 'ar');
      });

      test('Missing requested locale falls back to FR', () {
        final content = CourseContentResolver.resolve(
          testCourse,
          const Locale('es'), // Spanish not available
        );

        expect(content.title, 'Titre français');
        expect(content.description, 'Description française');
        expect(content.source, 'fr');
      });

      test('No translations falls back to legacy', () {
        final courseNoTranslations = Course(
          id: 'test',
          title: 'Legacy English Title',
          description: 'Legacy English Description',
          instructor: 'Test',
          createdAt: DateTime.now(),
        );

        final content = CourseContentResolver.resolve(
          courseNoTranslations,
          const Locale('fr'),
        );

        expect(content.title, 'Legacy English Title');
        expect(content.description, 'Legacy English Description');
        expect(content.source, 'legacy');
      });
    });

    group('Module Resolution', () {
      test('FR locale resolves French translation', () {
        final content = ModuleContentResolver.resolve(
          testModule,
          const Locale('fr'),
        );

        expect(content.title, 'Module français');
        expect(content.description, 'Description du module française');
        expect(content.source, 'fr');
      });

      test('EN locale resolves English translation', () {
        final content = ModuleContentResolver.resolve(
          testModule,
          const Locale('en'),
        );

        expect(content.title, 'English Module');
        expect(content.description, 'English module description');
        expect(content.source, 'en');
      });

      test('AR locale resolves Arabic translation', () {
        final content = ModuleContentResolver.resolve(
          testModule,
          const Locale('ar'),
        );

        expect(content.title, 'وحدة عربية');
        expect(content.description, 'وصف الوحدة العربية');
        expect(content.source, 'ar');
      });

      test('Missing requested locale falls back to FR', () {
        final content = ModuleContentResolver.resolve(
          testModule,
          const Locale('de'),
        );

        expect(content.title, 'Module français');
        expect(content.source, 'fr');
      });

      test('No translations falls back to legacy', () {
        const moduleNoTranslations = CourseModule(
          id: 'test',
          courseId: 'test',
          title: 'Legacy English Module',
          order: 1,
        );

        final content = ModuleContentResolver.resolve(
          moduleNoTranslations,
          const Locale('fr'),
        );

        expect(content.title, 'Legacy English Module');
        expect(content.source, 'legacy');
      });
    });

    group('Lesson Resolution', () {
      test('FR locale resolves all French fields', () {
        final content = LessonContentResolver.resolve(
          testLesson,
          const Locale('fr'),
        );

        expect(content.title, 'Leçon française');
        expect(content.description, 'Description de la leçon française');
        expect(content.contentText, 'Contenu français');
        expect(content.summary, ['Résumé français']);
        expect(content.actionToApply, 'Action française');
        expect(content.source, 'fr');
      });

      test('EN locale resolves all English fields', () {
        final content = LessonContentResolver.resolve(
          testLesson,
          const Locale('en'),
        );

        expect(content.title, 'English Lesson');
        expect(content.description, 'English lesson description');
        expect(content.contentText, 'English content');
        expect(content.summary, ['English summary']);
        expect(content.actionToApply, 'English action');
        expect(content.source, 'en');
      });

      test('AR locale resolves all Arabic fields', () {
        final content = LessonContentResolver.resolve(
          testLesson,
          const Locale('ar'),
        );

        expect(content.title, 'درس عربي');
        expect(content.description, 'وصف الدرس العربي');
        expect(content.contentText, 'محتوى عربي');
        expect(content.summary, ['ملخص عربي']);
        expect(content.actionToApply, 'إجراء عربي');
        expect(content.source, 'ar');
      });

      test('Missing requested locale falls back to FR', () {
        final content = LessonContentResolver.resolve(
          testLesson,
          const Locale('it'),
        );

        expect(content.title, 'Leçon française');
        expect(content.contentText, 'Contenu français');
        expect(content.source, 'fr');
      });

      test('No translations falls back to legacy', () {
        const lessonNoTranslations = Lesson(
          id: 'test',
          moduleId: 'test',
          courseId: 'test',
          title: 'Legacy English Lesson',
          type: LessonType.text,
          contentText: 'Legacy content',
          summary: ['Legacy summary'],
          order: 1,
        );

        final content = LessonContentResolver.resolve(
          lessonNoTranslations,
          const Locale('fr'),
        );

        expect(content.title, 'Legacy English Lesson');
        expect(content.contentText, 'Legacy content');
        expect(content.summary, ['Legacy summary']);
        expect(content.source, 'legacy');
      });
    });

    group('Backward Compatibility', () {
      test('Course with only FR translation works for FR request', () {
        final courseOnlyFr = Course(
          id: 'test',
          title: 'Legacy',
          description: 'Legacy',
          instructor: 'Test',
          createdAt: DateTime.now(),
          translations: const {
            'fr': CourseTranslation(
              title: 'Seulement français',
              description: 'Seulement description française',
            ),
          },
        );

        final content = CourseContentResolver.resolve(
          courseOnlyFr,
          const Locale('fr'),
        );

        expect(content.title, 'Seulement français');
        expect(content.source, 'fr');
      });

      test('Course with only FR translation falls back for EN request', () {
        final courseOnlyFr = Course(
          id: 'test',
          title: 'Legacy',
          description: 'Legacy',
          instructor: 'Test',
          createdAt: DateTime.now(),
          translations: const {
            'fr': CourseTranslation(
              title: 'Seulement français',
              description: 'Seulement description française',
            ),
          },
        );

        final content = CourseContentResolver.resolve(
          courseOnlyFr,
          const Locale('en'),
        );

        expect(content.title, 'Seulement français');
        expect(content.source, 'fr'); // Falls back to FR
      });

      test('Empty translation title uses FR fallback', () {
        final courseEmptyEn = Course(
          id: 'test',
          title: 'Legacy',
          description: 'Legacy',
          instructor: 'Test',
          createdAt: DateTime.now(),
          translations: const {
            'en': CourseTranslation(
              title: '', // Empty
              description: 'Description',
            ),
            'fr': CourseTranslation(
              title: 'Français valide',
              description: 'Description française',
            ),
          },
        );

        final content = CourseContentResolver.resolve(
          courseEmptyEn,
          const Locale('en'),
        );

        expect(content.title, 'Français valide'); // Falls back to FR
        expect(content.source, 'fr');
      });
    });
  });
}
