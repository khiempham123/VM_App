class PlaceRequest {
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

  PlaceRequest({
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
}

class PlaceDetailsRequest {
  final String refid;

  PlaceDetailsRequest({required this.refid});
}