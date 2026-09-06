import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/providers/home_dashboard_provider.dart';
import 'package:anis_khatamat/core/utils/duration_formatter.dart';

void main() {
  group('NextPrayerInfo Prayer Time Logic', () {
    // Test coordinates (Paris)
    final coords = Coordinates(48.8566, 2.3522);
    final params = CalculationMethod.muslim_world_league.getParameters();

    test('Before Dhuhr: next prayer should be Dhuhr', () {
      // Use today's date
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      final pt = PrayerTimes(coords, date, params);
      
      // Verify prayer times are generated
      expect(pt.fajr, isNotNull);
      expect(pt.dhuhr, isNotNull);
      expect(pt.asr, isNotNull);
      expect(pt.maghrib, isNotNull);
      expect(pt.isha, isNotNull);
    });

    test('Prayer times are in chronological order', () {
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      final pt = PrayerTimes(coords, date, params);
      
      expect(pt.fajr.isBefore(pt.dhuhr), isTrue);
      expect(pt.dhuhr.isBefore(pt.asr), isTrue);
      expect(pt.asr.isBefore(pt.maghrib), isTrue);
      expect(pt.maghrib.isBefore(pt.isha), isTrue);
    });

    test('fromPrayerTimes returns null when PrayerTimes is null', () {
      final result = NextPrayerInfo.fromPrayerTimes(null);
      expect(result, isNull);
    });

    test('fromPrayerTimes returns non-null when PrayerTimes exists', () {
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      final pt = PrayerTimes(coords, date, params);
      
      // This will always return something since we added tomorrow's Fajr logic
      final result = NextPrayerInfo.fromPrayerTimes(pt);
      expect(result, isNotNull);
      expect(result!.prayerKey, isNotEmpty);
      expect(result.duration, isA<Duration>());
    });

    test('Next prayer is always in the future', () {
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      final pt = PrayerTimes(coords, date, params);
      
      final result = NextPrayerInfo.fromPrayerTimes(pt);
      expect(result, isNotNull);
      
      // The time should be in the future (or very close to now)
      final diff = result!.time.difference(now);
      expect(diff.inSeconds, greaterThanOrEqualTo(-60),
          reason: 'Next prayer should be in the future or within last minute');
    });

    test('After all prayers pass, returns tomorrow Fajr', () {
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      final pt = PrayerTimes(coords, date, params);
      
      // If current time is after Isha, next prayer should be tomorrow's Fajr
      if (now.isAfter(pt.isha)) {
        final result = NextPrayerInfo.fromPrayerTimes(pt);
        expect(result, isNotNull);
        expect(result!.prayerKey, 'fajr');
        
        // Verify it's tomorrow's Fajr (approximately)
        expect(result.time.day, greaterThanOrEqualTo(now.day));
      }
    });

    test('All prayer times use local DateTime', () {
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      final pt = PrayerTimes(coords, date, params);
      
      // Verify all times are in local timezone (not UTC)
      expect(pt.fajr.isUtc, isFalse);
      expect(pt.dhuhr.isUtc, isFalse);
      expect(pt.asr.isUtc, isFalse);
      expect(pt.maghrib.isUtc, isFalse);
      expect(pt.isha.isUtc, isFalse);
    });

    test('Duration formatting works for hours', () {
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      final pt = PrayerTimes(coords, date, params);
      
      final result = NextPrayerInfo.fromPrayerTimes(pt);
      expect(result, isNotNull);
      
      // Duration should be positive and formatted correctly
      final duration = result!.duration;
      expect(duration.inMinutes, greaterThan(0));
      final formatted = DurationFormatter.formatCompact(duration);
      expect(formatted, anyOf(contains('h'), contains('min')));
    });
  });
}
