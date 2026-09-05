import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/utils/quran_reading_formatter.dart';

void main() {
  group('formatRubsAsReadingPace', () {
    test('formats 0 Rub\'', () {
      expect(formatRubsAsReadingPace(0, 'fr'), '0');
    });

    test('formats fractions of Hizb', () {
      expect(formatRubsAsReadingPace(1, 'fr'), '¼ Hizb');
      expect(formatRubsAsReadingPace(2, 'fr'), '½ Hizb');
      expect(formatRubsAsReadingPace(3, 'fr'), '¾ Hizb');
    });

    test('formats whole Hizb', () {
      expect(formatRubsAsReadingPace(4, 'fr'), '1 Hizb');
      expect(formatRubsAsReadingPace(8, 'fr'), '2 Hizbs');
      expect(formatRubsAsReadingPace(12, 'fr'), '3 Hizbs');
    });

    test('formats Hizb + fraction', () {
      expect(formatRubsAsReadingPace(5, 'fr'), '1 Hizb + ¼ Hizb');
      expect(formatRubsAsReadingPace(6, 'fr'), '1 Hizb + ½ Hizb');
      expect(formatRubsAsReadingPace(7, 'fr'), '1 Hizb + ¾ Hizb');
      expect(formatRubsAsReadingPace(9, 'fr'), '2 Hizbs + ¼ Hizb');
      expect(formatRubsAsReadingPace(10, 'fr'), '2 Hizbs + ½ Hizb');
    });

    test('never uses decimals', () {
      for (int i = 1; i <= 240; i++) {
        final result = formatRubsAsReadingPace(i, 'fr');
        expect(result.contains('.'), false);
        expect(result.contains(','), false);
      }
    });

    test('formats typical daily allocations', () {
      // 240/30 = 8 Rub' → 2 Hizb
      expect(formatRubsAsReadingPace(8, 'fr'), '2 Hizbs');

      // 240/29 = 8.27... → some days 9, some 8
      expect(formatRubsAsReadingPace(9, 'fr'), '2 Hizbs + ¼ Hizb');
      expect(formatRubsAsReadingPace(8, 'fr'), '2 Hizbs');

      // 240/31 = 7.74... → some days 8, some 7
      expect(formatRubsAsReadingPace(7, 'fr'), '1 Hizb + ¾ Hizb');
    });
  });

  group('formatDailyPace', () {
    test('formats pace with Rub\' count and readable form', () {
      expect(formatDailyPace(4, 'fr'), '4 Rub\' / jour (1 Hizb)');
      expect(formatDailyPace(8, 'fr'), '8 Rub\' / jour (2 Hizbs)');
      expect(formatDailyPace(9, 'fr'), '9 Rub\' / jour (2 Hizbs + ¼ Hizb)');
    });
  });
}
