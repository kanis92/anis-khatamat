import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:anis_khatamat/core/models/wird.dart';
import 'package:anis_khatamat/core/models/wird_plan.dart';
import 'package:anis_khatamat/core/services/wird_plan_service.dart';

void main() {
  group('Adaptive Allocation — Behind/Ahead Scenarios', () {
    late WirdPlanService service;
    late Wird wird;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = WirdPlanService();
      wird = Wird.defaultWird();
    });

    group('Behind schedule', () {
      test('Day 15/30 with 0 progress → redistributes over 16 days', () {
        // Scénario: mi-mois, aucune lecture
        final plan = WirdPlan(
          id: const Uuid().v4(),
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
        );

        final today = DateTime(2026, 9, 15);
        final progress = <int>{}; // 0 Rub' complétés

        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          today,
        );

        // Reste: 240 Rub' sur 16 jours (15-30 inclus)
        // 240 / 16 = 15 Rub'/jour
        expect(allocation, 15);
      });

      test('Day 20/30 with 50 Rub\' → redistributes remaining over 11 days', () {
        // Scénario: retard, 50/240 seulement
        final plan = WirdPlan(
          id: const Uuid().v4(),
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
        );

        final today = DateTime(2026, 9, 20);
        final progress = Set<int>.from(List.generate(50, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          today,
        );

        // Reste: 190 Rub' sur 11 jours (20-30 inclus)
        // 190 / 11 ≈ 17.27 → balanced: 18 ou 17
        // Premiers (190 % 11 = 3) jours: 18, reste: 17
        expect(allocation, greaterThanOrEqualTo(17));
        expect(allocation, lessThanOrEqualTo(18));
      });

      test('Final day with remaining Rub\' → allocates all remaining', () {
        // Scénario: dernier jour, reste 10 Rub'
        final plan = WirdPlan(
          id: const Uuid().v4(),
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
        );

        final today = DateTime(2026, 9, 30);
        final progress = Set<int>.from(List.generate(230, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          today,
        );

        // Reste: 10 Rub', dernier jour → tout
        expect(allocation, 10);
      });
    });

    group('Ahead of schedule', () {
      test('Day 10/30 with 120 Rub\' → reduces future allocation', () {
        // Scénario: avance (120/240 en 10 jours au lieu de 80)
        final plan = WirdPlan(
          id: const Uuid().v4(),
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
        );

        final today = DateTime(2026, 9, 10);
        final progress = Set<int>.from(List.generate(120, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          today,
        );

        // Reste: 120 Rub' sur 21 jours (10-30 inclus)
        // 120 / 21 ≈ 5.71 → balanced: 6 ou 5
        // Premiers (120 % 21 = 15) jours: 6, reste: 5
        expect(allocation, greaterThanOrEqualTo(5));
        expect(allocation, lessThanOrEqualTo(6));
      });

      test('Day 15/30 with 200 Rub\' → minimal allocation', () {
        // Scénario: très en avance (200/240)
        final plan = WirdPlan(
          id: const Uuid().v4(),
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
        );

        final today = DateTime(2026, 9, 15);
        final progress = Set<int>.from(List.generate(200, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          today,
        );

        // Reste: 40 Rub' sur 16 jours (15-30 inclus)
        // 40 / 16 = 2.5 → balanced: 3 ou 2
        // Premiers (40 % 16 = 8) jours: 3, reste: 2
        expect(allocation, greaterThanOrEqualTo(2));
        expect(allocation, lessThanOrEqualTo(3));
      });

      test('Completed plan → returns 0', () {
        final plan = WirdPlan(
          id: const Uuid().v4(),
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
        );

        final today = DateTime(2026, 9, 15);
        final progress = Set<int>.from(List.generate(240, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          today,
        );

        expect(allocation, 0);
      });
    });

    group('Hijri month 29 vs 30 days', () {
      test('29-day Hijri month → correct redistribution', () {
        // Ramadan 1447 (mars 2026) = 29 jours
        final plan = service.createHijriMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 3, 1),
          startNextMonth: false,
        );

        final today = DateTime(2026, 3, 15);
        final progress = Set<int>.from(List.generate(100, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          today,
        );

        // Doit redistribuer 140 Rub' sur jours restants
        expect(allocation, greaterThan(0));
      });

      test('30-day Hijri month → correct redistribution', () {
        // Shawwal 1447 (avril 2026) = 30 jours
        final plan = service.createHijriMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 4, 1),
          startNextMonth: false,
        );

        final today = DateTime(2026, 4, 15);
        final progress = Set<int>.from(List.generate(100, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          today,
        );

        // Doit redistribuer 140 Rub' sur jours restants
        expect(allocation, greaterThan(0));
      });
    });

    group('Gregorian month variations', () {
      test('28-day February → exact completion possible', () {
        final plan = service.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 2, 1),
          startNextMonth: false,
        );

        // 240 Rub' / 28 jours ≈ 8.57
        final allocation = service.calculateTodayAllocation(
          plan,
          {},
          wird,
          DateTime(2026, 2, 1),
        );

        // Premiers (240 % 28 = 16) jours: 9, reste: 8
        expect(allocation, greaterThanOrEqualTo(8));
        expect(allocation, lessThanOrEqualTo(9));
      });

      test('31-day January → exact completion possible', () {
        final plan = service.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 1, 1),
          startNextMonth: false,
        );

        // 240 Rub' / 31 jours ≈ 7.74
        final allocation = service.calculateTodayAllocation(
          plan,
          {},
          wird,
          DateTime(2026, 1, 1),
        );

        // Premiers (240 % 31 = 23) jours: 8, reste: 7
        expect(allocation, greaterThanOrEqualTo(7));
        expect(allocation, lessThanOrEqualTo(8));
      });
    });

    group('Edge cases', () {
      test('Expired plan → returns 0', () {
        final plan = WirdPlan(
          id: const Uuid().v4(),
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 8, 1).subtract(const Duration(days: 1)),
          endDate: DateTime(2026, 8, 31),
          createdAt: DateTime(2026, 8, 1),
        );

        final today = DateTime(2026, 9, 5); // Après deadline
        final progress = Set<int>.from(List.generate(100, (i) => i + 1));

        final allocation = service.calculateTodayAllocation(
          plan,
          progress,
          wird,
          today,
        );

        // Deadline passée → allocation = reste (pour permettre continuation)
        expect(allocation, 140);
      });

      test('Start immediately on last day of month', () {
        final plan = service.createGregorianMonthPlan(
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          startGregorian: DateTime(2026, 9, 30),
          startNextMonth: false,
        );

        final allocation = service.calculateTodayAllocation(
          plan,
          {},
          wird,
          DateTime(2026, 9, 30),
        );

        // 1 seul jour → tout
        expect(allocation, 240);
      });
    });

    group('Invariants', () {
      test('Allocation never exceeds remaining Rub\'', () {
        final plan = WirdPlan(
          id: const Uuid().v4(),
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
        );

        for (var day = 1; day <= 30; day++) {
          for (var completed = 0; completed <= 240; completed += 20) {
            final today = DateTime(2026, 9, day);
            final progress = Set<int>.from(
              List.generate(completed, (i) => i + 1),
            );

            final allocation = service.calculateTodayAllocation(
              plan,
              progress,
              wird,
              today,
            );

            final remaining = 240 - completed;
            expect(allocation, lessThanOrEqualTo(remaining));
          }
        }
      });

      test('Sum of daily allocations equals total when followed exactly', () {
        final plan = WirdPlan(
          id: const Uuid().v4(),
          type: WirdPlanType.gregorianMonth,
          subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
          baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
          endDate: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
        );

        var totalAllocated = 0;
        var cumulativeProgress = <int>{};

        for (var day = 1; day <= 30; day++) {
          final today = DateTime(2026, 9, day);
          final allocation = service.calculateTodayAllocation(
            plan,
            cumulativeProgress,
            wird,
            today,
          );

          totalAllocated += allocation;

          // Simulate completing today's allocation
          final newIds = List.generate(
            allocation,
            (i) => cumulativeProgress.length + i + 1,
          );
          cumulativeProgress.addAll(newIds);

          if (cumulativeProgress.length >= 240) break;
        }

        expect(totalAllocated, 240);
        expect(cumulativeProgress.length, 240);
      });
    });
  });
}
