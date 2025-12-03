import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vietmap_flutter_plugin/vietmap_flutter_plugin.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
class MetroMapProvider extends ChangeNotifier {
  final AppProvider _appProvider;

  // VietmapGL controller (for simple route drawing)
  VietmapController? _vietmapController;
  VietmapController get vietmapController => _vietmapController!;

  // NavigationView controller (for full navigation with callbacks)
  MapNavigationViewController? _navigationController;
  MapNavigationViewController? get navigationController => _navigationController;

  // Navigation plugin and options
  late MapOptions _navigationOption;
  MapOptions get navigationOption => _navigationOption;

  RouteProgressEvent? _routeProgressEvent;
  RouteProgressEvent? get routeProgressEvent => _routeProgressEvent;

  final searchController = TextEditingController();

  late final MetroMapRepository _metroMapRepository;
  late final RouteRepository _routeRepository;

  PlaceDetailEntity? _selectedPlace;
  PlaceDetailEntity? get selectedPlace => _selectedPlace;

  LatLng? _currentPlaceLatLng;
  LatLng? get currentPlaceLatLng => _currentPlaceLatLng;
  LatLng? _selectedPlaceLatLng;
  LatLng? get selectedPlaceLatLng => _selectedPlaceLatLng;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isOnMyLocation = false;
  bool get isOnMyLocation => _isOnMyLocation;
  bool _isOnSelectedLocation = false;
  bool get isOnSelectedLocation => _isOnSelectedLocation;

  bool _isOnRoute = false;
  bool get isOnRoute => _isOnRoute;

  bool _isOnNavigationRoute = false;
  bool get isOnNavigationRoute => _isOnNavigationRoute;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;// Route information
  Line? _routeLine;
  Line? get routeLine => _routeLine;

  double? _routeDistance; // in kilometers
  double? get routeDistance => _routeDistance;

  double? _routeDuration; // in minutes
  double? get routeDuration => _routeDuration;

  bool _isCalculatingRoute = false;
  bool get isCalculatingRoute => _isCalculatingRoute;

  MetroMapProvider(this._appProvider){
    Vietmap.getInstance('${dotenv.env['VM_API_KEY']}');
    _metroMapRepository = locator<MetroMapRepository>();
    _routeRepository = locator<RouteRepository>();
  }

  // Initialize NavigationView options


  List<PointLatLng> latLngList = [];
  List<LatLng> latLngListForRoute = [];

  void onMapCreated(VietmapController controller) {
    _vietmapController = controller;
    notifyListeners();
  }


  Future<void> moveToMyLocation() async {
    if (_vietmapController == null) {
      return;
    }


    try {
      _currentPlaceLatLng = await _vietmapController!.requestMyLocationLatLng();
      await _vietmapController!.moveCamera(
        CameraUpdate.newLatLngZoom(
          _currentPlaceLatLng ??
              const LatLng(11.8903231, 106.654551),
          16.0,
        ),
      );
      _isOnMyLocation = true;
      notifyListeners();
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<List<PlaceEntity>> onSearchChanged(String query) async {
    final request = PlaceRequest(text: query);
    if(query != ''){
      final suggestions = await _metroMapRepository.searchPlaces(request);
      return suggestions;
    }
    return [];
  }

  Future<void> onSuggestionSelected(PlaceEntity place) async {

    final request = PlaceDetailsRequest(refid: place.refId);
    final details = await _metroMapRepository.getPlaceDetails(request);
    if (details != null) {
      _selectedPlace = details;
      notifyListeners();
    } else {
      debugPrint('Failed to get place details for refId: ${place.refId}');
    }
    await _vietmapController!.moveCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(details?.lat ?? 0, details?.lng ?? 0), 16.0
      ),
    );
    _selectedPlaceLatLng = LatLng(details?.lat ?? 0, details?.lng ?? 0);
    _isOnSelectedLocation = true;
    notifyListeners();
  }

  Future<void> onRouteSelected() async {

    _isCalculatingRoute = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use RouteRepository to calculate route (Clean Architecture)
      final routeRequest = RouteRequest(
        points: [
          RoutePointRequest(
            lat: _currentPlaceLatLng!.latitude,
            lng: _currentPlaceLatLng!.longitude,
          ),
          RoutePointRequest(
            lat: _selectedPlaceLatLng!.latitude,
            lng: _selectedPlaceLatLng!.longitude,
          ),
        ],
        vehicle: 'car',
        pointsEncoded: true,

      );
      final routeEntity = await _routeRepository.getRoute(routeRequest);

      if (routeEntity != null && routeEntity.paths.isNotEmpty) {
        final firstPath = routeEntity.paths[0];

        _routeDistance = firstPath.distance / 1000; // Convert meters to km
        _routeDuration = firstPath.time / 60000; // Convert milliseconds to minutes

        // Get encoded polyline
        final String encodedPolyline = routeEntity.paths[0].points;
        debugPrint('Show encoded: ${encodedPolyline}');
        if (encodedPolyline.isNotEmpty) {
          //latLngList.clear();
          latLngListForRoute.clear();
          // Decode polyline to list of LatLng using VietmapPolylineDecoder
          latLngList = PolylinePoints.decodePolyline(
            encodedPolyline,
          );
          debugPrint('LatLngList from package is: ${latLngList}');
          latLngListForRoute = [];
          for (var latLng in latLngList) {
            latLngListForRoute.add(LatLng(latLng.latitude, latLng.longitude));
          }
          _isOnRoute = true;
          _isCalculatingRoute = false;

          Line? lineDrive = await _vietmapController?.addPolyline(PolylineOptions(
            geometry: latLngListForRoute,
            polylineColor: Colors.black,
            polylineWidth: 2.0,
          ));
          notifyListeners();
        } else {
          _errorMessage = 'No polyline data in route';
          _isCalculatingRoute = false;
          notifyListeners();
        }
      } else {
        _errorMessage = 'No route found';
        _isCalculatingRoute = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error calculating route: $e';
      _isCalculatingRoute = false;

      notifyListeners();
    }
  }




  @override
  void dispose() {
    _navigationController?.onDispose();
    searchController.dispose();
    super.dispose();
  }
}
