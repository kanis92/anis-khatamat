import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/core/utils/duration_formatter.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';

void main() {
  group('DurationFormatter', () {
    group('format with context', () {
      testWidgets('formats hours + minutes in French', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Builder(
              builder: (context) {
                final duration = const Duration(hours: 3, minutes: 15);
                final formatted = DurationFormatter.format(duration, context);
                expect(formatted, equals('3h 15m'));
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('formats hours only in French', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Builder(
              builder: (context) {
                final duration = const Duration(hours: 2);
                final formatted = DurationFormatter.format(duration, context);
                expect(formatted, equals('2h'));
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('formats minutes only in French', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Builder(
              builder: (context) {
                final duration = const Duration(minutes: 45);
                final formatted = DurationFormatter.format(duration, context);
                expect(formatted, equals('45min'));
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('formats hours + minutes in English', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Builder(
              builder: (context) {
                final duration = const Duration(hours: 3, minutes: 15);
                final formatted = DurationFormatter.format(duration, context);
                expect(formatted, equals('3h 15m'));
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('formats hours only in English', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Builder(
              builder: (context) {
                final duration = const Duration(hours: 2);
                final formatted = DurationFormatter.format(duration, context);
                expect(formatted, equals('2h'));
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('formats minutes only in English', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Builder(
              builder: (context) {
                final duration = const Duration(minutes: 45);
                final formatted = DurationFormatter.format(duration, context);
                expect(formatted, equals('45min'));
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('formats hours + minutes in Arabic', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: Builder(
              builder: (context) {
                final duration = const Duration(hours: 3, minutes: 15);
                final formatted = DurationFormatter.format(duration, context);
                expect(formatted, equals('3 س 15 د'));
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('formats hours only in Arabic', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: Builder(
              builder: (context) {
                final duration = const Duration(hours: 2);
                final formatted = DurationFormatter.format(duration, context);
                expect(formatted, equals('2 س'));
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('formats minutes only in Arabic', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: Builder(
              builder: (context) {
                final duration = const Duration(minutes: 45);
                final formatted = DurationFormatter.format(duration, context);
                expect(formatted, equals('45 د'));
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('formatCompact without context', () {
      test('formats hours + minutes', () {
        final duration = const Duration(hours: 3, minutes: 15);
        final formatted = DurationFormatter.formatCompact(duration);
        expect(formatted, equals('3h 15m'));
      });

      test('formats hours only', () {
        final duration = const Duration(hours: 2);
        final formatted = DurationFormatter.formatCompact(duration);
        expect(formatted, equals('2h'));
      });

      test('formats minutes only', () {
        final duration = const Duration(minutes: 45);
        final formatted = DurationFormatter.formatCompact(duration);
        expect(formatted, equals('45min'));
      });
    });
  });
}
