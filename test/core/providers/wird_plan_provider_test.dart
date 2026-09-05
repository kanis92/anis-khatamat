import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/models/wird.dart';
import '../../../lib/core/models/wird_plan.dart';
import '../../../lib/core/models/wird_plan_state.dart';
import '../../../lib/core/providers/wird_provider.dart';
import '../../../lib/core/services/wird_plan_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Wird Plan Providers — Phase 1 Runtime Integration', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('No Plan (Legacy Free Daily Mode)', () {
      test('returns WirdPlanState.none when no plan', () async {
        // Setup: Wird with no activePlan
        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': '{"subdivisionDefinitionId":"hafs_quran_foundation_rub_240_v1","dailyTargetRubs":4,"createdAt":"2026-09-05T00:00:00.000"}',
        });

        container = ProviderContainer();

        final state = await container.read(wirdPlanStateProvider.future);
        expect(state, WirdPlanState.none);
      });

      test('allocation returns dailyTargetRubs when no plan', () async {
        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': '{"subdivisionDefinitionId":"hafs_quran_foundation_rub_240_v1","dailyTargetRubs":8,"createdAt":"2026-09-05T00:00:00.000"}',
        });

        container = ProviderContainer();

        final allocation = await container.read(wirdPlanAllocationProvider.future);
        expect(allocation, 8); // Free daily goal
      });

      test('progress is empty when no plan', () async {
        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': '{"subdivisionDefinitionId":"hafs_quran_foundation_rub_240_v1","dailyTargetRubs":4,"createdAt":"2026-09-05T00:00:00.000"}',
        });

        container = ProviderContainer();

        final progress = await container.read(wirdPlanProgressProvider.future);
        expect(progress, isEmpty);
      });
    });

    group('Active Gregorian Plan', () {
      test('returns WirdPlanState.active for current month plan', () async {
        final plan = WirdPlan(
          id: 'greg-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 4), // Day before start
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 5),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 5),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
        });

        container = ProviderContainer();

        final state = await container.read(wirdPlanStateProvider.future);
        expect(state, WirdPlanState.active);
      });

      test('calculates dynamic allocation for active Gregorian plan', () async {
        final plan = WirdPlan(
          id: 'greg-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1), // Baseline Sept 1
          endDate: DateTime(2026, 9, 30), // End Sept 30
          createdAt: DateTime(2026, 9, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 2),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
        });

        container = ProviderContainer();

        final allocation = await container.read(wirdPlanAllocationProvider.future);
        
        // Sept 2 (today assumed in test context): 29 days left (Sept 2-30)
        // 240 / 29 = 8.275... → 8×9 + 21×8, first day gets 9
        expect(allocation, greaterThan(0));
      });

      test('derives progress from tracker for Gregorian plan', () async {
        final plan = WirdPlan(
          id: 'greg-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 4),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 5),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 5),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-09-05': ['1', '2', '3', '4'],
        });

        container = ProviderContainer();

        final progress = await container.read(wirdPlanProgressProvider.future);
        expect(progress, {1, 2, 3, 4});
      });

      test('calculates remaining Rub for Gregorian plan', () async {
        final plan = WirdPlan(
          id: 'greg-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 4),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 5),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 5),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-09-05': ['1', '2', '3', '4', '5', '6', '7', '8'],
        });

        container = ProviderContainer();

        final remaining = await container.read(wirdPlanRemainingRubsProvider.future);
        expect(remaining, 232); // 240 - 8
      });
    });

    group('Active Hijri Plan', () {
      test('returns WirdPlanState.active for Hijri plan', () async {
        final plan = WirdPlan(
          id: 'hijri-plan',
          type: WirdPlanType.hijriMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 4),
          endDate: DateTime(2026, 10, 3), // Approximate Hijri month end
          createdAt: DateTime(2026, 9, 5),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 5),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
        });

        container = ProviderContainer();

        final state = await container.read(wirdPlanStateProvider.future);
        expect(state, WirdPlanState.active);
      });

      test('calculates allocation for Hijri plan', () async {
        final plan = WirdPlan(
          id: 'hijri-plan',
          type: WirdPlanType.hijriMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 29), // 29-day Hijri month
          createdAt: DateTime(2026, 9, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 2),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
        });

        container = ProviderContainer();

        final allocation = await container.read(wirdPlanAllocationProvider.future);
        expect(allocation, greaterThan(0));
      });
    });

    group('Scheduled Plan', () {
      test('returns WirdPlanState.scheduled for future plan', () async {
        final plan = WirdPlan(
          id: 'scheduled-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 30), // Baseline Sept 30
          endDate: DateTime(2026, 10, 31), // Oct 1-31
          createdAt: DateTime(2026, 9, 5),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 8,
          createdAt: DateTime(2026, 9, 5),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
        });

        container = ProviderContainer();

        final state = await container.read(wirdPlanStateProvider.future);
        expect(state, WirdPlanState.scheduled);
      });

      test('allocation returns dailyTargetRubs for scheduled plan', () async {
        final plan = WirdPlan(
          id: 'scheduled-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 30),
          endDate: DateTime(2026, 10, 31),
          createdAt: DateTime(2026, 9, 5),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 12, // Custom free goal
          createdAt: DateTime(2026, 9, 5),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
        });

        container = ProviderContainer();

        final allocation = await container.read(wirdPlanAllocationProvider.future);
        expect(allocation, 12); // Scheduled plan doesn't affect today's free goal
      });
    });

    group('Completed Plan', () {
      test('returns WirdPlanState.completed when all Rub accomplished', () async {
        final plan = WirdPlan(
          id: 'completed-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          startCompletionId: 1,
          endCompletionId: 8, // Only first Juzz
          createdAt: DateTime(2026, 9, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 2),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-09-02': ['1', '2', '3', '4'],
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-09-03': ['5', '6', '7', '8'],
        });

        container = ProviderContainer();

        final state = await container.read(wirdPlanStateProvider.future);
        expect(state, WirdPlanState.completed);
      });

      test('allocation returns 0 for completed plan', () async {
        final plan = WirdPlan(
          id: 'completed-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          startCompletionId: 1,
          endCompletionId: 4,
          createdAt: DateTime(2026, 9, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 2),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-09-02': ['1', '2', '3', '4'],
        });

        container = ProviderContainer();

        final allocation = await container.read(wirdPlanAllocationProvider.future);
        expect(allocation, 0);
      });

      test('remaining Rub is 0 for completed plan', () async {
        final plan = WirdPlan(
          id: 'completed-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          startCompletionId: 1,
          endCompletionId: 4,
          createdAt: DateTime(2026, 9, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 2),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-09-02': ['1', '2', '3', '4'],
        });

        container = ProviderContainer();

        final remaining = await container.read(wirdPlanRemainingRubsProvider.future);
        expect(remaining, 0);
      });
    });

    group('Expired Plan', () {
      test('returns WirdPlanState.expired when past endDate', () async {
        final plan = WirdPlan(
          id: 'expired-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31), // Expired
          createdAt: DateTime(2026, 8, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 8, 2),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
          // Only 100 Rub completed (plan incomplete)
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-08-02':
              List.generate(100, (i) => (i + 1).toString()),
        });

        container = ProviderContainer();

        final state = await container.read(wirdPlanStateProvider.future);
        expect(state, WirdPlanState.expired);
      });

      test('allocation returns 0 for expired plan', () async {
        final plan = WirdPlan(
          id: 'expired-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31),
          createdAt: DateTime(2026, 8, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 8, 2),
          activePlan: plan,
        );

        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
        });

        container = ProviderContainer();

        final allocation = await container.read(wirdPlanAllocationProvider.future);
        expect(allocation, 0);
      });
    });

    group('Ahead/Behind Allocation Recalculation', () {
      test('recalculates allocation when ahead', () async {
        final plan = WirdPlan(
          id: 'ahead-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 2),
          activePlan: plan,
        );

        // Completed 32 Rub' already (ahead of 8 Rub'/day pace)
        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-09-02':
              List.generate(32, (i) => (i + 1).toString()),
        });

        container = ProviderContainer();

        final service = WirdPlanService();
        final progress = await container.read(wirdPlanProgressProvider.future);
        
        // Should recalculate: 208 remaining / 28 days = ...
        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          DateTime(2026, 9, 3), // Next day
        );

        expect(allocation, greaterThan(0));
        expect(progress.length, 32); // Ahead
      });

      test('recalculates allocation when behind', () async {
        final plan = WirdPlan(
          id: 'behind-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 2),
          activePlan: plan,
        );

        // Completed only 4 Rub' (behind 8 Rub'/day pace)
        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-09-02': ['1', '2', '3', '4'],
        });

        container = ProviderContainer();

        final service = WirdPlanService();
        final progress = await container.read(wirdPlanProgressProvider.future);
        
        // Should recalculate: 236 remaining / 28 days = ...
        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          DateTime(2026, 9, 3),
        );

        expect(allocation, greaterThan(0));
        expect(progress.length, 4); // Behind
      });
    });

    group('SubdivisionDefinition Consistency', () {
      test('plan and wird must have same subdivisionDefinitionId', () async {
        final plan = WirdPlan(
          id: 'mismatched-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'different_definition', // Mismatch!
          baselineDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 2),
        );

        final wird = Wird(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          dailyTargetRubs: 4,
          createdAt: DateTime(2026, 9, 2),
          activePlan: plan,
        );

        // In production, this should be validated before saving
        // For now, test that service correctly reads different namespaces
        SharedPreferences.setMockInitialValues({
          'anis_wird_v2_demo': _wirdToJson(wird),
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:demo:2026-09-02': ['1', '2', '3'],
          'anis_wird_rubs_completed:different_definition:demo:2026-09-02': ['4', '5', '6'],
        });

        container = ProviderContainer();

        await expectLater(
          container.read(wirdPlanProgressProvider.future),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('does not match'),
            ),
          ),
        );
      });
    });
  });
}

// Helper to serialize Wird with plan
String _wirdToJson(Wird wird) {
  return jsonEncode(wird.toMap());
}
