import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vm_first_app/data/database/key_value_store.dart';
import 'package:vm_first_app/data/dto/route_dto.dart';
import 'package:vm_first_app/data/dto/reverse_dto.dart';
import 'package:vm_first_app/data/services/route_service.dart';
import 'package:vm_first_app/domain/domain.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteService routeService;
  final KeyValueStorage storage;
  RouteRepositoryImpl(this.routeService, this.storage);

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
      debugPrint('❌ Error getting route: $e');
      return null;
    }
  }

  @override
  Future<ReverseEntity?> getReverse(RoutePointRequest request) async {
    try {
      final response = await routeService.getReverse(
        request.lng,
        request.lat,
      );

      return response.first.toEntity();

    } catch (e) {
      debugPrint('❌ Error getting reverse: $e');
      return null;
    }
  }

  @override
  Future<void> setMyRouteTrip(List<ReverseEntity> myTrip, String key) async {
    final jsonString = jsonEncode(myTrip.map((e) => e.toJson()).toList());
    await storage.setString(key, jsonString);
  }


  @override
  Future<Set<String>> getSavedTripNames() async {
    final Set<String> allKeys = await storage.keys();
    final Iterable<String> tripNames = allKeys
        .where((element) => element.contains('trip_'));
    return tripNames.toSet();
  }

  @override
  Future<List<ReverseEntity>> getTripByName(String tripNameKey) async {
    final String? value = await storage.getString(tripNameKey);
    if (value != null && value.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(value);
        return decoded.map((item) => ReverseEntity.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error decoding trip data: $e');
      }
    }
    return [];
  }

  @override
  Future<void> deleteTripByName(String tripNameKey) async {
      await storage.removeKey(tripNameKey);

  }
}

