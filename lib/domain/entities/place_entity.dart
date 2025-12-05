class PlaceEntity {
  final String refId;
  final double distance;
  final String address;
  final String name;
  final String display;
  final List<BoundaryEntity> boundaries;
  final List<String> categories;
  final List<EntryPointEntity> entryPoints;

  PlaceEntity({
    required this.refId,
    required this.distance,
    required this.address,
    required this.name,
    required this.display,
    required this.boundaries,
    required this.categories,
    required this.entryPoints,
  });

  factory PlaceEntity.fromJson(Map<String, dynamic> json) => PlaceEntity(
    refId: json['ref_id'] ?? '',
    distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    address: json['address'] ?? '',
    name: json['name'] ?? '',
    display: json['display'] ?? '',
    boundaries: (json['boundaries'] as List<dynamic>?)
        ?.map((item) => BoundaryEntity.fromJson(item as Map<String, dynamic>))
        .toList() ?? [],
    categories: (json['categories'] as List<dynamic>?)?.map((item) => item as String).toList() ?? [],
    entryPoints: (json['entry_points'] as List<dynamic>?)
        ?.map((item) => EntryPointEntity.fromJson(item as Map<String, dynamic>))
        .toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'refId': refId,
    'distance': distance,
    'address': address,
    'name': name,
    'display': display,
    'boundaries': boundaries.map((b) => b.toJson()).toList(),
    'categories': categories,
    'entryPoints': entryPoints.map((e) => e.toJson()).toList(),
  };
}

class BoundaryEntity {
  final int type;
  final int id;
  final String name;
  final String prefix;
  final String fullName;

  BoundaryEntity({
    required this.type,
    required this.id,
    required this.name,
    required this.prefix,
    required this.fullName,
  });
  
  factory BoundaryEntity.fromJson(Map<String, dynamic> json) => BoundaryEntity(
    type: json['type'] ?? 0,
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    prefix: json['prefix'] ?? '',
    fullName: json['full_name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'name': name,
    'prefix': prefix,
    'fullName': fullName,
  };
}

class EntryPointEntity {
  final int refId;
  final String name;

  EntryPointEntity({
    required this.refId,
    required this.name,
  });

  factory EntryPointEntity.fromJson(Map<String, dynamic> json) => EntryPointEntity(
    refId: json['ref_id'] ?? 0,
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'refId': refId,
    'name': name,
  };
}

class PlaceDetailEntity {
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

  PlaceDetailEntity({
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

  factory PlaceDetailEntity.fromJson(Map<String, dynamic> json) => PlaceDetailEntity(
    display: json['display'],
    name: json['name'],
    hsNum: json['hsNum'],
    street: json['street'],
    address: json['address'],
    cityId: json['cityId'],
    city: json['city'],
    districtId: json['districtId'],
    district: json['district'],
    wardId: json['wardId'],
    ward: json['ward'],
    lat: json['lat'],
    lng: json['lng'],
  );

  Map<String, dynamic> toJson() => {
    'display': display,
    'name': name,
    'hsNum': hsNum,
    'street': street,
    'address': address,
    'cityId': cityId,
    'city': city,
    'districtId': districtId,
    'district': district,
    'wardId': wardId,
    'ward': ward,
    'lat': lat,
    'lng': lng,
  };
}