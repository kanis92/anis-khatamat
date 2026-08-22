import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'prayer_calculation_method';

/// Méthodes de calcul des horaires de prière
enum PrayerCalculationMethod {
  /// Ligue Islamique Mondiale (18° Fajr, 17° Isha) — standard international
  muslimWorldLeague,

  /// France UOIF (12° Fajr, 12° Isha) — Union des Organisations Islamiques de France
  franceUoif,

  /// Autorité égyptienne (19.5° Fajr, 17.5° Isha)
  egyptian,
}

extension PrayerCalculationMethodExt on PrayerCalculationMethod {
  String get storageKey {
    switch (this) {
      case PrayerCalculationMethod.muslimWorldLeague:
        return 'muslim_world_league';
      case PrayerCalculationMethod.franceUoif:
        return 'france_uoif';
      case PrayerCalculationMethod.egyptian:
        return 'egyptian';
    }
  }

  String get displayName {
    switch (this) {
      case PrayerCalculationMethod.muslimWorldLeague:
        return 'Ligue Islamique Mondiale';
      case PrayerCalculationMethod.franceUoif:
        return 'France (UOIF)';
      case PrayerCalculationMethod.egyptian:
        return 'Autorité égyptienne';
    }
  }

  CalculationParameters get parameters {
    switch (this) {
      case PrayerCalculationMethod.muslimWorldLeague:
        final p = CalculationMethod.muslim_world_league.getParameters();
        p.madhab = Madhab.shafi;
        return p;
      case PrayerCalculationMethod.franceUoif:
        // UOIF : Fajr 12°, Isha 12°
        final p = CalculationParameters(
          method: CalculationMethod.other,
          fajrAngle: 12,
          ishaAngle: 12,
          madhab: Madhab.shafi,
        );
        return p;
      case PrayerCalculationMethod.egyptian:
        final p = CalculationMethod.egyptian.getParameters();
        p.madhab = Madhab.shafi;
        return p;
    }
  }
}

PrayerCalculationMethod _fromStorage(String? key) {
  switch (key) {
    case 'france_uoif':
      return PrayerCalculationMethod.franceUoif;
    case 'egyptian':
      return PrayerCalculationMethod.egyptian;
    default:
      return PrayerCalculationMethod.muslimWorldLeague;
  }
}

final prayerCalculationMethodProvider = StateNotifierProvider<
  PrayerCalculationMethodNotifier,
  PrayerCalculationMethod
>((ref) => PrayerCalculationMethodNotifier());

class PrayerCalculationMethodNotifier
    extends StateNotifier<PrayerCalculationMethod> {
  PrayerCalculationMethodNotifier()
    : super(PrayerCalculationMethod.muslimWorldLeague) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_key);
    if (key != null) {
      state = _fromStorage(key);
    }
  }

  Future<void> setMethod(PrayerCalculationMethod method) async {
    state = method;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, method.storageKey);
  }
}
