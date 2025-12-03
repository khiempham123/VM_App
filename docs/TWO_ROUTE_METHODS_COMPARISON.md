# Hướng Dẫn Sử Dụng 2 Phương Pháp Route Trong Metro Map

## 📋 Tổng Quan

Project hiện tại đã được cập nhật để hỗ trợ **2 phương pháp** tạo và hiển thị route:

### 1. ⚡ Simple Route Drawing (VietmapGL + Polyline)
- **Button**: `Icons.assistant_direction` (bottom: 50)
- **Method**: `provider.onRouteSelected()`
- **Mục đích**: Vẽ route đơn giản trên VietmapGL
- **Không có**: Navigation callbacks, voice instructions, turn-by-turn

### 2. 🧭 Full Navigation (NavigationView + Callbacks)
- **Button**: `Icons.near_me_outlined` (bottom: 100)  
- **Method**: `provider.buildNavigationRoute()`
- **Mục đích**: Navigation đầy đủ với callbacks, voice, turn-by-turn
- **Có đầy đủ**: All NavigationView callbacks

---

## 🎯 Khi Nào Dùng Phương Pháp Nào?

### Dùng Simple Route Drawing Khi:
- ✅ Chỉ cần **preview route** trên map
- ✅ Không cần voice instructions
- ✅ Không cần theo dõi tiến trình real-time
- ✅ Chỉ muốn **vẽ đường đi** đơn giản
- ✅ Performance quan trọng (nhẹ hơn NavigationView)

**Ví dụ**: Hiển thị route từ điểm A đến điểm B để user xem trước.

### Dùng Full Navigation Khi:
- ✅ Cần **điều hướng turn-by-turn**
- ✅ Cần **voice instructions** (tiếng Việt)
- ✅ Cần theo dõi **tiến trình real-time** (distance, duration remaining)
- ✅ Cần **callbacks** khi route built/failed/arrived
- ✅ Cần điều khiển navigation (start, stop, recenter, overview)

**Ví dụ**: User đang đi từ điểm A đến điểm B và cần hướng dẫn từng bước.

---

## 🔧 Chi Tiết Implementation

### Phương Pháp 1: Simple Route Drawing

#### Provider Method
```dart
Future<void> onRouteSelected() async {
  _isCalculatingRoute = true;
  _errorMessage = null;
  notifyListeners();

  try {
    // Call Route API
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
      // Get encoded polyline from API
      final String encodedPolyline = routeEntity.paths[0].points;
      
      // Decode polyline
      latLngList = PolylinePoints.decodePolyline(encodedPolyline);
      
      // Convert to LatLng list
      latLngListForRoute.clear();
      for (var latLng in latLngList) {
        latLngListForRoute.add(LatLng(latLng.latitude, latLng.longitude));
      }
      
      // Draw polyline on VietmapGL
      await _vietmapController?.addPolyline(PolylineOptions(
        geometry: latLngListForRoute,
        polylineColor: Colors.black,
        polylineWidth: 2.0,
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

#### Screen Usage
```dart
FloatingActionButton(
  mini: true,
  tooltip: 'Vẽ route đơn giản',
  onPressed: () {
    provider.onRouteSelected(); // Simple route drawing
  },
  child: const Icon(Icons.assistant_direction, color: AppColors.primary),
)
```

**Flow**:
1. User clicks button
2. Call Route API → get encoded polyline
3. Decode polyline using `flutter_polyline_points`
4. Draw polyline on VietmapGL
5. Done - no callbacks, no navigation

---

### Phương Pháp 2: Full Navigation

#### Provider Methods

##### 1. Initialize Navigation Options
```dart
void _initializeNavigationOptions() {
  _navigationOption = _vietmapNavigationPlugin.getDefaultOptions();
  
  _navigationOption.simulateRoute = false;
  _navigationOption.apiKey = dotenv.env['VM_API_KEY'] ?? '';
  _navigationOption.mapStyle = 
      "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=${dotenv.env['VM_API_KEY']}";
  _navigationOption.zoom = 15.0;
  _navigationOption.language = 'vi';
  _navigationOption.voiceInstructionsEnabled = true;
  _navigationOption.bannerInstructionsEnabled = true;
  
  _vietmapNavigationPlugin.setDefaultOptions(_navigationOption);
}
```

##### 2. Build Navigation Route
```dart
Future<void> buildNavigationRoute() async {
  if (_navigationController == null) {
    debugPrint('❌ Navigation controller is null');
    return;
  }
  
  if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
    debugPrint('❌ Missing start or end location');
    return;
  }
  
  _isCalculatingRoute = true;
  notifyListeners();
  
  try {
    final waypoints = [_currentPlaceLatLng!, _selectedPlaceLatLng!];
    
    // Build route using NavigationView API
    await _navigationController?.buildRoute(
      waypoints: waypoints,
      profile: DrivingProfile.drivingTraffic,
    );
    
    // Result will come in onNavigationRouteBuilt callback
  } catch (e) {
    debugPrint('❌ Error building navigation route: $e');
    _isCalculatingRoute = false;
    notifyListeners();
  }
}
```

##### 3. Handle Callbacks
```dart
// Called when route is built successfully
void onNavigationRouteBuilt(dynamic route) {
  _isOnNavigationRoute = true;
  _isCalculatingRoute = false;
  
  debugPrint('✅ Navigation route built successfully');
  notifyListeners();
}

// Called when route build failed
void onNavigationRouteBuildFailed(dynamic error) {
  _isCalculatingRoute = false;
  _errorMessage = 'Failed to build navigation route: $error';
  
  debugPrint('❌ Navigation route build failed: $error');
  notifyListeners();
}

// Called when route progress changes (real-time)
void onNavigationRouteProgressChange(RouteProgressEvent event) {
  _routeProgressEvent = event;
  
  debugPrint('📍 Distance remaining: ${event.distanceRemaining}m');
  debugPrint('⏱️ Duration remaining: ${event.durationRemaining}s');
  debugPrint('🧭 Current modifier: ${event.currentModifier}');
  
  notifyListeners();
}

// Called when arrived at destination
void onNavigationArrival() {
  _isOnNavigationRoute = false;
  debugPrint('🎯 Arrived at destination!');
  notifyListeners();
}
```

##### 4. Control Methods
```dart
// Start navigation
void startNavigation() {
  if (!_isOnNavigationRoute) {
    debugPrint('❌ Route not built yet');
    return;
  }
  
  _navigationController?.startNavigation();
  debugPrint('▶️ Navigation started');
}

// Stop navigation
void stopNavigation() {
  _navigationController?.finishNavigation();
  _isOnNavigationRoute = false;
  _routeProgressEvent = null;
  debugPrint('⏹️ Navigation stopped');
  notifyListeners();
}

// Recenter camera
void recenterCamera() {
  _navigationController?.recenter();
  debugPrint('📍 Camera recentered');
}

// Overview route
void overviewRoute() {
  _navigationController?.overview();
  debugPrint('🗺️ Route overview');
}
```

#### Screen Usage

##### NavigationView Widget
```dart
provider.isOnNavigationRoute
    ? NavigationView(
        mapOptions: provider.navigationOption,
        
        // Controller created
        onMapCreated: (controller) {
          provider.onNavigationControllerCreated(controller);
        },
        
        // Map rendered
        onMapRendered: () {
          debugPrint('✅ Navigation map rendered');
        },
        
        // Route built successfully
        onRouteBuilt: (route) {
          provider.onNavigationRouteBuilt(route);
        },
        
        // Route build failed
        onRouteBuildFailed: (error) {
          provider.onNavigationRouteBuildFailed(error);
        },
        
        // Route progress change (real-time)
        onRouteProgressChange: (RouteProgressEvent event) {
          provider.onNavigationRouteProgressChange(event);
          
          setState(() {
            routeProgressEvent = event;
          });
          
          _setInstructionImage(
            event.currentModifier,
            event.currentModifierType,
          );
        },
        
        // Arrived at destination
        onArrival: () {
          provider.onNavigationArrival();
        },
        
        // Map interactions
        onMapLongClick: provider.onMapLongSelected,
      )
    : const SizedBox.shrink(),
```

##### Control Buttons
```dart
// Main navigation button
FloatingActionButton(
  mini: true,
  tooltip: 'Bắt đầu điều hướng',
  onPressed: () {
    provider.buildNavigationRoute(); // Build navigation route
  },
  child: const Icon(Icons.near_me_outlined, color: AppColors.primary),
)

// Additional controls when navigation is active
if (provider.isOnNavigationRoute) ...[
  // Start button
  FloatingActionButton(
    backgroundColor: Colors.green,
    onPressed: provider.startNavigation,
    child: const Icon(Icons.play_arrow),
  ),
  
  // Stop button
  FloatingActionButton(
    backgroundColor: Colors.red,
    onPressed: provider.stopNavigation,
    child: const Icon(Icons.stop),
  ),
  
  // Recenter button
  FloatingActionButton(
    onPressed: provider.recenterCamera,
    child: const Icon(Icons.my_location),
  ),
  
  // Overview button
  FloatingActionButton(
    onPressed: provider.overviewRoute,
    child: const Icon(Icons.map),
  ),
]
```

##### Navigation Info Display
```dart
if (provider.isOnNavigationRoute && routeProgressEvent != null)
  Card(
    child: Column(
      children: [
        // Instruction
        Row(
          children: [
            Icon(Icons.turn_right),
            Text(_instruction!),
          ],
        ),
        
        // Distance remaining
        Row(
          children: [
            Icon(Icons.straighten),
            Text('Còn lại: ${(event.distanceRemaining / 1000).toStringAsFixed(1)} km'),
          ],
        ),
        
        // Duration remaining
        Row(
          children: [
            Icon(Icons.access_time),
            Text('Thời gian: ${(event.durationRemaining / 60).toStringAsFixed(0)} phút'),
          ],
        ),
      ],
    ),
  ),
```

**Flow**:
1. User clicks navigation button
2. `buildNavigationRoute()` called
3. NavigationView builds route → `onRouteBuilt` callback
4. User clicks "Start" → `startNavigation()`
5. Real-time updates → `onRouteProgressChange` callback
6. UI updates with distance, duration, instructions
7. Arrive → `onArrival` callback
8. Stop → `stopNavigation()`

---

## 🔄 So Sánh 2 Phương Pháp

| Feature | Simple Route Drawing | Full Navigation |
|---------|---------------------|-----------------|
| **Vẽ route trên map** | ✅ | ✅ |
| **Voice instructions** | ❌ | ✅ |
| **Turn-by-turn guidance** | ❌ | ✅ |
| **Real-time progress** | ❌ | ✅ |
| **Distance/Duration remaining** | ❌ | ✅ |
| **Callbacks (built/failed/arrived)** | ❌ | ✅ |
| **Control (start/stop/recenter)** | ❌ | ✅ |
| **Performance** | Nhẹ hơn | Nặng hơn |
| **Complexity** | Đơn giản | Phức tạp hơn |
| **Use case** | Preview route | Active navigation |

---

## 📱 User Flow

### Simple Route Drawing Flow
```
1. User selects destination (search or click)
2. User clicks assistant_direction button
3. Route API called
4. Polyline decoded and drawn on map
5. User sees route on map
6. Done
```

### Full Navigation Flow
```
1. User selects destination (search or click)
2. User clicks near_me_outlined button
3. NavigationView builds route
4. onRouteBuilt callback → show route
5. User clicks "Start" button (play_arrow)
6. Navigation starts
7. Real-time updates:
   - Distance remaining
   - Duration remaining
   - Turn instructions
   - Voice guidance
8. User arrives → onArrival callback
9. Navigation stops automatically
   OR
   User clicks "Stop" button
```

---

## 🎨 UI States

### State 1: Không có route
- Show: VietmapGL widget
- Show: Search bar
- Show: My location button
- Show: 2 route buttons (assistant_direction, near_me_outlined)

### State 2: Simple route drawn (isOnRoute = true)
- Show: VietmapGL widget với polyline
- Show: Search bar
- Show: My location button
- Show: 2 route buttons

### State 3: Navigation route built (isOnNavigationRoute = true)
- Show: NavigationView widget (thay thế VietmapGL)
- Hide: Search bar
- Show: Navigation info card (distance, duration, instructions)
- Show: 4 control buttons:
  - Start (green)
  - Stop (red)
  - Recenter
  - Overview

---

## 🐛 Troubleshooting

### Lỗi 1: Navigation callbacks không hoạt động
**Nguyên nhân**: Đang dùng `onRouteSelected()` thay vì `buildNavigationRoute()`

**Giải pháp**: Đảm bảo button `near_me_outlined` gọi đúng method:
```dart
onPressed: () {
  provider.buildNavigationRoute(); // ✅ ĐÚNG - dùng NavigationView
  // provider.onRouteSelected(); // ❌ SAI - dùng simple drawing
}
```

### Lỗi 2: NavigationView không hiển thị
**Nguyên nhân**: `isOnNavigationRoute` chưa được set = true

**Giải pháp**: Check `onNavigationRouteBuilt` callback đã được gọi chưa:
```dart
void onNavigationRouteBuilt(dynamic route) {
  _isOnNavigationRoute = true; // Phải set = true
  notifyListeners();
}
```

### Lỗi 3: Voice instructions không hoạt động
**Nguyên nhân**: Chưa bật voice hoặc test trên simulator

**Giải pháp**: 
```dart
_navigationOption.voiceInstructionsEnabled = true; // Bật voice
// Test trên real device (simulator không có voice)
```

### Lỗi 4: Route progress không update
**Nguyên nhân**: Chưa gọi `startNavigation()`

**Giải pháp**: Sau khi route built, phải gọi start:
```dart
// Sau khi onRouteBuilt callback
provider.startNavigation(); // Bắt đầu navigation
```

---

## 💡 Best Practices

### 1. Tách Biệt 2 Phương Pháp
```dart
// ✅ ĐÚNG - 2 methods riêng biệt
provider.onRouteSelected();        // Simple drawing
provider.buildNavigationRoute();   // Full navigation

// ❌ SAI - dùng chung 1 method
provider.onRouteSelected(); // Cho cả 2 buttons
```

### 2. Kiểm Tra Controller Trước Khi Dùng
```dart
// ✅ ĐÚNG
if (_navigationController == null) {
  debugPrint('❌ Controller null');
  return;
}
await _navigationController?.buildRoute(...);

// ❌ SAI
await _navigationController.buildRoute(...); // Crash nếu null
```

### 3. Handle Callbacks Đầy Đủ
```dart
// ✅ ĐÚNG - Handle cả success và failure
onRouteBuilt: (route) => provider.onNavigationRouteBuilt(route),
onRouteBuildFailed: (error) => provider.onNavigationRouteBuildFailed(error),

// ❌ SAI - Chỉ handle success
onRouteBuilt: (route) => provider.onNavigationRouteBuilt(route),
// Không handle failure
```

### 4. Cleanup Khi Dispose
```dart
@override
void dispose() {
  _navigationController?.onDispose(); // ✅ Quan trọng!
  searchController.dispose();
  super.dispose();
}
```

### 5. Conditional UI Based on State
```dart
// ✅ ĐÚNG - Hide search bar khi navigating
if (!provider.isOnNavigationRoute)
  SearchBar(...),

// ✅ ĐÚNG - Show navigation info khi navigating  
if (provider.isOnNavigationRoute && routeProgressEvent != null)
  NavigationInfoCard(...),
```

---

## 📚 Tài Liệu Liên Quan

1. **VIETMAP_NAVIGATION_CREATE_ROUTE_GUIDE.md** - Chi tiết về NavigationView
2. **FIX_NAVIGATION_AND_POLYLINE_ERRORS.md** - Troubleshooting
3. **VIETMAP_NAVIGATION_QUICK_START.md** - Quick start guide

---

## ✅ Checklist

### Simple Route Drawing
- [x] Method `onRouteSelected()` implemented
- [x] Route API integration
- [x] Polyline decoding
- [x] Draw on VietmapGL
- [x] Button with `assistant_direction` icon

### Full Navigation
- [x] Method `buildNavigationRoute()` implemented
- [x] NavigationView widget added
- [x] MapOptions initialized
- [x] All callbacks connected:
  - [x] onMapCreated
  - [x] onRouteBuilt
  - [x] onRouteBuildFailed
  - [x] onRouteProgressChange
  - [x] onArrival
- [x] Control methods:
  - [x] startNavigation()
  - [x] stopNavigation()
  - [x] recenterCamera()
  - [x] overviewRoute()
- [x] Button with `near_me_outlined` icon
- [x] Navigation info UI
- [x] Control buttons UI

---

## 🎉 Kết Luận

Project của bạn giờ đã có **2 phương pháp hoàn chỉnh** để xử lý route:

1. **Simple Route Drawing**: Nhanh, nhẹ, dùng để preview
2. **Full Navigation**: Đầy đủ callbacks, voice, turn-by-turn

**Cách sử dụng**:
- Click `assistant_direction` → Simple route drawing
- Click `near_me_outlined` → Full navigation với callbacks

Tất cả callbacks của NavigationView giờ đã hoạt động chính xác! ✅

---

*Tài liệu được tạo: December 3, 2024*
*Project: vm_first_app - Metro Map Module*

