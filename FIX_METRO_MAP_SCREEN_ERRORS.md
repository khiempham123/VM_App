# Sửa Lỗi MetroMapScreen

## 🔍 Các Lỗi Phát Hiện

Khi phân tích file `metro_map_screen.dart`, tôi phát hiện **4 lỗi nghiêm trọng** vi phạm cú pháp Dart:

### **Lỗi 1: StatelessWidget với const body chứa callback động** ❌

```dart
class MetroMapScreen extends StatelessWidget {
  const MetroMapScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(  // ← const keyword
        child: Stack(children: [
          VietmapGL(
            onMapCreated: (VietmapController controller) {  // ← Callback động
              // ...
            },
          );
        ])
      )
    );
  }
}
```

**Vấn đề**:
- `const` Center yêu cầu tất cả children phải là constant values
- `VietmapGL` có callback `onMapCreated` → **KHÔNG thể là const**
- Compiler error: `Invalid constant value`

---

### **Lỗi 2: Thiếu dấu đóng `}` cho callback onMapCreated** ❌

```dart
onMapCreated: (VietmapController controller) {
  //   setState(() {
  //     _mapController = controller;
  //   });
  // },   ← Đóng comment thay vì đóng function
);      ← Thiếu }
```

**Vấn đề**:
- Callback function chưa được đóng đúng cú pháp
- Comment `// },` không phải là code thực thi
- Compiler error: `Expected to find '}'`

---

### **Lỗi 3: Thiếu dấu đóng `,` cho constructor VietmapGL** ❌

```dart
VietmapGL(
  styleString: '...',
  initialCameraPosition: CameraPosition(...),
  onMapCreated: (controller) {...}   // ← Thiếu dấu phẩy
);  ← Không có trailing comma
```

**Vấn đề**:
- Constructor VietmapGL chưa được đóng đúng
- Thiếu trailing comma sau parameter cuối
- Compiler error: `Expected to find ']'` (vì Stack children chưa đóng)

---

### **Lỗi 4: StatelessWidget không thể sử dụng setState** ❌

```dart
class MetroMapScreen extends StatelessWidget {
  // ...
  onMapCreated: (VietmapController controller) {
    // setState(() {  // ← StatelessWidget KHÔNG có setState
    //   _mapController = controller;
    // });
  }
}
```

**Vấn đề**:
- `StatelessWidget` không có state → không có `setState()`
- Cần chuyển sang `StatefulWidget` để lưu `_mapController`
- Code hiện tại đã comment nhưng cấu trúc vẫn sai

---

## ✅ GIẢI PHÁP

### **Option 1: Chuyển sang StatefulWidget** (RECOMMENDED)

Nếu bạn cần lưu `_mapController` để tương tác với map sau này (zoom, move camera, add markers...), **BẮT BUỘC** dùng `StatefulWidget`.

#### **Code đúng**:

```dart
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';

/// Metro Map Screen - Hiển thị bản đồ tuyến metro
/// 
/// **Features**:
/// - Hiển thị bản đồ Vietmap với các trạm metro
/// - Tìm kiếm địa điểm gần trạm metro
/// - Suggest địa điểm khi di chuyển giữa các trạm
@RoutePage()
class MetroMapScreen extends StatefulWidget {
  const MetroMapScreen({super.key});

  @override
  State<MetroMapScreen> createState() => _MetroMapScreenState();
}

class _MetroMapScreenState extends State<MetroMapScreen> {
  VietmapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Go'),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          VietmapGL(
            styleString:
                'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=YOUR_API_KEY_HERE',
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.762317, 106.654551),
              zoom: 14.0,
            ),
            onMapCreated: (VietmapController controller) {
              setState(() {
                _mapController = controller;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
```

**Thay đổi**:
1. ✅ `StatelessWidget` → `StatefulWidget`
2. ✅ Thêm `_mapController` field để lưu controller
3. ✅ Xóa `const` ở body (vì có callback động)
4. ✅ Đóng đúng callback `onMapCreated` với `}`
5. ✅ Thêm `dispose()` để cleanup controller khi widget bị remove
6. ✅ Thêm `zoom: 14.0` cho initialCameraPosition
7. ✅ Xóa `Center` widget không cần thiết (Stack đã full screen)

---

### **Option 2: Giữ StatelessWidget nếu KHÔNG cần controller** (Simple)

Nếu chỉ hiển thị map tĩnh, không cần tương tác (zoom, move camera...), có thể giữ `StatelessWidget`.

#### **Code đúng**:

```dart
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';

@RoutePage()
class MetroMapScreen extends StatelessWidget {
  const MetroMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Go'),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          VietmapGL(
            styleString:
                'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=YOUR_API_KEY_HERE',
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.762317, 106.654551),
              zoom: 14.0,
            ),
            onMapCreated: (VietmapController controller) {
              // Map created - không cần lưu controller
              // Có thể thêm log hoặc analytics tracking ở đây
              debugPrint('🗺️ Metro map loaded');
            },
          ),
        ],
      ),
    );
  }
}
```

**Thay đổi**:
1. ✅ Giữ `StatelessWidget`
2. ✅ Xóa `const` ở body
3. ✅ Đóng đúng callback với `}`
4. ✅ Đơn giản hóa callback (không lưu controller)
5. ✅ Xóa `Center` không cần thiết

---

## 🏗️ Tuân Thủ Clean Architecture

### **1. Screen Structure** (Presentation Layer)

```
modules/metro_go/
├── metro_map_screen.dart        ← UI Screen (bạn đang làm)
├── metro_map_provider.dart      ← State management (nếu cần)
└── widgets/                     ← Custom widgets (nếu cần)
    ├── metro_station_marker.dart
    └── metro_route_line.dart
```

**Theo Rules.md**:
- ✅ Screen nằm trong `modules/` (Presentation layer)
- ✅ File naming: `metro_map_screen.dart` (snake_case)
- ✅ Class naming: `MetroMapScreen` (PascalCase)

---

### **2. Nếu Cần Call API hoặc Business Logic**

Khi implement features (Step 1-6 trong comment), cần thêm các layers:

```
┌─────────────────────────────────────────────────────────┐
│ PRESENTATION (modules/metro_go/)                         │
│ MetroMapScreen, MetroMapProvider                         │
│  → Hiển thị map, handle user interactions               │
│  → Gọi Provider để fetch metro stations, places         │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ DOMAIN (domain/)                                         │
│ Entities: MetroStation, Place                            │
│ UseCases: GetMetroStations, GetNearbyPlaces             │
│ Repository Interface: MetroRepository                    │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ DATA (data/)                                             │
│ DTOs: MetroStationDto, PlaceDto                          │
│ Services: VietmapService (Retrofit)                      │
│ Repository Implementation: MetroRepositoryImpl           │
└─────────────────────────────────────────────────────────┘
```

**Ví dụ với Provider**:

```dart
// modules/metro_go/metro_map_provider.dart
class MetroMapProvider extends ChangeNotifier {
  final GetMetroStations _getMetroStations;
  final GetNearbyPlaces _getNearbyPlaces;
  
  List<MetroStation>? _stations;
  List<Place>? _places;
  bool _isLoading = false;
  
  MetroMapProvider(this._getMetroStations, this._getNearbyPlaces);
  
  Future<void> loadMetroStations() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _stations = await _getMetroStations.execute();
      notifyListeners();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> findNearbyPlaces(String stationId) async {
    // Implement Step 2, 3, 4, 5
  }
}

// Update MetroMapScreen
@RoutePage()
class MetroMapScreen extends StatefulWidget {
  const MetroMapScreen({super.key});

  @override
  State<MetroMapScreen> createState() => _MetroMapScreenState();
}

class _MetroMapScreenState extends State<MetroMapScreen> {
  VietmapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Load metro stations khi screen init
    Future.microtask(() {
      context.read<MetroMapProvider>().loadMetroStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Go'),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          VietmapGL(
            styleString: '...',
            initialCameraPosition: const CameraPosition(...),
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
              _addMetroStationsToMap(provider.stations);
            },
          ),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
  
  void _addMetroStationsToMap(List<MetroStation>? stations) {
    if (stations == null || _mapController == null) return;
    
    for (var station in stations) {
      _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(station.lat, station.lng),
          iconImage: 'metro-station-icon',
          textField: station.name,
        ),
      );
    }
  }
}
```

---

## 📋 So Sánh: Trước & Sau Fix

### **Code LỖI** (Hiện tại):

```dart
class MetroMapScreen extends StatelessWidget {  // ❌ Sai: Cần StatefulWidget
  const MetroMapScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(  // ❌ const với callback động
        child: Stack(children: [
          VietmapGL(
            styleString: '...',
            initialCameraPosition: CameraPosition(...),
            onMapCreated: (VietmapController controller) {
              //   setState(() {  // ❌ StatelessWidget không có setState
              //     _mapController = controller;
              //   });
              // },  // ❌ Comment thay vì close function
          );  // ❌ Thiếu }
         ]
      )
    )
    );
  }
}
```

**Các lỗi**:
1. ❌ StatelessWidget nhưng cần state
2. ❌ const với callback động
3. ❌ Callback không đóng đúng
4. ❌ Constructor VietmapGL không đóng đúng
5. ❌ setState trong StatelessWidget

---

### **Code ĐÚNG** (StatefulWidget):

```dart
@RoutePage()
class MetroMapScreen extends StatefulWidget {  // ✅ StatefulWidget
  const MetroMapScreen({super.key});

  @override
  State<MetroMapScreen> createState() => _MetroMapScreenState();
}

class _MetroMapScreenState extends State<MetroMapScreen> {
  VietmapController? _mapController;  // ✅ State variable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Go'),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: Stack(  // ✅ Không có const (vì có callback)
        children: [
          VietmapGL(
            styleString:
                'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=YOUR_API_KEY_HERE',
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.762317, 106.654551),
              zoom: 14.0,
            ),
            onMapCreated: (VietmapController controller) {  // ✅ Callback đúng
              setState(() {
                _mapController = controller;
              });
            },  // ✅ Đóng đúng với },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {  // ✅ Cleanup
    _mapController?.dispose();
    super.dispose();
  }
}
```

**Các fix**:
1. ✅ Chuyển sang StatefulWidget
2. ✅ Thêm state variable `_mapController`
3. ✅ Xóa const ở body
4. ✅ Callback đóng đúng với `},`
5. ✅ setState() hoạt động trong StatefulWidget
6. ✅ Thêm dispose() cleanup

---

## 🎓 Giải Thích Chi Tiết

### **Tại sao cần StatefulWidget?**

**StatelessWidget**:
- Build 1 lần dựa trên constructor parameters
- Không thể thay đổi state sau khi build
- Suitable cho: Static content, pure UI

**StatefulWidget**:
- Có thể thay đổi state và rebuild UI
- `setState()` trigger rebuild
- Suitable cho: Interactive widgets, dynamic content

**Metro Map Screen**:
- Cần lưu `_mapController` để tương tác với map
- Sau này cần: Add markers, change camera, handle user input
- → **BẮT BUỘC dùng StatefulWidget**

---

### **Tại sao không dùng const với VietmapGL?**

```dart
const VietmapGL(  // ❌ SAI
  onMapCreated: (controller) { ... },  // Callback động
)
```

**const widget**:
- Compile-time constant
- Không thể có callbacks, state, dynamic values
- Flutter optimize bằng cách reuse instance

**VietmapGL có callback**:
- `onMapCreated` là runtime callback
- Được gọi khi map render xong
- → **KHÔNG thể là const**

---

### **VietmapGL Widget Properties**

```dart
VietmapGL(
  // Required: API key trong style URL
  styleString: 'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=YOUR_KEY',
  
  // Required: Vị trí camera ban đầu
  initialCameraPosition: const CameraPosition(
    target: LatLng(10.762317, 106.654551),  // Tọa độ TP.HCM
    zoom: 14.0,  // Level zoom (0-22)
    bearing: 0.0,  // Rotation (optional)
    tilt: 0.0,  // Perspective (optional)
  ),
  
  // Callback khi map ready
  onMapCreated: (VietmapController controller) {
    // Lưu controller để tương tác sau này
  },
  
  // Optional: Style, gestures, compassEnabled...
  myLocationEnabled: true,  // Hiển thị vị trí user
  compassEnabled: true,  // Hiển thị compass
  rotateGesturesEnabled: true,  // Cho phép xoay map
  scrollGesturesEnabled: true,  // Cho phép scroll
  zoomGesturesEnabled: true,  // Cho phép zoom
)
```

**Lưu ý**:
- `apikey=YOUR_API_KEY_HERE` → Thay bằng API key thực từ Vietmap
- Tọa độ `(10.762317, 106.654551)` → Landmark 81, TP.HCM
- Zoom `14.0` → City level (phù hợp xem metro lines)

---

## ⚠️ Best Practices

### **1. API Key Management**

❌ **KHÔNG hard-code API key**:
```dart
styleString: 'https://...?apikey=YOUR_API_KEY_HERE',  // ❌ Public
```

✅ **Dùng environment variables**:
```dart
// lib/core/config/env.dart
class Env {
  static const vietmapApiKey = String.fromEnvironment(
    'VIETMAP_API_KEY',
    defaultValue: '',
  );
}

// metro_map_screen.dart
styleString: 'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${Env.vietmapApiKey}',
```

---

### **2. Error Handling**

```dart
onMapCreated: (VietmapController controller) {
  try {
    setState(() {
      _mapController = controller;
    });
    debugPrint('✅ Metro map loaded successfully');
  } catch (e) {
    debugPrint('❌ Error loading map: $e');
    // Show error to user
  }
},
```

---

### **3. Loading State**

```dart
class _MetroMapScreenState extends State<MetroMapScreen> {
  VietmapController? _mapController;
  bool _isMapLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          VietmapGL(
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
                _isMapLoaded = true;
              });
            },
          ),
          if (!_isMapLoaded)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
```

---

## 🎯 Checklist Fix

- [ ] **Chuyển sang StatefulWidget**
  - [ ] Rename class thành `StatefulWidget`
  - [ ] Tạo `_MetroMapScreenState` class
  - [ ] Move build() vào State class

- [ ] **Thêm State Management**
  - [ ] Khai báo `VietmapController? _mapController`
  - [ ] Implement `dispose()` method

- [ ] **Fix VietmapGL Widget**
  - [ ] Xóa `const` trước Stack/Center
  - [ ] Đóng đúng callback `onMapCreated` với `},`
  - [ ] Thêm `zoom` parameter cho CameraPosition

- [ ] **Cleanup Code**
  - [ ] Xóa `Center` widget không cần thiết
  - [ ] Format code đúng indentation
  - [ ] Xóa comments cũ không dùng

- [ ] **Test**
  - [ ] Run app → No compile errors
  - [ ] Navigate to Metro Go screen
  - [ ] Map hiển thị đúng vị trí TP.HCM
  - [ ] Check console log khi map loaded

---

## 📝 Tóm Tắt

**Các lỗi chính**:
1. ❌ StatelessWidget thay vì StatefulWidget
2. ❌ const body với callback động
3. ❌ Callback không đóng đúng cú pháp
4. ❌ setState trong StatelessWidget

**Giải pháp**:
1. ✅ Chuyển sang StatefulWidget với State class
2. ✅ Xóa const ở body
3. ✅ Đóng đúng callback với `},`
4. ✅ Lưu controller trong state variable
5. ✅ Implement dispose() để cleanup

**Tuân thủ Clean Architecture**: ✅
- Screen ở `modules/` layer (Presentation)
- Naming conventions đúng
- Ready để thêm Provider và UseCase sau này

---

## 📚 Next Steps

Khi implement features (Step 1-6 trong comment):

1. **Tạo Domain Layer**:
   - `domain/entities/metro_station.dart`
   - `domain/entities/place.dart`
   - `domain/usecases/get_metro_stations.dart`
   - `domain/repository/metro_repository.dart`

2. **Tạo Data Layer**:
   - `data/dto/metro_station_dto.dart`
   - `data/services/vietmap_service.dart`
   - `data/repository/metro_repository_impl.dart`

3. **Tạo Provider**:
   - `modules/metro_go/metro_map_provider.dart`

4. **Add vào Dependencies**:
   - Register services, repositories, usecases trong GetIt

Tham khảo file `how_to_add_new_screen.md` để biết chi tiết cách implement đầy đủ!

