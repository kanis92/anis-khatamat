import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../lib/core/models/wird.dart';
import '../../lib/core/models/wird_plan.dart';
import '../../lib/core/models/wird_plan_state.dart';
import '../../lib/core/providers/wird_provider.dart';
import '../../lib/screens/wird_screen.dart';
import '../../lib/l10n/gen_l10n/app_localizations.dart';

/// STRICT compact screen regression test.
/// 
/// MUST FAIL on:
/// - RenderFlex overflow
/// - Pixel overflow
/// - Layout exception
/// - Clipped critical content
/// 
/// NO tolerance for overflow.
void main() {
  group('Compact Screen Regression (375x667) — STRICT', () {
    // Realistic coherent state
    final mockWirdWithPlan = Wird(
      subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
      dailyTargetRubs: 9, // 2¼ Hizb adaptive
      activePlan: WirdPlan(
        id: 'test_plan_1',
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 8, 31),
        endDate: DateTime(2026, 9, 30),
        startCompletionId: 1,
        endCompletionId: 240,
        createdAt: DateTime(2026, 8, 31),
      ),
      lastMushafType: 'hafs',
      lastPage: 281, // Hizb 16 start
      createdAt: DateTime(2026, 8, 1),
      currentCycleStartDate: DateTime(2026, 8, 1),
    );

    // Coherent: 60 Rub' completed = Hizb 1-15 done, in Hizb 16
    final completedRubs = List.generate(60, (i) => i + 1).toSet();

    List<Override> makeOverrides(Wird wird, int todayProgress) {
      return [
        wirdProvider.overrideWith((ref) async => wird),
        wirdTodayProgressProvider.overrideWith((ref) async => todayProgress),
        wirdTodayCompletedRubIdsProvider.overrideWith((ref) async => completedRubs),
        wirdTodayAuthoritativeTargetProvider.overrideWith((ref) async => wird.dailyTargetRubs),
        wirdPlanStateProvider.overrideWith((ref) async => WirdPlanState.active),
        wirdPlanProgressProvider.overrideWith((ref) async => <int>{}),
        wirdCycleProgressProvider.overrideWith((ref) async => completedRubs),
      ];
    }

    testWidgets('FR: NO overflow on iPhone SE 375x667', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: makeOverrides(mockWirdWithPlan, 7), // 7/9 today
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
      
      await tester.pumpAndSettle();

      // Verify critical content is present
      expect(find.textContaining('Hizb'), findsAtLeastNWidgets(1));

      // STRICT: NO tolerance for overflow
      final exception = tester.takeException();
      if (exception != null) {
        if (exception is FlutterError) {
          final message = exception.toString();
          if (message.contains('RenderFlex') && message.contains('overflow')) {
            fail('RenderFlex overflow detected at 375x667 (FR):\n$message');
          }
          if (message.contains('pixels')) {
            fail('Pixel overflow detected at 375x667 (FR):\n$message');
          }
        }
        // Other exceptions are critical too
        fail('Layout exception at 375x667 (FR): $exception');
      }
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('EN: NO overflow on iPhone SE 375x667', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: makeOverrides(mockWirdWithPlan, 7),
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
      
      await tester.pumpAndSettle();

      expect(find.textContaining('Hizb'), findsAtLeastNWidgets(1));

      final exception = tester.takeException();
      if (exception != null) {
        if (exception is FlutterError) {
          final message = exception.toString();
          if (message.contains('RenderFlex') && message.contains('overflow')) {
            fail('RenderFlex overflow detected at 375x667 (EN):\n$message');
          }
          if (message.contains('pixels')) {
            fail('Pixel overflow detected at 375x667 (EN):\n$message');
          }
        }
        fail('Layout exception at 375x667 (EN): $exception');
      }
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('AR: NO overflow on iPhone SE 375x667 + RTL validation', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: makeOverrides(mockWirdWithPlan, 7),
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
      
      await tester.pumpAndSettle();

      // Verify Arabic term for Hizb: حزب
      expect(find.textContaining('حزب'), findsAtLeastNWidgets(1));

      // Verify RTL
      final Directionality directionality = tester.widget(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl,
        reason: 'Arabic must be RTL');

      // STRICT: NO tolerance for overflow
      final exception = tester.takeException();
      if (exception != null) {
        if (exception is FlutterError) {
          final message = exception.toString();
          if (message.contains('RenderFlex') && message.contains('overflow')) {
            fail('RenderFlex overflow detected at 375x667 (AR/RTL):\n$message');
          }
          if (message.contains('pixels')) {
            fail('Pixel overflow detected at 375x667 (AR/RTL):\n$message');
          }
        }
        fail('Layout exception at 375x667 (AR): $exception');
      }
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
