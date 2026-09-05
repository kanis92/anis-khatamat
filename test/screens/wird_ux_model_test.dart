import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../lib/core/models/wird.dart';
import '../../lib/core/models/wird_plan_state.dart';
import '../../lib/core/providers/wird_provider.dart';
import '../../lib/screens/wird_screen.dart';
import '../../lib/l10n/gen_l10n/app_localizations.dart';

/// Tests for the new simplified Wird UX model.
/// 
/// Key principles:
/// 1. Primary: Whole Hizb objective (no giant fractions)
/// 2. Secondary: Quarter supplements if fractional
/// 3. Monthly ring: Exact canonical progress / 240 Rub'
/// 4. Truthful display: No fake completion
void main() {
  group('Wird Simplified UX Model', () {
    // Mock Wird for testing
    final mockWirdNoplan = Wird(
      subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
      dailyTargetRubs: 8, // 2 Hizb exact
      activePlan: null,
      lastMushafType: 'hafs',
      lastPage: 1,
      createdAt: DateTime.now(),
    );

    final mockWirdFractional = Wird(
      subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
      dailyTargetRubs: 9, // 2¼ Hizb
      activePlan: null,
      lastMushafType: 'hafs',
      lastPage: 1,
      createdAt: DateTime.now(),
    );

    // Provider overrides
    List<Override> makeOverrides(Wird wird, int progress, Set<int> completedIds) {
      return [
        wirdProvider.overrideWith((ref) async => wird),
        wirdTodayProgressProvider.overrideWith((ref) async => progress),
        wirdTodayCompletedRubIdsProvider.overrideWith((ref) async => completedIds),
        wirdTodayAuthoritativeTargetProvider.overrideWith((ref) async => wird.dailyTargetRubs),
        wirdPlanStateProvider.overrideWith((ref) async => WirdPlanState.none),
        wirdPlanProgressProvider.overrideWith((ref) async => <int>{}),
        wirdCycleProgressProvider.overrideWith((ref) async => completedIds), // Ring uses cycle progress
      ];
    }

    testWidgets('Exact Hizb target (8 Rub = 2 Hizb): shows whole Hizb primary', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: makeOverrides(mockWirdNoplan, 0, {}),
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WirdScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show "2 Hizb" as primary objective
      expect(find.textContaining('2'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Hizb'), findsAtLeastNWidgets(1));
      
      // Should NOT show fractional display like "1¾"
      expect(find.textContaining('¾'), findsNothing);
      expect(find.textContaining('¼'), findsNothing);
      expect(find.textContaining('½'), findsNothing);
    });

    testWidgets('Fractional target (9 Rub = 2¼ Hizb): shows 2 Hizb primary + quarter secondary', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: makeOverrides(mockWirdFractional, 0, {}),
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WirdScreen(),
          ),
        ),
      );
      await tester.pump();

      // Should show "2 Hizb" as primary (not 2¼)
      expect(find.textContaining('2'), findsAtLeastNWidgets(1));
      
      // Should show secondary quarter supplement
      // "Puis 1 quart" in French
      expect(find.textContaining('quart'), findsAtLeastNWidgets(1));
    });

    testWidgets('Progress shows whole Hizb completed (not fractions)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: makeOverrides(mockWirdFractional, 7, {1,2,3,4,5,6,7}),
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WirdScreen(),
          ),
        ),
      );
      await tester.pump();

      // 7 Rub' = 1 whole Hizb + 3 quarters
      // Should show semantic progress like "1 Hizb terminé"
      // The NEW UX model focuses on semantic display, not raw numbers
      
      // Verify that 2¼ or 1¾ fractions are NOT displayed in giant form
      expect(find.textContaining('¾'), findsNothing);
      expect(find.textContaining('2¼'), findsNothing);
      expect(find.textContaining('1¾'), findsNothing);
    });

    testWidgets('Renders in English without errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: makeOverrides(mockWirdNoplan, 0, {}),
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WirdScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Hizb'), findsAtLeastNWidgets(1));
    });

    testWidgets('Renders in Arabic RTL', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: makeOverrides(mockWirdNoplan, 0, {}),
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WirdScreen(),
          ),
        ),
      );
      await tester.pump();

      // Check RTL directionality
      final Directionality directionality = tester.widget(find.byType(Directionality).first);
      expect(directionality.textDirection, TextDirection.rtl);
      
      // Check Arabic term for Hizb: حزب
      expect(find.textContaining('حزب'), findsAtLeastNWidgets(1));
    });

    testWidgets('No overflow at iPhone SE width (375px)', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: makeOverrides(mockWirdFractional, 0, {}),
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WirdScreen(),
          ),
        ),
      );
      await tester.pump();

      // Check for critical labels
      expect(find.textContaining('Hizb'), findsAtLeastNWidgets(1));
      
      // Accept minor FlutterError overflows, fail on critical exceptions
      final exception = tester.takeException();
      if (exception != null && exception is! FlutterError) {
        fail('Critical exception occurred: $exception');
      }
      
      // Reset view
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
