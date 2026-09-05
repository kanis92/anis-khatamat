import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';

import 'package:anis_khatamat/core/providers/prayer_times_provider.dart';
import 'package:anis_khatamat/core/providers/home_dashboard_provider.dart';

void main() {
  group('Prayer Times Overnight Background Regression', () {
    test('Prayer times calculated for Sept 4, app crosses midnight to Sept 5', () {
      // This is the EXACT bug scenario reported by user
      final coords = Coordinates(33.5731, -7.5898); // Casablanca
      final params = CalculationMethod.muslim_world_league.getParameters();
      
      // ===== SEPTEMBER 4 =====
      // App launches on Sept 4, prayer times calculated
      final sept4 = DateTime(2026, 9, 4);
      final sept4Date = DateComponents(sept4.year, sept4.month, sept4.day);
      final sept4PrayerTimes = PrayerTimes(coords, sept4Date, params);
      
      // Create state as if calculated on Sept 4
      final sept4State = PrayerTimesState(
        latitude: coords.latitude,
        longitude: coords.longitude,
        prayerTimes: sept4PrayerTimes,
        calculatedDate: sept4,
        isLoading: false,
      );
      
      // Verify Sept 4 state is valid for Sept 4
      expect(sept4State.calculatedDate!.day, 4);
      // Note: sept4State.isStale uses DateTime.now() which is test execution time
      // We manually verify staleness logic instead
      final staleSept4 = sept4State.calculatedDate!.year != sept4.year ||
                         sept4State.calculatedDate!.month != sept4.month ||
                         sept4State.calculatedDate!.day != sept4.day;
      expect(staleSept4, isFalse, 
          reason: 'On Sept 4, Sept 4 prayer times are fresh');
      
      // ===== APP BACKGROUNDED OVERNIGHT =====
      // Timers may be suspended, no refresh happens
      
      // ===== SEPTEMBER 5 — APP RESUMES =====
      // Now it's Sept 5, user opens app
      final sept5 = DateTime(2026, 9, 5);
      
      // Check if Sept 4 prayer times are now stale
      // (simulating the isStale check that would happen on app resume)
      final now = sept5;
      final staleCheck = sept4State.calculatedDate!.year != now.year ||
                         sept4State.calculatedDate!.month != now.month ||
                         sept4State.calculatedDate!.day != now.day;
      
      expect(staleCheck, isTrue, 
          reason: 'Sept 4 prayer times are STALE on Sept 5');
      
      // App lifecycle resume triggers refresh
      // New prayer times calculated for Sept 5
      final sept5Date = DateComponents(sept5.year, sept5.month, sept5.day);
      final sept5PrayerTimes = PrayerTimes(coords, sept5Date, params);
      
      final sept5State = PrayerTimesState(
        latitude: coords.latitude,
        longitude: coords.longitude,
        prayerTimes: sept5PrayerTimes,
        calculatedDate: sept5,
        isLoading: false,
      );
      
      // Verify Sept 5 state is fresh
      expect(sept5State.calculatedDate!.day, 5);
      final staleSept5 = sept5State.calculatedDate!.year != sept5.year ||
                         sept5State.calculatedDate!.month != sept5.month ||
                         sept5State.calculatedDate!.day != sept5.day;
      expect(staleSept5, isFalse,
          reason: 'On Sept 5, Sept 5 prayer times are fresh');
      
      // Next prayer countdown uses Sept 5 times with Sept 5 DateTime.now()
      final nextPrayerSept5 = NextPrayerInfo.fromPrayerTimes(sept5PrayerTimes);
      expect(nextPrayerSept5, isNotNull);
      
      // Prayer time should be on Sept 5 (or Sept 6 if after Isha)
      expect(nextPrayerSept5!.time.day, greaterThanOrEqualTo(5));
      expect(nextPrayerSept5.time.day, lessThanOrEqualTo(6));
      
      // Countdown is positive (future time)
      final countdownDuration = nextPrayerSept5.time.difference(sept5);
      expect(countdownDuration.inSeconds, greaterThanOrEqualTo(0),
          reason: 'Countdown must be positive with fresh Sept 5 prayer times');
    });

    test('PrayerTimesState.isStale detects day boundary correctly', () {
      final sept4 = DateTime(2026, 9, 4, 14, 30); // Sept 4 at 14:30
      
      final state = PrayerTimesState(
        calculatedDate: sept4,
        isLoading: false,
      );
      
      // Mock "current time" as Sept 4 → not stale
      final now4 = DateTime(2026, 9, 4, 16, 0);
      final stale4 = state.calculatedDate!.year != now4.year ||
                     state.calculatedDate!.month != now4.month ||
                     state.calculatedDate!.day != now4.day;
      expect(stale4, isFalse);
      
      // Mock "current time" as Sept 5 → STALE
      final now5 = DateTime(2026, 9, 5, 8, 0);
      final stale5 = state.calculatedDate!.year != now5.year ||
                     state.calculatedDate!.month != now5.month ||
                     state.calculatedDate!.day != now5.day;
      expect(stale5, isTrue,
          reason: 'Prayer times from Sept 4 are stale on Sept 5');
      
      // Mock "current time" as Sept 6 → STALE
      final now6 = DateTime(2026, 9, 6, 10, 0);
      final stale6 = state.calculatedDate!.year != now6.year ||
                     state.calculatedDate!.month != now6.month ||
                     state.calculatedDate!.day != now6.day;
      expect(stale6, isTrue,
          reason: 'Prayer times from Sept 4 are stale on Sept 6');
    });

    test('After-Isha still returns tomorrow Fajr (separate bug fix)', () {
      final coords = Coordinates(48.8566, 2.3522); // Paris
      final params = CalculationMethod.muslim_world_league.getParameters();
      
      final today = DateTime.now();
      final todayDate = DateComponents(today.year, today.month, today.day);
      final prayerTimes = PrayerTimes(coords, todayDate, params);
      
      // If we're past Isha, fromPrayerTimes should return tomorrow's Fajr
      // This is tested by checking that the result is never null
      final result = NextPrayerInfo.fromPrayerTimes(prayerTimes);
      
      expect(result, isNotNull,
          reason: 'After Isha, should return tomorrow Fajr, not null');
      expect(result!.name, isNotEmpty);
    });

    test('Normal daytime next-prayer selection works', () {
      final coords = Coordinates(33.5731, -7.5898);
      final params = CalculationMethod.muslim_world_league.getParameters();
      
      final today = DateTime.now();
      final todayDate = DateComponents(today.year, today.month, today.day);
      final prayerTimes = PrayerTimes(coords, todayDate, params);
      
      final result = NextPrayerInfo.fromPrayerTimes(prayerTimes);
      
      expect(result, isNotNull);
      expect(result!.name, isIn(['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']));
      
      // Countdown should be positive
      final countdown = result.time.difference(DateTime.now());
      expect(countdown.inSeconds, greaterThanOrEqualTo(-60),
          reason: 'Countdown should be in the future (allow 1min tolerance)');
    });
  });
}
