# Hướng Dẫn Quản Lý State VietmapGL Thông Qua Provider

## Tổng Quan

Tài liệu này hướng dẫn cách quản lý state của `VietmapGL` (package `vietmap_flutter_gl`) theo đúng quy tắc Clean Architecture và coding rules của dự án.

---

## 1. Phân Tích Package vietmap_flutter_gl

### Các thành phần chính:
- **VietmapController**: Controller để điều khiển map (zoom, move camera, add symbols/layers, etc.)
- **VietmapGL Widget**: Widget hiển thị bản đồ
- **CameraPosition**: Vị trí và zoom level của camera
- **LatLng**: Tọa độ địa lý (latitude, longitude)
- **Callbacks**: `onMapCreated`, `onMapClick`, `onStyleLoadedCallback`, etc.

### Lifecycle của VietmapGL:
1. Widget được khởi tạo với `initialCameraPosition`
2. Callback `onMapCreated` được gọi và trả về `VietmapController`
3. Controller có thể được sử dụng để điều khiển map (animateCamera, addSymbol, addLayer, etc.)

---

## 2. Cấu Trúc State Management Theo Clean Architecture

### 2.1. Layer Domain (Nếu cần)

**File**: `lib/domain/entities/metro_map_state.dart`

```dart
/// Entity đại diện cho trạng thái của Metro Map
class MetroMapState {
  final LatLng currentPosition;
  final double currentZoom;
  final bool isMapReady;
  final List<MetroStation>? metroStations;
  final MetroStation? selectedStation;
  
  const MetroMapState({
    required this.currentPosition,
    required this.currentZoom,
    this.isMapReady = false,
    this.metroStations,
    this.selectedStation,
  });
  
  MetroMapState copyWith({
    LatLng? currentPosition,
    double? currentZoom,
    bool? isMapReady,
    List<MetroStation>? metroStations,
    MetroStation? selectedStation,
  }) {
    return MetroMapState(
      currentPosition: currentPosition ?? this.currentPosition,
      currentZoom: currentZoom ?? this.currentZoom,
      isMapReady: isMapReady ?? this.isMapReady,
      metroStations: metroStations ?? this.metroStations,
      selectedStation: selectedStation ?? this.selectedStation,
    );
  }
}
```

**File**: `lib/domain/entities/metro_station.dart`

```dart
/// Entity đại diện cho một trạm Metro
class MetroStation {
  final String id;
  final String name;
  final LatLng location;
  final String? description;
  
  const MetroStation({
    required this.id,
    required this.name,
    required this.location,
    this.description,
  });
}
```

### 2.2. Layer Modules (Provider)

**File**: `lib/modules/metro_go/metro_map_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/entities/metro_map_state.dart';
import 'package:vm_first_app/domain/entities/metro_station.dart';

class MetroMapProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  
  // VietmapController - sẽ được khởi tạo khi map ready
  VietmapController? _mapController;
  VietmapController? get mapController => _mapController;
  
  // State của map
  MetroMapState _state = MetroMapState(
    currentPosition: const LatLng(10.762317, 106.654551), // Vị trí mặc định HCM
    currentZoom: 14.0,
    isMapReady: false,
  );
  
  MetroMapState get state => _state;
  bool get isMapReady => _state.isMapReady;
  LatLng get currentPosition => _state.currentPosition;
  double get currentZoom => _state.currentZoom;
  List<MetroStation>? get metroStations => _state.metroStations;
  
  MetroMapProvider(this._appProvider);
  
  // ===== MAP LIFECYCLE METHODS =====
  
  /// Callback khi map được tạo
  /// Đây là nơi nhận VietmapController
  void onMapCreated(VietmapController controller) {
    _mapController = controller;
    _updateState(_state.copyWith(isMapReady: true));
    
    // Load dữ liệu ban đầu
    _loadInitialData();
    
    debugPrint('🗺️ [METRO_MAP] Map created and ready');
  }
  
  /// Callback khi style của map được load xong
  void onStyleLoadedCallback() {
    debugPrint('🗺️ [METRO_MAP] Map style loaded');
    // Có thể add custom layers, symbols ở đây
    _addMetroStationsToMap();
  }
  
  /// Callback khi map được click
  void onMapClick(Point<double> point, LatLng latLng) {
    debugPrint('🗺️ [METRO_MAP] Map clicked at: ${latLng.latitude}, ${latLng.longitude}');
    // Xử lý logic khi click vào map
  }
  
  // ===== CAMERA CONTROL METHODS =====
  
  /// Di chuyển camera đến vị trí cụ thể
  Future<void> moveToLocation(LatLng location, {double? zoom}) async {
    if (_mapController == null) {
      debugPrint('⚠️ [METRO_MAP] Controller not ready');
      return;
    }
    
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          location,
          zoom ?? _state.currentZoom,
        ),
      );
      
      _updateState(_state.copyWith(
        currentPosition: location,
        currentZoom: zoom ?? _state.currentZoom,
      ));
      
      debugPrint('🗺️ [METRO_MAP] Moved to: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      debugPrint('❌ [METRO_MAP] Error moving camera: $e');
    }
  }
  
  /// Zoom in map
  Future<void> zoomIn() async {
    if (_mapController == null) return;
    
    final newZoom = _state.currentZoom + 1;
    await _mapController!.animateCamera(CameraUpdate.zoomTo(newZoom));
    _updateState(_state.copyWith(currentZoom: newZoom));
  }
  
  /// Zoom out map
  Future<void> zoomOut() async {
    if (_mapController == null) return;
    
    final newZoom = _state.currentZoom - 1;
    await _mapController!.animateCamera(CameraUpdate.zoomTo(newZoom));
    _updateState(_state.copyWith(currentZoom: newZoom));
  }
  
  /// Di chuyển về vị trí hiện tại của user
  Future<void> moveToCurrentLocation() async {
    // TODO: Implement location service để lấy vị trí hiện tại
    // Ví dụ tạm:
    const userLocation = LatLng(10.762317, 106.654551);
    await moveToLocation(userLocation, zoom: 16.0);
  }
  
  // ===== DATA METHODS =====
  
  /// Load dữ liệu ban đầu (danh sách trạm metro)
  Future<void> _loadInitialData() async {
    // TODO: Gọi API hoặc load từ local data
    // Ví dụ tạm:
    final stations = [
      MetroStation(
        id: '1',
        name: 'Bến Thành',
        location: const LatLng(10.7722, 106.6980),
        description: 'Trạm Bến Thành - Metro Line 1',
      ),
      MetroStation(
        id: '2',
        name: 'Nhà hát Thành phố',
        location: const LatLng(10.7769, 106.7009),
        description: 'Trạm Nhà hát Thành phố - Metro Line 1',
      ),
      // ... thêm các trạm khác
    ];
    
    _updateState(_state.copyWith(metroStations: stations));
  }
  
  /// Thêm các trạm metro lên map dưới dạng symbols
  Future<void> _addMetroStationsToMap() async {
    if (_mapController == null || _state.metroStations == null) return;
    
    try {
      // Load icon cho metro station
      await _mapController!.addImage(
        'metro-icon',
        // Sử dụng icon từ assets hoặc network
        // await loadImageFromAsset('assets/icons/metro_station.png'),
      );
      
      // Add symbols cho từng trạm
      for (final station in _state.metroStations!) {
        await _mapController!.addSymbol(
          SymbolOptions(
            geometry: station.location,
            iconImage: 'metro-icon',
            iconSize: 1.5,
            textField: station.name,
            textOffset: const Offset(0, 2),
            textSize: 12,
          ),
        );
      }
      
      debugPrint('🗺️ [METRO_MAP] Added ${_state.metroStations!.length} metro stations to map');
    } catch (e) {
      debugPrint('❌ [METRO_MAP] Error adding stations: $e');
    }
  }
  
  /// Chọn một trạm metro
  void selectStation(MetroStation station) {
    _updateState(_state.copyWith(selectedStation: station));
    moveToLocation(station.location, zoom: 16.0);
    debugPrint('🗺️ [METRO_MAP] Selected station: ${station.name}');
  }
  
  // ===== HELPER METHODS =====
  
  /// Update state và notify listeners
  void _updateState(MetroMapState newState) {
    _state = newState;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
```

### 2.3. Layer UI (Screen)

**File**: `lib/modules/metro_go/metro_map_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:auto_route/auto_route.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/core.dart';
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
      appBar: AppBar(
        title: const Text('Metro Map'),
        backgroundColor: AppColors.primary,
        actions: [
          // Zoom controls trong AppBar
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: provider.isMapReady ? provider.zoomIn : null,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: provider.isMapReady ? provider.zoomOut : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map Widget
          VietmapGL(
            styleString:
                'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${dotenv.env['VM_API_KEY']}',
            initialCameraPosition: CameraPosition(
              target: provider.currentPosition,
              zoom: provider.currentZoom,
            ),
            onMapCreated: provider.onMapCreated,
            onStyleLoadedCallback: provider.onStyleLoadedCallback,
            onMapClick: provider.onMapClick,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.tracking,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),
          
          // Loading indicator khi map chưa ready
          if (!provider.isMapReady)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
          
          // Danh sách trạm metro (bottom sheet có thể kéo lên)
          if (provider.metroStations != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _MetroStationsList(stations: provider.metroStations!),
            ),
        ],
      ),
      floatingActionButton: _MapFloatingButtons(provider: provider),
    );
  }
}

/// Widget chứa các floating action buttons
class _MapFloatingButtons extends StatelessWidget {
  final MetroMapProvider provider;
  
  const _MapFloatingButtons({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Button về vị trí hiện tại
        FloatingActionButton(
          heroTag: 'current_location',
          mini: true,
          backgroundColor: AppColors.primary,
          onPressed: provider.isMapReady 
              ? provider.moveToCurrentLocation 
              : null,
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
        const SizedBox(height: 8),
        
        // Button zoom in (nếu muốn thêm ở đây)
        FloatingActionButton(
          heroTag: 'zoom_in',
          mini: true,
          backgroundColor: AppColors.primary,
          onPressed: provider.isMapReady ? provider.zoomIn : null,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        const SizedBox(height: 8),
        
        // Button zoom out
        FloatingActionButton(
          heroTag: 'zoom_out',
          mini: true,
          backgroundColor: AppColors.primary,
          onPressed: provider.isMapReady ? provider.zoomOut : null,
          child: const Icon(Icons.remove, color: Colors.white),
        ),
      ],
    );
  }
}

/// Widget hiển thị danh sách trạm metro
class _MetroStationsList extends StatelessWidget {
  final List<MetroStation> stations;
  
  const _MetroStationsList({required this.stations});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MetroMapProvider>();
    
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Metro Stations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // List of stations
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                final isSelected = provider.state.selectedStation?.id == station.id;
                
                return GestureDetector(
                  onTap: () => provider.selectStation(station),
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.train,
                          color: isSelected ? Colors.white : AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          station.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. Giải Thích Các Khái Niệm Quan Trọng

### 3.1. VietmapController
- **Không thể khởi tạo trực tiếp**: Controller chỉ được trả về thông qua callback `onMapCreated`
- **Phải kiểm tra null**: Luôn check `_mapController != null` trước khi sử dụng
- **Async operations**: Hầu hết các method của controller đều là async (animateCamera, addSymbol, etc.)

### 3.2. Provider Pattern
```dart
// BAD - Không nên lưu controller như thế này
final onMapCreate = VietmapController(); // ❌ Sai

// GOOD - Nên như thế này
VietmapController? _mapController; // ✅ Đúng
void onMapCreated(VietmapController controller) {
  _mapController = controller;
  notifyListeners();
}
```

### 3.3. State Management
- **Immutable State**: Sử dụng `copyWith()` để tạo state mới
- **Single Source of Truth**: Tất cả state được quản lý trong Provider
- **Reactive UI**: UI tự động update khi state thay đổi thông qua `notifyListeners()`

---

## 4. Các Tính Năng Floating Button

### 4.1. Button Di Chuyển Về Vị Trí Hiện Tại

```dart
FloatingActionButton(
  onPressed: provider.isMapReady 
      ? provider.moveToCurrentLocation 
      : null,
  child: const Icon(Icons.my_location),
)
```

**Implementation trong Provider**:
```dart
Future<void> moveToCurrentLocation() async {
  if (_mapController == null) return;
  
  // Lấy vị trí hiện tại từ location service
  final userLocation = await _getUserLocation();
  
  // Di chuyển camera
  await moveToLocation(userLocation, zoom: 16.0);
}

Future<LatLng> _getUserLocation() async {
  // TODO: Implement với location package
  // Ví dụ: geolocator, location, etc.
  return const LatLng(10.762317, 106.654551);
}
```

### 4.2. Button Zoom In/Out

```dart
// Zoom In
FloatingActionButton(
  onPressed: provider.isMapReady ? provider.zoomIn : null,
  child: const Icon(Icons.add),
)

// Zoom Out
FloatingActionButton(
  onPressed: provider.isMapReady ? provider.zoomOut : null,
  child: const Icon(Icons.remove),
)
```

### 4.3. Button Tìm Địa Điểm

```dart
FloatingActionButton(
  onPressed: () => _showSearchDialog(context),
  child: const Icon(Icons.search),
)

Future<void> _showSearchDialog(BuildContext context) async {
  // Show dialog để search địa điểm
  // Sau đó gọi provider.moveToLocation()
}
```

---

## 5. Tuân Thủ Coding Rules

### ✅ Import Rules
```dart
// ✅ ĐÚNG - modules/ có thể import từ domain/
import 'package:vm_first_app/domain/entities/metro_map_state.dart';
import 'package:vm_first_app/domain/entities/metro_station.dart';

// ✅ ĐÚNG - modules/ có thể import từ core/
import 'package:vm_first_app/core/core.dart';

// ❌ SAI - modules/ không được import từ data/
import 'package:vm_first_app/data/services/metro_service.dart'; // ❌
```

### ✅ Naming Conventions
```dart
// ✅ Provider
class MetroMapProvider extends ChangeNotifier { }

// ✅ Screen
class MetroMapScreen extends StatelessWidget { }

// ✅ Private View Widget
class _MetroMapView extends StatelessWidget { }

// ✅ Entity
class MetroStation { }
```

### ✅ File Structure
```
lib/
├── domain/
│   └── entities/
│       ├── metro_map_state.dart      // State entity
│       └── metro_station.dart        // Metro station entity
├── modules/
│   └── metro_go/
│       ├── metro_map_screen.dart     // UI Screen
│       └── metro_map_provider.dart   // State Provider
└── core/
    ├── constants/                     // Colors, strings, etc.
    └── widgets/                       // Shared widgets
```

---

## 6. Xử Lý Lỗi "Null check operator used on a null value"

### Nguyên nhân:
```dart
final onMapCreate = VietmapController(); // ❌ 
// VietmapController không thể khởi tạo trực tiếp
// Gây lỗi null check khi sử dụng
```

### Giải pháp:
```dart
VietmapController? _mapController; // ✅ Nullable

void onMapCreated(VietmapController controller) {
  _mapController = controller; // Gán từ callback
  _updateState(_state.copyWith(isMapReady: true));
}

// Luôn check null trước khi dùng
Future<void> zoomIn() async {
  if (_mapController == null) return; // ✅ Safety check
  await _mapController!.animateCamera(...);
}
```

---

## 7. Testing State Management

### 7.1. Unit Test Provider
```dart
void main() {
  test('onMapCreated should set controller and update state', () {
    final provider = MetroMapProvider(mockAppProvider);
    final mockController = MockVietmapController();
    
    provider.onMapCreated(mockController);
    
    expect(provider.mapController, isNotNull);
    expect(provider.isMapReady, true);
  });
}
```

### 7.2. Widget Test
```dart
testWidgets('FloatingActionButton should trigger moveToCurrentLocation', 
  (WidgetTester tester) async {
  // Test UI interaction với Provider
});
```

---

## 8. Best Practices

### ✅ DO
- Luôn check `_mapController != null` trước khi sử dụng
- Sử dụng `copyWith()` để update state immutably
- Wrap các operation với try-catch để handle errors
- Dispose controller trong `dispose()` method
- Log debug messages để trace flow
- Sử dụng `isMapReady` flag để disable/enable UI

### ❌ DON'T
- Không khởi tạo VietmapController trực tiếp
- Không mutate state trực tiếp (phải dùng copyWith)
- Không forget gọi `notifyListeners()` sau khi update state
- Không expose mutable state ra ngoài Provider

---

## 9. Tích Hợp Location Service (Optional)

Nếu cần tính năng location, cần thêm:

### 9.1. Dependencies
```yaml
dependencies:
  geolocator: ^11.0.0
  permission_handler: ^11.0.0
```

### 9.2. Location Service (trong core/)
```dart
// lib/core/services/location_service.dart
abstract class LocationService {
  Future<LatLng> getCurrentLocation();
  Future<bool> requestPermission();
}

// lib/core/services/location_service_impl.dart
class LocationServiceImpl implements LocationService {
  @override
  Future<LatLng> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }
  
  @override
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
}
```

### 9.3. Inject vào Provider
```dart
class MetroMapProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  final LocationService _locationService;
  
  MetroMapProvider(this._appProvider, this._locationService);
  
  Future<void> moveToCurrentLocation() async {
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) {
      debugPrint('⚠️ Location permission denied');
      return;
    }
    
    final location = await _locationService.getCurrentLocation();
    await moveToLocation(location, zoom: 16.0);
  }
}
```

---

## 10. Tổng Kết

### Các bước thực hiện:

1. **Tạo Entities trong domain/** (nếu cần quản lý state phức tạp)
2. **Tạo Provider trong modules/metro_go/**
   - Định nghĩa state và getters
   - Implement lifecycle callbacks (onMapCreated, onStyleLoaded, etc.)
   - Implement camera control methods
   - Implement data loading methods
3. **Update Screen UI**
   - Inject Provider
   - Use context.watch để reactive UI
   - Add FloatingActionButtons với các tính năng
4. **Test và Debug**
   - Kiểm tra null safety
   - Test các tính năng zoom, move, select station

### Lưu ý quan trọng:
- ✅ VietmapController chỉ có thể lấy từ callback `onMapCreated`
- ✅ Luôn check null và isMapReady trước khi sử dụng controller
- ✅ Tuân thủ Clean Architecture: Domain → Modules, không import từ Data
- ✅ Sử dụng immutable state với copyWith pattern
- ✅ Disable buttons khi map chưa ready

---

**Tài liệu tham khảo**:
- VietmapGL Package: https://pub.dev/packages/vietmap_flutter_gl
- Provider Pattern: https://pub.dev/packages/provider
- Clean Architecture: Rules.md trong dự án

