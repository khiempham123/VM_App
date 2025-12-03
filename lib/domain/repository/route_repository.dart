import 'package:vm_first_app/domain/entities/route_entity.dart';
import 'package:vm_first_app/domain/entities/route_request.dart';

abstract class RouteRepository {
  Future<RouteEntity?> getRoute(RouteRequest request);
}

