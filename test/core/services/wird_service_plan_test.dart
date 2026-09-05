import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/models/wird.dart';
import '../../../lib/core/models/wird_plan.dart';
import '../../../lib/core/services/wird_plan_service.dart';
import '../../../lib/core/services/wird_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WirdService — Plan Management', () {
    late WirdService service;
    late WirdPlanService planService;

    setUp(() {
      service = WirdService();
      planService = WirdPlanService();
    });

    group('activatePlan', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
      });

      test('saves plan with matching subdivisionDefinitionId', () async {
        final plan = planService.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 9, 5),
          startNextMonth: false,
        );

        await service.activatePlan('test-user', plan);

        final wird = await service.getWird('test-user');
        expect(wird.activePlan, isNotNull);
        expect(wird.activePlan!.id, plan.id);
      });

      test('throws ArgumentError when definition mismatches', () async {
        // Create wird with Hafs definition
        final wird = Wird.defaultWird(); // Uses hafs_quran_foundation_rub_240_v1
        await service.saveWird('test-user', wird);

        // Try to activate plan with different definition
        final plan = WirdPlan(
          id: 'wrong-def-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'different_definition', // Mismatch!
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 2),
        );

        expect(
          () async => await service.activatePlan('test-user', plan),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('preserves other wird fields when activating plan', () async {
        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 8, // Custom target
          lastMushafType: 'hafs',
          lastPage: 100,
          lastReadAt: DateTime(2026, 9, 4),
          createdAt: DateTime(2026, 9, 1),
        );
        await service.saveWird('test-user', wird);

        final plan = planService.createHijriMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 9, 5),
          startNextMonth: false,
        );

        await service.activatePlan('test-user', plan);

        final updated = await service.getWird('test-user');
        expect(updated.dailyTargetRubs, 8); // Preserved
        expect(updated.lastMushafType, 'hafs'); // Preserved
        expect(updated.lastPage, 100); // Preserved
        expect(updated.activePlan, isNotNull);
      });
    });

    group('clearActivePlan', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
      });

      test('removes active plan and returns to free daily mode', () async {
        // Create wird with active plan
        final plan = planService.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 9, 5),
          startNextMonth: false,
        );
        await service.activatePlan('test-user', plan);

        final withPlan = await service.getWird('test-user');
        expect(withPlan.activePlan, isNotNull);

        // Clear plan
        await service.clearActivePlan('test-user');

        final withoutPlan = await service.getWird('test-user');
        expect(withoutPlan.activePlan, isNull);
      });

      test('preserves other wird fields when clearing plan', () async {
        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 8,
          lastMushafType: 'hafs',
          lastPage: 100,
          lastReadAt: DateTime(2026, 9, 4),
          createdAt: DateTime(2026, 9, 1),
        );
        await service.saveWird('test-user', wird);

        final plan = planService.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 9, 5),
          startNextMonth: false,
        );
        await service.activatePlan('test-user', plan);

        await service.clearActivePlan('test-user');

        final updated = await service.getWird('test-user');
        expect(updated.dailyTargetRubs, 8); // Preserved
        expect(updated.lastMushafType, 'hafs'); // Preserved
        expect(updated.lastPage, 100); // Preserved
        expect(updated.activePlan, isNull); // Cleared
      });
    });

    group('Plan Creation End-to-End', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
      });

      test('Gregorian plan — start now', () async {
        final now = DateTime(2026, 9, 5);
        final plan = planService.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: now,
          startNextMonth: false,
        );

        await service.activatePlan('test-user', plan);

        final wird = await service.getWird('test-user');
        expect(wird.activePlan, isNotNull);
        expect(wird.activePlan!.type, WirdPlanType.gregorianMonth);
        expect(wird.activePlan!.baselineDate, DateTime(2026, 9, 4)); // Day before
        expect(wird.activePlan!.endDate, DateTime(2026, 9, 30)); // End of month
      });

      test('Gregorian plan — start next month', () async {
        final now = DateTime(2026, 9, 5);
        final plan = planService.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: now,
          startNextMonth: true,
        );

        await service.activatePlan('test-user', plan);

        final wird = await service.getWird('test-user');
        expect(wird.activePlan, isNotNull);
        expect(wird.activePlan!.baselineDate, DateTime(2026, 9, 30)); // Last day of Sept
        expect(wird.activePlan!.endDate, DateTime(2026, 10, 31)); // End of Oct
      });

      test('Hijri plan — start now', () async {
        final now = DateTime(2026, 9, 5);
        final plan = planService.createHijriMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: now,
          startNextMonth: false,
        );

        await service.activatePlan('test-user', plan);

        final wird = await service.getWird('test-user');
        expect(wird.activePlan, isNotNull);
        expect(wird.activePlan!.type, WirdPlanType.hijriMonth);
        expect(wird.activePlan!.baselineDate.isBefore(now), true);
        expect(wird.activePlan!.endDate!.isAfter(now), true);
      });

      test('Hijri plan — start next month', () async {
        final now = DateTime(2026, 9, 5);
        final plan = planService.createHijriMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: now,
          startNextMonth: true,
        );

        await service.activatePlan('test-user', plan);

        final wird = await service.getWird('test-user');
        expect(wird.activePlan, isNotNull);
        expect(wird.activePlan!.baselineDate.isAfter(now), true); // Scheduled
      });
    });
  });
}
