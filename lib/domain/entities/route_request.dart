class RouteRequest {
  final List<RoutePointRequest> points;
  final String? vehicle;
  final String? optimize;
  final bool? pointsEncoded;
  final String? avoid;
  final int? capacity;
  final String? time;
  final bool? alternatives;
  final double? heading;
  final String? annotations;
  RouteRequest({
    required this.points,
    this.pointsEncoded,
    this.vehicle,
    this.optimize,
    this.avoid,
    this.capacity,
    this.time,
    this.alternatives,
    this.heading,
    this.annotations,
  }) : assert(
  vehicle != 'truck' || capacity != null,
  'Capacity is required when vehicle is truck (capacity represents weight in kg)',
  );
}
class RoutePointRequest {
  final double lat;
  final double lng;
  RoutePointRequest({
    required this.lat,
    required this.lng,
  });
  @override
  String toString() => '$lat,$lng';
}
