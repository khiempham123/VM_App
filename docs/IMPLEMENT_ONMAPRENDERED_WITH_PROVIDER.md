# Giải Pháp: Sử Dụng onMapRendered Callback Với Provider

## 🎯 Khuyến Nghị Từ Package

Package `vietmap_flutter_navigation` khuyến nghị:

> **We strongly recommend you call the `_navigationController?.buildRouteAndStartNavigation()` in a button or `onMapRendered` callback**, which is called when the map is rendered successfully to ensure that the application does not crash while executing some function while our SDK is rendering the map.

## ✅ Có Thể Áp Dụng Với Provider Pattern

**Câu trả lời: HOÀN TOÀN CÓ THỂ!** ✅

Đây chính là giải pháp tốt nhất cho vấn đề "navigation controller is null" của bạn.

---

## 🔄 Flow Hoạt Động

### Flow Hiện Tại (LỖI)
```
User clicks near_me_outlined
    ↓
provider.buildNavigationRoute()
    ↓
Check: _navigationController == null? → YES ❌
    ↓
Return với error
    ↓
NavigationView không được render
    ↓
Controller không bao giờ được khởi tạo
```

### Flow Mới (ĐÚNG) - Theo Khuyến Nghị Package
```
User clicks near_me_outlined
    ↓
Set flag: _pendingNavigationRoute = true
Set flag: _isOnNavigationRoute = true
    ↓
notifyListeners() → Screen rebuild
    ↓
NavigationView được render (vì isOnNavigationRoute = true)
    ↓
onMapCreated → Controller được khởi tạo ✅
    ↓
onMapRendered → Map đã sẵn sàng ✅
    ↓
Check: _pendingNavigationRoute == true?
    ↓
Auto call buildRoute() hoặc buildAndStartNavigation()
    ↓
SUCCESS ✅
```

---

## 💡 Implementation Chi Tiết

### Option A: Build Route Trong onMapRendered (Khuyến Nghị) ⭐

#### 1. Provider Changes

```dart
class MetroMapProvider extends ChangeNotifier {
  // Existing fields...
  bool _pendingNavigationRoute = false;  // NEW: Track pending route
  bool get hasPendingNavigationRoute => _pendingNavigationRoute;
  
  // Existing methods...
  
  /// User clicks button → Set pending flag
  Future<void> buildNavigationRoute() async {
    // Validation
    if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
      debugPrint('❌ Missing start or end location');
      _errorMessage = 'Vui lòng chọn điểm bắt đầu và điểm đến';
      notifyListeners();
      return;
    }
    
    // Check if controller is ready
    if (_navigationController == null) {
      debugPrint('🔄 Navigation controller not ready, will build when map renders...');
      
      // Set flags to enable NavigationView and mark pending route
      _isOnNavigationRoute = true;
      _pendingNavigationRoute = true;
      _isCalculatingRoute = true;
      
      notifyListeners();
      return;
    }
    
    // Controller is ready, build route immediately
    _pendingNavigationRoute = false;
    await _buildNavigationRouteInternal();
  }
  
  /// Called when NavigationView map is rendered (Package recommendation)
  void onNavigationMapRendered() {
    debugPrint('✅ Navigation map rendered successfully');
    
    // Check if there's a pending route to build
    if (_pendingNavigationRoute && _navigationController != null) {
      debugPrint('🚀 Auto-building pending navigation route...');
      _buildNavigationRouteInternal();
    }
  }
  
  /// Internal method to actually build the route
  Future<void> _buildNavigationRouteInternal() async {
    if (_navigationController == null) {
      debugPrint('❌ Controller still null in internal build');
      _isCalculatingRoute = false;
      return;
    }
    
    if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
      debugPrint('❌ Locations missing in internal build');
      _isCalculatingRoute = false;
      return;
    }
    
    _pendingNavigationRoute = false;  // Clear pending flag
    _isCalculatingRoute = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final waypoints = [_currentPlaceLatLng!, _selectedPlaceLatLng!];
      
      debugPrint('🚀 Building navigation route...');
      debugPrint('From: ${_currentPlaceLatLng!.latitude}, ${_currentPlaceLatLng!.longitude}');
      debugPrint('To: ${_selectedPlaceLatLng!.latitude}, ${_selectedPlaceLatLng!.longitude}');
      
      await _navigationController?.buildRoute(
        waypoints: waypoints,
        profile: DrivingProfile.drivingTraffic,
      );
      
      debugPrint('✅ Navigation route building...');
    } catch (e) {
      debugPrint('❌ Error building navigation route: $e');
      _errorMessage = 'Error building navigation route: $e';
      _isCalculatingRoute = false;
      notifyListeners();
    }
  }
  
  // Update stopNavigation to reset pending flag
  void stopNavigation() {
    _navigationController?.finishNavigation();
    _isOnNavigationRoute = false;
    _pendingNavigationRoute = false;  // Reset pending flag
    _routeProgressEvent = null;
    debugPrint('⏹️ Navigation stopped');
    notifyListeners();
  }
}
```

#### 2. Screen Changes

```dart
// In metro_map_screen.dart

// Change từ conditional ? : sang Visibility hoặc Stack
Stack(
  children: [
    // VietmapGL for simple route drawing
    if (!provider.isOnNavigationRoute)
      _VietmapWidget(onMapCreated: provider.onMapCreated),
    
    // NavigationView - Render when needed
    if (provider.isOnNavigationRoute)
      NavigationView(
        mapOptions: provider.navigationOption,
        
        onMapCreated: (controller) {
          provider.onNavigationControllerCreated(controller);
          debugPrint('✅ Navigation controller created');
        },
        
        // 🎯 KEY: onMapRendered callback - Package recommendation
        onMapRendered: () {
          provider.onNavigationMapRendered();  // Auto-build pending route
        },
        
        onRouteBuilt: (route) {
          provider.onNavigationRouteBuilt(route);
        },
        
        onRouteBuildFailed: (error) {
          provider.onNavigationRouteBuildFailed(error);
        },
        
        onRouteProgressChange: (event) {
          provider.onNavigationRouteProgressChange(event);
          setState(() {
            routeProgressEvent = event;
          });
          _setInstructionImage(
            event.currentModifier,
            event.currentModifierType,
          );
        },
        
        onArrival: () {
          provider.onNavigationArrival();
        },
        
        onMapLongClick: provider.onMapLongSelected,
        
        onMapClick: (latLng, point) async {
          debugPrint('🗺️ Map clicked at: $latLng');
        },
      ),
    
    // Other widgets...
  ],
)
```

---

### Option B: Build And Start Trong onMapRendered (Một Bước) ⚡

Nếu bạn muốn **build route VÀ start navigation luôn** (không cần nhấn Start button):

```dart
class MetroMapProvider extends ChangeNotifier {
  bool _autoStartNavigation = false;  // NEW: Flag to auto-start
  
  /// User clicks button → Will build and start automatically
  Future<void> buildAndStartNavigationRoute() async {
    if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
      debugPrint('❌ Missing locations');
      _errorMessage = 'Vui lòng chọn điểm bắt đầu và điểm đến';
      notifyListeners();
      return;
    }
    
    if (_navigationController == null) {
      debugPrint('🔄 Controller not ready, will build+start when map renders...');
      
      _isOnNavigationRoute = true;
      _pendingNavigationRoute = true;
      _autoStartNavigation = true;  // Set auto-start flag
      _isCalculatingRoute = true;
      
      notifyListeners();
      return;
    }
    
    // Controller ready, build and start immediately
    await _buildAndStartInternal();
  }
  
  /// Called when map is rendered
  void onNavigationMapRendered() {
    debugPrint('✅ Navigation map rendered');
    
    if (_pendingNavigationRoute && _navigationController != null) {
      if (_autoStartNavigation) {
        debugPrint('🚀 Auto-building and starting navigation...');
        _buildAndStartInternal();
      } else {
        debugPrint('🚀 Auto-building route...');
        _buildNavigationRouteInternal();
      }
    }
  }
  
  /// Build route and start navigation immediately
  Future<void> _buildAndStartInternal() async {
    if (_navigationController == null) return;
    if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) return;
    
    _pendingNavigationRoute = false;
    _autoStartNavigation = false;
    _isCalculatingRoute = true;
    notifyListeners();
    
    try {
      final waypoints = [_currentPlaceLatLng!, _selectedPlaceLatLng!];
      
      debugPrint('🚀 Building and starting navigation...');
      
      // Use buildAndStartNavigation - Package method
      await _navigationController?.buildAndStartNavigation(
        waypoints: waypoints,
        profile: DrivingProfile.drivingTraffic,
      );
      
      debugPrint('✅ Navigation started automatically');
    } catch (e) {
      debugPrint('❌ Error: $e');
      _errorMessage = 'Error: $e';
      _isCalculatingRoute = false;
      notifyListeners();
    }
  }
}
```

---

## 🎨 UI/UX Improvements

### Thêm Loading State

```dart
// Provider
bool _isInitializingNavigation = false;
bool get isInitializingNavigation => _isInitializingNavigation;

Future<void> buildNavigationRoute() async {
  // ...validation...
  
  if (_navigationController == null) {
    _isInitializingNavigation = true;  // Show loading
    _isOnNavigationRoute = true;
    _pendingNavigationRoute = true;
    notifyListeners();
    return;
  }
  
  // ...build route...
}

void onNavigationMapRendered() {
  // ...existing code...
  _isInitializingNavigation = false;  // Hide loading
  notifyListeners();
}
```

```dart
// Screen: Show loading overlay
if (provider.isInitializingNavigation)
  Container(
    color: Colors.black54,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Đang khởi tạo bản đồ điều hướng...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    ),
  ),
```

---

## 📊 So Sánh 2 Options

| Feature | Option A: Build Only | Option B: Build + Start |
|---------|---------------------|-------------------------|
| **User clicks button** | Route được vẽ | Route vẽ + start luôn |
| **Cần Start button?** | ✅ Yes | ❌ No |
| **User control** | Cao (preview trước) | Thấp (auto start) |
| **Steps** | 2 steps (Build → Start) | 1 step |
| **Use case** | Muốn xem route trước | Navigation ngay lập tức |
| **Khuyến nghị** | ⭐⭐⭐⭐⭐ Tốt nhất | ⭐⭐⭐⭐ Tốt |

---

## ✅ Code Implementation Hoàn Chỉnh

### Provider (metro_map_provider.dart)

```dart
class MetroMapProvider extends ChangeNotifier {
  // ...existing fields...
  
  bool _pendingNavigationRoute = false;
  bool _isInitializingNavigation = false;
  
  bool get hasPendingNavigationRoute => _pendingNavigationRoute;
  bool get isInitializingNavigation => _isInitializingNavigation;
  
  // Constructor
  MetroMapProvider(this._appProvider) {
    Vietmap.getInstance('${dotenv.env['VM_API_KEY']}');
    _metroMapRepository = locator<MetroMapRepository>();
    _routeRepository = locator<RouteRepository>();
    _initializeNavigationOptions();
  }
  
  // ...existing methods unchanged...
  
  /// User clicks near_me_outlined button
  Future<void> buildNavigationRoute() async {
    // Validation
    if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
      debugPrint('❌ Missing start or end location');
      _errorMessage = 'Vui lòng chọn điểm bắt đầu và điểm đến';
      notifyListeners();
      return;
    }
    
    // Check if controller is ready
    if (_navigationController == null) {
      debugPrint('🔄 Navigation controller not ready yet');
      debugPrint('📋 Setting up NavigationView to initialize controller...');
      
      // Enable NavigationView and mark pending route
      _isOnNavigationRoute = true;
      _pendingNavigationRoute = true;
      _isInitializingNavigation = true;
      _isCalculatingRoute = true;
      
      notifyListeners();
      return;
    }
    
    // Controller is ready, build route immediately
    debugPrint('✅ Controller ready, building route now');
    await _buildNavigationRouteInternal();
  }
  
  /// Package recommendation: Called when NavigationView map is rendered
  void onNavigationMapRendered() {
    debugPrint('✅ Navigation map rendered successfully');
    
    _isInitializingNavigation = false;
    
    // Auto-build pending route
    if (_pendingNavigationRoute && _navigationController != null) {
      debugPrint('🚀 Auto-building pending navigation route...');
      _buildNavigationRouteInternal();
    }
    
    notifyListeners();
  }
  
  /// Internal method to build route
  Future<void> _buildNavigationRouteInternal() async {
    if (_navigationController == null) {
      debugPrint('❌ Controller is null in internal build');
      _isCalculatingRoute = false;
      _pendingNavigationRoute = false;
      notifyListeners();
      return;
    }
    
    if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
      debugPrint('❌ Locations missing');
      _isCalculatingRoute = false;
      _pendingNavigationRoute = false;
      notifyListeners();
      return;
    }
    
    _pendingNavigationRoute = false;
    _isCalculatingRoute = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final waypoints = [_currentPlaceLatLng!, _selectedPlaceLatLng!];
      
      debugPrint('🚀 Building navigation route...');
      debugPrint('From: ${_currentPlaceLatLng!.latitude}, ${_currentPlaceLatLng!.longitude}');
      debugPrint('To: ${_selectedPlaceLatLng!.latitude}, ${_selectedPlaceLatLng!.longitude}');
      
      await _navigationController?.buildRoute(
        waypoints: waypoints,
        profile: DrivingProfile.drivingTraffic,
      );
      
      debugPrint('✅ Navigation route request sent');
    } catch (e) {
      debugPrint('❌ Error building navigation route: $e');
      _errorMessage = 'Lỗi tạo route: $e';
      _isCalculatingRoute = false;
      notifyListeners();
    }
  }
  
  // Update callbacks
  void onNavigationRouteBuilt(dynamic route) {
    _isOnNavigationRoute = true;
    _isCalculatingRoute = false;
    _pendingNavigationRoute = false;
    
    debugPrint('✅ Navigation route built successfully');
    notifyListeners();
  }
  
  void onNavigationRouteBuildFailed(dynamic error) {
    _isCalculatingRoute = false;
    _pendingNavigationRoute = false;
    _errorMessage = 'Không thể tạo route: $error';
    
    debugPrint('❌ Navigation route build failed: $error');
    notifyListeners();
  }
  
  void stopNavigation() {
    _navigationController?.finishNavigation();
    _isOnNavigationRoute = false;
    _pendingNavigationRoute = false;
    _isInitializingNavigation = false;
    _routeProgressEvent = null;
    debugPrint('⏹️ Navigation stopped');
    notifyListeners();
  }
  
  // ...rest of existing methods unchanged...
}
```

### Screen (metro_map_screen.dart)

```dart
// In _MetroMapViewState

@override
Widget build(BuildContext context) {
  final provider = context.watch<MetroMapProvider>();

  return Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      children: [
        // VietmapGL for simple route
        if (!provider.isOnNavigationRoute)
          _VietmapWidget(onMapCreated: provider.onMapCreated),
        
        // NavigationView with callbacks
        if (provider.isOnNavigationRoute)
          NavigationView(
            mapOptions: provider.navigationOption,
            
            onMapCreated: (controller) {
              provider.onNavigationControllerCreated(controller);
            },
            
            // 🎯 KEY: onMapRendered - Auto-build pending route
            onMapRendered: () {
              provider.onNavigationMapRendered();
            },
            
            onRouteBuilt: (route) {
              provider.onNavigationRouteBuilt(route);
            },
            
            onRouteBuildFailed: (error) {
              provider.onNavigationRouteBuildFailed(error);
            },
            
            onRouteProgressChange: (event) {
              provider.onNavigationRouteProgressChange(event);
              setState(() {
                routeProgressEvent = event;
              });
              _setInstructionImage(
                event.currentModifier,
                event.currentModifierType,
              );
            },
            
            onArrival: () {
              provider.onNavigationArrival();
            },
            
            onMapLongClick: provider.onMapLongSelected,
            
            onMapClick: (latLng, point) async {
              debugPrint('🗺️ Map clicked at: $latLng');
            },
          ),
        
        // Loading overlay when initializing navigation
        if (provider.isInitializingNavigation)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang khởi tạo bản đồ điều hướng...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // ...rest of your UI widgets...
      ],
    ),
    // ...floatingActionButton...
  );
}
```

---

## 🎯 Lợi Ích Của Giải Pháp Này

### 1. Theo Khuyến Nghị Của Package ✅
- Đúng theo best practice từ documentation
- Tránh crash khi SDK đang render map
- Đảm bảo controller đã sẵn sàng

### 2. Hoạt Động Hoàn Hảo Với Provider Pattern ✅
- State management rõ ràng với flags
- notifyListeners() trigger UI rebuild
- Separationof concerns (logic vs UI)

### 3. UX Tốt ✅
- User chỉ click 1 lần
- Loading indicator rõ ràng
- Tự động build route khi ready

### 4. Code Clean & Maintainable ✅
- Logic tách biệt trong internal method
- Dễ debug với logs
- Dễ extend (thêm auto-start, v.v.)

---

## 🐛 Xử Lý Edge Cases

### Case 1: User Click Nhiều Lần Nhanh

```dart
Future<void> buildNavigationRoute() async {
  // Prevent double-click
  if (_isInitializingNavigation || _isCalculatingRoute) {
    debugPrint('⚠️ Already processing, please wait...');
    return;
  }
  
  // ...rest of code...
}
```

### Case 2: User Stop Trước Khi Route Build Xong

```dart
void stopNavigation() {
  _navigationController?.finishNavigation();
  
  // Clear all flags
  _isOnNavigationRoute = false;
  _pendingNavigationRoute = false;  // Cancel pending route
  _isInitializingNavigation = false;
  _isCalculatingRoute = false;
  _routeProgressEvent = null;
  
  debugPrint('⏹️ Navigation stopped');
  notifyListeners();
}
```

### Case 3: Location Chưa Được Chọn

```dart
// Trong screen, disable button nếu chưa có locations
FloatingActionButton(
  mini: true,
  tooltip: 'Bắt đầu điều hướng',
  onPressed: (provider.currentPlaceLatLng != null && 
             provider.selectedPlaceLatLng != null)
      ? () => provider.buildNavigationRoute()
      : null,  // Disable button
  child: Icon(Icons.near_me_outlined, 
       color: (provider.currentPlaceLatLng != null && 
              provider.selectedPlaceLatLng != null)
           ? AppColors.primary 
           : Colors.grey),
)
```

---

## ✅ Kết Luận

**CÓ THỂ** áp dụng khuyến nghị của package với Provider pattern! 🎉

**Giải pháp tốt nhất**:
1. Set flag `_pendingNavigationRoute = true` khi user click
2. Enable NavigationView (`_isOnNavigationRoute = true`)
3. NavigationView render → `onMapCreated` → Controller khởi tạo
4. Map rendered → `onMapRendered` → Auto-build pending route
5. Success! ✅

**Lợi ích**:
- ✅ Theo đúng best practice của package
- ✅ Tránh crash
- ✅ UX tốt (user chỉ click 1 lần)
- ✅ Code clean với Provider pattern
- ✅ Dễ maintain và extend

---

*Tài liệu này cung cấp giải pháp hoàn chỉnh để implement khuyến nghị của package với Provider pattern.*

