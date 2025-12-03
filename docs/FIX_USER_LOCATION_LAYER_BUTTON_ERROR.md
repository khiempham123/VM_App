# Fix: Show UserLocationLayer Marker On Button Click

## 🔴 Lỗi Hiện Tại

### Code bị lỗi:
```dart
FloatingActionButton(
  onPressed: provider.moveToMyLocation ? null : () => UserLocationLayer(
    mapController: provider.vietmapController,
    locationIcon: Icon(...),
    bearingIcon: Container(...),
    ignorePointer: true,
  ),
  child: const Icon(Icons.location_pin),
)
```

### Errors:
```
❌ ERROR: Conditions must have a static type of 'bool'
❌ ERROR: A value of type 'UserLocationLayer' can't be returned from callback
```

### Nguyên nhân:

#### 1. **Type mismatch trong condition**
```dart
// ❌ SAI
provider.moveToMyLocation ? null : () => ...
// moveToMyLocation là Future<bool> Function(), KHÔNG phải bool
```

#### 2. **Không thể return Widget từ onPressed**
```dart
// ❌ SAI
onPressed: () => UserLocationLayer(...) // Return Widget???

// ✅ ĐÚNG
onPressed: () { } // Return void hoặc Future<void>
```

#### 3. **Hiểu sai về UserLocationLayer**
- `UserLocationLayer` là một **Widget overlay**, không phải action
- Nó phải được **add vào Stack** của Scaffold body
- Không thể "show" nó từ button callback

---

## ✅ Giải Pháp

### Approach 1: Show UserLocationLayer Permanently (RECOMMENDED)

UserLocationLayer nên **luôn hiển thị** trong Stack, tự động update khi có vị trí mới.

#### File: `lib/modules/metro_go/metro_map_provider.dart`

```dart
import 'package:vm_first_app/app/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';

class MetroMapProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  
  VietmapController? _vietmapController;
  VietmapController? get vietmapController => _vietmapController;
  bool get isMapReady => _vietmapController != null;

  bool _hasLocationPermission = false;
  bool get hasLocationPermission => _hasLocationPermission;

  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;
  
  // ✅ State để track xem đã di chuyển đến user location chưa
  bool _hasMovedToUserLocation = false;
  bool get hasMovedToUserLocation => _hasMovedToUserLocation;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MetroMapProvider(this._appProvider) {
    _checkInitialPermission();
  }
  
  Future<void> _checkInitialPermission() async {
    _hasLocationPermission = await LocationPermissionService.checkPermission();
    notifyListeners();
  }

  void onMapCreated(VietmapController controller) {
    _vietmapController = controller;
    notifyListeners();
    debugPrint('🗺️ [METRO_MAP] Map created and ready');
  }

  /// Di chuyển camera đến vị trí hiện tại của user
  /// Method này được gọi khi click FloatingActionButton
  Future<void> moveToMyLocation() async {
    if (_vietmapController == null) {
      debugPrint('⚠️ [METRO_MAP] Controller not ready');
      return;
    }

    // Set loading state
    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check permission
      if (!_hasLocationPermission) {
        final granted = await LocationPermissionService.requestPermission();
        if (!granted) {
          _errorMessage = 'Location permission is required';
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
        _hasLocationPermission = granted;
      }

      // ✅ Lấy vị trí user từ VietmapGL
      debugPrint('📍 [METRO_MAP] Requesting user location...');
      final userLocation = await _vietmapController!.requestMyLocationLatLng();
      
      if (userLocation != null) {
        debugPrint('✅ [METRO_MAP] Got location: ${userLocation.latitude}, ${userLocation.longitude}');
        
        // Di chuyển camera đến vị trí user
        await _vietmapController!.animateCamera(
          CameraUpdate.newLatLngZoom(userLocation, 16.0),
          duration: const Duration(milliseconds: 500),
        );
        
        // ✅ Set flag để hiển thị UserLocationLayer
        _hasMovedToUserLocation = true;
        _errorMessage = null;
        
        debugPrint('🗺️ [METRO_MAP] Moved to user location');
      } else {
        debugPrint('⚠️ [METRO_MAP] User location is null');
        _errorMessage = 'Cannot get your location';
      }
    } catch (e) {
      debugPrint('❌ [METRO_MAP] Error: $e');
      _errorMessage = 'Error getting location: $e';
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _vietmapController?.dispose();
    super.dispose();
  }
}
```

#### File: `lib/modules/metro_go/metro_map_screen.dart`

```dart
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vm_first_app/modules/metro_go/metro_map_provider.dart';

@RoutePage()
class MetroMapScreen extends StatelessWidget {
  const MetroMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetroMapProvider(locator<AppProvider>()),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: AppColors.background,
        ),
      ),
      body: Stack(
        children: [
          // Map Widget
          _VietmapWidget(
            onMapCreated: provider.onMapCreated,
            hasLocationPermission: provider.hasLocationPermission,
          ),

          // ✅ UserLocationLayer - Luôn hiển thị nếu có permission và map ready
          if (provider.isMapReady && provider.hasLocationPermission)
            UserLocationLayer(
              mapController: provider.vietmapController!,
              locationIcon: const Icon(
                Icons.circle,
                color: Colors.blue,
                size: 50,
              ),
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
                  color: Colors.red,
                  size: 15,
                ),
              ),
              ignorePointer: true,
            ),
          
          // Error message overlay
          if (provider.errorMessage != null)
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
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: provider.clearError,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Loading indicator
          if (provider.isLoadingLocation)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          // ✅ My Location Button - FIXED
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'my_location',
              backgroundColor: AppColors.primary,
              // ✅ ĐÚNG: onPressed nhận void Function() hoặc null
              onPressed: provider.isMapReady && !provider.isLoadingLocation
                  ? () {
                      // ✅ Gọi method moveToMyLocation
                      provider.moveToMyLocation();
                    }
                  : null, // Disable khi map chưa ready hoặc đang loading
              child: provider.isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: Colors.white,
                    ),
            ),
          ),
          
          // Directions button
          Positioned(
            bottom: 60,
            right: 0.0,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'directions',
              backgroundColor: AppColors.primary,
              onPressed: provider.isMapReady
                  ? () {
                      debugPrint('🗺️ Directions button clicked');
                    }
                  : null,
              child: const Icon(
                Icons.assistant_direction,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VietmapWidget extends StatefulWidget {
  final Function(VietmapController) onMapCreated;
  final bool hasLocationPermission;

  const _VietmapWidget({
    required this.onMapCreated,
    required this.hasLocationPermission,
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
      
      // Location settings
      trackCameraPosition: true,
      myLocationEnabled: widget.hasLocationPermission, // Chỉ bật khi có permission
      myLocationTrackingMode: MyLocationTrackingMode.none, // Manual control
      myLocationRenderMode: MyLocationRenderMode.compass,
      
      // Map controls
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

## 📊 So Sánh: Before vs After

### ❌ Before (Code bị lỗi):

```dart
// Provider
Future<bool> moveToMyLocation() async {
  // ... logic
  _isOnMyLocation = true; // ??? Biến này để làm gì?
  return isOnMyLocation;
}

// UI
FloatingActionButton(
  // ❌ Lỗi: moveToMyLocation là Function, không phải bool
  onPressed: provider.moveToMyLocation ? null : () => UserLocationLayer(...),
  //         ^^^^^^^^^^^^^^^^^^^^^^^^
  //         Type: Future<bool> Function()
  //         Expected: bool
)
```

### ✅ After (Code đúng):

```dart
// Provider
Future<void> moveToMyLocation() async {
  _isLoadingLocation = true;
  notifyListeners();
  
  try {
    final location = await _vietmapController!.requestMyLocationLatLng();
    if (location != null) {
      await _vietmapController!.animateCamera(...);
      _hasMovedToUserLocation = true;
    }
  } finally {
    _isLoadingLocation = false;
    notifyListeners();
  }
}

// UI - UserLocationLayer trong Stack (luôn hiển thị)
body: Stack(
  children: [
    VietmapWidget(),
    
    // ✅ UserLocationLayer luôn có trong Stack
    if (provider.isMapReady && provider.hasLocationPermission)
      UserLocationLayer(...),
  ],
)

// UI - Button chỉ trigger action
FloatingActionButton(
  // ✅ Đúng: Check bool để enable/disable
  onPressed: provider.isMapReady && !provider.isLoadingLocation
      ? () { provider.moveToMyLocation(); } // ✅ Call method
      : null, // ✅ Disable button
  child: provider.isLoadingLocation
      ? CircularProgressIndicator()
      : Icon(Icons.my_location),
)
```

---

## 🎯 Giải Thích Chi Tiết

### 1. Tại sao không thể return Widget từ onPressed?

```dart
// ❌ SAI
FloatingActionButton(
  onPressed: () => UserLocationLayer(...), // Return Widget
  //              ^^^
  //              Type: Widget
  //              Expected: void hoặc Future<void>
)

// onPressed signature:
typedef VoidCallback = void Function();
// Phải return void, KHÔNG thể return Widget
```

### 2. UserLocationLayer là gì?

**UserLocationLayer** là một **Overlay Widget** của VietmapGL:

```dart
// UserLocationLayer là StatelessWidget
class UserLocationLayer extends StatelessWidget {
  final VietmapController mapController;
  final Widget locationIcon;
  final Widget bearingIcon;
  // ...
}
```

**Cách hoạt động:**
- Nó **overlay** lên VietmapGL widget
- Tự động **listen** vào user location changes từ VietmapController
- Tự động **update** position của icon khi location thay đổi
- Phải **add vào Stack**, không phải show từ callback

### 3. Flow đúng:

```
1. User mở app
   ↓
2. VietmapGL render
   ↓
3. Provider check permission
   ↓
4. Nếu có permission → UserLocationLayer được add vào Stack
   ↓
5. UserLocationLayer tự động hiển thị blue dot tại vị trí user
   ↓
6. User click "My Location" button
   ↓
7. Provider.moveToMyLocation() được gọi
   ↓
8. Set loading state (show spinner trong button)
   ↓
9. Request location từ VietmapGL
   ↓
10. Animate camera đến vị trí user
    ↓
11. Clear loading state
    ↓
12. UserLocationLayer TỰ ĐỘNG update icon position
```

---

## 🎨 Approach 2: Toggle UserLocationLayer (Alternative)

Nếu bạn muốn **chỉ hiển thị** UserLocationLayer sau khi click button:

### Provider Changes:

```dart
class MetroMapProvider extends ChangeNotifier {
  // ...existing code...
  
  // ✅ State để control việc hiển thị UserLocationLayer
  bool _showUserLocationLayer = false;
  bool get showUserLocationLayer => _showUserLocationLayer;
  
  Future<void> moveToMyLocation() async {
    // ...existing logic...
    
    // ✅ Sau khi di chuyển camera thành công
    if (userLocation != null) {
      await _vietmapController!.animateCamera(...);
      
      // ✅ Bật hiển thị UserLocationLayer
      _showUserLocationLayer = true;
      notifyListeners();
    }
  }
  
  // ✅ Method để tắt UserLocationLayer nếu cần
  void hideUserLocationLayer() {
    _showUserLocationLayer = false;
    notifyListeners();
  }
}
```

### UI Changes:

```dart
body: Stack(
  children: [
    VietmapWidget(),
    
    // ✅ Chỉ hiển thị khi flag = true
    if (provider.isMapReady && 
        provider.hasLocationPermission && 
        provider.showUserLocationLayer)
      UserLocationLayer(
        mapController: provider.vietmapController!,
        locationIcon: Icon(...),
        bearingIcon: Container(...),
        ignorePointer: true,
      ),
  ],
)
```

---

## 🐛 Common Mistakes

### Mistake 1: Dùng Function làm condition

```dart
// ❌ SAI
provider.moveToMyLocation ? null : () => ...
// moveToMyLocation là Function, không phải bool value

// ✅ ĐÚNG
provider.isLoadingLocation ? null : () => ...
// isLoadingLocation là bool value
```

### Mistake 2: Return Widget từ callback

```dart
// ❌ SAI
onPressed: () => UserLocationLayer(...)
// Return type: Widget (sai!)

// ✅ ĐÚNG
onPressed: () {
  provider.someAction(); // Return type: void
}
```

### Mistake 3: Không check null controller

```dart
// ❌ SAI
UserLocationLayer(
  mapController: provider.vietmapController, // Có thể null!
)

// ✅ ĐÚNG
if (provider.isMapReady && provider.vietmapController != null)
  UserLocationLayer(
    mapController: provider.vietmapController!,
  )
```

---

## 📋 Checklist Implementation

### Provider:
- [ ] Remove `_isOnMyLocation` (không cần thiết)
- [ ] Add `_isLoadingLocation` để show loading state
- [ ] Add `_errorMessage` để show errors
- [ ] Change return type `Future<bool>` → `Future<void>`
- [ ] Add proper error handling với try-catch-finally
- [ ] Add `clearError()` method

### UI:
- [ ] Move UserLocationLayer vào Stack (không phải trong button callback)
- [ ] Fix button `onPressed` logic:
  - Check `provider.isMapReady && !provider.isLoadingLocation`
  - Call `provider.moveToMyLocation()` trong callback
- [ ] Show loading spinner trong button khi `isLoadingLocation = true`
- [ ] Disable button khi map chưa ready hoặc đang loading
- [ ] Add error message overlay
- [ ] Add loading overlay (optional)

### Cleanup:
- [ ] Remove unused imports (`rxdart`)
- [ ] Remove unused fields (`_appProvider` nếu không dùng)
- [ ] Add proper debug logs
- [ ] Test trên simulator và device

---

## 🎯 Tóm Tắt

### Vấn đề chính:
1. ❌ Dùng `Function` làm `bool` condition
2. ❌ Cố return `Widget` từ `onPressed` callback
3. ❌ Hiểu sai về cách hoạt động của `UserLocationLayer`

### Giải pháp:
1. ✅ UserLocationLayer phải **add vào Stack**, không phải show từ callback
2. ✅ Button callback chỉ **call method** để trigger action
3. ✅ Provider quản lý **state và logic**, UI chỉ render theo state
4. ✅ Dùng `isLoadingLocation` (bool) để check condition, không dùng `moveToMyLocation` (Function)

### Key Points:
- 🎨 **UserLocationLayer = Widget overlay**, phải trong Stack
- 🔘 **Button = Trigger action**, chỉ gọi methods
- 📊 **Provider = State management**, quản lý loading/error states
- ✅ **Separation of concerns**: UI ≠ Logic ≠ State

---

**Recommendation**: Sử dụng **Approach 1** (luôn hiển thị UserLocationLayer) vì đơn giản và đúng với best practices của VietmapGL.

