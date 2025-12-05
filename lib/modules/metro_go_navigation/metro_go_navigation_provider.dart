import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:vm_first_app/domain/domain.dart';

class MetroGoNavigationProvider extends ChangeNotifier {
  // Navigation controller
  MapNavigationViewController? _navigationController;
  MapNavigationViewController? get navigationController => _navigationController;

  // Navigation plugin and options
  final _vietmapNavigationPlugin = VietMapNavigationPlugin();
  late MapOptions _navigationOption;
  MapOptions get navigationOption => _navigationOption;

  // Waypoints
  final LatLng currentLocation;
  final LatLng selectedLocation;
  final RouteEntity route;
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

  // Constructor
  MetroGoNavigationProvider({
    required this.currentLocation,
    required this.selectedLocation,
    required this.route,
  }) {
    waypoints = [currentLocation, selectedLocation];
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
    debugPrint('From: ${currentLocation.latitude}, ${currentLocation.longitude}');
    debugPrint('To: ${selectedLocation.latitude}, ${selectedLocation.longitude}');
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
    notifyListeners();
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
    debugPrint('i here: $_routeProgressEvent');
    debugPrint('📍 Distance remaining: ${event.distanceRemaining}m');
    debugPrint('⏱️ Duration remaining: ${event.durationRemaining}s');

    notifyListeners();
  }

  /// Called when arrived at destination
  void onArrival() {
    _isNavigating = false;
    debugPrint('🎯 Arrived at destination!');
    notifyListeners();
  }

  /// Start navigation
  void startNavigation() {
    if (!_isRouteBuilt) {
      debugPrint('❌ Route not built yet');
      return;
    }

    _navigationController?.startNavigation();

    _isNavigating = true;
    debugPrint('▶️ Navigation started');
    notifyListeners();
  }

  /// Stop navigation
  void onStopNavigation() {
    _navigationController?.finishNavigation();
    _isNavigating = false;
    _routeProgressEvent = null;

    notifyListeners();
  }

  /// Clear route
  void clearRoute() {
    _navigationController?.clearRoute();
    _isRouteBuilt = false;
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