import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/course_detail_screen.dart';

void main() {
  group('CourseDetailScreen progress error semantics', () {
    final testCourse = Course(
      id: 'test-course',
      title: 'Test Course',
      description: 'Test',
      instructor: 'Test',
      createdAt: DateTime.now(),
      totalLessons: 5,
    );

    testWidgets(
      'A. AsyncError does not crash',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              courseProgressProvider(testCourse.id).overrideWith(
                (ref) => Future.error(
                  Exception('[cloud_firestore/permission-denied] Denied'),
                ),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: CourseDetailScreen(course: testCourse),
            ),
          ),
        );

        await tester.pump();

        // INVARIANT: AsyncError must not crash
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'B. AsyncError does NOT show "Commencer" CTA',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              courseProgressProvider(testCourse.id).overrideWith(
                (ref) => Future.error(
                  Exception('Progress load failed'),
                ),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: CourseDetailScreen(course: testCourse),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // INVARIANT: ERROR != NO PROGRESS
        // Must NOT show "Commencer" (which is for genuine no-progress)
        expect(find.text('Commencer'), findsNothing);
        
        // Must show retry affordance
        expect(find.text('Réessayer'), findsOneWidget);
      },
    );

    testWidgets(
      'C. AsyncData(null) DOES show "Commencer"',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              courseProgressProvider(testCourse.id).overrideWith(
                (ref) => Future.value(null), // No progress
              ),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: CourseDetailScreen(course: testCourse),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // INVARIANT: genuine no-progress shows "Commencer"
        expect(find.text('Commencer'), findsOneWidget);
        expect(find.text('Réessayer'), findsNothing);
      },
    );
  });
}
