import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/presentation/course_content_resolver.dart';

Course _course({Map<String, CourseTranslation>? translations}) {
  return Course(
    id: 'c1',
    title: 'Titre legacy FR',
    description: 'Desc legacy FR',
    instructor: 'Ustadh',
    createdAt: DateTime(2024, 1, 1),
    translations: translations,
  );
}

void main() {
  test('AR translation selected when present', () {
    final resolved = CourseContentResolver.resolve(
      _course(
        translations: {
          'fr': const CourseTranslation(title: 'FR', description: 'dfr'),
          'ar': const CourseTranslation(title: 'عربي', description: 'وصف'),
        },
      ),
      const Locale('ar'),
    );
    expect(resolved.title, 'عربي');
    expect(resolved.source, 'ar');
    expect(resolved.linkedFeatures, isEmpty);
  });

  test('EN translation selected when present', () {
    final resolved = CourseContentResolver.resolve(
      _course(
        translations: {
          'en': const CourseTranslation(title: 'EN', description: 'den'),
          'fr': const CourseTranslation(title: 'FR', description: 'dfr'),
        },
      ),
      const Locale('en'),
    );
    expect(resolved.title, 'EN');
    expect(resolved.source, 'en');
  });

  test('FR selected correctly', () {
    final resolved = CourseContentResolver.resolve(
      _course(
        translations: {
          'fr': const CourseTranslation(title: 'FR', description: 'dfr'),
        },
      ),
      const Locale('fr'),
    );
    expect(resolved.title, 'FR');
    expect(resolved.source, 'fr');
  });

  test('AR missing → French translation then legacy', () {
    final viaFr = CourseContentResolver.resolve(
      _course(
        translations: {
          'fr': const CourseTranslation(title: 'FR only', description: 'd'),
        },
      ),
      const Locale('ar'),
    );
    expect(viaFr.title, 'FR only');
    expect(viaFr.source, 'fr');

    final viaLegacy = CourseContentResolver.resolve(
      _course(),
      const Locale('ar'),
    );
    expect(viaLegacy.title, 'Titre legacy FR');
    expect(viaLegacy.source, 'legacy');
  });

  test('legacy course remains readable', () {
    final c = _course();
    expect(c.title, isNotEmpty);
    expect(c.translations, isNull);
  });
}
