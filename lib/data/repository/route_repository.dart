import 'package:vm_first_app/data/dto/route_dto.dart';
import 'package:vm_first_app/data/services/route_service.dart';
import 'package:vm_first_app/domain/domain.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteService routeService;

  RouteRepositoryImpl(this.routeService);

  @override
  Future<RouteEntity?> getRoute(RouteRequest request) async {
    try {
      // Convert RoutePointRequest list to String list
      final pointStrings = request.points.map((p) => p.toString()).toList();

      final response = await routeService.getRoute(
        pointStrings,
        request.vehicle,
        request.pointsEncoded,
        request.optimize,
        request.avoid,
        request.capacity,
        request.time,
        request.alternatives,
        request.heading,
        request.annotations,
      );

      return response.toEntity();
    } catch (e) {
      print('❌ Error getting route: $e');
      return null;
    }
  }
}

