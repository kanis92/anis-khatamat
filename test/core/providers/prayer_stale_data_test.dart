import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';

import 'package:anis_khatamat/core/providers/home_dashboard_provider.dart';

void main() {
  group('Prayer Times Stale Data Bug', () {
    test('Prayer times calculated for different day cause incorrect countdown', () {
      // Simulate the ACTUAL bug: prayer times from yesterday + now from today
      final coords = Coordinates(33.5731, -7.5898); // Casablanca
      final params = CalculationMethod.muslim_world_league.getParameters();
      
      // Yesterday's prayer times
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateComponents(yesterday.year, yesterday.month, yesterday.day);
      final yesterdayPrayerTimes = PrayerTimes(coords, yesterdayDate, params);
      
      // Today's DateTime.now()
      final now = DateTime.now();
      
      // Calculate countdown using yesterday's times with today's now
      final dhuhrDiff = yesterdayPrayerTimes.dhuhr.difference(now);
      
      // This will be NEGATIVE (bug!)
      expect(dhuhrDiff.inSeconds, lessThan(0),
          reason: 'Using yesterday\'s prayer times with today\'s DateTime.now() produces negative countdown');
      
      // Now with TODAY's prayer times (correct)
      final todayDate = DateComponents(now.year, now.month, now.day);
      final todayPrayerTimes = PrayerTimes(coords, todayDate, params);
      
      // Verify that using today's prayer times works correctly
      final result = NextPrayerInfo.fromPrayerTimes(todayPrayerTimes);
      expect(result, isNotNull);
      
      // The next prayer should be in the future
      final correctDiff = result!.time.difference(now);
      expect(correctDiff.inSeconds, greaterThanOrEqualTo(-60),
          reason: 'Using fresh prayer times produces correct countdown');
    });

    test('Prayer times must be recalculated daily', () {
      final coords = Coordinates(48.8566, 2.3522); // Paris
      final params = CalculationMethod.muslim_world_league.getParameters();
      
      final now = DateTime.now();
      final today = DateComponents(now.year, now.month, now.day);
      final todayPrayers = PrayerTimes(coords, today, params);
      
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowDate = DateComponents(tomorrow.year, tomorrow.month, tomorrow.day);
      final tomorrowPrayers = PrayerTimes(coords, tomorrowDate, params);
      
      // Verify that prayer times are different between days
      expect(todayPrayers.fajr.day, isNot(equals(tomorrowPrayers.fajr.day)),
          reason: 'Prayer times must be recalculated for each day');
    });

    test('Countdown must use DateTime.now() from SAME instant as prayer times', () {
      final coords = Coordinates(33.5731, -7.5898);
      final params = CalculationMethod.muslim_world_league.getParameters();
      
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      final prayers = PrayerTimes(coords, date, params);
      
      // Simulate the provider's behavior
      final result = NextPrayerInfo.fromPrayerTimes(prayers);
      
      if (result != null) {
        // The prayer time should be on the same day OR next day (for after-Isha case)
        final dayDiff = result.time.difference(now).inDays.abs();
        expect(dayDiff, lessThanOrEqualTo(1),
            reason: 'Next prayer should be within 1 day (today or tomorrow)');
      }
    });
  });
}
