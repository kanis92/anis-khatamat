import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/mosque.dart';

/// Service pour récupérer les mosquées à proximité via OpenStreetMap (Overpass API)
/// Données communautaires, gratuites, sans clé API
class MosqueService {
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Rayon de recherche en mètres (5 km)
  static const int searchRadiusMeters = 5000;

  /// Récupère les mosquées à proximité des coordonnées données
  Future<List<Mosque>> getNearbyMosques(
    double latitude,
    double longitude,
  ) async {
    // Requête Overpass : nodes et ways (mosquées) dans un rayon
    // religion=muslim OU building=mosque
    const query = '''
[out:json];
(
  node(around:$searchRadiusMeters,%LAT%,%LNG%)["amenity"="place_of_worship"]["religion"="muslim"];
  way(around:$searchRadiusMeters,%LAT%,%LNG%)["amenity"="place_of_worship"]["religion"="muslim"];
  way(around:$searchRadiusMeters,%LAT%,%LNG%)["building"="mosque"];
);
out center body;
''';

    final q = query
        .replaceAll('%LAT%', latitude.toString())
        .replaceAll('%LNG%', longitude.toString())
        .replaceAll('\n', '')
        .replaceAll('  ', ' ');

    final response = await http
        .post(Uri.parse(_overpassUrl), body: q)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Délai dépassé'),
        );

    if (response.statusCode != 200) {
      throw Exception('Erreur réseau: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? [];

    final mosques = <Mosque>[];
    final seenIds = <String>{};

    for (final el in elements) {
      final map = el as Map<String, dynamic>;
      final type = map['type'] as String?;
      final id = map['id']?.toString() ?? '';

      double lat;
      double lon;

      if (type == 'node') {
        lat = (map['lat'] as num?)?.toDouble() ?? 0;
        lon = (map['lon'] as num?)?.toDouble() ?? 0;
      } else if (type == 'way') {
        final center = map['center'] as Map<String, dynamic>?;
        if (center == null) continue;
        lat = (center['lat'] as num?)?.toDouble() ?? 0;
        lon = (center['lon'] as num?)?.toDouble() ?? 0;
      } else {
        continue;
      }

      final tags = map['tags'] as Map<String, dynamic>? ?? {};
      final name =
          _getTag(tags, 'name') ?? _getTag(tags, 'name:fr') ?? 'Mosquée';
      final address = _buildAddress(tags);

      final uniqueId = '${type}_$id';
      if (seenIds.contains(uniqueId)) continue;
      seenIds.add(uniqueId);

      final mawaqitUrl = _getTag(tags, 'service_times:url');

      mosques.add(
        Mosque(
          id: uniqueId,
          name: name,
          latitude: lat,
          longitude: lon,
          address: address.isNotEmpty ? address : null,
          mawaqitUrl: mawaqitUrl,
        ),
      );
    }

    // Trier par distance (approximative)
    mosques.sort((a, b) {
      final distA = _distance(latitude, longitude, a.latitude, a.longitude);
      final distB = _distance(latitude, longitude, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    return mosques;
  }

  String? _getTag(Map<String, dynamic> tags, String key) {
    final v = tags[key];
    return v?.toString();
  }

  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final street =
        _getTag(tags, 'addr:street') ?? _getTag(tags, 'contact:street');
    final number =
        _getTag(tags, 'addr:housenumber') ??
        _getTag(tags, 'contact:housenumber');
    final city = _getTag(tags, 'addr:city') ?? _getTag(tags, 'contact:city');
    final postcode =
        _getTag(tags, 'addr:postcode') ?? _getTag(tags, 'contact:postcode');

    if (number != null && street != null) {
      parts.add('$number $street');
    } else if (street != null) {
      parts.add(street);
    }
    if (postcode != null && city != null) {
      parts.add('$postcode $city');
    } else if (city != null) {
      parts.add(city);
    }
    return parts.join(', ');
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }
}
