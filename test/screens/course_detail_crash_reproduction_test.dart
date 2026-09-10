import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/course_detail_screen.dart';

void main() {
  group('CourseDetailScreen crash reproduction', () {
    testWidgets(
      'PROVEN: accessing progressAsync.value when AsyncError crashes',
      (tester) async {
        final course = Course(
          id: 'test-course',
          title: 'Test Course',
          description: 'Test',
          instructor: 'Test',
          createdAt: DateTime.now(),
        );

        // This test proves that if courseProgressProvider is in AsyncError state
        // (e.g. due to Firestore permission-denied), then accessing .value
        // will crash with AsyncError.value exception

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              // Simulate permission-denied error
              courseProgressProvider(course.id).overrideWith(
                (ref) => Future.error(
                  Exception('[cloud_firestore/permission-denied] Denied'),
                ),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: CourseDetailScreen(course: course),
            ),
          ),
        );

        await tester.pump();

        // The screen tries to access progressAsync.value
        // If AsyncValue is AsyncError, this will throw
        // FlutterError: AsyncError.value
        
        // This test will fail with the crash if the bug exists
        // After fix, it should pass because we'll use valueOrNull
        expect(tester.takeException(), isNull);
      },
    );
  });
}
