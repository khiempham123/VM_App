# Fix Navigation and Polyline Decoding Errors

## Tổng Quan Vấn Đề (Problem Overview)

### Lỗi Gặp Phải
```
❌ Error getting route: DioException [bad response]: 
Error: -8
❌ Error in onRouteSelected: NoSuchMethodError: The method 'decodePolyline' was called on null.
Receiver: null
Tried calling: decodePolyline("...")
```

### Nguyên Nhân
1. **API trả về đúng dữ liệu nhưng bị xử lý sai**: Mặc dù API Vietmap trả về response thành công với encoded polyline, nhưng code đang gặp lỗi `NoSuchMethodError` khi decode polyline.

2. **Sử dụng sai cách `PolylinePoints`**: Code đang cố gắng gọi `decodePolyline` trên một đối tượng null hoặc sử dụng sai phương thức static/instance.

3. **Thiếu state management cho NavigationView**: `_MetroMapView` là StatelessWidget nhưng lại cố gọi `setState()` và truy cập các biến state không tồn tại.

---

## Giải Pháp Chi Tiết (Detailed Solution)

### 1. Fix PolylinePoints Decoding

#### ❌ Lỗi Code Cũ
```dart
// Sai: Gọi static method như instance method
latLngList = PolylinePoints.decodePolyline(encodedPolyline);

// Hoặc tạo instance không đúng
final PolylinePoints _polylinePoints = PolylinePoints(); // Thiếu API key
latLngList = _polylinePoints.decodePolyline(encodedPolyline);
```

#### ✅ Code Đúng
```dart
// Đúng: Tạo instance mới và gọi method
latLngList = PolylinePoints().decodePolyline(encodedPolyline);
```

**Giải thích**: Package `flutter_polyline_points` version 3.x không yêu cầu API key cho việc decode polyline (chỉ cần cho Google Maps directions API). Method `decodePolyline()` là instance method, nên phải tạo instance trước.

### 2. Convert StatelessWidget to StatefulWidget

#### ❌ Lỗi Code Cũ
```dart
class _MetroMapView extends StatelessWidget {
  const _MetroMapView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>();
    
    return Scaffold(
      body: Stack(
        children: [
          provider.isOnRoute ? NavigationView(
            mapOptions: _navigationOption, // ❌ Undefined
            onMapCreated: (controller) {
              provider.navigationController; // ❌ No assignment
            },
            onRouteProgressChange: (RouteProgressEvent routeProgressEvent) {
              setState(() { // ❌ Can't call setState in StatelessWidget
                this.routeProgressEvent = routeProgressEvent; // ❌ Not defined
              });
              _setInstructionImage(...); // ❌ Not defined
            },
          ) : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
```

#### ✅ Code Đúng
```dart
class _MetroMapView extends StatefulWidget {
  const _MetroMapView();

  @override
  State<_MetroMapView> createState() => _MetroMapViewState();
}

class _MetroMapViewState extends State<_MetroMapView> {
  MapOptions? _navigationOption;
  RouteProgressEvent? routeProgressEvent;
  String? _instruction = "";

  void _setInstructionImage(String? modifier, String? type) {
    if (modifier != null && type != null) {
      setState(() {
        _instruction = "$type - $modifier";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>();
    
    return Scaffold(
      body: Stack(
        children: [
          provider.isOnRoute && _navigationOption != null
              ? NavigationView(
                  mapOptions: _navigationOption!,
                  onMapCreated: (controller) {
                    // Store controller if needed
                  },
                  onRouteProgressChange: (RouteProgressEvent event) {
                    setState(() {
                      routeProgressEvent = event;
                    });
                    _setInstructionImage(
                      event.currentModifier,
                      event.currentModifierType,
                    );
                  },
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
```

---

## Package Information: vietmap_flutter_navigation

### Package Details
- **Package**: `vietmap_flutter_navigation`
- **Version**: ^4.1.0
- **Pub.dev**: https://pub.dev/packages/vietmap_flutter_navigation

### Key Features
1. **Turn-by-turn Navigation**: Hỗ trợ điều hướng từng bước với voice guidance
2. **Route Progress Tracking**: Theo dõi tiến trình di chuyển real-time
3. **Navigation Events**: Callbacks cho các sự kiện navigation
4. **Multiple Waypoints**: Hỗ trợ nhiều điểm dừng trung gian

### Core Components

#### 1. NavigationView Widget
```dart
NavigationView(
  mapOptions: MapOptions(
    zoom: 15.0,
    tilt: 0.0,
    bearing: 0.0,
    // Các options khác
  ),
  onMapCreated: (MapNavigationViewController controller) {
    // Lưu controller để điều khiển navigation
  },
  onRouteProgressChange: (RouteProgressEvent event) {
    // Xử lý sự kiện thay đổi progress
    // event.currentModifier: "turn-left", "turn-right", etc.
    // event.currentModifierType: "turn", "arrive", etc.
  },
)
```

#### 2. MapOptions Configuration
```dart
MapOptions(
  zoom: 15.0,
  tilt: 0.0,
  bearing: 0.0,
  animationDuration: 300,
  // Waypoints
  wayPoints: [
    LatLng(10.762317, 106.654551), // Start
    LatLng(10.770000, 106.660000), // End
  ],
  // Navigation settings
  navigationMode: NavigationMode.driving,
  simulateRoute: false, // Set true for testing
  language: 'vi', // Vietnamese language
  voiceInstructions: true,
  bannerInstructions: true,
)
```

#### 3. RouteProgressEvent Properties
```dart
class RouteProgressEvent {
  final String? currentModifier;        // e.g., "left", "right", "straight"
  final String? currentModifierType;    // e.g., "turn", "arrive", "depart"
  final double? distanceRemaining;      // Meters
  final double? durationRemaining;      // Seconds
  final LatLng? currentLocation;        // Current user location
  // ... other properties
}
```

### Usage Flow

#### Step 1: Initialize Navigation Options
```dart
class _MetroMapViewState extends State<_MetroMapView> {
  MapOptions? _navigationOption;

  void _initializeNavigation(LatLng start, LatLng end) {
    setState(() {
      _navigationOption = MapOptions(
        zoom: 15.0,
        tilt: 0.0,
        bearing: 0.0,
        wayPoints: [start, end],
        navigationMode: NavigationMode.driving,
        simulateRoute: false,
        language: 'vi',
        voiceInstructions: true,
        bannerInstructions: true,
      );
    });
  }
}
```

#### Step 2: Trigger Navigation When Route is Ready
```dart
// In MetroMapProvider
Future<void> onRouteSelected() async {
  _isCalculatingRoute = true;
  notifyListeners();

  try {
    // Get route from API
    final routeEntity = await _routeRepository.getRoute(routeRequest);

    if (routeEntity != null && routeEntity.paths.isNotEmpty) {
      // Decode polyline
      final String encodedPolyline = routeEntity.paths[0].points;
      latLngList = PolylinePoints().decodePolyline(encodedPolyline);
      
      // Convert to LatLng list
      latLngListForRoute.clear();
      for (var latLng in latLngList) {
        latLngListForRoute.add(LatLng(latLng.latitude, latLng.longitude));
      }

      // Draw polyline on map
      await _vietmapController?.addPolyline(PolylineOptions(
        geometry: latLngListForRoute,
        polylineColor: Colors.blue,
        polylineWidth: 4.0,
      ));

      _isOnRoute = true;
      _isCalculatingRoute = false;
      notifyListeners();
    }
  } catch (e) {
    _errorMessage = 'Error calculating route: $e';
    _isCalculatingRoute = false;
    notifyListeners();
  }
}
```

#### Step 3: Handle Navigation Events
```dart
NavigationView(
  mapOptions: _navigationOption!,
  onMapCreated: (MapNavigationViewController controller) {
    // Save controller for later use
    _navigationController = controller;
  },
  onRouteProgressChange: (RouteProgressEvent event) {
    setState(() {
      routeProgressEvent = event;
    });
    
    // Update UI based on navigation progress
    _updateNavigationUI(event);
  },
)

void _updateNavigationUI(RouteProgressEvent event) {
  // Update instruction text
  final instruction = "${event.currentModifierType} ${event.currentModifier}";
  
  // Update distance remaining
  final distanceKm = (event.distanceRemaining ?? 0) / 1000;
  
  // Update duration remaining
  final durationMin = (event.durationRemaining ?? 0) / 60;
}
```

---

## Implementation Checklist

### ✅ Fixed Issues
- [x] Fix `PolylinePoints().decodePolyline()` usage
- [x] Convert `_MetroMapView` to StatefulWidget
- [x] Add state variables: `_navigationOption`, `routeProgressEvent`, `_instruction`
- [x] Add `_setInstructionImage()` method
- [x] Fix NavigationView integration

### 🔄 Additional Improvements Needed

#### 1. Initialize NavigationView Properly
Bạn cần thêm logic để khởi tạo `_navigationOption` khi route được tính toán:

```dart
// In metro_map_provider.dart
// Add getter for navigation waypoints
List<LatLng> getNavigationWaypoints() {
  if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
    return [];
  }
  return [_currentPlaceLatLng!, _selectedPlaceLatLng!];
}

// In metro_map_screen.dart
@override
void initState() {
  super.initState();
  
  // Listen to provider changes
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final provider = context.read<MetroMapProvider>();
    provider.addListener(_onProviderChanged);
  });
}

void _onProviderChanged() {
  final provider = context.read<MetroMapProvider>();
  
  if (provider.isOnRoute && _navigationOption == null) {
    final waypoints = provider.getNavigationWaypoints();
    if (waypoints.length >= 2) {
      setState(() {
        _navigationOption = MapOptions(
          zoom: 15.0,
          tilt: 0.0,
          bearing: 0.0,
          wayPoints: waypoints,
          navigationMode: NavigationMode.driving,
          simulateRoute: false,
          language: 'vi',
          voiceInstructions: true,
          bannerInstructions: true,
        );
      });
    }
  }
}

@override
void dispose() {
  final provider = context.read<MetroMapProvider>();
  provider.removeListener(_onProviderChanged);
  super.dispose();
}
```

#### 2. Add Navigation Controls
```dart
// Add buttons to control navigation
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    ElevatedButton(
      onPressed: () => _navigationController?.startNavigation(),
      child: Text('Start'),
    ),
    ElevatedButton(
      onPressed: () => _navigationController?.stopNavigation(),
      child: Text('Stop'),
    ),
    ElevatedButton(
      onPressed: () => _navigationController?.recenterCamera(),
      child: Text('Recenter'),
    ),
  ],
)
```

#### 3. Display Navigation Info UI
```dart
if (provider.isOnRoute && routeProgressEvent != null)
  Positioned(
    top: 100,
    left: 16,
    right: 16,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instruction: ${routeProgressEvent?.currentModifierType} ${routeProgressEvent?.currentModifier}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Distance: ${((routeProgressEvent?.distanceRemaining ?? 0) / 1000).toStringAsFixed(2)} km',
            ),
            Text(
              'Duration: ${((routeProgressEvent?.durationRemaining ?? 0) / 60).toStringAsFixed(0)} min',
            ),
          ],
        ),
      ),
    ),
  ),
```

---

## Testing Guide

### 1. Test Polyline Decoding
```dart
final encodedPolyline = "mpt`A{fbjSOMk@m@..."; // From API
final decoded = PolylinePoints().decodePolyline(encodedPolyline);
print('Decoded ${decoded.length} points');
```

### 2. Test Navigation in Simulator Mode
```dart
_navigationOption = MapOptions(
  // ...
  simulateRoute: true, // Enable simulation for testing
  // ...
);
```

### 3. Test Route Calculation
```dart
// Add debug logs in onRouteSelected
debugPrint('Route distance: $_routeDistance km');
debugPrint('Route duration: $_routeDuration min');
debugPrint('Polyline points: ${latLngListForRoute.length}');
```

---

## Common Errors and Solutions

### Error 1: "The method 'decodePolyline' was called on null"
**Solution**: Đã fix bằng cách sử dụng `PolylinePoints().decodePolyline()`

### Error 2: "setState() called in StatelessWidget"
**Solution**: Đã chuyển thành StatefulWidget

### Error 3: "_navigationOption is null"
**Solution**: Cần khởi tạo `_navigationOption` trước khi hiển thị NavigationView

### Error 4: "DioException [bad response]: Error: -8"
**Possible Causes**:
1. API key không hợp lệ
2. Request parameters không đúng format
3. Network timeout
4. Backend error code -8 (check API documentation)

**Debug Steps**:
```dart
// Check API response before processing
debugPrint('API Response: ${response.data}');
debugPrint('Status Code: ${response.statusCode}');
debugPrint('Response Message: ${response.data['message']}');
```

---

## Best Practices

### 1. Error Handling
```dart
try {
  final decoded = PolylinePoints().decodePolyline(encodedPolyline);
  if (decoded.isEmpty) {
    throw Exception('Decoded polyline is empty');
  }
  // Process decoded points
} catch (e) {
  debugPrint('Error decoding polyline: $e');
  _errorMessage = 'Failed to decode route';
  notifyListeners();
}
```

### 2. Null Safety
```dart
// Always check null before using
if (_currentPlaceLatLng != null && _selectedPlaceLatLng != null) {
  // Proceed with route calculation
} else {
  _errorMessage = 'Please select start and end locations';
  notifyListeners();
  return;
}
```

### 3. Resource Management
```dart
@override
void dispose() {
  _navigationController?.dispose();
  searchController.dispose();
  super.dispose();
}
```

---

## References

1. **Vietmap Flutter Navigation**
   - Pub.dev: https://pub.dev/packages/vietmap_flutter_navigation
   - GitHub: https://github.com/vietmap-company/vietmap-flutter-navigation

2. **Flutter Polyline Points**
   - Pub.dev: https://pub.dev/packages/flutter_polyline_points
   - Usage: Decode Google-encoded polylines

3. **Vietmap API Documentation**
   - Route API: https://maps.vietmap.vn/docs/route-api

---

## Next Steps

1. ✅ **Fix syntax errors** - COMPLETED
2. 🔄 **Test polyline decoding** - TODO
3. 🔄 **Initialize NavigationView properly** - TODO
4. 🔄 **Add navigation controls** - TODO
5. 🔄 **Test end-to-end navigation flow** - TODO

---

## Summary

### Những Thay Đổi Đã Thực Hiện
1. ✅ Fix `PolylinePoints().decodePolyline()` - sử dụng đúng instance method
2. ✅ Convert `_MetroMapView` sang StatefulWidget
3. ✅ Thêm state management cho NavigationView
4. ✅ Fix all syntax errors

### Những Gì Cần Làm Tiếp
1. Initialize `_navigationOption` khi route được tính toán
2. Add navigation controls (start, stop, recenter)
3. Display navigation info UI
4. Test với real device hoặc simulator mode

### Kết Quả Mong Đợi
- ✅ API trả về route thành công
- ✅ Polyline được decode chính xác
- ✅ NavigationView hoạt động với turn-by-turn instructions
- ✅ Voice guidance hoạt động (on real device)
- ✅ UI hiển thị progress real-time

