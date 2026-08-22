import 'package:equatable/equatable.dart';

/// Mosquée issue d'OpenStreetMap (Overpass API)
class Mosque extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? mawaqitUrl;

  const Mosque({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.mawaqitUrl,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    latitude,
    longitude,
    address,
    mawaqitUrl,
  ];
}
