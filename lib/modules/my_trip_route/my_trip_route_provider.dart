import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vietmap_flutter_plugin/vietmap_flutter_plugin.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';
import 'package:app_color_parser/app_color_parser.dart';

class MyTripRouteProvider extends ChangeNotifier {
  // Kept for future use
  // ignore: unused_field
  final AppProvider appProvider;
  // VietmapGL controller
  VietmapController? _vietmapController;
  VietmapController get vietmapController => _vietmapController!;
  bool get isMapReady => _vietmapController != null;

  // Flag to track if map is fully rendered
  bool _isMapFullyRendered = false;
  bool get isMapFullyRendered => _isMapFullyRendered;

  final searchController = TextEditingController();

  late final MetroMapRepository _metroMapRepository;
  late final RouteRepository _routeRepository;

  // 14 nhà ga metro với tọa độ (theo thứ tự từ Bến Thành đến Suối Tiên)
  final List<LatLng> metroStations = const [
    LatLng(10.770215179294059, 106.69689029348139), // 1. Bến Thành
    LatLng(10.776229, 106.703003),                   // 2. Nhà hát TP
    LatLng(10.781322149729117, 106.70773289741469), // 3. Ba Son
    LatLng(10.796577, 106.716293),                   // 4. Văn Thánh
    LatLng(10.798878, 106.722768),                   // 5. Tân Cảng
    LatLng(10.800463, 106.733723),                   // 6. Thảo Điền
    LatLng(10.801830530540999, 106.7416294022247),  // 7. An Phú
    LatLng(10.808485, 106.755103),                   // 8. Rạch Chiếc
    LatLng(10.822636, 106.759832),                   // 9. Phước Long
    LatLng(10.832322, 106.763676),                   // 10. Bình Thái
    LatLng(10.846283, 106.773891),                   // 11. Thủ Đức
    LatLng(10.856754, 106.785423),                   // 12. Khu Công Nghệ Cao
    LatLng(10.871523, 106.799856),                   // 13. Đại học Quốc Gia
    LatLng(10.879234, 106.812678),                   // 14. Suối Tiên
  ];

  // Tên các nhà ga metro (theo thứ tự tương ứng)
  final List<String> metroStationNames = const [
    'Bến Thành',
    'Nhà hát TP',
    'Ba Son',
    'Văn Thánh',
    'Tân Cảng',
    'Thảo Điền',
    'An Phú',
    'Rạch Chiếc',
    'Phước Long',
    'Bình Thái',
    'Thủ Đức',
    'Khu Công Nghệ Cao',
    'Đại học Quốc Gia',
    'Suối Tiên',
  ];

  PlaceDetailEntity? _selectedPlace;
  PlaceDetailEntity? get selectedPlace => _selectedPlace;

  LatLng? _currentPlaceLatLng;
  LatLng? get currentPlaceLatLng => _currentPlaceLatLng;

  LatLng? _selectedPlaceLatLng;
  LatLng? get selectedPlaceLatLng => _selectedPlaceLatLng;

  LatLng? _longPressedLocation;
  LatLng? get longPressedLocation => _longPressedLocation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isOnMyLocation = false;
  bool get isOnMyLocation => _isOnMyLocation;

  bool _isOnSelectedLocation = false;
  bool get isOnSelectedLocation => _isOnSelectedLocation;

  bool _isOnLongPressedLocation = false;
  bool get isOnLongPressedLocation => _isOnLongPressedLocation;

  bool _isMetroRouteDrawn = false;
  bool get isMetroRouteDrawn => _isMetroRouteDrawn;

  bool _isReverseDrawn = false;
  bool get isReverseDrawn => _isReverseDrawn;

  bool _isSelectedTripSaved = false;
  bool get isSelectedTripSaved => _isSelectedTripSaved;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Metro route line
  Line? _metroRouteLine;
  Line? get metroRouteLine => _metroRouteLine;

  // Station markers - đổi từ List<Symbol> thành list để lưu symbols
  List<Symbol> _metroStationSymbols = [];
  List<Symbol> get metroStationSymbols => _metroStationSymbols;

  // Nearest metro station properties
  int? _nearestStationIndex;
  int? get nearestStationIndex => _nearestStationIndex;

  String? get nearestStationName => _nearestStationIndex != null &&
      _nearestStationIndex! >= 0 &&
      _nearestStationIndex! < metroStationNames.length
      ? metroStationNames[_nearestStationIndex!]
      : null;
  LatLng? get nearestStationLatLng => _nearestStationIndex != null &&
      _nearestStationIndex! >= 0 &&
      _nearestStationIndex! < metroStations.length
      ? metroStations[_nearestStationIndex!]
      : null;

  double? _distanceToNearestStation;
  double? get distanceToNearestStation => _distanceToNearestStation;

  // Route to nearest station
  RouteEntity? _routeToNearestStation;
  RouteEntity? get routeToNearestStation => _routeToNearestStation;
  
  RouteEntity? _routeToLongPressedLocation;
  RouteEntity? get routeToLongPressedLocation => _routeToLongPressedLocation;

  ReverseEntity? _reverseEntity;
  ReverseEntity? get reverseEntity => _reverseEntity;
  
  // All long pressed locations - list of all locations user has clicked
  final List<LatLng> _allLongPressedLocations = [];
  List<LatLng> get allLongPressedLocations => _allLongPressedLocations;
  
  final List<ReverseEntity> _allLongPressedEntities = [];
  List<ReverseEntity> get allLongPressedEntities => _allLongPressedEntities;
  
  // Trip waypoints - list of locations added to trip
  final List<LatLng> _tripWaypoints = [];
  List<LatLng> get tripWaypoints => _tripWaypoints;

  final List<ReverseEntity> _tripWaypointEntities = [];
  List<ReverseEntity> get tripWaypointEntities => _tripWaypointEntities;

  // data from local storage loaded
  List<ReverseEntity> _originalTripWaypointEntities = [];
  List<ReverseEntity> get originalTripWaypointEntities => _originalTripWaypointEntities;

  String _originalKey = '';
  String get originalKey => _originalKey;

  Line? _routeToStationLine;
  Line? get routeToStationLine => _routeToStationLine;

  Line? _currentTripRouteLine;
  Line? get currentTripRouteLine => _currentTripRouteLine;
  String _encodedPolyline = "";
  String get encodedPolyline => _encodedPolyline;

  bool _isRouteToStationDrawn = false;
  bool get isRouteToStationDrawn => _isRouteToStationDrawn;
  double? _routeDistance;
  double? get routeDistance => _routeDistance;
  double? _routeDuration;
  double? get routeDuration => _routeDuration;

  // Selected metro station
  int? _selectedMetroStationIndex;
  int? get selectedMetroStationIndex => _selectedMetroStationIndex;
  String? get selectedMetroStationName => _selectedMetroStationIndex != null &&
      _selectedMetroStationIndex! >= 0 &&
      _selectedMetroStationIndex! < metroStationNames.length
      ? metroStationNames[_selectedMetroStationIndex!]
      : null;
  LatLng? get selectedMetroStationLatLng => _selectedMetroStationIndex != null &&
      _selectedMetroStationIndex! >= 0 &&
      _selectedMetroStationIndex! < metroStations.length
      ? metroStations[_selectedMetroStationIndex!]
      : null;

  // Current trip name
  String? _currentTripName;
  String? get currentTripName => _currentTripName;

  // Flag to track if currently viewing a saved trip
  bool _isViewingSavedTrip = false;
  bool get isViewingSavedTrip => _isViewingSavedTrip;

  // List of saved trip names
  Set<String> _savedTripNames = {};
  Set<String> get savedTripNames => _savedTripNames;

  // Loading state for saved trip names
  bool _isLoadingSavedTrips = false;
  bool get isLoadingSavedTrips => _isLoadingSavedTrips;

  // Error state for loading trips
  String? _loadTripsError;
  String? get loadTripsError => _loadTripsError;

  // Flag to indicate if trips have been loaded at least once
  bool _hasFetchedTrips = false;
  bool get hasFetchedTrips => _hasFetchedTrips;

  // Add place to trip
  bool _isPlaceAdded = false;
  bool get isPlaceAdded => _isPlaceAdded;

  bool _isInitSuccess = false;
  bool get isInitSuccess => _isInitSuccess;

  bool _mustSaveBeforeSwitchNewTrip = false;
  bool get mustSaveBeforeSwitchNewTrip => _mustSaveBeforeSwitchNewTrip;

  String _currentRouteColor = '';
  String get currentRouteColor => _currentRouteColor;
  MyTripRouteProvider(this.appProvider) {
    Vietmap.getInstance('${dotenv.env['VM_API_KEY']}');
    _metroMapRepository = locator<MetroMapRepository>();
    _routeRepository = locator<RouteRepository>();
  }

  void onMapCreated(VietmapController controller) {
    _vietmapController = controller;
    notifyListeners();

    if(_currentTripName != null) {
      _drawRouteForTripLoaded(_currentTripName!);
    }
    _isLoading = true;
    notifyListeners();
    // Draw metro route when map is created
    _drawMetroRoute();

  }

  /// Called when map is fully rendered for the first time
  /// This ensures map is ready before displaying static markers from SharedPreferences
  void onMapFullyRendered() {
    _isMapFullyRendered = true;
    notifyListeners();
  }

  // Callback khi map style đã load hoàn toàn - gọi từ _VietmapWidget

  Future<void> _drawMetroRoute() async {
    if (_vietmapController == null || metroStations.isEmpty) return;

    try {
      // Vẽ polyline đi qua các nhà ga metro
      _metroRouteLine = await _vietmapController?.addPolyline(
        PolylineOptions(
          geometry: metroStations,
          polylineColor: Colors.lightBlue,
          polylineWidth: 4.0,
        ),
      );

      _isMetroRouteDrawn = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error drawing metro route: $e');
    }
  }

  Future<void> moveToMyLocation() async {
    if (_vietmapController == null) return;

    try {
      _currentPlaceLatLng = await _vietmapController!.requestMyLocationLatLng();
      await _vietmapController!.moveCamera(
        CameraUpdate.newLatLngZoom(
          _currentPlaceLatLng ?? const LatLng(10.770215179294059, 106.69689029348139),
          14.0,
        ),
      );
      _isOnMyLocation = true;

      // Find nearest metro station when moving to my location
      if (_currentPlaceLatLng != null) {
        _findNearestMetroStation(_currentPlaceLatLng!);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting my location: $e');
    }
  }

  /// Calculate distance between two LatLng points using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1 = point1.latitude * math.pi / 180;
    final double lat2 = point2.latitude * math.pi / 180;
    final double dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final double dLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c; // Distance in kilometers
  }

  /// Find the nearest metro station from a given location
  void _findNearestMetroStation(LatLng userLocation) {
    if (metroStations.isEmpty || metroStationNames.isEmpty) return;

    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < metroStations.length; i++) {
      final distance = _calculateDistance(userLocation, metroStations[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Guard: đảm bảo nearestIndex trong range hợp lệ (0-13)
    if (nearestIndex >= 0 && nearestIndex < metroStationNames.length) {
      _nearestStationIndex = nearestIndex;
      _distanceToNearestStation = minDistance;
    }
  }

  /// Draw route from current location to the nearest metro station
  Future<void> drawRouteToNearestStation() async {
    if (_vietmapController == null ||
        _currentPlaceLatLng == null ||
        _nearestStationIndex == null) {
      return;
    }

    try {
      // Clear existing route line if any
      if (_routeToStationLine != null) {
        await _vietmapController!.removePolyline(_routeToStationLine!);
        _routeToStationLine = null;
      }

      final targetStation = metroStations[_nearestStationIndex!];

      final routeRequest = RouteRequest(
        points: [
          RoutePointRequest(
            lat: _currentPlaceLatLng!.latitude,
            lng: _currentPlaceLatLng!.longitude,
          ),
          RoutePointRequest(
            lat: targetStation.latitude,
            lng: targetStation.longitude,
          ),
        ],
        vehicle: 'car',
        pointsEncoded: true,
      );

      _routeToNearestStation = await _routeRepository.getRoute(routeRequest);

      if (_routeToNearestStation != null && _routeToNearestStation!.paths.isNotEmpty) {
        final firstPath = _routeToNearestStation!.paths[0];

        _routeDistance = firstPath.distance / 1000; // Convert meters to km
        _routeDuration = firstPath.time / 60000; // Convert milliseconds to minutes

        _encodedPolyline = firstPath.points ;

        if (_encodedPolyline.isNotEmpty) {
          final decodedPoints = PolylinePoints.decodePolyline(_encodedPolyline);
          final List<LatLng> routePoints = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          _routeToStationLine = await _vietmapController!.addPolyline(
            PolylineOptions(
              geometry: routePoints,
              polylineColor: Colors.green,
              polylineWidth: 2,
            ),
          );

          _isRouteToStationDrawn = true;

          // Adjust camera to show both user location and station
          _showRouteBounds();

          notifyListeners();
        }
      } else {
        debugPrint('No route found to station');
      }
    } catch (e) {
      debugPrint('Error drawing route to station: $e');
    }
  }

  /// Adjust camera to show the route bounds
  Future<void> _showRouteBounds() async {
    if (_currentPlaceLatLng == null || _nearestStationIndex == null) return;

    final targetStation = metroStations[_nearestStationIndex!];

    final minLat = math.min(_currentPlaceLatLng!.latitude, targetStation.latitude);
    final maxLat = math.max(_currentPlaceLatLng!.latitude, targetStation.latitude);
    final minLng = math.min(_currentPlaceLatLng!.longitude, targetStation.longitude);
    final maxLng = math.max(_currentPlaceLatLng!.longitude, targetStation.longitude);

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _vietmapController?.moveCamera(
      CameraUpdate.newLatLngBounds(bounds, left: 50, right: 50, top: 150, bottom: 150),
    );
  }

  /// Clear the route to station
  Future<void> clearRouteToStation() async {
    if (_routeToStationLine != null && _vietmapController != null) {
      await _vietmapController!.removePolyline(_routeToStationLine!);
      _routeToStationLine = null;
    }
    _routeToNearestStation = null;
    _isRouteToStationDrawn = false;
    _routeDistance = null;
    _routeDuration = null;
    notifyListeners();
  }

  Future<List<PlaceEntity>> onSearchChanged(String query) async {
    final request = PlaceRequest(text: query);
    if (query.isNotEmpty) {
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
      _selectedPlaceLatLng = LatLng(details.lat, details.lng);
      _isOnSelectedLocation = true;

      await _vietmapController!.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(details.lat, details.lng),
          16.0,
        ),
      );
      notifyListeners();
    } else {
      debugPrint('Failed to get place details for refId: ${place.refId}');
    }
  }

  Future<void> onMapLongClick(LatLng latLng) async {
    _longPressedLocation = latLng;
    _isOnLongPressedLocation = true;

    _reverseEntity = await _routeRepository.getReverse(RoutePointRequest(lng: latLng.longitude, lat: latLng.latitude));
    
    // Add to all long pressed locations list (không ghi đè, chỉ thêm mới)
    if (_reverseEntity != null) {
      _allLongPressedLocations.add(latLng);
      _allLongPressedEntities.add(_reverseEntity!);
    }
    _allLongPressedEntities.sort((a,b) => a.distance > b.distance ? 1 : -1);
    _isReverseDrawn = true;
    _vietmapController?.moveCamera(
      CameraUpdate.newLatLngZoom(latLng, 16.0),
    );
    notifyListeners();
  }

  /// Get route from current location to long pressed location
  Future<void> getRouteToLongPressedLocation() async {
    if (_longPressedLocation == null) return;

    // Get current location if not available
    _currentPlaceLatLng ??= await _vietmapController?.requestMyLocationLatLng();

    if (_currentPlaceLatLng == null) return;

    try {
      final request = RouteRequest(
        points: [
          RoutePointRequest(
            lat: _currentPlaceLatLng!.latitude,
            lng: _currentPlaceLatLng!.longitude,
          ),
          ...allLongPressedLocations.map((location) => RoutePointRequest(lat: location.latitude, lng: location.longitude)),
        ],
        vehicle: 'car',
      );

      _routeToLongPressedLocation = await _routeRepository.getRoute(request);
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting route to long pressed location: $e');
    }
  }

  /// Clear only the current long pressed location (last one)
  void clearLongPressedLocation() {
    if (_allLongPressedLocations.isNotEmpty) {
      _allLongPressedLocations.removeLast();
      _allLongPressedEntities.removeLast();
    }
    
    // Update current to previous one if exists
    if (_allLongPressedLocations.isNotEmpty) {
      _longPressedLocation = _allLongPressedLocations.last;
      _reverseEntity = _allLongPressedEntities.last;
      _isOnLongPressedLocation = true;
      _isReverseDrawn = true;
    } else {
      _longPressedLocation = null;
      _reverseEntity = null;
      _isOnLongPressedLocation = false;
      _isReverseDrawn = false;
    }

    if(!_allLongPressedLocations.isNotEmpty) {
      _currentTripName = '';
    }
    notifyListeners();
  }
  
  /// Clear all long pressed locations
  void clearAllLongPressedLocations() {
    _allLongPressedLocations.clear();
    _allLongPressedEntities.clear();
    _longPressedLocation = null;
    _reverseEntity = null;
    _isOnLongPressedLocation = false;
    _isReverseDrawn = false;
    notifyListeners();
  }

  /// Clear all unsaved trip data (markers and polylines) before switching to a new trip
  /// This is called when user decides NOT to save the current trip
  Future<void> clearUnsavedTripData() async {
    // Clear all long pressed locations (markers)
    _allLongPressedLocations.clear();
    _allLongPressedEntities.clear();
    _longPressedLocation = null;
    _reverseEntity = null;
    _isOnLongPressedLocation = false;
    _isReverseDrawn = false;

    // Clear trip waypoints
    _tripWaypoints.clear();
    _tripWaypointEntities.clear();

    // Remove current trip route polyline
    if (_currentTripRouteLine != null ) {
      await _vietmapController!.removePolyline(_currentTripRouteLine!);
      _currentTripRouteLine = null;
    }
    _encodedPolyline = '';

    // Remove route to station polyline if exists
    if (_routeToStationLine != null) {
      await _vietmapController!.removePolyline(_routeToStationLine!);
      _routeToStationLine = null;
      _isRouteToStationDrawn = false;
      _routeDistance = null;
      _routeDuration = null;
      _nearestStationIndex = null;
      _distanceToNearestStation = null;
    }

    // Reset place added flag
    _isPlaceAdded = false;
    _mustSaveBeforeSwitchNewTrip = false;
    // Reset current trip name
    _currentTripName = null;
    _isOnMyLocation = false;
    // Clear original trip tracking
    _originalKey = '';
    _originalTripWaypointEntities.clear();
    notifyListeners();
    debugPrint('Cleared all unsaved trip data');
  }

  /// Select a marker at specific index from allLongPressedLocations
  void selectMarkerAtIndex(int index) {
    if (index >= 0 && index < _allLongPressedLocations.length) {
      _longPressedLocation = _allLongPressedLocations[index];
      _reverseEntity = _allLongPressedEntities[index];
      _isOnLongPressedLocation = true;
      _isReverseDrawn = true;

      // Move camera to selected location
      _vietmapController?.moveCamera(
        CameraUpdate.newLatLngZoom(_longPressedLocation!, 16.0),
      );
      notifyListeners();
    }
  }

  /// Select a metro station at specific index
  void selectMetroStation(int index) {
    if (index >= 0 && index < metroStations.length) {
      final oldIndex = _selectedMetroStationIndex;
      _selectedMetroStationIndex = index;

      // Update symbol appearances
      _updateSelectedStationSymbol(oldIndex, index);

      // Move camera to selected metro station
      _vietmapController?.moveCamera(
        CameraUpdate.newLatLngZoom(metroStations[index], 16.0),
      );
      notifyListeners();
    }
  }

  /// Clear selected metro station
  void clearSelectedMetroStation() {
    final oldIndex = _selectedMetroStationIndex;
    _selectedMetroStationIndex = null;

    // Reset symbol appearance
    _updateSelectedStationSymbol(oldIndex, null);

    notifyListeners();
  }

  /// Get route from current location to selected metro station
  Future<void> getRouteToSelectedMetroStation() async {
    if (_selectedMetroStationIndex == null) return;

    // Get current location if not available
    _currentPlaceLatLng ??= await _vietmapController?.requestMyLocationLatLng();

    if (_currentPlaceLatLng == null) return;

    final targetStation = metroStations[_selectedMetroStationIndex!];

    try {
      final request = RouteRequest(
        points: [
          RoutePointRequest(
            lat: _currentPlaceLatLng!.latitude,
            lng: _currentPlaceLatLng!.longitude,
          ),
          RoutePointRequest(
            lat: targetStation.latitude,
            lng: targetStation.longitude,
          ),
        ],
        vehicle: 'car',
      );

      _routeToLongPressedLocation = await _routeRepository.getRoute(request);
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting route to metro station: $e');
    }
  }

  /// Add current long pressed location to trip waypoints
  void addToTrip() async {
    if (_longPressedLocation != null && _reverseEntity != null) {
      // Check if location already exists in trip
      if (!isLocationInTrip(_longPressedLocation!)) {
        _tripWaypoints.add(_longPressedLocation!);
        _tripWaypointEntities.add(_reverseEntity!);
        _isPlaceAdded = true;
        if(_currentPlaceLatLng == null) {
          await moveToMyLocation();
        }
        final request = RouteRequest(
          points: [
            RoutePointRequest(
              lat: _currentPlaceLatLng!.latitude,
              lng: _currentPlaceLatLng!.longitude,
            ),
            ...allLongPressedEntities.map((location) => RoutePointRequest(lat: location.lat, lng: location.lng)),
          ],
          vehicle: 'car',
          pointsEncoded: true,
        );

        RouteEntity? routeEntity = await _routeRepository.getRoute(request);
        if (routeEntity != null && routeEntity.paths.isNotEmpty) {
          final firstPath = routeEntity.paths[0];

          _routeDistance = firstPath.distance / 1000; // Convert meters to km
          _routeDuration = firstPath.time / 60000; // Convert milliseconds to minutes

          _encodedPolyline = routeEntity.paths[0].points;
          if (_encodedPolyline.isNotEmpty) {
            //latLngListForRoute.clear();
            List<PointLatLng>latLngList = PolylinePoints.decodePolyline(
              _encodedPolyline,
            );
            List<LatLng> latLngListForRoute =[];
            for (var latLng in latLngList) {
              latLngListForRoute.add(LatLng(latLng.latitude, latLng.longitude));
            }
            _currentTripRouteLine = await _vietmapController?.addPolyline(PolylineOptions(
              geometry: latLngListForRoute,
              polylineColor: Color(int.parse(RandomColorParser().parseHexColor(_currentRouteColor), radix: 16)),
              polylineWidth: 2,
            ));
            notifyListeners();
          } else {
            _errorMessage = 'No polyline data in route';
            notifyListeners();
          }
        } else {
          _errorMessage = 'No route found';
          notifyListeners();
        }
        notifyListeners();
      }
    }
  }

  Future<void> mustSavedBeforeStartNewTrip() async{
    _currentTripName ='';
    _mustSaveBeforeSwitchNewTrip = true;
    notifyListeners();
  }
  /// Remove current long pressed location from trip waypoints
  void removeFromTrip() {
    if (_longPressedLocation != null) {
      final index = _tripWaypoints.indexWhere(
        (waypoint) =>
            waypoint.latitude == _longPressedLocation!.latitude &&
            waypoint.longitude == _longPressedLocation!.longitude,
      );
      if (index != -1) {
        _tripWaypoints.removeAt(index);
        _tripWaypointEntities.removeAt(index);
        notifyListeners();
      }
    }
    if(!_tripWaypoints.isNotEmpty) {
      _isPlaceAdded = false;
      notifyListeners();
    }
  }

  /// Check if a location is already in trip
  bool isLocationInTrip(LatLng location) {
    return _tripWaypoints.any(
      (waypoint) =>
          waypoint.latitude == location.latitude &&
          waypoint.longitude == location.longitude,
    );
  }

  /// Clear all trip waypoints
  void clearAllTrip() {
    _tripWaypoints.clear();
    _tripWaypointEntities.clear();
    _allLongPressedEntities.clear();
    _allLongPressedLocations.clear();
    // Clear original trip tracking to prevent incorrect deletions
    _originalKey = '';
    _originalTripWaypointEntities.clear();
    if(_currentTripRouteLine != null) {
      _vietmapController?.removePolyline(_currentTripRouteLine!);
      notifyListeners();
    }
    notifyListeners();
  }

  Future<void> storageMyTrip(String tripName) async {
    if (_allLongPressedEntities.isEmpty) return;

    final refIdList = _allLongPressedEntities.map((e) => e.refId).join('_');

    final newKey = 'trip_{$tripName}_${refIdList}_encodedPolyline_${_encodedPolyline}_color_$_currentRouteColor';
    if(_originalKey != newKey && _originalTripWaypointEntities != _allLongPressedEntities) {
      _routeRepository.deleteTripByName(_originalKey);
      _originalKey = '';
      _originalTripWaypointEntities.clear();
    }
    await _routeRepository.setMyRouteTrip(_allLongPressedEntities, newKey);
    _currentTripName = newKey; // Store full key as trip name
    _isViewingSavedTrip = true; // Now viewing saved trip after saving
    await loadSavedTripNames();
    notifyListeners();
  }

  // Create a new trip with a name
  Future<void> createNewTrip(String tripName) async {
    _currentTripName = tripName;
    _isViewingSavedTrip = false; // Creating new trip, not viewing saved one
    _currentRouteColor = RandomColor.getColorObject(Options()).toHex(includeAlpha: true);
    // Clear current trip data to start fresh
    clearAllTrip();
    notifyListeners();
  }

  // Load all saved trip names from SharedPreferences
  Future<void> loadSavedTripNames() async {
    _isLoadingSavedTrips = true;
    _loadTripsError = null;
    notifyListeners();

    try {
      _savedTripNames = await _routeRepository.getSavedTripNames();
      _hasFetchedTrips = true;
      _loadTripsError = null;
    } catch (e) {
      debugPrint('Error loading saved trip names: $e');
      _loadTripsError = 'Không thể tải danh sách chuyến đi';
    }
    _isLoadingSavedTrips = false;
    notifyListeners();
  }

  // Load trip markers by trip name
  Future<void> loadTripMarkers(String tripName) async {
    try {

      _currentTripName = tripName;
      _isViewingSavedTrip = true; // Mark as viewing a saved trip

      // Clear current markers
      _allLongPressedLocations.clear();
      _allLongPressedEntities.clear();
      _tripWaypoints.clear();
      _tripWaypointEntities.clear();
      if(_currentTripRouteLine != null) {
        _encodedPolyline = '';
        _vietmapController!.removePolyline(_currentTripRouteLine!);
      }
      // Load trip from storage
      final trips = await _routeRepository.getTripByName(tripName);
      _originalTripWaypointEntities = trips;
      _originalKey = tripName;

      for (final entity in trips) {
        final latLng = LatLng(entity.lat, entity.lng);
        _allLongPressedLocations.add(latLng);
        _allLongPressedEntities.add(entity);
        _tripWaypoints.add(latLng);
        _tripWaypointEntities.add(entity);
      }

      _isOnLongPressedLocation = _allLongPressedLocations.isNotEmpty;
      _isReverseDrawn = _allLongPressedEntities.isNotEmpty;

      if (_allLongPressedLocations.isNotEmpty) {
        _longPressedLocation = _allLongPressedLocations.last;
        _reverseEntity = _allLongPressedEntities.last;
      }

      // Show all loaded markers on map
      if (_allLongPressedLocations.isNotEmpty && _vietmapController != null) {
        // Calculate bounds to show all markers
        double minLat = _allLongPressedLocations.first.latitude;
        double maxLat = _allLongPressedLocations.first.latitude;
        double minLng = _allLongPressedLocations.first.longitude;
        double maxLng = _allLongPressedLocations.first.longitude;

        for (final location in _allLongPressedLocations) {
          if (location.latitude < minLat) minLat = location.latitude;
          if (location.latitude > maxLat) maxLat = location.latitude;
          if (location.longitude < minLng) minLng = location.longitude;
          if (location.longitude > maxLng) maxLng = location.longitude;
        }

        final bounds = LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        );

        await _vietmapController!.moveCamera(
          CameraUpdate.newLatLngBounds(bounds, left: 50, right: 50, top: 150, bottom: 100),
        );
      }
      _isOnLongPressedLocation = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading trip markers: $e');
    }
  }

  Future<void> _drawRouteForTripLoaded(String tripName) async {
    try{
      if (_currentTripRouteLine != null && _vietmapController != null) {
        await _vietmapController!.removePolyline(_currentTripRouteLine!);
        _currentTripRouteLine = null;
      }

      // Extract encoded polyline properly (between 'encodedPolyline_' and '_color_')
      final int polylineStartIndex = tripName.indexOf('encodedPolyline_') + 'encodedPolyline_'.length;
      final int colorStartIndex = tripName.indexOf('_color_');
      if (polylineStartIndex != -1 && colorStartIndex != -1 && colorStartIndex > polylineStartIndex) {
        _encodedPolyline = tripName.substring(polylineStartIndex, colorStartIndex);
      } else {
        // Fallback to old method if format is unexpected
        _encodedPolyline = tripName.split('encodedPolyline_').last.split('_color_').first;
      }

      _currentRouteColor = tripName.split('color_').last;
      List<PointLatLng>latLngList = PolylinePoints.decodePolyline(
        _encodedPolyline,
      );
      List<LatLng> latLngListForRoute =[];
      for (var latLng in latLngList) {
        latLngListForRoute.add(LatLng(latLng.latitude, latLng.longitude));
      }

      _currentTripRouteLine = await _vietmapController!.addPolyline(
        PolylineOptions(
          geometry: latLngListForRoute,
          polylineColor:Color(int.parse('0x${RandomColorParser().parseHexColor(_currentRouteColor)}')),
          polylineWidth: 2,
        ),
      );
    }
    catch(e){
      debugPrint('$e');
    }
  }

  Future<void> currentRoute(String tripName) async {
    await _drawRouteForTripLoaded(tripName);
    notifyListeners();
  }
  // Check if current trip has markers to save
  bool get hasMarkersToSave => _allLongPressedLocations.isNotEmpty;
  Future<void> tripSelected(String tripName) async {
    _isSelectedTripSaved = true;
    notifyListeners();
  }
  Future<void> deleteTripByName(String tripName) async {
    await _routeRepository.deleteTripByName(tripName);
    if(_currentTripName == tripName) {
      _currentTripName = '';
      if (_currentTripRouteLine != null && _vietmapController != null) {
        try {
          await _vietmapController!.removePolyline(_currentTripRouteLine!);
          _currentTripRouteLine = null;
        } catch (e) {
          debugPrint('Error removing trip route line: $e');
        }
      }
    }
    _allLongPressedLocations.clear();
    _allLongPressedEntities.clear();
    _tripWaypoints.clear();
    _tripWaypointEntities.clear();
    _longPressedLocation = null;
    _reverseEntity = null;
    _isOnLongPressedLocation = false;
    _isReverseDrawn = false;
    await loadSavedTripNames();
    notifyListeners();
  }

  void clearSelectedLocation() {
    _selectedPlace = null;
    _selectedPlaceLatLng = null;
    _isOnSelectedLocation = false;
    searchController.clear();
    notifyListeners();
  }

  // Move camera to show all metro stations
  Future<void> showAllMetroStations() async {
    if (_vietmapController == null || metroStations.isEmpty) return;

    try {
      // Calculate bounds manually from metro stations
      double minLat = metroStations.first.latitude;
      double maxLat = metroStations.first.latitude;
      double minLng = metroStations.first.longitude;
      double maxLng = metroStations.first.longitude;

      for (final station in metroStations) {
        if (station.latitude < minLat) minLat = station.latitude;
        if (station.latitude > maxLat) maxLat = station.latitude;
        if (station.longitude < minLng) minLng = station.longitude;
        if (station.longitude > maxLng) maxLng = station.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await _vietmapController!.moveCamera(
        CameraUpdate.newLatLngBounds(bounds, left: 50, right: 50, top: 100, bottom: 100),
      );
    } catch (e) {
      debugPrint('Error showing all metro stations: $e');
    }
  }

  /// Handle metro station symbol tap
  void onSymbolTapped(Symbol symbol) {
    final index = _metroStationSymbols.indexOf(symbol);
    if (index != -1) {
      selectMetroStation(index);
    }
  }

  /// Update symbol appearance when selected
  Future<void> _updateSelectedStationSymbol(int? oldIndex, int? newIndex) async {
    if (_vietmapController == null) return;

    try {
      // Reset old selected symbol
      if (oldIndex != null && oldIndex >= 0 && oldIndex < _metroStationSymbols.length) {
        await _vietmapController!.updateSymbol(
          _metroStationSymbols[oldIndex],
          SymbolOptions(
            iconSize: 0.15,
            textSize: 11,
          ),
        );
      }

      // Highlight new selected symbol
      if (newIndex != null && newIndex >= 0 && newIndex < _metroStationSymbols.length) {
        await _vietmapController!.updateSymbol(
          _metroStationSymbols[newIndex],
          SymbolOptions(
            iconSize: 0.2,
            textSize: 14,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating symbol: $e');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
