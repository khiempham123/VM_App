import 'dart:convert';

import 'package:vm_first_app/data/dto/place_dto.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'metro_map_service.g.dart';

@RestApi()
abstract class MetroMapService {
  factory MetroMapService(Dio dio, {String? baseUrl}) = _MetroMapService;

  @GET('/api/autocomplete/v4')
  Future<List<PlaceDtoResponse>> searchPlaces(@Query('text') String text);

  // @GET('/api/place/v4')
  // Future<PlaceDetailsDtoResponse> getPlaceDetails(@Query('refid') String refId);
}

extension MetroMapServiceExtension on MetroMapService {
  Future<PlaceDetailsDtoResponse?> getPlaceDetailsSafe(String refId, Dio dio) async {
    try {
      // Get raw response with String type to inspect
      final response = await dio.get(
        '/api/place/v4',
        queryParameters: {'refid': refId},
        options: Options(
          responseType: ResponseType.plain, // Get as plain string first
        ),
      );
      // Check if response data is null or empty
      if (response.data == null || response.data.toString().trim().isEmpty) {
        return null;
      }

      // Try to parse the string as JSON
      final String rawData = response.data.toString();
      final Map<String, dynamic> jsonData = jsonDecode(rawData);



      return PlaceDetailsDtoResponse.fromJson(jsonData);
    } catch (e, stackTrace) {

      return null;
    }
  }
}
