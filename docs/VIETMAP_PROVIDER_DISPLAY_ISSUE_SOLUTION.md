# Giải Pháp: Vietmap Không Hiển Thị Khi Dùng Provider

## 🔴 Vấn Đề Hiện Tại

### Triệu chứng:
- Khi **KHÔNG dùng Provider**: Bản đồ hiển thị bình thường
- Khi **dùng Provider**: Bản đồ không hiển thị hoặc hoạt động không đúng
- Phải viết lại toàn bộ callbacks của VietmapGL trong Provider

### Nguyên nhân:
Khi sử dụng `context.watch<MetroMapProvider>()`, mỗi khi Provider gọi `notifyListeners()`, **toàn bộ Widget tree sẽ rebuild**, bao gồm cả `VietmapGL` widget. Điều này khiến VietmapGL bị khởi tạo lại và mất state.

---

## ✅ Giải Pháp 1: Tách Widget VietmapGL Sang StatefulWidget Riêng (RECOMMENDED)

### Ý tưởng:
- Tách `VietmapGL` vào một **StatefulWidget độc lập**
- Widget này **KHÔNG listen** vào Provider (không dùng `context.watch`)
- Chỉ truyền callback `onMapCreated` vào để lấy controller
- Provider chỉ quản lý state LOGIC, không can thiệp vào widget VietmapGL

### Ưu điểm:
- ✅ VietmapGL không bị rebuild khi Provider thay đổi state
- ✅ Không cần viết lại tất cả callbacks
- ✅ Performance tốt hơn
- ✅ Code gọn gàng, dễ maintain
- ✅ Tuân thủ coding rules (separation of concerns)

### Cấu trúc:

```
metro_map_screen.dart
├── MetroMapScreen (StatelessWidget)              → Provide Provider
├── _MetroMapView (StatelessWidget)               → Layout chính
└── _VietmapWidget (StatefulWidget)               → Chỉ chứa VietmapGL
    └── Không listen Provider
    └── Chỉ gọi callback để truyền controller ra ngoài
```

### Implementation:

#### File: `metro_map_screen.dart`

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
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
        backgroundColor: AppColors.primaryLight,
        actions: [
          // Có thể thêm zoom controls ở đây
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
          // ✅ QUAN TRỌNG: Tách VietmapGL vào widget riêng
          // Widget này KHÔNG listen Provider
          _VietmapWidget(
            onMapCreated: provider.onMapCreated,
          ),
          
          // Loading overlay (CÓ thể listen Provider)
          if (!provider.isMapReady)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: provider.isMapReady 
            ? provider.moveToCurrentLocation 
            : null,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

/// ✅ Widget riêng cho VietmapGL - KHÔNG listen Provider
/// Đây là KEY để tránh rebuild VietmapGL
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
      // Các config cơ bản
      styleString:
          'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${dotenv.env['VM_API_KEY']}',
      initialCameraPosition: const CameraPosition(
        target: LatLng(10.762317, 106.654551),
        zoom: 14.0,
      ),
      
      // ✅ Chỉ cần callback này để truyền controller ra ngoài
      onMapCreated: widget.onMapCreated,
      
      // Các tính năng map (tùy chọn)
      trackCameraPosition: true,
      myLocationEnabled: true,
      myLocationTrackingMode: MyLocationTrackingMode.none,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      
      // Các callbacks khác (nếu cần) - OPTIONAL
      // onStyleLoadedCallback: () {
      //   debugPrint('🗺️ Map style loaded');
      // },
      // onMapClick: (point, latLng) {
      //   debugPrint('🗺️ Map clicked at: $latLng');
      // },
    );
  }
}
```

#### File: `metro_map_provider.dart`

```dart
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/app/app_provider.dart';

class MetroMapProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  
  // Controller
  VietmapController? _mapController;
  VietmapController? get mapController => _mapController;
  
  // State
  bool _isMapReady = false;
  bool get isMapReady => _isMapReady;
  
  LatLng _currentPosition = const LatLng(10.762317, 106.654551);
  LatLng get currentPosition => _currentPosition;
  
  double _currentZoom = 14.0;
  double get currentZoom => _currentZoom;
  
  MetroMapProvider(this._appProvider);
  
  // ===== CALLBACK METHODS =====
  
  /// ✅ Callback duy nhất cần thiết để nhận controller
  void onMapCreated(VietmapController controller) {
    _mapController = controller;
    _isMapReady = true;
    notifyListeners(); // ⚠️ Chỉ notify ở đây, VietmapWidget sẽ không rebuild
    
    debugPrint('🗺️ [METRO_MAP] Map created and ready');
    
    // Load dữ liệu ban đầu nếu cần
    _loadInitialData();
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
          zoom ?? _currentZoom,
        ),
      );
      
      _currentPosition = location;
      if (zoom != null) _currentZoom = zoom;
      notifyListeners();
      
      debugPrint('🗺️ [METRO_MAP] Moved to: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      debugPrint('❌ [METRO_MAP] Error moving camera: $e');
    }
  }
  
  /// Zoom in
  Future<void> zoomIn() async {
    if (_mapController == null) return;
    
    final newZoom = _currentZoom + 1;
    await _mapController!.animateCamera(CameraUpdate.zoomTo(newZoom));
    _currentZoom = newZoom;
    notifyListeners();
  }
  
  /// Zoom out
  Future<void> zoomOut() async {
    if (_mapController == null) return;
    
    final newZoom = _currentZoom - 1;
    await _mapController!.animateCamera(CameraUpdate.zoomTo(newZoom));
    _currentZoom = newZoom;
    notifyListeners();
  }
  
  /// Di chuyển về vị trí hiện tại
  Future<void> moveToCurrentLocation() async {
    // TODO: Lấy vị trí hiện tại từ location service
    const userLocation = LatLng(10.762317, 106.654551);
    await moveToLocation(userLocation, zoom: 16.0);
  }
  
  // ===== DATA METHODS =====
  
  Future<void> _loadInitialData() async {
    // TODO: Load metro stations, places, etc.
    debugPrint('🗺️ [METRO_MAP] Loading initial data...');
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
```

### Giải thích:

#### 1. Tại sao tách `_VietmapWidget`?
```dart
// ❌ CÁCH CŨ - VietmapGL bị rebuild mỗi khi Provider thay đổi
class _MetroMapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>(); // 👈 Listen Provider
    
    return Scaffold(
      body: VietmapGL(
        onMapCreated: provider.onMapCreated, // 👈 Widget này bị rebuild
      ),
    );
  }
}

// ✅ CÁCH MỚI - VietmapGL KHÔNG bị rebuild
class _MetroMapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>(); // 👈 Listen Provider
    
    return Scaffold(
      body: _VietmapWidget( // 👈 Widget này KHÔNG listen Provider
        onMapCreated: provider.onMapCreated,
      ),
    );
  }
}

class _VietmapWidget extends StatefulWidget {
  // Không có context.watch ở đây
  // Widget này độc lập, không bị ảnh hưởng bởi Provider
}
```

#### 2. Flow hoạt động:
```
1. MetroMapScreen được mount
   ↓
2. Provider được tạo (create)
   ↓
3. _MetroMapView render (listen Provider)
   ↓
4. _VietmapWidget render (KHÔNG listen Provider)
   ↓
5. VietmapGL được tạo → onMapCreated callback
   ↓
6. Provider nhận controller → notifyListeners()
   ↓
7. _MetroMapView rebuild (hiện nút zoom)
   ↓
8. _VietmapWidget KHÔNG rebuild ✅
   ↓
9. User click zoom → Provider.zoomIn() → notifyListeners()
   ↓
10. _MetroMapView rebuild (update UI)
    ↓
11. _VietmapWidget KHÔNG rebuild ✅
```

#### 3. Khi nào thì rebuild?
```dart
// _VietmapWidget chỉ rebuild khi:
// 1. Parent widget thay đổi properties
const _VietmapWidget(
  onMapCreated: callback, // 👈 Nếu callback này thay đổi
)

// Provider notifyListeners() → _VietmapWidget KHÔNG rebuild ✅
```

---

## ✅ Giải Pháp 2: Sử dụng `context.select` Thay Vì `context.watch`

### Ý tưởng:
Chỉ listen vào **một phần state cụ thể** thay vì toàn bộ Provider.

### Ưu điểm:
- ✅ Widget chỉ rebuild khi state cần thiết thay đổi
- ✅ Performance tốt hơn `context.watch`

### Nhược điểm:
- ⚠️ Vẫn có khả năng VietmapGL bị rebuild nếu không cẩn thận
- ⚠️ Code phức tạp hơn Giải pháp 1

### Implementation:

```dart
class _MetroMapView extends StatelessWidget {
  const _MetroMapView();

  @override
  Widget build(BuildContext context) {
    // ✅ Chỉ listen vào isMapReady, không listen toàn bộ Provider
    final isMapReady = context.select<MetroMapProvider, bool>(
      (provider) => provider.isMapReady,
    );
    
    // ✅ Lấy Provider KHÔNG listen (dùng read)
    final provider = context.read<MetroMapProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Metro Map'),
        backgroundColor: AppColors.primaryLight,
      ),
      body: Stack(
        children: [
          VietmapGL(
            trackCameraPosition: true,
            styleString:
                'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${dotenv.env['VM_API_KEY']}',
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.762317, 106.654551),
              zoom: 14.0,
            ),
            onMapCreated: provider.onMapCreated, // ✅ Dùng read, không watch
            myLocationEnabled: true,
            compassEnabled: true,
          ),
          
          // Chỉ rebuild phần này khi isMapReady thay đổi
          if (!isMapReady)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: provider.moveToCurrentLocation, // ✅ Dùng read
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
```

### Giải thích:

```dart
// ❌ SAI - Listen toàn bộ Provider
final provider = context.watch<MetroMapProvider>();
// → Mỗi khi provider.notifyListeners(), toàn bộ widget rebuild

// ✅ ĐÚNG - Chỉ listen 1 field cụ thể
final isMapReady = context.select<MetroMapProvider, bool>(
  (provider) => provider.isMapReady,
);
// → Chỉ rebuild khi isMapReady thay đổi

// ✅ ĐÚNG - Không listen, chỉ gọi methods
final provider = context.read<MetroMapProvider>();
// → Không rebuild khi provider thay đổi
```

---

## ✅ Giải Pháp 3: Sử dụng `Consumer` Widget

### Ý tưởng:
Bọc **chỉ các phần cần listen** vào `Consumer`, để VietmapGL ở ngoài.

### Implementation:

```dart
class _MetroMapView extends StatelessWidget {
  const _MetroMapView();

  @override
  Widget build(BuildContext context) {
    // ✅ Không dùng context.watch ở đây
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Metro Map'),
        backgroundColor: AppColors.primaryLight,
        actions: [
          // ✅ Consumer cho AppBar actions
          Consumer<MetroMapProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: provider.isMapReady ? provider.zoomIn : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out),
                    onPressed: provider.isMapReady ? provider.zoomOut : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ VietmapGL KHÔNG nằm trong Consumer
          Builder(
            builder: (context) {
              final provider = context.read<MetroMapProvider>();
              return VietmapGL(
                trackCameraPosition: true,
                styleString:
                    'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${dotenv.env['VM_API_KEY']}',
                initialCameraPosition: const CameraPosition(
                  target: LatLng(10.762317, 106.654551),
                  zoom: 14.0,
                ),
                onMapCreated: provider.onMapCreated,
                myLocationEnabled: true,
                compassEnabled: true,
              );
            },
          ),
          
          // ✅ Consumer cho loading overlay
          Consumer<MetroMapProvider>(
            builder: (context, provider, child) {
              if (provider.isMapReady) return const SizedBox.shrink();
              
              return Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Consumer<MetroMapProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton(
            onPressed: provider.isMapReady 
                ? provider.moveToCurrentLocation 
                : null,
            child: const Icon(Icons.my_location),
          );
        },
      ),
    );
  }
}
```

---

## 📊 So Sánh Các Giải Pháp

| Tiêu chí | Giải pháp 1<br/>(Tách Widget) | Giải pháp 2<br/>(context.select) | Giải pháp 3<br/>(Consumer) |
|----------|-------------------------------|-----------------------------------|----------------------------|
| **Performance** | ⭐⭐⭐⭐⭐ Tốt nhất | ⭐⭐⭐⭐ Tốt | ⭐⭐⭐ Khá |
| **Code clarity** | ⭐⭐⭐⭐⭐ Rất rõ ràng | ⭐⭐⭐ Trung bình | ⭐⭐⭐⭐ Rõ ràng |
| **Dễ maintain** | ⭐⭐⭐⭐⭐ Dễ nhất | ⭐⭐⭐ Trung bình | ⭐⭐⭐⭐ Dễ |
| **Tránh rebuild** | ✅ Hoàn toàn | ⚠️ Phụ thuộc usage | ⚠️ Phụ thuộc usage |
| **Coding rules** | ✅ Tuân thủ 100% | ✅ Tuân thủ | ✅ Tuân thủ |
| **Recommended** | ✅ **HIGHLY RECOMMENDED** | ⚠️ Optional | ✅ Good alternative |

---

## 🎯 Khuyến Nghị

### ✅ Sử dụng Giải Pháp 1 (Tách Widget) Vì:

1. **Performance tốt nhất**: VietmapGL hoàn toàn không bị rebuild
2. **Code rõ ràng**: Tách biệt rõ ràng giữa Map UI và State Management
3. **Dễ debug**: Biết chính xác widget nào bị rebuild
4. **Scalable**: Dễ mở rộng thêm tính năng
5. **Best practice**: Đúng với pattern của Flutter (separation of concerns)

### Implementation checklist:

- [ ] Tạo `_VietmapWidget` extends `StatefulWidget`
- [ ] Widget này KHÔNG có `context.watch` hay `context.select`
- [ ] Chỉ nhận callback qua constructor parameters
- [ ] Provider chỉ quản lý logic state, không chứa UI
- [ ] Các widget khác (AppBar, FloatingButton) có thể listen Provider bình thường

---

## 🚫 Các Lỗi Thường Gặp

### Lỗi 1: Dùng `context.watch` trong widget chứa VietmapGL

```dart
// ❌ SAI
class _MetroMapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>(); // 👈 Lỗi ở đây
    
    return Scaffold(
      body: VietmapGL(
        onMapCreated: provider.onMapCreated, // 👈 Widget này bị rebuild
      ),
    );
  }
}
```

**Kết quả**: VietmapGL bị rebuild → Mất state → Không hiển thị đúng

### Lỗi 2: Gọi `notifyListeners()` quá nhiều

```dart
// ❌ SAI
void onMapCreated(VietmapController controller) {
  _mapController = controller;
  notifyListeners(); // 👈 OK
  
  _isMapReady = true;
  notifyListeners(); // 👈 Thừa, gây rebuild 2 lần
}

// ✅ ĐÚNG
void onMapCreated(VietmapController controller) {
  _mapController = controller;
  _isMapReady = true;
  notifyListeners(); // 👈 Chỉ gọi 1 lần
}
```

### Lỗi 3: Không check null controller

```dart
// ❌ SAI
Future<void> zoomIn() async {
  await _mapController!.animateCamera(...); // 👈 Crash nếu null
}

// ✅ ĐÚNG
Future<void> zoomIn() async {
  if (_mapController == null) return; // 👈 Safety check
  await _mapController!.animateCamera(...);
}
```

---

## 📝 Kết Luận

### Câu trả lời cho câu hỏi của bạn:

> "Tôi có phải viết lại hết toàn bộ các callback do Vietmap define không?"

**Trả lời**: **KHÔNG CẦN**! 

✅ Bạn chỉ cần:
1. **Tách VietmapGL** vào một `StatefulWidget` riêng
2. Widget đó **KHÔNG listen** Provider
3. Chỉ truyền `onMapCreated` callback để lấy controller
4. Provider quản lý **logic state**, không chứa UI callbacks

✅ **Các callbacks khác** của VietmapGL (onMapClick, onStyleLoaded, etc.):
- Có thể để **trống** nếu không cần
- Hoặc implement **trực tiếp trong VietmapWidget** nếu cần
- **KHÔNG** cần viết lại trong Provider

### Quy tắc vàng:
```
🎨 UI Widget (VietmapGL) = Stateful, không listen Provider
🧠 Logic State (Provider) = Quản lý controller và business logic
📦 View (Screen) = Connect UI với Logic thông qua callbacks
```

### Tuân thủ Coding Rules:
- ✅ Separation of concerns (UI vs Logic)
- ✅ Single responsibility (Widget chỉ render, Provider chỉ quản lý state)
- ✅ Performance optimization (Tránh unnecessary rebuilds)
- ✅ Clean Architecture principles

---

**Tài liệu tham khảo**:
- VietmapGL: https://pub.dev/packages/vietmap_flutter_gl
- Provider Best Practices: https://pub.dev/packages/provider
- Flutter Performance: https://docs.flutter.dev/perf/best-practices
- Rules.md: Coding rules của dự án

