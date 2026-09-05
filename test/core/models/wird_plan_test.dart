import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/models/wird_plan.dart';

void main() {
  group('WirdPlan Model', () {
    group('Construction and Validation', () {
      test('creates valid plan with all required fields', () {
        final plan = WirdPlan(
          id: 'test-plan-1',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 1, 14),
          endDate: DateTime(2026, 1, 31),
          startCompletionId: 1,
          endCompletionId: 240,
          createdAt: DateTime(2026, 1, 15),
        );

        expect(plan.id, 'test-plan-1');
        expect(plan.type, WirdPlanType.gregorianMonth);
        expect(plan.totalRubTarget, 240);
        expect(plan.cycleNumber, 1); // default
      });

      test('enforces completion ID range 1..240 for start', () {
        expect(
          () => WirdPlan(
            id: 'invalid',
            type: WirdPlanType.freeDaily,
            subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
            baselineDate: DateTime(2026, 1, 1),
            startCompletionId: 0, // INVALID
            endCompletionId: 240,
            createdAt: DateTime.now(),
          ),
          throwsAssertionError,
        );

        expect(
          () => WirdPlan(
            id: 'invalid',
            type: WirdPlanType.freeDaily,
            subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
            baselineDate: DateTime(2026, 1, 1),
            startCompletionId: 241, // INVALID
            endCompletionId: 240,
            createdAt: DateTime.now(),
          ),
          throwsAssertionError,
        );
      });

      test('enforces completion ID range 1..240 for end', () {
        expect(
          () => WirdPlan(
            id: 'invalid',
            type: WirdPlanType.freeDaily,
            subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
            baselineDate: DateTime(2026, 1, 1),
            startCompletionId: 1,
            endCompletionId: 0, // INVALID
            createdAt: DateTime.now(),
          ),
          throwsAssertionError,
        );

        expect(
          () => WirdPlan(
            id: 'invalid',
            type: WirdPlanType.freeDaily,
            subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
            baselineDate: DateTime(2026, 1, 1),
            startCompletionId: 1,
            endCompletionId: 241, // INVALID
            createdAt: DateTime.now(),
          ),
          throwsAssertionError,
        );
      });

      test('enforces start <= end', () {
        expect(
          () => WirdPlan(
            id: 'invalid',
            type: WirdPlanType.freeDaily,
            subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
            baselineDate: DateTime(2026, 1, 1),
            startCompletionId: 100,
            endCompletionId: 50, // INVALID: start > end
            createdAt: DateTime.now(),
          ),
          throwsAssertionError,
        );
      });

      test('allows valid partial ranges', () {
        final plan = WirdPlan(
          id: 'partial',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 1, 1),
          startCompletionId: 1,
          endCompletionId: 8, // First Juzz (2 Hizb = 8 Rub')
          createdAt: DateTime.now(),
        );

        expect(plan.totalRubTarget, 8);
      });
    });

    group('Serialization', () {
      test('roundtrip toMap/fromMap preserves all fields', () {
        final original = WirdPlan(
          id: 'test-uuid',
          type: WirdPlanType.hijriMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 3, 0, 0, 0),
          endDate: DateTime(2026, 9, 30, 0, 0, 0),
          startCompletionId: 1,
          endCompletionId: 240,
          createdAt: DateTime(2026, 9, 4, 10, 30, 0),
          cycleNumber: 1,
        );

        final map = original.toMap();
        final restored = WirdPlan.fromMap(map);

        expect(restored, original);
      });

      test('toMap includes completedAt when present', () {
        final plan = WirdPlan(
          id: 'completed-plan',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          completedAt: DateTime(2026, 1, 25),
          createdAt: DateTime(2026, 1, 1),
        );

        final map = plan.toMap();
        expect(map['completedAt'], isNotNull);
        expect(map['completedAt'], '2026-01-25T00:00:00.000');
      });

      test('fromMap handles missing optional fields', () {
        final map = {
          'id': 'minimal-plan',
          'type': 'freeDaily',
          'subdivisionDefinitionId': 'hafs_quran_foundation_rub_240_v1',
          'baselineDate': '2026-01-01T00:00:00.000',
          'createdAt': '2026-01-01T00:00:00.000',
        };

        final plan = WirdPlan.fromMap(map);

        expect(plan.endDate, isNull);
        expect(plan.completedAt, isNull);
        expect(plan.startCompletionId, 1); // default
        expect(plan.endCompletionId, 240); // default
        expect(plan.cycleNumber, 1); // default
      });
    });

    group('Business Logic', () {
      test('totalRubTarget calculates correctly', () {
        expect(
          WirdPlan(
            id: '1',
            type: WirdPlanType.freeDaily,
            subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
            baselineDate: DateTime(2026, 1, 1),
            startCompletionId: 1,
            endCompletionId: 240,
            createdAt: DateTime.now(),
          ).totalRubTarget,
          240,
        );

        expect(
          WirdPlan(
            id: '2',
            type: WirdPlanType.freeDaily,
            subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
            baselineDate: DateTime(2026, 1, 1),
            startCompletionId: 1,
            endCompletionId: 4, // 1 Hizb
            createdAt: DateTime.now(),
          ).totalRubTarget,
          4,
        );

        expect(
          WirdPlan(
            id: '3',
            type: WirdPlanType.freeDaily,
            subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
            baselineDate: DateTime(2026, 1, 1),
            startCompletionId: 237,
            endCompletionId: 240, // Last Hizb
            createdAt: DateTime.now(),
          ).totalRubTarget,
          4,
        );
      });

      test('isExpired returns false for completed plans', () {
        final plan = WirdPlan(
          id: 'completed',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          completedAt: DateTime(2026, 1, 25),
          createdAt: DateTime(2026, 1, 1),
        );

        expect(plan.isExpired(DateTime(2026, 2, 5)), false);
      });

      test('isExpired returns false for plans without deadline', () {
        final plan = WirdPlan(
          id: 'free',
          type: WirdPlanType.freeDaily,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 1, 1),
          endDate: null, // No deadline
          createdAt: DateTime(2026, 1, 1),
        );

        expect(plan.isExpired(DateTime(2027, 12, 31)), false);
      });

      test('isExpired returns true when past endDate', () {
        final plan = WirdPlan(
          id: 'expired',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          createdAt: DateTime(2026, 1, 1),
        );

        expect(plan.isExpired(DateTime(2026, 2, 1)), true);
      });

      test('isExpired returns false on exact endDate', () {
        final plan = WirdPlan(
          id: 'on-deadline',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          createdAt: DateTime(2026, 1, 1),
        );

        expect(plan.isExpired(DateTime(2026, 1, 31)), false);
      });

      test('isCompleted reflects completedAt state', () {
        final incomplete = WirdPlan(
          id: 'incomplete',
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
        );

        expect(incomplete.isCompleted, false);

        final complete = incomplete.copyWith(
          completedAt: DateTime(2026, 1, 25),
        );

        expect(complete.isCompleted, true);
      });
    });
  });
}
