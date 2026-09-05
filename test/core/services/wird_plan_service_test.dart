import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/models/wird.dart';
import '../../../lib/core/models/wird_plan.dart';
import '../../../lib/core/services/wird_plan_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WirdPlanService', () {
    late WirdPlanService service;

    setUp(() {
      service = WirdPlanService();
    });

    group('getPlanProgress', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
      });

      test('returns empty set when no progress exists', () async {
        final plan = WirdPlan(
          id: 'test-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 3),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 4),
        );

        final progress = await service.getPlanProgress('test-user', plan);

        expect(progress, isEmpty);
      });

      test('aggregates completion IDs from tracker after baseline', () async {
        final prefs = await SharedPreferences.getInstance();

        // Baseline = 2026-09-03, plan starts 2026-09-04
        // Simulate completion IDs on 2026-09-04 and 2026-09-05
        await prefs.setStringList(
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:test-user:2026-09-04',
          ['1', '2', '3', '4'], // First Hizb
        );
        await prefs.setStringList(
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:test-user:2026-09-05',
          ['5', '6', '7', '8'], // Second Hizb
        );

        final plan = WirdPlan(
          id: 'test-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 3),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 4),
        );

        // Note: getPlanProgress uses DateTime.now() internally for 'today'
        // Since we can't mock DateTime.now() easily, this test may be flaky
        // In production use, consider making 'today' a parameter
        final progress = await service.getPlanProgress('test-user', plan);

        // Should contain at least IDs from 09-04
        expect(progress, contains(1));
        expect(progress, contains(2));
        expect(progress, contains(3));
        expect(progress, contains(4));
      });

      test('filters completion IDs by plan range', () async {
        final prefs = await SharedPreferences.getInstance();

        // All completion IDs 1..240
        await prefs.setStringList(
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:test-user:2026-09-04',
          List.generate(240, (i) => (i + 1).toString()),
        );

        final plan = WirdPlan(
          id: 'partial-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 3),
          endDate: DateTime(2026, 9, 30),
          startCompletionId: 1,
          endCompletionId: 8, // Only first Juzz
          createdAt: DateTime(2026, 9, 4),
        );

        final progress = await service.getPlanProgress('test-user', plan);

        expect(progress, {1, 2, 3, 4, 5, 6, 7, 8});
      });

      test('ignores completion IDs before baseline', () async {
        final prefs = await SharedPreferences.getInstance();

        // Completion on baseline date (should be excluded)
        await prefs.setStringList(
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:test-user:2026-09-03',
          ['1', '2', '3'],
        );

        // Completion before baseline (should be excluded)
        await prefs.setStringList(
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:test-user:2026-09-02',
          ['4', '5'],
        );

        // Completion after baseline (should be included)
        await prefs.setStringList(
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:test-user:2026-09-04',
          ['6', '7', '8'],
        );

        final plan = WirdPlan(
          id: 'test-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 3),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 4),
        );

        final progress = await service.getPlanProgress('test-user', plan);

        expect(progress, {6, 7, 8}); // Only after baseline
      });

      test('respects subdivisionDefinitionId namespace', () async {
        final prefs = await SharedPreferences.getInstance();

        // Different namespace
        await prefs.setStringList(
          'anis_wird_rubs_completed:other_definition:test-user:2026-09-04',
          ['1', '2', '3'],
        );

        // Correct namespace
        await prefs.setStringList(
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:test-user:2026-09-04',
          ['4', '5', '6'],
        );

        final plan = WirdPlan(
          id: 'test-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 3),
          createdAt: DateTime(2026, 9, 4),
        );

        final progress = await service.getPlanProgress('test-user', plan);

        expect(progress, {4, 5, 6}); // Only hafs namespace
      });
    });

    group('calculateTodayAllocation', () {
      test('returns 0 when plan completed', () {
        final plan = WirdPlan(
          id: 'test',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime.now(),
        );

        final wird = Wird.defaultWird();
        final completedAll = Set<int>.from(List.generate(240, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          completedAll,
          wird,
          DateTime(2026, 9, 15),
        );

        expect(allocation, 0);
      });

      test('returns fixed target for freeDaily plan', () {
        final plan = WirdPlan(
          id: 'free',
          type: WirdPlanType.freeDaily,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          createdAt: DateTime.now(),
        );

        final wird = Wird.defaultWird().copyWith(dailyTargetRubs: 8);

        final allocation = service.calculateTodayAllocation(
          plan,
          {},
          wird,
          DateTime(2026, 9, 15),
        );

        expect(allocation, 8); // Fixed from Wird
      });

      test('calculates balanced allocation for 30-day plan', () {
        final plan = WirdPlan(
          id: 'test',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime.now(),
        );

        final wird = Wird.defaultWird();

        // Day 1: 0 completed, baseline = Sept 1, today = Sept 2
        // Days left from Sept 2 to Sept 30 = 29 days
        // 240 / 29 = 8.275... → 8×9 + 21×8, first day gets 9
        final allocation = service.calculateTodayAllocation(
          plan,
          {},
          wird,
          DateTime(2026, 9, 2),
        );

        expect(allocation, 9); // 240/29 → first allocation is 9
      });

      test('recalculates when ahead', () {
        final plan = WirdPlan(
          id: 'test',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime.now(),
        );

        final wird = Wird.defaultWird();

        // Day 1: completed 16 Rub' (instead of 8)
        // Remaining: 224, days left: 29
        final completed = Set<int>.from([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        final allocation = service.calculateTodayAllocation(
          plan,
          completed,
          wird,
          DateTime(2026, 9, 3),
        );

        // 224 / 29 = 7.724... → 21×8 + 8×7, first day gets 8
        expect(allocation, 8);
      });

      test('recalculates when behind', () {
        final plan = WirdPlan(
          id: 'test',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime.now(),
        );

        final wird = Wird.defaultWird();

        // Day 5: completed 0 (should have ~32)
        // Remaining: 240, days left: 26
        final allocation = service.calculateTodayAllocation(
          plan,
          {},
          wird,
          DateTime(2026, 9, 6),
        );

        // 240 / 26 = 9.230... → 6×10 + 20×9, first day gets 10
        expect(allocation, 10);
      });

      test('returns all remaining on last day', () {
        final plan = WirdPlan(
          id: 'test',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime.now(),
        );

        final wird = Wird.defaultWird();

        // Last day: 50 Rub' remaining
        final completed = Set<int>.from(List.generate(190, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          completed,
          wird,
          DateTime(2026, 9, 30),
        );

        expect(allocation, 50); // All remaining
      });

      test('returns all remaining when past deadline', () {
        final plan = WirdPlan(
          id: 'test',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime.now(),
        );

        final wird = Wird.defaultWird();

        // Past deadline: 100 Rub' remaining
        final completed = Set<int>.from(List.generate(140, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          completed,
          wird,
          DateTime(2026, 10, 5),
        );

        expect(allocation, 100); // All remaining
      });
    });

    group('createGregorianMonthPlan', () {
      test('creates plan for current month (start now)', () {
        final plan = service.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 1, 15),
          startNextMonth: false,
        );

        expect(plan.type, WirdPlanType.gregorianMonth);
        expect(plan.baselineDate, DateTime(2026, 1, 14)); // day before start
        expect(plan.endDate, DateTime(2026, 1, 31)); // end of January
        expect(plan.startCompletionId, 1);
        expect(plan.endCompletionId, 240);
      });

      test('creates plan for next month (schedule)', () {
        final plan = service.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 1, 15),
          startNextMonth: true,
        );

        expect(plan.baselineDate, DateTime(2026, 1, 31)); // day before Feb 1
        expect(plan.endDate, DateTime(2026, 2, 28)); // end of February 2026 (non-leap)
      });

      test('handles February leap year', () {
        final plan = service.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2028, 1, 15), // 2028 is leap year
          startNextMonth: true,
        );

        expect(plan.endDate, DateTime(2028, 2, 29)); // Leap year February
      });

      test('handles year rollover', () {
        final plan = service.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 12, 15),
          startNextMonth: true,
        );

        expect(plan.baselineDate, DateTime(2026, 12, 31)); // Last day of 2026
        expect(plan.endDate, DateTime(2027, 1, 31)); // End of January 2027
      });

      test('handles 31-day months', () {
        final plan = service.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 3, 1),
          startNextMonth: false,
        );

        expect(plan.endDate, DateTime(2026, 3, 31)); // March has 31 days
      });

      test('handles 30-day months', () {
        final plan = service.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 4, 1),
          startNextMonth: false,
        );

        expect(plan.endDate, DateTime(2026, 4, 30)); // April has 30 days
      });
    });

    group('createHijriMonthPlan', () {
      test('creates plan for current Hijri month (start now)', () {
        // 2026-09-04 gregorian
        final plan = service.createHijriMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 9, 4),
          startNextMonth: false,
        );

        expect(plan.type, WirdPlanType.hijriMonth);
        expect(plan.startCompletionId, 1);
        expect(plan.endCompletionId, 240);

        // Baseline should be day before start
        expect(plan.baselineDate.isBefore(plan.endDate!), true);
      });

      test('creates plan for next Hijri month (schedule)', () {
        final plan = service.createHijriMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 9, 4),
          startNextMonth: true,
        );

        // Next month should start after current date
        expect(plan.baselineDate.isAfter(DateTime(2026, 9, 4)), true);
      });

      test('respects subdivisionDefinitionId', () {
        final plan = service.createHijriMonthPlan(
          subdivisionDefinitionId: 'custom_definition_id',
          startGregorian: DateTime(2026, 9, 4),
          startNextMonth: false,
        );

        expect(plan.subdivisionDefinitionId, 'custom_definition_id');
      });

      test('generates unique IDs', () {
        final plan1 = service.createHijriMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 9, 4),
        );

        final plan2 = service.createHijriMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 9, 4),
        );

        expect(plan1.id, isNot(plan2.id));
      });
    });
  });
}
