import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/presentation/course_presentation.dart';

void main() {
  group('Arabic UI Localization', () {
    late AppLocalizations frL10n;
    late AppLocalizations enL10n;
    late AppLocalizations arL10n;

    setUpAll(() async {
      frL10n = await AppLocalizations.delegate.load(const Locale('fr'));
      enL10n = await AppLocalizations.delegate.load(const Locale('en'));
      arL10n = await AppLocalizations.delegate.load(const Locale('ar'));
    });

    group('Prayer names localized', () {
      test('Fajr is localized in FR', () {
        expect(frL10n.prayerFajr, equals('Fajr'));
      });

      test('Fajr is localized in EN', () {
        expect(enL10n.prayerFajr, equals('Fajr'));
      });

      test('Fajr is localized in AR', () {
        expect(arL10n.prayerFajr, equals('الفجر'));
      });

      test('All prayer names exist in Arabic', () {
        expect(arL10n.prayerFajr, isNotEmpty);
        expect(arL10n.prayerDhuhr, isNotEmpty);
        expect(arL10n.prayerAsr, isNotEmpty);
        expect(arL10n.prayerMaghrib, isNotEmpty);
        expect(arL10n.prayerIsha, isNotEmpty);
      });
    });

    group('Prayer time format localized', () {
      test('Time format in FR uses "dans"', () {
        expect(frL10n.timeIn('2h 30m'), equals('dans 2h 30m'));
      });

      test('Time format in EN uses "in"', () {
        expect(enL10n.timeIn('2h 30m'), equals('in 2h 30m'));
      });

      test('Time format in AR uses "بعد"', () {
        expect(arL10n.timeIn('2h 30m'), equals('بعد 2h 30m'));
      });
    });

    group('Formation labels localized', () {
      test('Course levels exist in French', () {
        expect(frL10n.courseLevelBeginner, equals('Débutant'));
        expect(frL10n.courseLevelIntermediate, equals('Intermédiaire'));
        expect(frL10n.courseLevelAdvanced, equals('Avancé'));
      });

      test('Course levels exist in English', () {
        expect(enL10n.courseLevelBeginner, equals('Beginner'));
        expect(enL10n.courseLevelIntermediate, equals('Intermediate'));
        expect(enL10n.courseLevelAdvanced, equals('Advanced'));
      });

      test('Course levels exist in Arabic', () {
        expect(arL10n.courseLevelBeginner, equals('مبتدئ'));
        expect(arL10n.courseLevelIntermediate, equals('متوسط'));
        expect(arL10n.courseLevelAdvanced, equals('متقدم'));
      });

      test('Course categories exist in Arabic', () {
        expect(arL10n.courseCategoryTajweed, equals('تجويد'));
        expect(arL10n.courseCategoryTafsir, equals('تفسير'));
        expect(arL10n.courseCategoryFiqh, equals('فقه'));
        expect(arL10n.courseCategorySira, equals('سيرة'));
        expect(arL10n.courseCategoryAqida, equals('عقيدة'));
        expect(arL10n.courseCategoryArabic, equals('عربية'));
        expect(arL10n.courseCategoryMemorization, equals('حفظ'));
        expect(arL10n.courseCategorySpirituality, equals('روحانية'));
        expect(arL10n.courseCategoryOther, equals('أخرى'));
      });
    });

    group('Course presentation labels (domain/presentation separation)', () {
      test('Course level beginner is localized in FR', () {
        final level = CoursePresentationLabels.level(CourseLevel.beginner, frL10n);
        expect(level, equals('Débutant'));
      });

      test('Course level beginner is localized in EN', () {
        final level = CoursePresentationLabels.level(CourseLevel.beginner, enL10n);
        expect(level, equals('Beginner'));
      });

      test('Course level beginner is localized in AR', () {
        final level = CoursePresentationLabels.level(CourseLevel.beginner, arL10n);
        expect(level, equals('مبتدئ'));
      });

      test('Course category tajweed is localized in FR', () {
        final category = CoursePresentationLabels.category(CourseCategory.tajweed, frL10n);
        expect(category, equals('Tajweed'));
      });

      test('Course category tajweed is localized in EN', () {
        final category = CoursePresentationLabels.category(CourseCategory.tajweed, enL10n);
        expect(category, equals('Tajweed'));
      });

      test('Course category tajweed is localized in AR', () {
        final category = CoursePresentationLabels.category(CourseCategory.tajweed, arL10n);
        expect(category, equals('تجويد'));
      });

      testWidgets('Course extension localizedLevel works with context', (tester) async {
        final course = Course(
          id: 'test',
          title: 'Test Course',
          description: 'Test',
          instructor: 'Test',
          createdAt: DateTime.now(),
          level: CourseLevel.beginner,
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: Builder(
              builder: (context) {
                final level = course.localizedLevel(context);
                return Text(level);
              },
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('مبتدئ'), findsOneWidget);
      });

      testWidgets('Course extension localizedCategory works with context', (tester) async {
        final course = Course(
          id: 'test',
          title: 'Test Course',
          description: 'Test',
          instructor: 'Test',
          createdAt: DateTime.now(),
          category: CourseCategory.tajweed,
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: Builder(
              builder: (context) {
                final category = course.localizedCategory(context);
                return Text(category);
              },
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('تجويد'), findsOneWidget);
      });
    });

    group('Settings logout visible in all locales', () {
      for (final locale in ['fr', 'en', 'ar']) {
        testWidgets('Logout button text exists in $locale', (tester) async {
          final l10n = await AppLocalizations.delegate.load(Locale(locale));
          expect(l10n.logout, isNotEmpty);
        });
      }
    });
  });
}
