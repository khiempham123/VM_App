# Hướng Dẫn: Hiển Thị và Cập Nhật Vị Trí Người Dùng Với FloatingActionButton

## 🎯 Yêu Cầu

1. Hiển thị vị trí hiện tại của người dùng trên map bằng `UserLocationLayer`
2. Click vào FloatingActionButton để cập nhật và di chuyển camera đến vị trí hiện tại
3. Tuân thủ coding rules: Clean Architecture, Provider pattern, separation of concerns

---

## 📋 Phân Tích Vấn Đề

### Vấn đề hiện tại:
```dart
// ❌ Code mẫu bạn đưa ra có vấn đề:
_mapController == null
    ? SizedBox.shrink()
    : UserLocationLayer(
        mapController: _mapController!, // 👈 Truy cập controller trực tiếp trong UI
        // ...
      )
```

**Vấn đề:**
- `_mapController` là private property của Provider
- Widget đang truy cập trực tiếp vào controller
- Không có logic quản lý location permission
- Không có error handling khi lấy vị trí thất bại

---

## ✅ Giải Pháp: Quản Lý State Qua Provider

### Kiến trúc:

```
📦 domain/entities/
├── user_location_state.dart          → Entity cho state vị trí người dùng

📦 core/services/
├── location_service.dart              → Abstract interface
└── location_service_impl.dart         → Implementation với geolocator

📦 core/dependencies/
└── app_dependencies.dart              → Register LocationService

📦 modules/metro_go/
├── metro_map_provider.dart            → Quản lý state location
├── metro_map_screen.dart              → UI
└── widgets/
    └── user_location_layer_widget.dart → Widget hiển thị UserLocationLayer
```

---

## 🏗️ Implementation Chi Tiết

### Bước 1: Thêm Dependencies

#### File: `pubspec.yaml`
```yaml
dependencies:
  # ... existing dependencies
  geolocator: ^11.0.0          # Lấy vị trí GPS
  permission_handler: ^11.0.0  # Xin permission
```

**Chạy lệnh:**
```bash
fvm flutter pub get
```

---

### Bước 2: Tạo Entity Cho User Location State

#### File: `lib/domain/entities/user_location_state.dart`
```dart
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';

/// Entity đại diện cho trạng thái vị trí người dùng
class UserLocationState {
  final LatLng? currentLocation;
  final bool isLocationEnabled;
  final bool isPermissionGranted;
  final bool isLoadingLocation;
  final String? errorMessage;
  final double? bearing; // Hướng của thiết bị (0-360 độ)
  
  const UserLocationState({
    this.currentLocation,
    this.isLocationEnabled = false,
    this.isPermissionGranted = false,
    this.isLoadingLocation = false,
    this.errorMessage,
    this.bearing,
  });
  
  UserLocationState copyWith({
    LatLng? currentLocation,
    bool? isLocationEnabled,
    bool? isPermissionGranted,
    bool? isLoadingLocation,
    String? errorMessage,
    double? bearing,
  }) {
    return UserLocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      errorMessage: errorMessage ?? this.errorMessage,
      bearing: bearing ?? this.bearing,
    );
  }
  
  /// Check xem có thể hiển thị vị trí không
  bool get canShowLocation => 
      isPermissionGranted && 
      isLocationEnabled && 
      currentLocation != null;
}
```

---

### Bước 3: Tạo Location Service (Core Layer)

#### File: `lib/core/services/location_service.dart`
```dart
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';

/// Abstract interface cho location service
/// Tuân thủ coding rules: core/ accessible to all layers
abstract class LocationService {
  /// Kiểm tra location permission
  Future<bool> checkPermission();
  
  /// Request location permission
  Future<bool> requestPermission();
  
  /// Kiểm tra location service có bật không
  Future<bool> isLocationServiceEnabled();
  
  /// Lấy vị trí hiện tại của người dùng
  Future<LatLng?> getCurrentLocation();
  
  /// Lấy hướng (bearing) của thiết bị
  Future<double?> getBearing();
  
  /// Mở settings để bật location service
  Future<bool> openLocationSettings();
}
```

#### File: `lib/core/services/location_service_impl.dart`
```dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/core/services/location_service.dart';

class LocationServiceImpl implements LocationService {
  @override
  Future<bool> checkPermission() async {
    final status = await Permission.location.status;
    debugPrint('📍 [LOCATION] Permission status: $status');
    return status.isGranted;
  }
  
  @override
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    debugPrint('📍 [LOCATION] Permission requested: $status');
    
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('⚠️ [LOCATION] Permission denied');
      return false;
    }
    
    return status.isGranted;
  }
  
  @override
  Future<bool> isLocationServiceEnabled() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('📍 [LOCATION] Service enabled: $isEnabled');
    return isEnabled;
  }
  
  @override
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Kiểm tra permission
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        debugPrint('⚠️ [LOCATION] No permission to get location');
        return null;
      }
      
      // Kiểm tra location service
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        debugPrint('⚠️ [LOCATION] Location service is disabled');
        return null;
      }
      
      // Lấy vị trí hiện tại
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      debugPrint('📍 [LOCATION] Got location: ${position.latitude}, ${position.longitude}');
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ [LOCATION] Error getting location: $e');
      return null;
    }
  }
  
  @override
  Future<double?> getBearing() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Bearing từ Geolocator (0-360 độ)
      return position.heading;
    } catch (e) {
      debugPrint('❌ [LOCATION] Error getting bearing: $e');
      return null;
    }
  }
  
  @override
  Future<bool> openLocationSettings() async {
    try {
      final opened = await Geolocator.openLocationSettings();
      return opened;
    } catch (e) {
      debugPrint('❌ [LOCATION] Error opening settings: $e');
      return false;
    }
  }
}
```

---

### Bước 4: Register Service Vào Dependency Injection

#### File: `lib/core/dependencies/app_dependencies.dart`
```dart
import 'package:get_it/get_it.dart';
import 'package:vm_first_app/core/services/location_service.dart';
import 'package:vm_first_app/core/services/location_service_impl.dart';

final locator = GetIt.instance;

void registerDependencies() {
  // ... existing registrations
  
  // ✅ Register LocationService
  locator.registerLazySingleton<LocationService>(
    () => LocationServiceImpl(),
  );
}
```

---

### Bước 5: Update MetroMapProvider

#### File: `lib/modules/metro_go/metro_map_provider.dart`
```dart
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/services/location_service.dart';
import 'package:vm_first_app/domain/entities/user_location_state.dart';

class MetroMapProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  final LocationService _locationService;
  
  // Vietmap Controller
  VietmapController? _vietmapController;
  VietmapController? get vietmapController => _vietmapController;
  bool get isMapReady => _vietmapController != null;
  
  // User Location State
  UserLocationState _locationState = const UserLocationState();
  UserLocationState get locationState => _locationState;
  
  // Getters for UI
  bool get canShowUserLocation => _locationState.canShowLocation;
  bool get isLoadingLocation => _locationState.isLoadingLocation;
  LatLng? get currentLocation => _locationState.currentLocation;
  
  MetroMapProvider(this._appProvider, this._locationService) {
    // Auto request permission khi khởi tạo
    _initializeLocation();
  }
  
  // ===== INITIALIZATION =====
  
  /// Khởi tạo location service
  Future<void> _initializeLocation() async {
    debugPrint('📍 [METRO_MAP] Initializing location service...');
    
    // Check permission
    final hasPermission = await _locationService.checkPermission();
    
    // Check location service
    final isEnabled = await _locationService.isLocationServiceEnabled();
    
    _locationState = _locationState.copyWith(
      isPermissionGranted: hasPermission,
      isLocationEnabled: isEnabled,
    );
    notifyListeners();
    
    // Nếu đã có permission, tự động lấy vị trí
    if (hasPermission && isEnabled) {
      await getCurrentLocation();
    }
  }
  
  // ===== MAP LIFECYCLE =====
  
  void onMapCreated(VietmapController controller) {
    _vietmapController = controller;
    notifyListeners();
    debugPrint('🗺️ [METRO_MAP] Map created and ready');
  }
  
  // ===== LOCATION METHODS =====
  
  /// Request location permission
  Future<bool> requestLocationPermission() async {
    debugPrint('📍 [METRO_MAP] Requesting location permission...');
    
    final granted = await _locationService.requestPermission();
    
    _locationState = _locationState.copyWith(
      isPermissionGranted: granted,
    );
    notifyListeners();
    
    if (granted) {
      // Auto lấy vị trí sau khi có permission
      await getCurrentLocation();
    }
    
    return granted;
  }
  
  /// Lấy vị trí hiện tại của người dùng
  /// Gọi method này khi user click vào FloatingActionButton
  Future<void> getCurrentLocation() async {
    debugPrint('📍 [METRO_MAP] Getting current location...');
    
    // Set loading state
    _locationState = _locationState.copyWith(
      isLoadingLocation: true,
      errorMessage: null,
    );
    notifyListeners();
    
    try {
      // Kiểm tra permission
      if (!_locationState.isPermissionGranted) {
        final granted = await requestLocationPermission();
        if (!granted) {
          _locationState = _locationState.copyWith(
            isLoadingLocation: false,
            errorMessage: 'Location permission denied',
          );
          notifyListeners();
          return;
        }
      }
      
      // Kiểm tra location service
      final isEnabled = await _locationService.isLocationServiceEnabled();
      if (!isEnabled) {
        _locationState = _locationState.copyWith(
          isLoadingLocation: false,
          errorMessage: 'Please enable location service',
          isLocationEnabled: false,
        );
        notifyListeners();
        return;
      }
      
      // Lấy vị trí
      final location = await _locationService.getCurrentLocation();
      final bearing = await _locationService.getBearing();
      
      if (location != null) {
        _locationState = _locationState.copyWith(
          currentLocation: location,
          bearing: bearing,
          isLoadingLocation: false,
          isLocationEnabled: true,
          errorMessage: null,
        );
        
        // Di chuyển camera đến vị trí hiện tại
        await _moveCameraToUserLocation(location);
        
        debugPrint('✅ [METRO_MAP] Location updated: $location');
      } else {
        _locationState = _locationState.copyWith(
          isLoadingLocation: false,
          errorMessage: 'Failed to get location',
        );
      }
    } catch (e) {
      debugPrint('❌ [METRO_MAP] Error getting location: $e');
      _locationState = _locationState.copyWith(
        isLoadingLocation: false,
        errorMessage: 'Error: $e',
      );
    }
    
    notifyListeners();
  }
  
  /// Di chuyển camera đến vị trí người dùng
  Future<void> _moveCameraToUserLocation(LatLng location) async {
    if (_vietmapController == null) return;
    
    try {
      await _vietmapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, 16.0),
        duration: const Duration(milliseconds: 500),
      );
      debugPrint('🗺️ [METRO_MAP] Camera moved to user location');
    } catch (e) {
      debugPrint('❌ [METRO_MAP] Error moving camera: $e');
    }
  }
  
  /// Mở settings để bật location service
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }
  
  // ===== OTHER CAMERA CONTROLS =====
  
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

### Bước 6: Tạo Widget Hiển Thị UserLocationLayer

#### File: `lib/modules/metro_go/widgets/user_location_layer_widget.dart`
```dart
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';

/// Widget riêng biệt để hiển thị UserLocationLayer
/// Tuân thủ coding rules: Tách UI component thành widget riêng
class UserLocationLayerWidget extends StatelessWidget {
  final VietmapController mapController;
  
  const UserLocationLayerWidget({
    super.key,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return UserLocationLayer(
      mapController: mapController,
      
      // Icon vị trí người dùng
      locationIcon: const Icon(
        Icons.circle,
        color: Colors.blue,
        size: 50,
      ),
      
      // Icon hướng (bearing)
      bearingIcon: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: Colors.red,
          size: 15,
        ),
      ),
      
      ignorePointer: true,
    );
  }
}
```

---

### Bước 7: Update MetroMapScreen

#### File: `lib/modules/metro_go/metro_map_screen.dart`
```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/modules/metro_go/metro_map_provider.dart';
import 'package:vm_first_app/modules/metro_go/widgets/user_location_layer_widget.dart';

@RoutePage()
class MetroMapScreen extends StatelessWidget {
  const MetroMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetroMapProvider(
        locator<AppProvider>(),
        locator<LocationService>(), // ✅ Inject LocationService
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
        backgroundColor: AppColors.primaryLight,
        actions: [
          // Hiển thị status location permission
          if (!provider.locationState.isPermissionGranted)
            IconButton(
              icon: const Icon(Icons.location_off),
              onPressed: provider.requestLocationPermission,
              tooltip: 'Enable location',
            ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ VietmapGL Widget (không bị rebuild)
          _VietmapWidget(onMapCreated: provider.onMapCreated),
          
          // ✅ UserLocationLayer (chỉ hiển thị khi có controller và permission)
          if (provider.isMapReady && provider.canShowUserLocation)
            UserLocationLayerWidget(
              mapController: provider.vietmapController!,
            ),
          
          // ✅ Loading indicator khi đang lấy vị trí
          if (provider.isLoadingLocation)
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          // ✅ Error message
          if (provider.locationState.errorMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.locationState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      if (!provider.locationState.isLocationEnabled)
                        TextButton(
                          onPressed: provider.openLocationSettings,
                          child: const Text('Open Settings'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      
      // ✅ FloatingActionButtons
      floatingActionButton: _FloatingButtons(provider: provider),
    );
  }
}

/// Widget chứa các FloatingActionButtons
class _FloatingButtons extends StatelessWidget {
  final MetroMapProvider provider;
  
  const _FloatingButtons({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // ✅ Button 1: Update vị trí hiện tại
        Positioned(
          bottom: 0,
          right: 0,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'location_button',
            backgroundColor: AppColors.primary,
            onPressed: provider.isMapReady && !provider.isLoadingLocation
                ? provider.getCurrentLocation // 👈 GỌI METHOD NÀY
                : null,
            child: provider.isLoadingLocation
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : const Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
          ),
        ),
        
        // ✅ Button 2: Directions (tính năng khác)
        Positioned(
          bottom: 60,
          right: 0,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'direction_button',
            backgroundColor: AppColors.primary,
            onPressed: provider.isMapReady ? () {
              // TODO: Implement directions feature
              debugPrint('🗺️ Directions button clicked');
            } : null,
            child: const Icon(
              Icons.assistant_direction,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// ✅ Widget riêng cho VietmapGL - KHÔNG listen Provider
class _VietmapWidget extends StatefulWidget {
  final Function(VietmapController) onMapCreated;

  const _VietmapWidget({
    required this.onMapCreated,
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
      trackCameraPosition: true,
      myLocationEnabled: false, // ✅ Tắt built-in location, dùng UserLocationLayer
      myLocationTrackingMode: MyLocationTrackingMode.none,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
    );
  }
}
```

---

## 🎨 UI/UX Flow

### Flow khi user click FloatingActionButton:

```
1. User click nút "My Location" 
   ↓
2. Provider.getCurrentLocation() được gọi
   ↓
3. Set loading state → UI hiển thị loading indicator
   ↓
4. Check permission:
   - Nếu chưa có → Request permission
   - Nếu bị từ chối → Show error message
   ↓
5. Check location service:
   - Nếu tắt → Show error + button "Open Settings"
   ↓
6. Lấy vị trí từ GPS (Geolocator)
   ↓
7. Update state với vị trí mới
   ↓
8. Di chuyển camera đến vị trí (animate)
   ↓
9. UserLocationLayer tự động hiển thị icon tại vị trí
   ↓
10. Clear loading state
```

### States của FloatingActionButton:

```dart
// Trạng thái 1: Map chưa ready → Disabled
onPressed: null

// Trạng thái 2: Đang loading → Show CircularProgressIndicator
child: CircularProgressIndicator()

// Trạng thái 3: Ready → Show icon, có thể click
child: Icon(Icons.my_location)
onPressed: provider.getCurrentLocation
```

---

## 🔐 Xử Lý Permissions

### iOS Configuration

#### File: `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to show you on the map</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to your location to show you on the map</string>
```

### Android Configuration

#### File: `android/app/src/main/AndroidManifest.xml`
```xml
<manifest>
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

---

## ✅ Checklist Implementation

### Bước thực hiện:

- [ ] **Bước 1**: Thêm dependencies (geolocator, permission_handler)
- [ ] **Bước 2**: Tạo `UserLocationState` entity trong `domain/entities/`
- [ ] **Bước 3**: Tạo `LocationService` interface trong `core/services/`
- [ ] **Bước 4**: Tạo `LocationServiceImpl` implementation
- [ ] **Bước 5**: Register service vào `app_dependencies.dart`
- [ ] **Bước 6**: Update `MetroMapProvider`:
  - Inject `LocationService`
  - Add `UserLocationState`
  - Implement `getCurrentLocation()` method
  - Implement `requestLocationPermission()` method
- [ ] **Bước 7**: Tạo `UserLocationLayerWidget` trong `widgets/`
- [ ] **Bước 8**: Update `MetroMapScreen`:
  - Inject `LocationService` vào Provider
  - Add UserLocationLayerWidget vào Stack
  - Update FloatingActionButton với `onPressed: provider.getCurrentLocation`
  - Add loading indicator
  - Add error message UI
- [ ] **Bước 9**: Config permissions (iOS + Android)
- [ ] **Bước 10**: Test trên thiết bị thật (GPS không chạy trên simulator)

---

## 📊 Tuân Thủ Coding Rules

### ✅ Layer Separation

```
domain/
└── entities/
    └── user_location_state.dart       ✅ Pure Dart entity

core/
├── services/
│   ├── location_service.dart          ✅ Abstract interface
│   └── location_service_impl.dart     ✅ Implementation
└── dependencies/
    └── app_dependencies.dart           ✅ DI registration

modules/
└── metro_go/
    ├── metro_map_provider.dart         ✅ State management
    ├── metro_map_screen.dart           ✅ UI
    └── widgets/
        └── user_location_layer_widget.dart ✅ Reusable widget
```

### ✅ Import Rules

```dart
// ✅ modules/ → domain/
import 'package:vm_first_app/domain/entities/user_location_state.dart';

// ✅ modules/ → core/
import 'package:vm_first_app/core/services/location_service.dart';

// ❌ modules/ → data/ (KHÔNG BAO GIỜ)
// KHÔNG import gì từ data/ layer
```

### ✅ Dependency Injection

```dart
// ✅ Service được inject qua constructor
MetroMapProvider(
  this._appProvider,
  this._locationService, // 👈 Inject từ GetIt
)

// ✅ UI nhận service từ Provider
create: (context) => MetroMapProvider(
  locator<AppProvider>(),
  locator<LocationService>(), // 👈 Resolve từ locator
)
```

### ✅ Single Responsibility

```
LocationService          → Chỉ lo việc lấy vị trí GPS
MetroMapProvider         → Quản lý state và logic
UserLocationLayerWidget  → Chỉ hiển thị UI layer
_VietmapWidget          → Chỉ render VietmapGL
_FloatingButtons        → Chỉ hiển thị buttons
```

---

## 🐛 Error Handling

### Các trường hợp lỗi cần xử lý:

#### 1. Permission bị từ chối
```dart
if (!_locationState.isPermissionGranted) {
  _locationState = _locationState.copyWith(
    errorMessage: 'Location permission denied',
  );
  // Show dialog yêu cầu user cấp quyền
}
```

#### 2. Location service bị tắt
```dart
if (!isEnabled) {
  _locationState = _locationState.copyWith(
    errorMessage: 'Please enable location service',
  );
  // Show button "Open Settings"
}
```

#### 3. Timeout khi lấy vị trí
```dart
final position = await Geolocator.getCurrentPosition(
  timeLimit: const Duration(seconds: 10), // 👈 Timeout
);
```

#### 4. GPS không khả dụng
```dart
if (location == null) {
  _locationState = _locationState.copyWith(
    errorMessage: 'Failed to get location. Please try again.',
  );
}
```

---

## 🎯 Tổng Kết

### Quy trình thực hiện:

1. **Domain Layer**: Tạo `UserLocationState` entity
2. **Core Layer**: Tạo `LocationService` (abstract + implementation)
3. **DI**: Register service vào GetIt
4. **Provider**: Inject service, quản lý state, implement logic
5. **UI**: Tách widgets, connect với Provider, handle user interactions

### Key Points:

✅ **Không truy cập trực tiếp** `_mapController` từ UI  
✅ **Quản lý state** qua Provider với `UserLocationState`  
✅ **Tách concerns**: LocationService (lấy GPS) ≠ Provider (quản lý state) ≠ UI (hiển thị)  
✅ **Error handling** đầy đủ: permission, service, timeout  
✅ **UX tốt**: Loading state, error messages, disable button khi cần  
✅ **Tuân thủ 100%** coding rules: Clean Architecture, DI, layer separation  

### FloatingActionButton Logic:

```dart
FloatingActionButton(
  onPressed: provider.isMapReady && !provider.isLoadingLocation
      ? provider.getCurrentLocation  // 👈 Click → Call method này
      : null,  // 👈 Disable khi chưa ready hoặc đang loading
  child: provider.isLoadingLocation
      ? CircularProgressIndicator()  // 👈 Show loading
      : Icon(Icons.my_location),     // 👈 Show icon
)
```

---

**Lưu ý**: 
- Test trên **thiết bị thật** (GPS không hoạt động trên simulator)
- Config permissions cho cả **iOS và Android**
- Handle tất cả **edge cases** (denied, disabled, timeout)
- Sử dụng **debug logs** để trace flow

