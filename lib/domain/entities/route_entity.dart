class RouteEntity {
  final String license;
  final String code;
  final String messages;
  final List<RoutePathEntity> paths;
  RouteEntity({
    required this.license,
    required this.code,
    required this.messages,
    required this.paths,
  });
}

class RoutePathEntity {
  final double distance; // in meters
  final double weight;
  final int time; // in milliseconds
  final int transfers;
  final bool pointsEncoded;
  final List<double> bbox;
  final String points; // encoded polyline
  final List<RouteInstructionEntity> instructions;
  final String snappedWaypoints;
  //final RouteAnnotationsEntity annotations;

  RoutePathEntity({
    required this.distance,
    required this.weight,
    required this.time,
    required this.transfers,
    required this.pointsEncoded,
    required this.bbox,
    required this.points,
    required this.instructions,
    required this.snappedWaypoints,
  });


}


class RouteInstructionEntity {
  final double distance;
  final int heading;
  final int sign;
  final List<int> interval;
  final String text;
  final int time;
  final String streetName;
  final int lastHeading;
  RouteInstructionEntity({
    required this.distance,
    required this.heading,
    required this.sign,
    required this.interval,
    required this.text,
    required this.time,
    required this.streetName,
    required this.lastHeading
  });
}




