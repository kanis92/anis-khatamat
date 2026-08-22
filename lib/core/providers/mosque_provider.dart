import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mosque.dart';
import '../services/mosque_service.dart';

final mosqueServiceProvider = Provider<MosqueService>((ref) => MosqueService());

const _selectedMosqueKey = 'prayer_selected_mosque';

/// Mosquées à proximité de la position de l'utilisateur
final nearbyMosquesProvider =
    FutureProvider.family<List<Mosque>, ({double lat, double lng})>((
      ref,
      coords,
    ) async {
      final service = ref.watch(mosqueServiceProvider);
      return service.getNearbyMosques(coords.lat, coords.lng);
    });

/// Mosquée sélectionnée par l'utilisateur (pour afficher ses horaires)
/// Si null, on utilise la position GPS de l'utilisateur
final selectedMosqueProvider =
    StateNotifierProvider<SelectedMosqueNotifier, Mosque?>(
      (ref) => SelectedMosqueNotifier(),
    );

class SelectedMosqueNotifier extends StateNotifier<Mosque?> {
  SelectedMosqueNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_selectedMosqueKey);
    if (json == null) return;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      state = Mosque(
        id: map['id'] as String,
        name: map['name'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        address: map['address'] as String?,
        mawaqitUrl: map['mawaqitUrl'] as String?,
      );
    } catch (_) {
      await prefs.remove(_selectedMosqueKey);
    }
  }

  Future<void> setMosque(Mosque? mosque) async {
    state = mosque;
    final prefs = await SharedPreferences.getInstance();
    if (mosque != null) {
      await prefs.setString(
        _selectedMosqueKey,
        jsonEncode({
          'id': mosque.id,
          'name': mosque.name,
          'latitude': mosque.latitude,
          'longitude': mosque.longitude,
          'address': mosque.address,
          'mawaqitUrl': mosque.mawaqitUrl,
        }),
      );
    } else {
      await prefs.remove(_selectedMosqueKey);
    }
  }
}
