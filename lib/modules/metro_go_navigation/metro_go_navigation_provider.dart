import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:vm_first_app/domain/domain.dart';

class MetroGoNavigationProvider extends ChangeNotifier {
  // Navigation controller
  MapNavigationViewController? _navigationController;
  MapNavigationViewController? get navigationController => _navigationController;

  // Waypoint markers
  List<NavigationMarker> _waypointMarkers = [];
  List<NavigationMarker> get waypointMarkers => _waypointMarkers;

  // Navigation plugin and options
  final _vietmapNavigationPlugin = VietMapNavigationPlugin();
  late MapOptions _navigationOption;
  MapOptions get navigationOption => _navigationOption;

  // Waypoints
  final LatLng currentLocation;
  final List<LatLng> listLocations;
  final RouteEntity route;

  // Get first destination from list (for backward compatibility)
  LatLng? get selectedLocation => listLocations.isNotEmpty ? listLocations.first : null;

  // Get last destination
  LatLng? get destinationLocation => listLocations.isNotEmpty ? listLocations.last : null;

  List<LatLng> waypoints = [];

  // Route progress
  RouteProgressEvent? _routeProgressEvent;
  RouteProgressEvent? get routeProgressEvent => _routeProgressEvent;

  // Instruction image for BannerInstructionView
  Widget _instructionImage = const SizedBox.shrink();
  Widget get instructionImage => _instructionImage;

  // Recenter button state
  Widget _recenterButton = const SizedBox.shrink();
  Widget get recenterButton => _recenterButton;

  // State flags
  bool _isRouteBuilt = false;
  bool get isRouteBuilt => _isRouteBuilt;

  bool _isNavigating = false;
  bool get isNavigating => _isNavigating;

  bool _isInitializingNavigation = false;
  bool get isInitializingNavigation => _isInitializingNavigation;

  bool _pendingNavigationRoute = false;
  bool get hasPendingNavigationRoute => _pendingNavigationRoute;

  // Multi-waypoint navigation tracking
  int _currentWaypointIndex = 0;
  int get currentWaypointIndex => _currentWaypointIndex;

  // Get current target waypoint (the one we're navigating to)
  LatLng? get currentTargetWaypoint =>
      _currentWaypointIndex < listLocations.length
          ? listLocations[_currentWaypointIndex]
          : null;

  // Get next waypoint after current target
  LatLng? get nextWaypoint =>
      (_currentWaypointIndex + 1) < listLocations.length
          ? listLocations[_currentWaypointIndex + 1]
          : null;

  // Check if there are more waypoints after current
  bool get hasMoreWaypoints => (_currentWaypointIndex + 1) < listLocations.length;

  // Get total number of waypoints (excluding start)
  int get totalWaypoints => listLocations.length;

  // Get remaining waypoints count
  int get remainingWaypoints => listLocations.length - _currentWaypointIndex;

  // Check if at final destination
  bool get isAtFinalDestination => _currentWaypointIndex >= listLocations.length - 1;

  // Constructor
  MetroGoNavigationProvider({
    required this.currentLocation,
    required this.listLocations,
    required this.route,
  }) {
    waypoints = [currentLocation, ...listLocations];
    _initializeNavigationOptions();
  }

  /// Initialize NavigationView options
  void _initializeNavigationOptions() {
    _navigationOption = _vietmapNavigationPlugin.getDefaultOptions();

    _navigationOption.simulateRoute = false;
    _navigationOption.apiKey = dotenv.env['VM_API_KEY'] ?? '';
    _navigationOption.mapStyle =
        "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=${dotenv.env['VM_API_KEY']}";
    _navigationOption.zoom = 15.0;
    _navigationOption.tilt = 0.0;
    _navigationOption.bearing = 0.0;
    _navigationOption.language = 'vi';
    _navigationOption.voiceInstructionsEnabled = true;
    _navigationOption.bannerInstructionsEnabled = true;

    _vietmapNavigationPlugin.setDefaultOptions(_navigationOption);

    debugPrint('✅ Navigation options initialized');
    debugPrint('📍 From: ${currentLocation.latitude}, ${currentLocation.longitude}');
    debugPrint('🎯 Total destinations: ${listLocations.length}');

    // Log all waypoints
    for (int i = 0; i < listLocations.length; i++) {
      final location = listLocations[i];
      final label = i == listLocations.length - 1 ? 'Final destination' : 'Waypoint ${i + 1}';
      debugPrint('  $label: ${location.latitude}, ${location.longitude}');
    }

    debugPrint('📊 Total navigation waypoints: ${waypoints.length}');
  }

  /// Called when NavigationView controller is created
  void onNavigationControllerCreated(MapNavigationViewController controller) {
    _navigationController = controller;
    debugPrint('✅ Navigation controller created');
    notifyListeners();
  }

  /// Package recommendation: Called when NavigationView map is rendered
  void onMapRendered() {
    debugPrint('✅ Navigation map rendered successfully');

    _isInitializingNavigation = false;

    // Auto-build route when map is ready
    if (!_isRouteBuilt && _navigationController != null) {
      debugPrint('🚀 Auto-building route on map rendered...');
      _buildRoute();
    }

    notifyListeners();
  }

  /// Build route
  Future<void> _buildRoute() async {
    if (_navigationController == null) {
      debugPrint('❌ Controller is null, cannot build route');
      return;
    }

    try {
      debugPrint('🚀 Building navigation route...');
      debugPrint('Waypoints: ${waypoints.length}');

      await _navigationController?.buildRoute(
        waypoints: waypoints,
        profile: DrivingProfile.drivingTraffic,
      );

      debugPrint('✅ Build route request sent');
    } catch (e) {
      debugPrint('❌ Error building route: $e');
    }
  }

  /// Called when route is built successfully
  void onRouteBuilt(dynamic route) {
    _isRouteBuilt = true;
    debugPrint('✅ Navigation route built successfully');
    debugPrint('Route geometry: ${route.geometry}');

    // Add waypoint markers after route is built
    _addWaypointMarkers();

    notifyListeners();
  }

  /// Add markers for all waypoints on the map
  Future<void> _addWaypointMarkers() async {
    if (_navigationController == null || listLocations.isEmpty) return;

    try {
      // Clear existing markers first
      await _navigationController?.removeAllMarkers();

      // Create markers for each waypoint
      _waypointMarkers = [];
      debugPrint('i here: ${listLocations.length}');
      debugPrint('destination: $destinationLocation');
      for (int i = 0; i < listLocations.length; i++) {
        final location = listLocations[i];
          final marker = NavigationMarker(
            imagePath: 'assets/icons/placeholder.png',
            latLng: location,
            title: 'Điểm ${i + 1}',
            snippet: 'Điểm dừng ${i + 1}/${listLocations.length}',
            width: 20,
            height: 20,
          );

          _waypointMarkers.add(marker);
      }
      // Add markers to map
      if (_waypointMarkers.isNotEmpty) {
        await _navigationController?.addImageMarkers(_waypointMarkers);
        debugPrint('✅ Added ${_waypointMarkers.length} waypoint markers');
      }
    } catch (e) {
      debugPrint('❌ Error adding waypoint markers: $e');
    }
  }

  /// Remove all waypoint markers
  Future<void> _removeWaypointMarkers() async {
    if (_navigationController == null) return;

    try {
      await _navigationController?.removeAllMarkers();
      _waypointMarkers.clear();
      debugPrint('🗑️ Removed all waypoint markers');
    } catch (e) {
      debugPrint('❌ Error removing waypoint markers: $e');
    }
  }

  /// Called when route build failed
  void onRouteBuildFailed(dynamic error) {
    _isRouteBuilt = false;
    debugPrint('❌ Navigation route build failed: $error');
    notifyListeners();
  }

  /// Called when route progress changes
  void onRouteProgressChange(RouteProgressEvent event) {
    _routeProgressEvent = event;

    // Log progress for debugging
    debugPrint('📍 Current waypoint: ${_currentWaypointIndex + 1}/$totalWaypoints');
    debugPrint('📍 Distance remaining: ${event.distanceRemaining}m');
    debugPrint('⏱️ Duration remaining: ${event.durationRemaining}s');

    notifyListeners();
  }

  /// Called when arrived at a waypoint (intermediate or final)
  void onArrival() {
    debugPrint('🎯 Arrived at waypoint ${_currentWaypointIndex + 1}/$totalWaypoints');

    if (hasMoreWaypoints) {
      // Arrived at intermediate waypoint, move to next
      _currentWaypointIndex++;
      debugPrint('➡️ Moving to next waypoint: ${_currentWaypointIndex + 1}/$totalWaypoints');
      notifyListeners();
    } else {
      // Arrived at final destination
      _isNavigating = false;
      debugPrint('🏁 Arrived at FINAL destination!');
      notifyListeners();
    }
  }

  /// Called when arrived at intermediate waypoint - continue to next
  void onWaypointArrival(int waypointIndex) {
    debugPrint('📍 Arrived at waypoint $waypointIndex');

    if (waypointIndex < listLocations.length - 1) {
      _currentWaypointIndex = waypointIndex + 1;
      debugPrint('➡️ Continuing to waypoint ${_currentWaypointIndex + 1}');
      notifyListeners();
    }
  }

  /// Skip to next waypoint manually
  void skipToNextWaypoint() {
    if (hasMoreWaypoints) {
      _currentWaypointIndex++;
      debugPrint('⏭️ Skipped to waypoint ${_currentWaypointIndex + 1}/$totalWaypoints');

      // Rebuild route from current location to remaining waypoints
      _rebuildRouteFromCurrentPosition();
      notifyListeners();
    }
  }

  /// Rebuild route from current position to remaining waypoints
  Future<void> _rebuildRouteFromCurrentPosition() async {
    if (_navigationController == null) return;

    try {
      // Get remaining waypoints including current target
      final remainingWaypointsList = listLocations.sublist(_currentWaypointIndex);

      // Build new waypoints list: current position + remaining destinations
      final newWaypoints = [currentLocation, ...remainingWaypointsList];

      debugPrint('🔄 Rebuilding route with ${newWaypoints.length} waypoints');

      await _navigationController?.buildRoute(
        waypoints: newWaypoints,
        profile: DrivingProfile.drivingTraffic,
      );
    } catch (e) {
      debugPrint('❌ Error rebuilding route: $e');
    }
  }

  /// Get waypoint info by index
  String getWaypointLabel(int index) {
    if (index == 0) return 'Điểm xuất phát';
    if (index == listLocations.length) return 'Điểm đến cuối';
    return 'Điểm dừng $index';
  }

  /// Reset waypoint tracking (for restart navigation)
  void resetWaypointTracking() {
    _currentWaypointIndex = 0;
    notifyListeners();
  }

  /// Start navigation
  void startNavigation() {
    if (!_isRouteBuilt) {
      debugPrint('❌ Route not built yet');
      return;
    }

    // Reset waypoint tracking when starting navigation
    _currentWaypointIndex = 0;

    _navigationController?.startNavigation();

    _isNavigating = true;
    debugPrint('▶️ Navigation started');
    debugPrint('🎯 Navigating through ${listLocations.length} waypoints');
    debugPrint('➡️ First target: waypoint 1/${listLocations.length}');
    notifyListeners();
  }

  /// Stop navigation
  void onStopNavigation() {
    _navigationController?.finishNavigation();
    _isNavigating = false;
    _routeProgressEvent = null;
    _currentWaypointIndex = 0; // Reset waypoint index

    notifyListeners();
  }

  /// Clear route
  void clearRoute() {
    _navigationController?.clearRoute();
    _removeWaypointMarkers(); // Also remove markers
    _isRouteBuilt = false;
    _currentWaypointIndex = 0; // Reset waypoint index
    debugPrint('🗑️ Route cleared');
    notifyListeners();
  }

  /// Recenter camera
  void recenterCamera() {
    _navigationController?.recenter();
    debugPrint('📍 Camera recentered');
  }

  /// Overview route
  void overviewRoute() {
    _navigationController?.overview();
    debugPrint('🗺️ Route overview');
  }

  /// Set instruction image for BannerInstructionView
  void setInstructionImage(String? modifier, String? type) {
    if (modifier != null && type != null) {
      // Map instruction type to icon
      IconData iconData = Icons.navigation;

      if (modifier.contains('left')) {
        iconData = Icons.turn_left;
      } else if (modifier.contains('right')) {
        iconData = Icons.turn_right;
      } else if (modifier.contains('straight')) {
        iconData = Icons.straight;
      } else if (type.contains('arrive')) {
        iconData = Icons.place;
      } else if (type.contains('depart')) {
        iconData = Icons.trip_origin;
      }

      _instructionImage = Icon(
        iconData,
        color: Colors.white,
        size: 50,
      );

      notifyListeners();
      debugPrint('🧭 Instruction image updated: $type - $modifier');
    }
  }

  /// Show recenter button
  void showRecenterButton() {
    _recenterButton = TextButton(
      onPressed: () {
        recenterCamera();
        hideRecenterButton();
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.white,
          border: Border.all(color: Colors.black45, width: 1),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.keyboard_double_arrow_up_sharp,
              color: Color(0xFF2196F3),
              size: 35,
            ),
            Text(
              'Về giữa',
              style: TextStyle(fontSize: 18, color: Color(0xFF2196F3)),
            )
          ],
        ),
      ),
    );
    notifyListeners();
  }

  /// Hide recenter button
  void hideRecenterButton() {
    _recenterButton = const SizedBox.shrink();
    notifyListeners();
  }

  @override
  void dispose() {
    _navigationController?.onDispose();
    debugPrint('🧹 MetroGoNavigationProvider disposed');
    super.dispose();
  }
}