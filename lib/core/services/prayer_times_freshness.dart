/// Pure freshness rules for prayer-time recalculation.
///
/// Timers may be suspended while the app is backgrounded. Resume must
/// therefore decide, from stored calculation metadata + the current local
/// calendar date, whether PrayerTimes are stale.
class PrayerTimesFreshness {
  const PrayerTimesFreshness._();

  /// True when [calculatedDate] is missing or not the same local calendar day
  /// as [now].
  static bool isDateStale(DateTime? calculatedDate, DateTime now) {
    if (calculatedDate == null) return true;
    return calculatedDate.year != now.year ||
        calculatedDate.month != now.month ||
        calculatedDate.day != now.day;
  }

  /// True when the mosque used for calculation changed while backgrounded.
  static bool mosqueInputChanged({
    required String? storedMosqueName,
    required String? currentMosqueName,
  }) {
    return storedMosqueName != currentMosqueName;
  }

  /// Resume should recalculate only when the stored result cannot be trusted
  /// for the current local day or calculation inputs.
  static bool shouldRefreshOnResume({
    required DateTime? calculatedDate,
    required DateTime now,
    String? storedMosqueName,
    String? currentMosqueName,
  }) {
    if (isDateStale(calculatedDate, now)) return true;
    return mosqueInputChanged(
      storedMosqueName: storedMosqueName,
      currentMosqueName: currentMosqueName,
    );
  }
}
