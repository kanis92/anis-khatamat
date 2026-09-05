import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/providers/home_dashboard_provider.dart';
import 'package:anis_khatamat/core/providers/prayer_times_provider.dart';
import 'package:anis_khatamat/core/services/prayer_times_freshness.dart';

void main() {
  // Deterministic coordinates (Casablanca) — same inputs for Sept 4 and Sept 5.
  final coords = Coordinates(33.5731, -7.5898);
  final params = CalculationMethod.muslim_world_league.getParameters();

  final sept4 = DateComponents(2026, 9, 4);
  final sept5 = DateComponents(2026, 9, 5);
  final sept4Local = DateTime(2026, 9, 4, 10, 0);
  final sept5Morning = DateTime(2026, 9, 5, 10, 0);

  late PrayerTimes ptSept4;
  late PrayerTimes ptSept5;

  setUp(() {
    ptSept4 = PrayerTimes(coords, sept4, params);
    ptSept5 = PrayerTimes(coords, sept5, params);
  });

  group('overnight background → resume lifecycle', () {
    test('Sept 4 calculation is stale on Sept 5 morning', () {
      final stored = PrayerTimesState(
        latitude: coords.latitude,
        longitude: coords.longitude,
        prayerTimes: ptSept4,
        calculatedDate: DateTime(2026, 9, 4),
      );

      expect(stored.isStale(sept4Local), isFalse);
      expect(stored.isStale(sept5Morning), isTrue);
      expect(
        PrayerTimesFreshness.shouldRefreshOnResume(
          calculatedDate: stored.calculatedDate,
          now: sept5Morning,
          storedMosqueName: null,
          currentMosqueName: null,
        ),
        isTrue,
        reason: 'Crossing midnight must force a resume refresh',
      );
    });

    test('resume refresh replaces Sept 4 PrayerTimes with Sept 5', () {
      expect(
        PrayerTimesFreshness.shouldRefreshOnResume(
          calculatedDate: DateTime(2026, 9, 4),
          now: sept5Morning,
        ),
        isTrue,
      );

      // What _load() produces after a stale-date resume: PrayerTimes.today
      // for the new local calendar day.
      expect(ptSept5.dhuhr.year, 2026);
      expect(ptSept5.dhuhr.month, 9);
      expect(ptSept5.dhuhr.day, 5);
      expect(ptSept5.dhuhr, isNot(ptSept4.dhuhr));
    });

    test('next prayer after resume uses Sept 5 values, never Sept 4 Dhuhr', () {
      // Stale path (bug): Sept 4 times + Sept 5 10:00 clock.
      final staleNext = NextPrayerInfo.fromPrayerTimes(
        ptSept4,
        now: sept5Morning,
      );
      expect(staleNext, isNotNull);
      expect(
        staleNext!.time,
        isNot(ptSept4.dhuhr),
        reason: 'Sept 4 Dhuhr must not remain the next-prayer instant on Sept 5',
      );

      // Fixed path: resume recalculates Sept 5, then next-prayer uses those.
      final freshNext = NextPrayerInfo.fromPrayerTimes(
        ptSept5,
        now: sept5Morning,
      );
      expect(freshNext, isNotNull);
      expect(freshNext!.time.year, 2026);
      expect(freshNext.time.month, 9);
      expect(freshNext.time.day, 5);
      expect(freshNext.time, isNot(ptSept4.dhuhr));

      if (sept5Morning.isBefore(ptSept5.dhuhr)) {
        expect(freshNext.name, 'Dhuhr');
        expect(freshNext.time, ptSept5.dhuhr);
      }

      expect(freshNext.time.difference(sept5Morning).isNegative, isFalse);
    });

    test('same-day resume does not require recalculation', () {
      expect(
        PrayerTimesFreshness.shouldRefreshOnResume(
          calculatedDate: DateTime(2026, 9, 5),
          now: sept5Morning,
        ),
        isFalse,
      );
    });

    test('mosque change on resume requires recalculation even same day', () {
      expect(
        PrayerTimesFreshness.shouldRefreshOnResume(
          calculatedDate: DateTime(2026, 9, 5),
          now: sept5Morning,
          storedMosqueName: null,
          currentMosqueName: 'Mosquée Hassan II',
        ),
        isTrue,
      );
    });
  });

  group('next-prayer selection (retained)', () {
    test('before Dhuhr on Sept 5 selects Sept 5 Dhuhr', () {
      final beforeDhuhr = DateTime(
        2026,
        9,
        5,
        ptSept5.dhuhr.hour - 3,
        ptSept5.dhuhr.minute,
      );
      final next = NextPrayerInfo.fromPrayerTimes(ptSept5, now: beforeDhuhr);
      expect(next, isNotNull);
      expect(next!.name, 'Dhuhr');
      expect(next.time, ptSept5.dhuhr);
      expect(next.time.difference(beforeDhuhr).isNegative, isFalse);
    });

    test('after Dhuhr advances to Asr', () {
      final afterDhuhr = ptSept5.dhuhr.add(const Duration(minutes: 1));
      final next = NextPrayerInfo.fromPrayerTimes(ptSept5, now: afterDhuhr);
      expect(next, isNotNull);
      expect(next!.name, 'Asr');
      expect(next.time, ptSept5.asr);
    });

    test('after Isha becomes next day Fajr with positive countdown', () {
      final afterIsha = ptSept5.isha.add(const Duration(minutes: 15));
      final next = NextPrayerInfo.fromPrayerTimes(ptSept5, now: afterIsha);
      expect(next, isNotNull);
      expect(next!.name, 'Fajr');
      expect(next.time, ptSept5.fajr.add(const Duration(days: 1)));
      expect(next.time.difference(afterIsha).isNegative, isFalse);
      expect(next.inStr, isNot(contains('-')));
    });
  });
}
