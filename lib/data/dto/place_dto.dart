import 'package:vm_first_app/domain/entities/place_entity.dart';

class PlaceDto {
  final String? focus;
  final String text;
  final int? displayType;
  final int? cityId;
  final int? distId;
  final int? wardId;
  final String? circleCenter;
  final int? circleRadius;
  final String? cats;
  final String? layers;

  PlaceDto({
    this.focus,
    required this.text,
    this.displayType,
    this.cityId,
    this.distId,
    this.wardId,
    this.circleCenter,
    this.circleRadius,
    this.cats,
    this.layers,
  });

  Map<String, dynamic> toJson() {
    return {
      if (focus != null) 'focus': focus,
      'text': text,
      if (displayType != null) 'displayType': displayType,
      if (cityId != null) 'cityId': cityId,
      if (distId != null) 'distId': distId,
      if (wardId != null) 'wardId': wardId,
      if (circleCenter != null) 'circleCenter': circleCenter,
      if (circleRadius != null) 'circleRadius': circleRadius,
      if (cats != null) 'cats': cats,
      if (layers != null) 'layers': layers,
    };
  }
}

class BoundaryDto {
  final int type;
  final int id;
  final String name;
  final String prefix;
  final String fullName;

  BoundaryDto({
    required this.type,
    required this.id,
    required this.name,
    required this.prefix,
    required this.fullName,
  });

  factory BoundaryDto.fromJson(Map<String, dynamic> json) => BoundaryDto(
    type: json['type'],
    id: json['id'],
    name: json['name'],
    prefix: json['prefix'],
    fullName: json['full_name'],
  );
}

class EntryPointDto {
  final int refId;
  final String name;

  EntryPointDto({
    required this.refId,
    required this.name,
  });

  factory EntryPointDto.fromJson(Map<String, dynamic> json) => EntryPointDto(
    refId: json['ref_id'],
    name: json['name'],
  );
}

class PlaceDetailsDto {
  final String display;
  final String name;
  final String hsNum;
  final String street;
  final String address;
  final int cityId;
  final String city;
  final int districtId;
  final String district;
  final int wardId;
  final String ward;
  final double lat;
  final double lng;

  PlaceDetailsDto({
    required this.display,
    required this.name,
    required this.hsNum,
    required this.street,
    required this.address,
    required this.cityId,
    required this.city,
    required this.districtId,
    required this.district,
    required this.wardId,
    required this.ward,
    required this.lat,
    required this.lng,
  });


}

class PlaceDtoResponse {
  final String? refId;
  final double? distance;
  final String? address;
  final String? name;
  final String? display;
  final List<BoundaryDto?>? boundaries;
  final List<String?>? categories;
  final List<EntryPointDto?>? entryPoints;

  PlaceDtoResponse({
    this.refId,
    this.distance,
    this.address,
    this.name,
    this.display,
    this.boundaries,
    this.categories,
    this.entryPoints,
  });

  factory PlaceDtoResponse.fromJson(Map<String, dynamic> json) => PlaceDtoResponse(
    refId: json['ref_id'] as String?,
    distance: json['distance'] as double?,
    address: json['address'] as String?,
    name: json['name'] as String?,
    display: json['display'] as String?,
    boundaries: (json['boundaries'] as List<dynamic>)
        .map((item) => BoundaryDto.fromJson(item as Map<String, dynamic>))
        .toList(),
    categories: (json['categories'] as List<dynamic>).map((item) => item as String).toList(),
    entryPoints: (json['entry_points'] as List<dynamic>)
        .map((item) => EntryPointDto.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class PlaceDetailsDtoResponse {
  final String? display;
  final String? name;
  final String? hsNum;
  final String? street;
  final String? address;
  final int? cityId;
  final String? city;
  final int? districtId;
  final String? district;
  final int? wardId;
  final String? ward;
  final double? lat;
  final double? lng;

  PlaceDetailsDtoResponse({
    this.display,
    this.name,
    this.hsNum,
    this.street,
    this.address,
    this.cityId,
    this.city,
    this.districtId,
    this.district,
    this.wardId,
    this.ward,
    this.lat,
    this.lng,
  });

  factory PlaceDetailsDtoResponse.fromJson(Map<String, dynamic> json) => PlaceDetailsDtoResponse(
    display: json['display'] as String?,
    name: json['name'] as String?,
    hsNum: json['hs_num'] as String?,
    street: json['street'] as String?,
    address: json['address'] as String?,
    cityId: json['city_id'] as int?,
    city: json['city'] as String?,
    districtId: json['district_id'] as int?,
    district: json['district'] as String?,
    wardId: json['ward_id'] as int?,
    ward: json['ward'] as String?,
    lat: json['lat'] as double?,
    lng: json['lng'] as double?,
  );
}

extension PlaceDtoResponseX on PlaceDtoResponse {
  PlaceEntity toEntity() {
    return PlaceEntity(
      refId: refId ?? '',
      distance: distance ?? 0.0,
      address: address ?? '',
      name: name ?? '',
      display: display ?? '',
      boundaries: boundaries?.map((dto) => dto!.toEntity()).toList() ?? [],
      categories: categories?.map((category) => category.toString()).toList() ?? [],
      entryPoints: entryPoints?.map((dto) => dto!.toEntity()).toList() ?? [],
    );
  }
}

extension BoundaryDtoX on BoundaryDto {
  BoundaryEntity toEntity() {
    return BoundaryEntity(
      type: type,
      id: id,
      name: name,
      prefix: prefix,
      fullName: fullName,
    );
  }
}

extension EntryPointDtoX on EntryPointDto {
  EntryPointEntity toEntity() {
    return EntryPointEntity(
      refId: refId,
      name: name,
    );
  }
}

extension PlaceDetailsDtoX on PlaceDetailsDtoResponse {
  PlaceDetailEntity toEntity() {
    return PlaceDetailEntity(
      display: display ?? '',
      name: name ?? '',
      hsNum: hsNum ?? '',
      street: street ?? '',
      address: address ?? '',
      cityId: cityId ?? 0,
      city: city ?? '',
      districtId: districtId ?? 0,
      district: district ?? '',
      wardId: wardId ?? 0,
      ward: ward ?? '',
      lat: lat ?? 0.0,
      lng: lng ?? 0.0,
    );
  }
}