import 'place_entity.dart';
import 'package:equatable/equatable.dart';

class ReverseEntity extends Equatable {
  final double lat;
  final double lng;
  final String? partnerCode;
  final String refId;
  final double distance;
  final String address;
  final String name;
  final String display;
  final List<BoundaryEntity> boundaries;
  final List<String> categories;
  final List<EntryPointEntity> entryPoints;
  final dynamic dataOld;
  final dynamic dataNew;

  const ReverseEntity({
    required this.lat,
    required this.lng,
    this.partnerCode,
    required this.refId,
    required this.distance,
    required this.address,
    required this.name,
    required this.display,
    required this.boundaries,
    required this.categories,
    required this.entryPoints,
    this.dataOld,
    this.dataNew,
  });

  factory ReverseEntity.fromJson(Map<String, dynamic> json) => ReverseEntity(
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    partnerCode: json['partner_code'],
    refId: json['ref_id'] ?? '',
    distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    address: json['address'] ?? '',
    name: json['name'] ?? '',
    display: json['display'] ?? '',
    boundaries: (json['boundaries'] as List<dynamic>?)
        ?.map((item) => BoundaryEntity.fromJson(item as Map<String, dynamic>))
        .toList() ?? [],
    categories: (json['categories'] as List<dynamic>?)
        ?.map((item) => item as String)
        .toList() ?? [],
    entryPoints: (json['entry_points'] as List<dynamic>?)
        ?.map((item) => EntryPointEntity.fromJson(item as Map<String, dynamic>))
        .toList() ?? [],
    dataOld: json['data_old'],
    dataNew: json['data_new'],
  );

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'partner_code': partnerCode,
    'ref_id': refId,
    'distance': distance,
    'address': address,
    'name': name,
    'display': display,
    'boundaries': boundaries.map((b) => b.toJson()).toList(),
    'categories': categories,
    'entry_points': entryPoints.map((e) => e.toJson()).toList(),
    'data_old': dataOld,
    'data_new': dataNew,
  };

  @override
  List<Object> get props => [refId, lat, lng];
}