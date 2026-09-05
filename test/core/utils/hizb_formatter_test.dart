import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/utils/hizb_formatter.dart';

void main() {
  group('Hizb Formatter', () {
    group('formatRubsAsHizb', () {
      test('formats 0 Rub\' as 0', () {
        expect(formatRubsAsHizb(0), '0');
      });

      test('formats quarter Hizb fractions', () {
        expect(formatRubsAsHizb(1), '¼');
        expect(formatRubsAsHizb(2), '½');
        expect(formatRubsAsHizb(3), '¾');
      });

      test('formats full Hizb', () {
        expect(formatRubsAsHizb(4), '1');
        expect(formatRubsAsHizb(8), '2');
        expect(formatRubsAsHizb(12), '3');
      });

      test('formats Hizb with fractions', () {
        expect(formatRubsAsHizb(5), '1¼');
        expect(formatRubsAsHizb(6), '1½');
        expect(formatRubsAsHizb(7), '1¾');
        expect(formatRubsAsHizb(9), '2¼');
        expect(formatRubsAsHizb(10), '2½');
      });

      test('formats 60 Hizb (240 Rub\')', () {
        expect(formatRubsAsHizb(240), '60');
      });

      test('formats partial Quran progress', () {
        expect(formatRubsAsHizb(49), '12¼');
        expect(formatRubsAsHizb(121), '30¼');
        expect(formatRubsAsHizb(180), '45');
      });
    });

    group('formatProgressAsHizb', () {
      test('formats 0 / 240 Rub\' as 0 / 60 Hizb', () {
        expect(formatProgressAsHizb(0, 240), '0 / 60 Hizb');
      });

      test('formats 4 / 240 Rub\' as 1 / 60 Hizb', () {
        expect(formatProgressAsHizb(4, 240), '1 / 60 Hizb');
      });

      test('formats 49 / 240 Rub\' as 12¼ / 60 Hizb', () {
        expect(formatProgressAsHizb(49, 240), '12¼ / 60 Hizb');
      });

      test('formats 120 / 240 Rub\' as 30 / 60 Hizb', () {
        expect(formatProgressAsHizb(120, 240), '30 / 60 Hizb');
      });

      test('formats 240 / 240 Rub\' as 60 / 60 Hizb', () {
        expect(formatProgressAsHizb(240, 240), '60 / 60 Hizb');
      });

      test('formats partial Hizb progress', () {
        expect(formatProgressAsHizb(1, 240), '¼ / 60 Hizb');
        expect(formatProgressAsHizb(2, 240), '½ / 60 Hizb');
        expect(formatProgressAsHizb(3, 240), '¾ / 60 Hizb');
      });

      test('never uses decimal approximations', () {
        // Ces valeurs doivent rester fractions exactes
        final result1 = formatProgressAsHizb(49, 240);
        expect(result1, '12¼ / 60 Hizb');
        expect(result1, isNot(contains('12.25')));
        
        final result2 = formatProgressAsHizb(2, 240);
        expect(result2, '½ / 60 Hizb');
        expect(result2, isNot(contains('0.5')));
      });
    });
  });
}
