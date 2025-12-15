import 'package:vm_first_app/domain/entities/reverse_entity.dart';
import 'package:vm_first_app/domain/entities/route_entity.dart';
import 'package:vm_first_app/domain/entities/route_request.dart';

abstract class RouteRepository {
  Future<RouteEntity?> getRoute(RouteRequest request);
  Future<ReverseEntity?> getReverse(RoutePointRequest request);
  Future<void> setMyRouteTrip(List<ReverseEntity> reversePlace, String key);
  Future<Set<String>> getSavedTripNames();
  Future<List<ReverseEntity>> getTripByName(String keyTripName);
  Future<void> deleteTripByName(String tripName);
}

