import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/presentation/course_content_resolver.dart';

void main() {
  group('Firestore Deserialization → Model → Resolver', () {
    group('Course Deserialization', () {
      test('Course with FR translations deserializes correctly', () {
        // Simulate exact Firestore document structure
        final firestoreData = {
          'title': 'Formation Basics Demo',
          'description': 'Legacy description',
          'level': 'beginner',
          'category': 'other',
          'pillarId': 'foundations_practice',
          'deliveryMode': 'selfPaced',
          'instructor': 'ANIS Team',
          'totalLessons': 3,
          'totalDurationMinutes': 30,
          'tags': ['introduction'],
          'linkedFeatures': [],
          'createdAt': Timestamp.now(),
          'isPublished': true,
          'translations': {
            'fr': {
              'title': 'Découvrir les formations ANIS',
              'description': 'Apprenez à tirer le meilleur parti',
              'linkedFeatures': [],
            },
            'en': {
              'title': 'Discover ANIS Learning',
              'description': 'Learn how to make the most',
              'linkedFeatures': [],
            },
            'ar': {
              'title': 'اكتشف تعلم ANIS',
              'description': 'تعلم كيفية تحقيق أقصى استفادة',
              'linkedFeatures': [],
            },
          },
        };

        // Deserialize through production parser
        final course = Course.fromFirestore('test-course', firestoreData);

        // Assert translations are loaded
        expect(course.translations, isNotNull, reason: 'Translations map should not be null');
        expect(course.translations!.containsKey('fr'), isTrue, reason: 'FR translation should exist');
        expect(course.translations!.containsKey('en'), isTrue, reason: 'EN translation should exist');
        expect(course.translations!.containsKey('ar'), isTrue, reason: 'AR translation should exist');

        // Assert FR translation content
        final frTranslation = course.translations!['fr']!;
        expect(frTranslation.title, 'Découvrir les formations ANIS');
        expect(frTranslation.description, 'Apprenez à tirer le meilleur parti');

        // Assert legacy fields preserved
        expect(course.title, 'Formation Basics Demo');
        expect(course.description, 'Legacy description');

        // Assert resolver uses FR translation for FR locale
        final resolvedFR = CourseContentResolver.resolve(course, const Locale('fr'));
        expect(resolvedFR.title, 'Découvrir les formations ANIS',
            reason: 'Resolver should return FR title for FR locale');
        expect(resolvedFR.description, 'Apprenez à tirer le meilleur parti',
            reason: 'Resolver should return FR description for FR locale');
        expect(resolvedFR.source, 'fr');

        // Assert resolver uses EN translation for EN locale
        final resolvedEN = CourseContentResolver.resolve(course, const Locale('en'));
        expect(resolvedEN.title, 'Discover ANIS Learning');
        expect(resolvedEN.source, 'en');

        // Assert resolver uses AR translation for AR locale
        final resolvedAR = CourseContentResolver.resolve(course, const Locale('ar'));
        expect(resolvedAR.title, 'اكتشف تعلم ANIS');
        expect(resolvedAR.source, 'ar');
      });

      test('Course without translations falls back to legacy', () {
        final firestoreData = {
          'title': 'Legacy Only Course',
          'description': 'No translations',
          'level': 'beginner',
          'category': 'other',
          'deliveryMode': 'selfPaced',
          'instructor': 'Test',
          'totalLessons': 1,
          'totalDurationMinutes': 10,
          'tags': [],
          'linkedFeatures': [],
          'createdAt': Timestamp.now(),
          'isPublished': true,
        };

        final course = Course.fromFirestore('test', firestoreData);

        expect(course.translations, isNull);

        final resolved = CourseContentResolver.resolve(course, const Locale('fr'));
        expect(resolved.title, 'Legacy Only Course');
        expect(resolved.source, 'legacy');
      });
    });

    group('Module Deserialization', () {
      test('Module with FR translations deserializes correctly', () {
        final firestoreData = {
          'courseId': 'test-course',
          'title': 'Introduction Module',
          'description': 'Legacy module description',
          'order': 1,
          'lessonIds': ['lesson-1', 'lesson-2'],
          'translations': {
            'fr': {
              'title': 'Bien démarrer',
              'description': 'Apprenez les bases',
            },
            'en': {
              'title': 'Getting Started',
              'description': 'Learn the basics',
            },
            'ar': {
              'title': 'البداية',
              'description': 'تعلم الأساسيات',
            },
          },
        };

        final module = CourseModule.fromFirestore('test-module', firestoreData);

        expect(module.translations, isNotNull);
        expect(module.translations!.containsKey('fr'), isTrue);

        final frTranslation = module.translations!['fr']!;
        expect(frTranslation.title, 'Bien démarrer');
        expect(frTranslation.description, 'Apprenez les bases');

        expect(module.title, 'Introduction Module');

        final resolvedFR = ModuleContentResolver.resolve(module, const Locale('fr'));
        expect(resolvedFR.title, 'Bien démarrer',
            reason: 'Resolver should return FR title for FR locale');
        expect(resolvedFR.description, 'Apprenez les bases');
        expect(resolvedFR.source, 'fr');

        final resolvedEN = ModuleContentResolver.resolve(module, const Locale('en'));
        expect(resolvedEN.title, 'Getting Started');
        expect(resolvedEN.source, 'en');
      });

      test('Module without translations falls back to legacy', () {
        final firestoreData = {
          'courseId': 'test',
          'title': 'Legacy Module',
          'order': 1,
          'lessonIds': [],
        };

        final module = CourseModule.fromFirestore('test', firestoreData);

        expect(module.translations, isNull);

        final resolved = ModuleContentResolver.resolve(module, const Locale('fr'));
        expect(resolved.title, 'Legacy Module');
        expect(resolved.source, 'legacy');
      });
    });

    group('Lesson Deserialization', () {
      test('Lesson with all FR fields deserializes correctly', () {
        final firestoreData = {
          'courseId': 'test-course',
          'moduleId': 'test-module',
          'title': 'Welcome to Formations',
          'description': 'Legacy lesson description',
          'type': 'text',
          'contentText': 'Legacy content',
          'summary': ['Legacy summary point'],
          'actionToApply': 'Legacy action',
          'order': 1,
          'durationMinutes': 5,
          'quiz': [],
          'translations': {
            'fr': {
              'title': 'Bienvenue dans les formations',
              'description': 'Introduction à la plateforme',
              'contentText': '# Bienvenue\n\nContenu français complet.',
              'summary': ['La plateforme vous aide', 'Les sujets sont organisés'],
              'actionToApply': 'Explorez les sujets d\'apprentissage',
            },
            'en': {
              'title': 'Welcome to ANIS Learning',
              'description': 'Introduction to the platform',
              'contentText': '# Welcome\n\nFull English content.',
              'summary': ['Platform helps you', 'Topics are organized'],
              'actionToApply': 'Explore learning topics',
            },
            'ar': {
              'title': 'مرحبا بك',
              'description': 'مقدمة إلى المنصة',
              'contentText': '# مرحبا\n\nمحتوى عربي كامل.',
              'summary': ['المنصة تساعدك', 'المواضيع منظمة'],
              'actionToApply': 'استكشف مواضيع التعلم',
            },
          },
        };

        final lesson = Lesson.fromFirestore('test-lesson', firestoreData);

        expect(lesson.translations, isNotNull);
        expect(lesson.translations!.containsKey('fr'), isTrue);

        final frTranslation = lesson.translations!['fr']!;
        expect(frTranslation.title, 'Bienvenue dans les formations');
        expect(frTranslation.description, 'Introduction à la plateforme');
        expect(frTranslation.contentText, '# Bienvenue\n\nContenu français complet.');
        expect(frTranslation.summary, ['La plateforme vous aide', 'Les sujets sont organisés']);
        expect(frTranslation.actionToApply, 'Explorez les sujets d\'apprentissage');

        expect(lesson.title, 'Welcome to Formations');
        expect(lesson.contentText, 'Legacy content');

        final resolvedFR = LessonContentResolver.resolve(lesson, const Locale('fr'));
        expect(resolvedFR.title, 'Bienvenue dans les formations',
            reason: 'Resolver should return FR title');
        expect(resolvedFR.description, 'Introduction à la plateforme',
            reason: 'Resolver should return FR description');
        expect(resolvedFR.contentText, '# Bienvenue\n\nContenu français complet.',
            reason: 'Resolver should return FR contentText');
        expect(resolvedFR.summary, ['La plateforme vous aide', 'Les sujets sont organisés'],
            reason: 'Resolver should return FR summary');
        expect(resolvedFR.actionToApply, 'Explorez les sujets d\'apprentissage',
            reason: 'Resolver should return FR actionToApply');
        expect(resolvedFR.source, 'fr');

        final resolvedEN = LessonContentResolver.resolve(lesson, const Locale('en'));
        expect(resolvedEN.title, 'Welcome to ANIS Learning');
        expect(resolvedEN.contentText, '# Welcome\n\nFull English content.');
        expect(resolvedEN.source, 'en');

        final resolvedAR = LessonContentResolver.resolve(lesson, const Locale('ar'));
        expect(resolvedAR.title, 'مرحبا بك');
        expect(resolvedAR.contentText, '# مرحبا\n\nمحتوى عربي كامل.');
        expect(resolvedAR.source, 'ar');
      });

      test('Lesson without translations falls back to legacy', () {
        final firestoreData = {
          'courseId': 'test',
          'moduleId': 'test',
          'title': 'Legacy Lesson',
          'type': 'text',
          'contentText': 'Legacy content',
          'summary': ['Legacy'],
          'order': 1,
          'durationMinutes': 5,
          'quiz': [],
        };

        final lesson = Lesson.fromFirestore('test', firestoreData);

        expect(lesson.translations, isNull);

        final resolved = LessonContentResolver.resolve(lesson, const Locale('fr'));
        expect(resolved.title, 'Legacy Lesson');
        expect(resolved.contentText, 'Legacy content');
        expect(resolved.source, 'legacy');
      });
    });

    group('Runtime Debugging Info', () {
      test('Course runtime resolution path can be traced', () {
        final firestoreData = {
          'title': 'Formation Basics Demo',
          'description': 'Legacy',
          'level': 'beginner',
          'category': 'other',
          'deliveryMode': 'selfPaced',
          'instructor': 'Test',
          'totalLessons': 1,
          'totalDurationMinutes': 10,
          'tags': [],
          'linkedFeatures': [],
          'createdAt': Timestamp.now(),
          'isPublished': true,
          'translations': {
            'fr': {
              'title': 'Découvrir les formations ANIS',
              'description': 'Description française',
              'linkedFeatures': [],
            },
          },
        };

        final course = Course.fromFirestore('test', firestoreData);
        final locale = const Locale('fr');
        final resolved = CourseContentResolver.resolve(course, locale);

        // Runtime trace values that should appear in logs
        final runtimeTrace = {
          'locale': locale.languageCode,
          'courseLegacy': course.title,
          'courseTranslationFR': course.translations?['fr']?.title,
          'courseResolved': resolved.title,
          'resolvedSource': resolved.source,
        };

        expect(runtimeTrace['locale'], 'fr');
        expect(runtimeTrace['courseLegacy'], 'Formation Basics Demo');
        expect(runtimeTrace['courseTranslationFR'], 'Découvrir les formations ANIS');
        expect(runtimeTrace['courseResolved'], 'Découvrir les formations ANIS');
        expect(runtimeTrace['resolvedSource'], 'fr');
      });
    });
  });
}
