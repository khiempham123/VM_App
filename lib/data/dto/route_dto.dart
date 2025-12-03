import 'package:vm_first_app/domain/entities/route_entity.dart';

class RouteDtoResponse {
  final String? license;
  final String? code;
  final String? messages;
  final List<RoutePathDto>? paths;

  RouteDtoResponse({
    this.license,
    this.code,
    this.messages,
    this.paths,
  });

  factory RouteDtoResponse.fromJson(Map<String, dynamic> json) => RouteDtoResponse(
    license: json['license'] as String?,
    code: json['code'] as String?,
    messages: json['messages'] as String?,
    paths: (json['paths'] as List<dynamic>?)
        ?.map((item) => RoutePathDto.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class RoutePathDto {
  final double? distance;
  final double? weight;
  final int? time;
  final int? transfers;
  final bool? pointsEncoded;
  final List<double>? bbox;
  final String? points;
  final List<RouteInstructionDto>? instructions;
  final String? snappedWaypoints;

  RoutePathDto({
    this.distance,
    this.time,
    this.weight,
    this.transfers,
    this.pointsEncoded,
    this.bbox,
    this.points,
    this.instructions,
    this.snappedWaypoints,
  });

  factory RoutePathDto.fromJson(Map<String, dynamic> json) => RoutePathDto(
    distance: (json['distance'] as num?)?.toDouble(),
    time: json['time'] as int?,
    weight: (json['weight'] as num?)?.toDouble(),
    transfers: json['transfers'] as int?,
    pointsEncoded: json['points_encoded'] as bool?,
    bbox: (json['bbox'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList(),
    points: json['points'] as String?,
    instructions: (json['instructions'] as List<dynamic>?)
        ?.map((item) => RouteInstructionDto.fromJson(item as Map<String, dynamic>))
        .toList(),
    snappedWaypoints: json['snapped_waypoints'] as String?,
  );
}

class RouteInstructionDto {
  final double? distance;
  final int? heading;
  final int? sign;
  final List<int>? interval;
  final String? text;
  final int? time;
  final String? streetName;
  final int? lastHeading;

  RouteInstructionDto({
    this.distance,
    this.heading,
    this.sign,
    this.interval,
    this.text,
    this.time,
    this.streetName,
    this.lastHeading,
  });

  factory RouteInstructionDto.fromJson(Map<String, dynamic> json) => RouteInstructionDto(
    distance: (json['distance'] as num?)?.toDouble(),
    heading: json['heading'] as int?,
    sign: json['sign'] as int?,
    interval: (json['interval'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(),
    text: json['text'] as String?,
    time: json['time'] as int?,
    streetName: json['street_name'] as String?,
    lastHeading: json['last_heading'] as int?,
  );
}



// Extensions to convert DTO to Entity
extension RouteDtoResponseX on RouteDtoResponse {
  RouteEntity toEntity() {
    return RouteEntity(
      license: license ?? '',
      code: code ?? '',
      messages: messages ?? '',
      paths: paths?.map((dto) => dto.toEntity()).toList() ?? [],
    );
  }
}

extension RoutePathDtoX on RoutePathDto {
  RoutePathEntity toEntity() {
    return RoutePathEntity(
      distance: distance ?? 0,
      time: time ?? 0,
      weight: weight ?? 0,
      transfers: transfers ?? 0,
      pointsEncoded: pointsEncoded ?? false,
      bbox: bbox ?? [],
      points: points ?? '',
      instructions: instructions?.map((dto) => dto.toEntity()).toList() ?? [],
      snappedWaypoints: snappedWaypoints ?? '',
    );
  }
}

extension RouteInstructionDtoX on RouteInstructionDto {
  RouteInstructionEntity toEntity() {
    return RouteInstructionEntity(
      distance: distance ?? 0,
      heading: heading ?? 0,
      sign: sign ?? 0,
      interval: interval ?? [],
      text: text ?? '',
      time: time ?? 0,
      streetName: streetName ?? '',
      lastHeading: lastHeading ?? 0,
    );
  }
}



