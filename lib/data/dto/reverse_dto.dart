import 'package:vm_first_app/domain/domain.dart';
import 'package:vm_first_app/domain/entities/reverse_entity.dart';
import 'package:vm_first_app/domain/entities/place_entity.dart';
class ReverseDtoResponse{
  final double? lat;
  final double? lng;
  final String? partnerCode;
  final String? refId;
  final double? distance;
  final String? address;
  final String? name;
  final String? display;
  final List<BoundaryEntity>? boundaries;
  final List<String>? categories;
  final List<EntryPointEntity>? entryPoints;
  final dynamic dataOld;
  final dynamic dataNew;

  ReverseDtoResponse({
    this.lat,
    this.lng,
    this.partnerCode,
    this.refId,
    this.distance,
    this.address,
    this.name,
    this.display,
    this.boundaries,
    this.categories,
    this.entryPoints,
    this.dataOld,
    this.dataNew,
  });

  factory ReverseDtoResponse.fromJson(Map<String, dynamic> json) => ReverseDtoResponse(
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    partnerCode: json['partner_code'] as String?,
    refId: json['ref_id'] as String?,
    distance: (json['distance'] as num?)?.toDouble(),
    address: json['address'] as String?,
    name: json['name'] as String?,
    display: json['display'] as String?,
    boundaries: (json['boundaries'] as List<dynamic>?)?.map((e) => BoundaryEntity.fromJson(e as Map<String, dynamic>)).toList(),
    categories: (json['categories'] as List<dynamic>?)?.map((e) => e as String).toList(),
    entryPoints: (json['entry_points'] as List<dynamic>?)?.map((e) => EntryPointEntity.fromJson(e as Map<String, dynamic>)).toList(),
    dataOld: json['data_old'],
    dataNew: json['data_new'],
  );
}

extension ReverseDtoResponseX on ReverseDtoResponse{
  ReverseEntity toEntity() => ReverseEntity(
    lat: lat ?? 0.0,
    lng: lng ?? 0.0,
    partnerCode: partnerCode,
    refId: refId ?? '',
    distance: distance ?? 0.0,
    address: address ?? '',
    name: name ?? '',
    display: display ?? '',
    boundaries: boundaries ?? [],
    categories: categories ?? [],
    entryPoints: entryPoints ?? [],
    dataOld: dataOld,
    dataNew: dataNew,
  );
}