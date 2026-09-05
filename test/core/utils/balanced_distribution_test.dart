import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/utils/balanced_distribution.dart';

void main() {
  group('Balanced Distribution', () {
    group('Exact Allocations', () {
      test('240 units / 28 days (February non-leap)', () {
        final dist = balancedDistribution(240, 28);

        expect(dist.length, 28);
        expect(dist.reduce((a, b) => a + b), 240, reason: 'Sum must equal 240');

        // 240 / 28 = 8.571... → base = 8, remainder = 16
        // 16 days get 9, 12 days get 8
        expect(dist.where((x) => x == 9).length, 16);
        expect(dist.where((x) => x == 8).length, 12);

        // Max - min <= 1
        expect(dist.reduce((a, b) => a > b ? a : b) - dist.reduce((a, b) => a < b ? a : b), 1);

        // Higher allocations come first
        expect(dist.take(16).every((x) => x == 9), true);
        expect(dist.skip(16).every((x) => x == 8), true);
      });

      test('240 units / 29 days (Hijri short month)', () {
        final dist = balancedDistribution(240, 29);

        expect(dist.length, 29);
        expect(dist.reduce((a, b) => a + b), 240);

        // 240 / 29 = 8.275... → base = 8, remainder = 8
        // 8 days get 9, 21 days get 8
        expect(dist.where((x) => x == 9).length, 8);
        expect(dist.where((x) => x == 8).length, 21);

        expect(dist.take(8).every((x) => x == 9), true);
        expect(dist.skip(8).every((x) => x == 8), true);
      });

      test('240 units / 30 days (Hijri long month / standard month)', () {
        final dist = balancedDistribution(240, 30);

        expect(dist.length, 30);
        expect(dist.reduce((a, b) => a + b), 240);

        // 240 / 30 = 8.0 → base = 8, remainder = 0
        // All days get 8
        expect(dist.every((x) => x == 8), true);
      });

      test('240 units / 31 days (Gregorian long month)', () {
        final dist = balancedDistribution(240, 31);

        expect(dist.length, 31);
        expect(dist.reduce((a, b) => a + b), 240);

        // 240 / 31 = 7.741... → base = 7, remainder = 23
        // 23 days get 8, 8 days get 7
        expect(dist.where((x) => x == 8).length, 23);
        expect(dist.where((x) => x == 7).length, 8);

        expect(dist.take(23).every((x) => x == 8), true);
        expect(dist.skip(23).every((x) => x == 7), true);
      });
    });

    group('Edge Cases', () {
      test('handles 0 units', () {
        final dist = balancedDistribution(0, 30);

        expect(dist.length, 30);
        expect(dist.every((x) => x == 0), true);
      });

      test('handles 0 days', () {
        final dist = balancedDistribution(240, 0);

        expect(dist.isEmpty, true);
      });

      test('handles negative days', () {
        final dist = balancedDistribution(240, -5);

        expect(dist.isEmpty, true);
      });

      test('handles negative units', () {
        final dist = balancedDistribution(-10, 30);

        expect(dist.length, 30);
        expect(dist.every((x) => x == 0), true);
      });

      test('handles 1 day', () {
        final dist = balancedDistribution(240, 1);

        expect(dist.length, 1);
        expect(dist.first, 240);
      });

      test('handles more days than units', () {
        final dist = balancedDistribution(10, 30);

        expect(dist.length, 30);
        expect(dist.reduce((a, b) => a + b), 10);

        // 10 / 30 = 0.333... → base = 0, remainder = 10
        // 10 days get 1, 20 days get 0
        expect(dist.where((x) => x == 1).length, 10);
        expect(dist.where((x) => x == 0).length, 20);

        expect(dist.take(10).every((x) => x == 1), true);
        expect(dist.skip(10).every((x) => x == 0), true);
      });
    });

    group('Mid-Month Scenarios', () {
      test('mid-month Hijri (15 days remaining)', () {
        final dist = balancedDistribution(240, 15);

        expect(dist.length, 15);
        expect(dist.reduce((a, b) => a + b), 240);

        // 240 / 15 = 16.0 → base = 16, remainder = 0
        expect(dist.every((x) => x == 16), true);
      });

      test('mid-month Gregorian (20 days remaining)', () {
        final dist = balancedDistribution(240, 20);

        expect(dist.length, 20);
        expect(dist.reduce((a, b) => a + b), 240);

        // 240 / 20 = 12.0 → base = 12, remainder = 0
        expect(dist.every((x) => x == 12), true);
      });

      test('late month start (5 days remaining)', () {
        final dist = balancedDistribution(240, 5);

        expect(dist.length, 5);
        expect(dist.reduce((a, b) => a + b), 240);

        // 240 / 5 = 48.0 → base = 48, remainder = 0
        expect(dist.every((x) => x == 48), true);
      });
    });

    group('Ahead/Behind Scenarios', () {
      test('ahead: 16 Rub completed on day 1, redistribute 224 over 29 days', () {
        final dist = balancedDistribution(224, 29);

        expect(dist.length, 29);
        expect(dist.reduce((a, b) => a + b), 224);

        // 224 / 29 = 7.724... → base = 7, remainder = 21
        // 21 days get 8, 8 days get 7
        expect(dist.where((x) => x == 8).length, 21);
        expect(dist.where((x) => x == 7).length, 8);
      });

      test('behind: 0 completed on day 1, redistribute 240 over 29 days', () {
        final dist = balancedDistribution(240, 29);

        // Same as standard 29-day distribution
        expect(dist.length, 29);
        expect(dist.reduce((a, b) => a + b), 240);

        expect(dist.where((x) => x == 9).length, 8);
        expect(dist.where((x) => x == 8).length, 21);
      });

      test('near completion: 230 completed, 10 remaining over 5 days', () {
        final dist = balancedDistribution(10, 5);

        expect(dist.length, 5);
        expect(dist.reduce((a, b) => a + b), 10);

        // 10 / 5 = 2.0 → base = 2, remainder = 0
        expect(dist.every((x) => x == 2), true);
      });
    });

    group('Invariants', () {
      test('sum always equals totalUnits', () {
        for (final units in [100, 150, 200, 240, 300]) {
          for (final days in [28, 29, 30, 31]) {
            final dist = balancedDistribution(units, days);
            expect(
              dist.reduce((a, b) => a + b),
              units,
              reason: '$units units / $days days',
            );
          }
        }
      });

      test('max - min is always <= 1', () {
        for (final units in [100, 150, 200, 240, 300]) {
          for (final days in [28, 29, 30, 31]) {
            final dist = balancedDistribution(units, days);
            if (dist.isEmpty) continue;

            final max = dist.reduce((a, b) => a > b ? a : b);
            final min = dist.reduce((a, b) => a < b ? a : b);

            expect(
              max - min,
              lessThanOrEqualTo(1),
              reason: '$units units / $days days',
            );
          }
        }
      });
    });
  });
}
