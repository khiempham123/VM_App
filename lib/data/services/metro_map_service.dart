import 'package:vm_first_app/data/dto/place_dto.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'metro_map_service.g.dart';

@RestApi()
abstract class MetroMapService {
  factory MetroMapService(Dio dio, {String? baseUrl}) = _MetroMapService;

  @GET('/api/search/v4')
  Future<List<PlaceDtoResponse>> searchPlaces(@Query('text') String text);

  @GET('/api/place/v4')
  Future<PlaceDetailsDtoResponse> getPlaceDetails(@Query('refid') String refId);
}