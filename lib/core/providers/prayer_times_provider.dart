import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:intl/intl.dart';

import 'prayer_calculation_provider.dart';
import 'mosque_provider.dart';

/// État des horaires de prière
class PrayerTimesState {
  final double? latitude;
  final double? longitude;
  final PrayerTimes? prayerTimes;
  final String? error;
  final bool isLoading;
  
  /// Date for which prayer times were calculated (local date)
  final DateTime? calculatedDate;

  /// Mosquée sélectionnée (si horaires affichés pour une mosquée)
  final String? selectedMosqueName;

  /// Position de l'utilisateur (pour recherche mosquées à proximité)
  final double? userLatitude;
  final double? userLongitude;

  const PrayerTimesState({
    this.latitude,
    this.longitude,
    this.prayerTimes,
    this.error,
    this.isLoading = false,
    this.calculatedDate,
    this.selectedMosqueName,
    this.userLatitude,
    this.userLongitude,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasError => error != null && error!.isNotEmpty;
  bool get isMosqueSelected => selectedMosqueName != null;
  bool get hasUserPosition => userLatitude != null && userLongitude != null;
  
  /// Check if prayer times are stale (calculated for a different day)
  bool get isStale {
    if (calculatedDate == null) return true;
    final now = DateTime.now();
    return calculatedDate!.year != now.year ||
           calculatedDate!.month != now.month ||
           calculatedDate!.day != now.day;
  }
}

/// Provider pour les horaires de prière basés sur la position GPS
final prayerTimesProvider =
    StateNotifierProvider<PrayerTimesNotifier, AsyncValue<PrayerTimesState>>(
      (ref) => PrayerTimesNotifier(ref),
    );

class PrayerTimesNotifier extends StateNotifier<AsyncValue<PrayerTimesState>> 
    with WidgetsBindingObserver {
  PrayerTimesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
    // Only setup auto-refresh in production/profile mode, not in debug tests
    if (kReleaseMode || kProfileMode) {
      _setupAutoRefresh();
    }
    // Listen to app lifecycle for resume detection
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref _ref;
  Timer? _refreshTimer;
  Timer? _midnightTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app resumes from background, check if prayer times are stale
    if (state == AppLifecycleState.resumed) {
      final currentState = this.state.valueOrNull;
      if (currentState != null && currentState.isStale) {
        // Prayer times were calculated for a different day
        // Refresh immediately to ensure correct next-prayer countdown
        _load();
      }
    }
  }

  void _setupAutoRefresh() {
    // Refresh prayer times at midnight and every hour
    // This prevents stale prayer times from causing incorrect countdowns
    // Note: Timers may be suspended on mobile when app is backgrounded
    // App resume lifecycle check provides additional safety
    _refreshTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _load();
    });
    
    // Also schedule a refresh at next midnight
    _scheduleNextMidnightRefresh();
  }

  void _scheduleNextMidnightRefresh() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);
    
    _midnightTimer = Timer(durationUntilMidnight, () {
      _load();
      _scheduleNextMidnightRefresh(); // Schedule next midnight
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = AsyncValue.data(
          PrayerTimesState(
            error: 'Location services disabled',
            isLoading: false,
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        state = AsyncValue.data(
          PrayerTimesState(
            error: 'Location permanently denied',
            isLoading: false,
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        state = AsyncValue.data(
          PrayerTimesState(error: 'Location denied', isLoading: false),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final selectedMosque = _ref.read(selectedMosqueProvider);
      final double lat;
      final double lon;
      final String? mosqueName;

      if (selectedMosque != null) {
        lat = selectedMosque.latitude;
        lon = selectedMosque.longitude;
        mosqueName = selectedMosque.name;
      } else {
        lat = position.latitude;
        lon = position.longitude;
        mosqueName = null;
      }

      final coordinates = Coordinates(lat, lon);
      final method = _ref.read(prayerCalculationMethodProvider);
      final params = method.parameters;

      final now = DateTime.now();
      final prayerTimes = PrayerTimes.today(coordinates, params);

      state = AsyncValue.data(
        PrayerTimesState(
          latitude: lat,
          longitude: lon,
          prayerTimes: prayerTimes,
          isLoading: false,
          calculatedDate: DateTime(now.year, now.month, now.day),
          selectedMosqueName: mosqueName,
          userLatitude: position.latitude,
          userLongitude: position.longitude,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        PrayerTimesState(error: e.toString(), isLoading: false),
      );
    }
  }

  Future<void> retry() => _load();
}

/// Heure actuelle (rafraîchie chaque seconde)
final currentTimeProvider = StreamProvider<String>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return DateFormat.Hm().format(DateTime.now());
  });
});

/// Date grégorienne formatée (locale du device)
String formatGregorianDate(String locale) {
  return DateFormat.yMMMMd(locale).format(DateTime.now());
}

/// Date hijri formatée
String formatHijriDate() {
  final hijri = HijriDateTime.now();
  final months = [
    'Muharram',
    'Safar',
    'Rabi I',
    'Rabi II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];
  return '${hijri.day} ${months[hijri.month - 1]} ${hijri.year} H';
}
