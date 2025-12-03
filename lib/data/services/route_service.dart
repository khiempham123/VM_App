import 'package:vm_first_app/data/dto/route_dto.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'route_service.g.dart';

@RestApi()
abstract class RouteService {
  factory RouteService(Dio dio, {String? baseUrl}) = _RouteService;

  @GET('/api/route')
  Future<RouteDtoResponse> getRoute(
    @Query('point') List<String> points,
    @Query('vehicle') String? vehicle,
    @Query('points_encoded') bool? pointsEncoded,
    @Query('optimize') String? optimize,
    @Query('avoid') String? avoid,
    @Query('capacity') int? capacity,
    @Query('time') String? time,
    @Query('alternatives') bool? alternatives,
    @Query('heading') double? heading,
    @Query('annotations') String? annotations,
  );
}

