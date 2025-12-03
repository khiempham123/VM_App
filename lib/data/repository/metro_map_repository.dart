import 'package:dio/dio.dart';
import 'package:vm_first_app/data/dto/place_dto.dart';
import 'package:vm_first_app/data/services/metro_map_service.dart';
import 'package:vm_first_app/domain/entities/place_entity.dart';
import 'package:vm_first_app/domain/entities/place_request.dart';
import 'package:vm_first_app/domain/repository/metro_map_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MetroMapRepositoryImpl implements MetroMapRepository {
  final FlutterSecureStorage storage;
  final MetroMapService metroMapService;
  final Dio dio;

  MetroMapRepositoryImpl(this.storage, this.metroMapService, this.dio);

  @override
  Future<List<PlaceEntity>> searchPlaces(PlaceRequest request) async {

    final response = await metroMapService.searchPlaces(request.text);
    return response.map((e) => e.toEntity()).toList();
  }

  @override
  Future<PlaceDetailEntity?> getPlaceDetails(PlaceDetailsRequest request) async {
    final response = await metroMapService.getPlaceDetailsSafe(request.refid, dio);
    return response?.toEntity();
  }
}
