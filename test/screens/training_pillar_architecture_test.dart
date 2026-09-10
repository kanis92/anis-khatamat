import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/presentation/formation_resume_resolver.dart';
import 'package:anis_khatamat/features/formations/providers/formation_learning_providers.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/training_screen.dart';

/// Overrides stables pour les tests de layout du landing « Tous ».
List<Override> _tousLandingOverrides() => [
      publishedCoursesProvider.overrideWith((ref) => Stream.value(<Course>[])),
      allProgressProvider.overrideWith((ref) async => []),
      myLearningStateProvider.overrideWith(
        (ref) async =>
            const MyLearningState(display: MyLearningDisplayState.empty),
      ),
    ];

void main() {
  group('TrainingScreen - Tab-Driven Architecture', () {
    testWidgets('Main landing renders horizontal theme tabs', (tester) async {
      final container = ProviderContainer(
        overrides: [
          publishedCoursesProvider.overrideWith((ref) => Stream.value(<Course>[])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TrainingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have "Tous" tab
      expect(find.text('Tous'), findsOneWidget);

      // Should have pillar tabs (at least some visible)
      expect(find.text('Bases & pratique'), findsOneWidget);
    });

    testWidgets('Main landing does NOT render large pillar cards grid', (tester) async {
      final container = ProviderContainer(
        overrides: [
          publishedCoursesProvider.overrideWith((ref) => Stream.value(<Course>[])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TrainingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should NOT have module titles on initial "Tous" view (only featured courses)
      expect(find.text('Bien démarrer'), findsNothing);
      expect(find.text('Comprendre les fondamentaux'), findsNothing);
      expect(find.text('La prière au quotidien'), findsNothing);
    });

    testWidgets('"Tous" tab shows premium overview with Live and Questions', (tester) async {
      final container = ProviderContainer(
        overrides: [
          publishedCoursesProvider.overrideWith((ref) => Stream.value(<Course>[])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TrainingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show Live section (FR locale = "EN DIRECT" appears in title + card)
      expect(find.text('EN DIRECT'), findsWidgets);

      // Should show Questions section
      expect(find.textContaining('Questions'), findsWidgets);
    });

    testWidgets('No overflow on iPhone SE dimensions with Tous tab', (tester) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2.0;

      final container = ProviderContainer(
        overrides: [
          publishedCoursesProvider.overrideWith((ref) => Stream.value(<Course>[])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TrainingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No overflow errors
      expect(tester.takeException(), isNull);

      // Scroll through content
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -2000), 1000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('No overflow on iPhone SE with pillar tabs scrollable', (tester) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2.0;

      final container = ProviderContainer(
        overrides: [
          publishedCoursesProvider.overrideWith((ref) => Stream.value(<Course>[])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TrainingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have horizontal scrollable tabs
      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('Bases & pratique'), findsOneWidget);

      // No overflow errors
      expect(tester.takeException(), isNull);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Hero supporting sentence stays inside green poster on iPhone SE', (tester) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: _tousLandingOverrides(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TrainingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final hero = tester.getRect(find.byKey(const ValueKey('formations-hero')));
      final supporting = tester.getRect(
        find.text('Des parcours conçus pour avancer avec clarté et constance.'),
      );

      expect(hero.height, inInclusiveRange(250.0, 340.0));
      expect(supporting.top, greaterThan(hero.top));
      expect(supporting.bottom, lessThan(hero.bottom));
      expect(supporting.left, greaterThanOrEqualTo(hero.left));
      expect(supporting.right, lessThanOrEqualTo(hero.right));

      final tabs = tester.getRect(find.text('Explorer par thème'));
      final gap = tabs.top - hero.bottom;
      // Hero → Mon apprentissage (vide) → Explorer par thème
      expect(gap, inInclusiveRange(300.0, 340.0));
    });

    testWidgets('No hardcoded module data in TrainingScreen widget tree', (tester) async {
      final container = ProviderContainer(
        overrides: [
          publishedCoursesProvider.overrideWith((ref) => Stream.value(<Course>[])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TrainingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have TrainingScreen
      expect(find.byType(TrainingScreen), findsOneWidget);

      // Should NOT have these module titles hardcoded in "Tous" view
      expect(find.text('Bien démarrer'), findsNothing);
      expect(find.text('Organiser sa pratique avec constance'), findsNothing);
    });
  });
}
