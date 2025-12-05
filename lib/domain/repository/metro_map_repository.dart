import 'package:vm_first_app/domain/entities/place_entity.dart';
import 'package:vm_first_app/domain/entities/place_request.dart';


abstract class MetroMapRepository {
  Future<List<PlaceEntity>> searchPlaces(PlaceRequest request);
  Future<PlaceDetailEntity?> getPlaceDetails(PlaceDetailsRequest request);

}
