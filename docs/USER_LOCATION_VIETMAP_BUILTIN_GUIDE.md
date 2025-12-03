# Hướng Dẫn: UserLocationLayer Theo Documentation Vietmap

## 📚 Tham Khảo Documentation Chính Thức

Theo documentation của `vietmap_flutter_gl`, package đã tích hợp sẵn **UserLocationLayer** với cách sử dụng đơn giản hơn nhiều so với việc tự implement LocationService.

**Package documentation**: https://pub.dev/packages/vietmap_flutter_gl

---

## ✅ Giải Pháp Đơn Giản: Sử Dụng Built-in Features

### Phân tích theo Documentation:

Vietmap Flutter GL đã có **built-in location tracking** thông qua các properties:

```dart
VietmapGL(
  myLocationEnabled: true,              // ✅ Bật location tracking
  myLocationTrackingMode: MyLocationTrackingMode.tracking,  // ✅ Auto follow user
  myLocationRenderMode: MyLocationRenderMode.normal,        // ✅ Render mode
)
```

### UserLocationLayer Usage:

`UserLocationLayer` là một **widget overlay** được dùng để **customize icon** hiển thị vị trí người dùng, nhưng **không thay thế** location tracking của VietmapGL.

---

## 🎯 Implementation Đơn Giản Hơn (Theo Documentation)

### Kiến trúc:

```
📦 core/services/
├── location_permission_service.dart    → Chỉ xử lý permission (đơn giản hóa)

📦 modules/metro_go/
├── metro_map_provider.dart             → Quản lý state (đơn giản)
├── metro_map_screen.dart               → UI
└── widgets/
    └── custom_user_location_layer.dart → Custom icon (optional)
```

**Lưu ý**: Không cần `geolocator` package nữa vì VietmapGL đã tích hợp sẵn!

---

## 🏗️ Implementation Chi Tiết

### Bước 1: Tạo Permission Service Đơn Giản

#### File: `lib/core/services/location_permission_service.dart`

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service đơn giản chỉ để xử lý permission
/// VietmapGL sẽ tự động handle việc lấy vị trí
class LocationPermissionService {
  /// Check permission status
  Future<bool> checkPermission() async {
    final status = await Permission.location.status;
    debugPrint('📍 [LOCATION] Permission status: $status');
    return status.isGranted;
  }
  
  /// Request permission
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    debugPrint('📍 [LOCATION] Permission requested: $status');
    
    if (status.isPermanentlyDenied) {
      // Nếu bị deny vĩnh viễn, mở settings
      await openAppSettings();
      return false;
    }
    
    return status.isGranted;
  }
  
  /// Check nếu permission bị deny vĩnh viễn
  Future<bool> isPermanentlyDenied() async {
    final status = await Permission.location.status;
    return status.isPermanentlyDenied;
  }
}
```

---

### Bước 2: Update MetroMapProvider (Đơn Giản Hóa)

#### File: `lib/modules/metro_go/metro_map_provider.dart`

```dart
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/services/location_permission_service.dart';

class MetroMapProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  final LocationPermissionService _permissionService;
  
  // Vietmap Controller
  VietmapController? _vietmapController;
  VietmapController? get vietmapController => _vietmapController;
  bool get isMapReady => _vietmapController != null;
  
  // Permission state
  bool _hasLocationPermission = false;
  bool get hasLocationPermission => _hasLocationPermission;
  
  bool _isRequestingPermission = false;
  bool get isRequestingPermission => _isRequestingPermission;
  
  // Tracking mode
  MyLocationTrackingMode _trackingMode = MyLocationTrackingMode.none;
  MyLocationTrackingMode get trackingMode => _trackingMode;
  
  MetroMapProvider(this._appProvider, this._permissionService) {
    _checkInitialPermission();
  }
  
  // ===== INITIALIZATION =====
  
  /// Check permission lúc khởi tạo
  Future<void> _checkInitialPermission() async {
    _hasLocationPermission = await _permissionService.checkPermission();
    notifyListeners();
    debugPrint('📍 [METRO_MAP] Initial permission: $_hasLocationPermission');
  }
  
  // ===== MAP LIFECYCLE =====
  
  void onMapCreated(VietmapController controller) {
    _vietmapController = controller;
    notifyListeners();
    debugPrint('🗺️ [METRO_MAP] Map created and ready');
  }
  
  // ===== LOCATION METHODS =====
  
  /// Request permission nếu chưa có
  Future<bool> requestLocationPermission() async {
    if (_hasLocationPermission) return true;
    
    _isRequestingPermission = true;
    notifyListeners();
    
    final granted = await _permissionService.requestPermission();
    
    _hasLocationPermission = granted;
    _isRequestingPermission = false;
    notifyListeners();
    
    debugPrint('📍 [METRO_MAP] Permission granted: $granted');
    return granted;
  }
  
  /// Di chuyển camera đến vị trí hiện tại của user
  /// Method này được gọi khi click FloatingActionButton
  Future<void> moveToMyLocation() async {
    if (_vietmapController == null) {
      debugPrint('⚠️ [METRO_MAP] Controller not ready');
      return;
    }
    
    // Check permission
    if (!_hasLocationPermission) {
      final granted = await requestLocationPermission();
      if (!granted) {
        debugPrint('⚠️ [METRO_MAP] Permission denied');
        return;
      }
    }
    
    try {
      // ✅ Sử dụng method built-in của VietmapController
      // Nó sẽ tự động lấy vị trí hiện tại và di chuyển camera
      await _vietmapController!.moveCamera(
        CameraUpdate.newLatLngZoom(
          await _vietmapController!.requestMyLocationLatLng() ?? 
              const LatLng(10.762317, 106.654551),
          16.0,
        ),
      );
      
      debugPrint('🗺️ [METRO_MAP] Moved to user location');
    } catch (e) {
      debugPrint('❌ [METRO_MAP] Error moving to location: $e');
    }
  }
  
  /// Toggle location tracking mode
  /// Khi bật, camera sẽ tự động follow vị trí user
  Future<void> toggleLocationTracking() async {
    if (_vietmapController == null) return;
    
    // Check permission
    if (!_hasLocationPermission) {
      final granted = await requestLocationPermission();
      if (!granted) return;
    }
    
    // Toggle tracking mode
    if (_trackingMode == MyLocationTrackingMode.none) {
      _trackingMode = MyLocationTrackingMode.tracking;
    } else {
      _trackingMode = MyLocationTrackingMode.none;
    }
    
    notifyListeners();
    debugPrint('🗺️ [METRO_MAP] Tracking mode: $_trackingMode');
  }
  
  // ===== CAMERA CONTROLS =====
  
  /// Zoom in
  Future<void> zoomIn() async {
    if (_vietmapController == null) return;
    await _vietmapController!.animateCamera(CameraUpdate.zoomIn());
  }
  
  /// Zoom out
  Future<void> zoomOut() async {
    if (_vietmapController == null) return;
    await _vietmapController!.animateCamera(CameraUpdate.zoomOut());
  }
  
  @override
  void dispose() {
    _vietmapController?.dispose();
    super.dispose();
  }
}
```

---

### Bước 3: Update MetroMapScreen

#### File: `lib/modules/metro_go/metro_map_screen.dart`

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/core/services/location_permission_service.dart';
import 'package:vm_first_app/modules/metro_go/metro_map_provider.dart';

@RoutePage()
class MetroMapScreen extends StatelessWidget {
  const MetroMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetroMapProvider(
        locator<AppProvider>(),
        LocationPermissionService(), // ✅ Không cần register vào GetIt nếu đơn giản
      ),
      child: const _MetroMapView(),
    );
  }
}

class _MetroMapView extends StatelessWidget {
  const _MetroMapView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Metro Map'),
        backgroundColor: AppColors.primary,
        actions: [
          // Show permission status
          if (!provider.hasLocationPermission)
            IconButton(
              icon: const Icon(Icons.location_off),
              onPressed: provider.requestLocationPermission,
              tooltip: 'Enable location',
            ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ VietmapGL với location built-in
          _VietmapWidget(
            onMapCreated: provider.onMapCreated,
            hasLocationPermission: provider.hasLocationPermission,
            trackingMode: provider.trackingMode,
          ),
          
          // Optional: Custom UserLocationLayer overlay
          if (provider.isMapReady && provider.hasLocationPermission)
            _CustomUserLocationLayer(
              mapController: provider.vietmapController!,
            ),
        ],
      ),
      floatingActionButton: _FloatingButtons(provider: provider),
    );
  }
}

/// ✅ Widget riêng cho VietmapGL - KHÔNG listen Provider
class _VietmapWidget extends StatefulWidget {
  final Function(VietmapController) onMapCreated;
  final bool hasLocationPermission;
  final MyLocationTrackingMode trackingMode;

  const _VietmapWidget({
    required this.onMapCreated,
    required this.hasLocationPermission,
    required this.trackingMode,
  });

  @override
  State<_VietmapWidget> createState() => _VietmapWidgetState();
}

class _VietmapWidgetState extends State<_VietmapWidget> {
  @override
  Widget build(BuildContext context) {
    return VietmapGL(
      styleString:
          'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${dotenv.env['VM_API_KEY']}',
      initialCameraPosition: const CameraPosition(
        target: LatLng(10.762317, 106.654551),
        zoom: 14.0,
      ),
      onMapCreated: widget.onMapCreated,
      
      // ✅ QUAN TRỌNG: Bật location tracking built-in
      myLocationEnabled: widget.hasLocationPermission, // Chỉ bật khi có permission
      myLocationTrackingMode: widget.trackingMode,
      myLocationRenderMode: MyLocationRenderMode.normal,
      
      // Other configs
      trackCameraPosition: true,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
    );
  }
  
  @override
  void didUpdateWidget(_VietmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Khi permission hoặc tracking mode thay đổi, widget sẽ rebuild
    // VietmapGL sẽ tự động update location tracking
    if (oldWidget.hasLocationPermission != widget.hasLocationPermission ||
        oldWidget.trackingMode != widget.trackingMode) {
      debugPrint('🗺️ Location settings changed - widget will rebuild');
    }
  }
}

/// ✅ Optional: Custom UserLocationLayer để thay đổi icon
class _CustomUserLocationLayer extends StatelessWidget {
  final VietmapController mapController;
  
  const _CustomUserLocationLayer({
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return UserLocationLayer(
      mapController: mapController,
      
      // Custom location icon
      locationIcon: const Icon(
        Icons.navigation,
        color: Colors.blue,
        size: 40,
      ),
      
      // Custom bearing icon
      bearingIcon: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: Colors.blue,
          size: 15,
        ),
      ),
      
      ignorePointer: true,
    );
  }
}

/// Widget chứa FloatingActionButtons
class _FloatingButtons extends StatelessWidget {
  final MetroMapProvider provider;
  
  const _FloatingButtons({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Button 1: Toggle tracking mode
        FloatingActionButton(
          mini: true,
          heroTag: 'tracking_button',
          backgroundColor: provider.trackingMode == MyLocationTrackingMode.tracking
              ? Colors.blue
              : Colors.grey,
          onPressed: provider.isMapReady
              ? provider.toggleLocationTracking
              : null,
          child: Icon(
            provider.trackingMode == MyLocationTrackingMode.tracking
                ? Icons.gps_fixed
                : Icons.gps_not_fixed,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        // Button 2: Move to my location (one-time)
        FloatingActionButton(
          heroTag: 'my_location_button',
          backgroundColor: AppColors.primary,
          onPressed: provider.isMapReady
              ? provider.moveToMyLocation  // 👈 GỌI METHOD NÀY
              : null,
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
```

---

## 🔑 Key Differences (So với approach trước)

### ❌ Approach Cũ (Quá phức tạp):
```dart
// Cần geolocator package
// Cần tự implement LocationService
// Cần tự lấy GPS coordinates
// Cần tự di chuyển camera
final location = await _locationService.getCurrentLocation();
await _mapController.animateCamera(CameraUpdate.newLatLng(location));
```

### ✅ Approach Mới (Theo documentation):
```dart
// VietmapGL tự động handle location tracking
VietmapGL(
  myLocationEnabled: true,              // ✅ Bật location
  myLocationTrackingMode: tracking,     // ✅ Auto follow
)

// Di chuyển đến vị trí user (built-in method)
await _vietmapController.moveCamera(
  CameraUpdate.newLatLngZoom(
    await _vietmapController.requestMyLocationLatLng(),
    16.0,
  ),
);
```

---

## 📊 So Sánh Approach

| Feature | Approach Cũ (LocationService) | Approach Mới (Built-in) |
|---------|-------------------------------|-------------------------|
| **Dependencies** | geolocator, permission_handler | Chỉ permission_handler |
| **Code complexity** | ⭐⭐⭐⭐⭐ Phức tạp | ⭐⭐ Đơn giản |
| **Performance** | ⭐⭐⭐ Trung bình | ⭐⭐⭐⭐⭐ Tốt hơn |
| **Maintenance** | ⭐⭐ Khó maintain | ⭐⭐⭐⭐⭐ Dễ maintain |
| **Lines of code** | ~300 lines | ~100 lines |
| **Features** | Manual control | Auto tracking + Manual |
| **Recommended** | ❌ Không cần thiết | ✅ **HIGHLY RECOMMENDED** |

---

## 🎯 Các Tính Năng Built-in Của VietmapGL

### 1. MyLocationTrackingMode

```dart
// Không track (mặc định)
MyLocationTrackingMode.none

// Track vị trí user (camera auto follow)
MyLocationTrackingMode.tracking

// Track vị trí và hướng
MyLocationTrackingMode.trackingCompass

// Track vị trí, hướng và GPS bearing
MyLocationTrackingMode.trackingGps
```

### 2. MyLocationRenderMode

```dart
// Hiển thị bình thường (dot)
MyLocationRenderMode.normal

// Hiển thị với compass
MyLocationRenderMode.compass

// Hiển thị với GPS bearing arrow
MyLocationRenderMode.gps
```

### 3. Built-in Methods

```dart
// Lấy vị trí hiện tại
final LatLng? myLocation = await controller.requestMyLocationLatLng();

// Lấy last known location
final LatLng? lastLocation = controller.lastKnownUserLocation;

// Check location permission
final bool hasPermission = await controller.checkLocationPermission();

// Request permission
final bool granted = await controller.requestLocationPermission();
```

---

## ✅ Checklist Implementation (Đơn Giản Hơn)

### Bước thực hiện:

- [ ] **Bước 1**: Thêm dependency `permission_handler` (KHÔNG cần geolocator)
- [ ] **Bước 2**: Tạo `LocationPermissionService` đơn giản
- [ ] **Bước 3**: Update `MetroMapProvider`:
  - Inject `LocationPermissionService`
  - Implement `moveToMyLocation()` dùng built-in method
  - Implement `toggleLocationTracking()` nếu cần auto-follow
- [ ] **Bước 4**: Update `MetroMapScreen`:
  - Set `myLocationEnabled: true` trong VietmapGL
  - Pass `trackingMode` vào VietmapWidget
  - Update FloatingActionButton → `provider.moveToMyLocation`
- [ ] **Bước 5**: Optional: Add `UserLocationLayer` để custom icon
- [ ] **Bước 6**: Config permissions (iOS + Android)
- [ ] **Bước 7**: Test trên thiết bị thật

---

## 🔐 Permissions Configuration (Giống như trước)

### iOS: `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show you on the map</string>
```

### Android: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

---

## 💡 Use Cases

### Use Case 1: One-time Location (Click Button)
```dart
// User click "My Location" button
FloatingActionButton(
  onPressed: provider.moveToMyLocation,
  // → Di chuyển camera đến vị trí hiện tại (1 lần)
)
```

### Use Case 2: Continuous Tracking
```dart
// User toggle tracking mode
FloatingActionButton(
  onPressed: provider.toggleLocationTracking,
  // → Camera auto follow user location
)
```

### Use Case 3: Custom Icon
```dart
// Thêm UserLocationLayer để customize icon
UserLocationLayer(
  mapController: controller,
  locationIcon: Icon(Icons.navigation, color: Colors.blue),
  bearingIcon: CustomBearingWidget(),
)
```

---

## 🎨 UI States

### FloatingActionButton States:

#### Button "My Location" (One-time):
```dart
FloatingActionButton(
  backgroundColor: AppColors.primary,
  onPressed: provider.isMapReady ? provider.moveToMyLocation : null,
  child: Icon(Icons.my_location),
)
```

#### Button "Tracking" (Toggle):
```dart
FloatingActionButton(
  backgroundColor: provider.trackingMode == MyLocationTrackingMode.tracking
      ? Colors.blue    // 👈 Active (đang tracking)
      : Colors.grey,   // 👈 Inactive
  onPressed: provider.toggleLocationTracking,
  child: Icon(
    provider.trackingMode == MyLocationTrackingMode.tracking
        ? Icons.gps_fixed      // 👈 Đang track
        : Icons.gps_not_fixed, // 👈 Không track
  ),
)
```

---

## 📊 Tuân Thủ Coding Rules

### ✅ Layer Separation (Đơn giản hơn)

```
core/services/
└── location_permission_service.dart   ✅ Chỉ xử lý permission

modules/metro_go/
├── metro_map_provider.dart            ✅ State management
├── metro_map_screen.dart              ✅ UI
└── widgets/
    └── custom_user_location_layer.dart ✅ Optional custom icon
```

### ✅ No External Dependencies (Geolocator)

```yaml
# ❌ KHÔNG CẦN geolocator
dependencies:
  # geolocator: ^11.0.0  # ❌ Removed
  
# ✅ CHỈ CẦN permission_handler
dependencies:
  permission_handler: ^11.0.0  # ✅ Chỉ để xin permission
  vietmap_flutter_gl: ^latest  # ✅ Đã có location built-in
```

---

## 🎯 Tổng Kết

### Điểm khác biệt chính:

#### 1. **VietmapGL đã có location tracking built-in**
- Không cần tự implement LocationService
- Không cần geolocator package
- Chỉ cần xử lý permission

#### 2. **UserLocationLayer là optional**
- Chỉ dùng để **customize icon**
- KHÔNG dùng để lấy vị trí
- KHÔNG thay thế `myLocationEnabled`

#### 3. **Đơn giản hơn nhiều**
- ~100 lines thay vì ~300 lines
- Ít dependencies hơn
- Dễ maintain hơn
- Performance tốt hơn

### Implementation Summary:

```dart
// 1. Bật location trong VietmapGL
VietmapGL(
  myLocationEnabled: true,
  myLocationTrackingMode: trackingMode,
)

// 2. Di chuyển đến vị trí user
await controller.moveCamera(
  CameraUpdate.newLatLngZoom(
    await controller.requestMyLocationLatLng(),
    16.0,
  ),
);

// 3. Optional: Custom icon
UserLocationLayer(
  mapController: controller,
  locationIcon: CustomIcon(),
)
```

### Tuân thủ Coding Rules:
- ✅ Separation of concerns
- ✅ Clean Architecture principles
- ✅ Minimal dependencies
- ✅ Provider pattern
- ✅ Single responsibility

---

**Khuyến nghị**: Sử dụng approach mới (built-in) vì đơn giản, hiệu quả và đúng theo documentation của VietmapGL! 🎯

