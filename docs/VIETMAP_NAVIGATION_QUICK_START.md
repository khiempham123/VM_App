# Vietmap Flutter Navigation - Tổng Hợp & Quick Start

## 📖 Mục Lục Tài Liệu

Tài liệu này tổng hợp các hướng dẫn chi tiết về việc sử dụng package `vietmap_flutter_navigation` trong dự án Flutter.

### Danh Sách Tài Liệu

1. **[FIX_NAVIGATION_AND_POLYLINE_ERRORS.md](./FIX_NAVIGATION_AND_POLYLINE_ERRORS.md)**
   - Fix lỗi decode polyline
   - Fix lỗi NavigationView implementation
   - Xử lý lỗi DioException bad response
   - Troubleshooting common errors

2. **[VIETMAP_NAVIGATION_CREATE_ROUTE_GUIDE.md](./VIETMAP_NAVIGATION_CREATE_ROUTE_GUIDE.md)** ⭐
   - Hướng dẫn chi tiết về package
   - 5 phương pháp tạo route từ 2 điểm
   - Code examples hoàn chỉnh
   - Best practices & troubleshooting

3. **Tài liệu này**: Quick Start & Summary

---

## 🚀 QUICK START - 5 Phút Có Navigation

### Bước 1: Cài Đặt Package (30 giây)

```bash
flutter pub add vietmap_flutter_navigation
```

### Bước 2: Cấu Hình API Key (1 phút)

**Android**: `android/app/src/main/AndroidManifest.xml`
```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<application>
    <!-- Service -->
    <service
        android:name="vn.vietmap.services.android.navigation.v5.navigation.NavigationService"
        android:foregroundServiceType="location"
        android:exported="false">
    </service>
</application>
```

**iOS**: `ios/Runner/Info.plist`
```xml
<key>VietMapAccessToken</key>
<string>YOUR_API_KEY_HERE</string>
```

### Bước 3: Code Cơ Bản (3 phút)

```dart
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';

class NavigationScreen extends StatefulWidget {
  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  MapNavigationViewController? _controller;
  late MapOptions _options;
  final _plugin = VietMapNavigationPlugin();

  @override
  void initState() {
    super.initState();
    
    // Initialize
    _options = _plugin.getDefaultOptions();
    _options.apiKey = 'YOUR_API_KEY_HERE';
    _options.simulateRoute = true; // Test mode
    _plugin.setDefaultOptions(_options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NavigationView(
            mapOptions: _options,
            onMapCreated: (controller) => _controller = controller,
            onMapRendered: () {
              // Build route when map is ready
              _controller?.buildRoute(
                waypoints: [
                  LatLng(10.759091, 106.675817), // Start
                  LatLng(10.762528, 106.653099), // End
                ],
                profile: DrivingProfile.drivingTraffic,
              );
            },
            onRouteBuilt: (route) {
              // Start navigation
              _controller?.startNavigation();
            },
          ),
          
          // Stop button
          Positioned(
            bottom: 20,
            child: ElevatedButton(
              onPressed: () => _controller?.finishNavigation(),
              child: Text('Stop'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.onDispose();
    super.dispose();
  }
}
```

**DONE! Bạn đã có navigation hoạt động!** 🎉

---

## 📊 SO SÁNH CÁC PHƯƠNG PHÁP TẠO ROUTE

| Phương Pháp | Khi Nào Dùng | Ưu Điểm | Nhược Điểm |
|-------------|--------------|---------|------------|
| **buildRoute()** | Muốn preview route trước | User có thể xem route trước khi đi | Phải gọi startNavigation() thủ công |
| **buildAndStartNavigation()** | Start ngay không cần confirm | Nhanh, ít code | Không có bước preview |
| **onMapLongClick + buildRoute** | User tự chọn điểm đến | Linh hoạt, UX tốt | Cần handle UI cho việc chọn điểm |
| **Build từ API route** | Đã có polyline từ API | Tận dụng API có sẵn | Phức tạp hơn |
| **Multiple waypoints** | Có nhiều điểm dừng | Linh hoạt route phức tạp | Route có thể dài |

---

## 🎯 CÁC SCENARIO THƯỜNG GẶP

### Scenario 1: Tìm Đường Từ Vị Trí Hiện Tại → Điểm Đích

```dart
Future<void> navigateToDestination(LatLng destination) async {
  // 1. Get current location
  final position = await Geolocator.getCurrentPosition();
  final currentLocation = LatLng(position.latitude, position.longitude);
  
  // 2. Build route
  await _controller?.buildRoute(
    waypoints: [currentLocation, destination],
    profile: DrivingProfile.drivingTraffic,
  );
}
```

### Scenario 2: Tìm Đường Giữa 2 Điểm Bất Kỳ

```dart
Future<void> navigateBetween(LatLng start, LatLng end) async {
  await _controller?.buildRoute(
    waypoints: [start, end],
    profile: DrivingProfile.driving,
  );
}
```

### Scenario 3: Tìm Đường Với Nhiều Điểm Dừng

```dart
Future<void> navigateWithStops(List<LatLng> locations) async {
  // locations = [start, stop1, stop2, ..., end]
  await _controller?.buildRoute(
    waypoints: locations,
    profile: DrivingProfile.drivingTraffic,
  );
}
```

### Scenario 4: Long Click Để Chọn Đích

```dart
NavigationView(
  onMapLongClick: (LatLng? latLng, Point? point) async {
    if (latLng == null) return;
    
    final currentLocation = await _getCurrentLocation();
    
    await _controller?.buildRoute(
      waypoints: [currentLocation, latLng],
      profile: DrivingProfile.drivingTraffic,
    );
  },
)
```

### Scenario 5: Preview Route Trước Khi Start

```dart
// Step 1: Build route
await _controller?.buildRoute(waypoints: waypoints);

// Step 2: Show preview with buttons
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Route Found'),
    content: Text('Distance: ${route.distance}m\nDuration: ${route.duration}s'),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          _controller?.clearRoute();
        },
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _controller?.startNavigation();
        },
        child: Text('Start'),
      ),
    ],
  ),
);
```

---

## 🔧 GIẢI QUYẾT VẤN ĐỀ TRONG CODE CỦA BẠN

### Vấn Đề Hiện Tại

Dựa vào code bạn đã gửi, có một số vấn đề:

1. ❌ **Decode polyline lỗi**: `PolylinePoints.decodePolyline()` được gọi sai
2. ❌ **NavigationView không được khởi tạo đúng**: Thiếu `_navigationOption`
3. ❌ **StatelessWidget không thể dùng setState**: Cần chuyển sang StatefulWidget
4. ⚠️ **Mixing 2 approaches**: Đang dùng cả VietmapGL và NavigationView cùng lúc

### Giải Pháp Đề Xuất

#### Option A: Dùng Hoàn Toàn NavigationView (Khuyến nghị) ⭐

**Ưu điểm**:
- Có built-in navigation features
- Voice instructions
- Turn-by-turn guidance
- Less code

**File: `metro_map_screen.dart`**
```dart
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';

class MetroMapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetroMapProvider(),
      child: const _MetroMapView(),
    );
  }
}

class _MetroMapView extends StatefulWidget {
  const _MetroMapView();

  @override
  State<_MetroMapView> createState() => _MetroMapViewState();
}

class _MetroMapViewState extends State<_MetroMapView> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // ✅ Dùng NavigationView thay vì VietmapGL
          NavigationView(
            mapOptions: provider.navigationOptions,
            onMapCreated: provider.onNavigationControllerCreated,
            onMapRendered: () => debugPrint('Map ready'),
            onRouteBuilt: provider.onRouteBuilt,
            onRouteBuildFailed: provider.onRouteBuildFailed,
            onRouteProgressChange: provider.onRouteProgressChange,
            onArrival: provider.onArrival,
            onMapLongClick: provider.onMapLongSelected,
          ),
          
          // Search bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TypeAheadField<PlaceEntity>(
                itemBuilder: (context, value) => ListTile(title: Text(value.display)),
                onSelected: provider.onSuggestionSelected,
                suggestionsCallback: provider.onSearchChanged,
              ),
            ),
          ),
          
          // Control buttons
          Positioned(
            bottom: 20,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: provider.moveToMyLocation,
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: provider.buildRoute,
                  child: Icon(Icons.directions),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**File: `metro_map_provider.dart`**
```dart
class MetroMapProvider extends ChangeNotifier {
  MapNavigationViewController? _navigationController;
  late MapOptions navigationOptions;
  final _plugin = VietMapNavigationPlugin();
  
  // State
  RouteProgressEvent? routeProgressEvent;
  bool isRouteBuilt = false;
  bool isNavigating = false;
  LatLng? currentLocation;
  LatLng? selectedLocation;
  
  MetroMapProvider() {
    _initializeNavigation();
  }
  
  void _initializeNavigation() {
    navigationOptions = _plugin.getDefaultOptions();
    navigationOptions.apiKey = dotenv.env['VM_API_KEY'] ?? '';
    navigationOptions.mapStyle = 
        "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=${dotenv.env['VM_API_KEY']}";
    navigationOptions.simulateRoute = false;
    navigationOptions.language = 'vi';
    _plugin.setDefaultOptions(navigationOptions);
  }
  
  void onNavigationControllerCreated(MapNavigationViewController controller) {
    _navigationController = controller;
    notifyListeners();
  }
  
  Future<void> moveToMyLocation() async {
    final position = await Geolocator.getCurrentPosition();
    currentLocation = LatLng(position.latitude, position.longitude);
    
    await _navigationController?.moveCamera(
      latLng: currentLocation!,
      zoom: 16,
    );
    
    notifyListeners();
  }
  
  Future<void> onSuggestionSelected(PlaceEntity place) async {
    // Get place details
    final details = await _metroMapRepository.getPlaceDetails(
      PlaceDetailsRequest(refid: place.refId)
    );
    
    if (details != null) {
      selectedLocation = LatLng(details.lat, details.lng);
      
      // Move camera
      await _navigationController?.moveCamera(
        latLng: selectedLocation!,
        zoom: 16,
      );
      
      notifyListeners();
    }
  }
  
  Future<void> buildRoute() async {
    if (currentLocation == null || selectedLocation == null) {
      debugPrint('❌ Missing locations');
      return;
    }
    
    await _navigationController?.buildRoute(
      waypoints: [currentLocation!, selectedLocation!],
      profile: DrivingProfile.drivingTraffic,
    );
  }
  
  Future<(LatLng?, Point?)> onMapLongSelected(LatLng? latLng, Point? point) async {
    if (latLng == null || currentLocation == null) return (null, null);
    
    selectedLocation = latLng;
    
    await _navigationController?.buildRoute(
      waypoints: [currentLocation!, latLng],
      profile: DrivingProfile.drivingTraffic,
    );
    
    return (latLng, point);
  }
  
  void onRouteBuilt(DirectionRoute route) {
    isRouteBuilt = true;
    debugPrint('✅ Route built: ${route.distance}m, ${route.duration}s');
    notifyListeners();
  }
  
  void onRouteBuildFailed(dynamic error) {
    debugPrint('❌ Route failed: $error');
    // Show error to user
    notifyListeners();
  }
  
  void onRouteProgressChange(RouteProgressEvent event) {
    routeProgressEvent = event;
    notifyListeners();
  }
  
  void onArrival() {
    isNavigating = false;
    debugPrint('🎯 Arrived!');
    notifyListeners();
  }
  
  @override
  void dispose() {
    _navigationController?.onDispose();
    super.dispose();
  }
}
```

#### Option B: Dùng VietmapGL + Custom Route Drawing (Phức tạp hơn)

Nếu bạn muốn giữ VietmapGL và tự vẽ route, xem chi tiết trong file `FIX_NAVIGATION_AND_POLYLINE_ERRORS.md`.

---

## 📋 CHECKLIST - ĐIỀU CHỈNH CODE CỦA BẠN

### Bước 1: Fix Provider
- [ ] Remove code liên quan đến `PolylinePoints.decodePolyline()`
- [ ] Add `MapNavigationViewController` controller
- [ ] Add `MapOptions navigationOptions`
- [ ] Initialize navigation options trong constructor
- [ ] Update `buildRoute()` method để dùng NavigationView API

### Bước 2: Fix Screen
- [ ] Convert `_MetroMapView` từ StatelessWidget → StatefulWidget
- [ ] Replace `_VietmapWidget` bằng `NavigationView`
- [ ] Add state variables nếu cần (`_instruction`, v.v.)
- [ ] Update callbacks

### Bước 3: Cleanup
- [ ] Remove unused imports (`flutter_polyline_points`, `adaptive_action_sheet`)
- [ ] Remove unused code (polyline drawing logic)
- [ ] Update floating action buttons

### Bước 4: Test
- [ ] Test build route
- [ ] Test start navigation
- [ ] Test voice instructions
- [ ] Test arrival callback

---

## 🎓 LỘ TRÌNH HỌC TẬP

### Level 1: Beginner - Làm Theo Quick Start
1. Copy code từ Quick Start section
2. Thay API key
3. Run và test với `simulateRoute = true`

### Level 2: Intermediate - Hiểu Callbacks
1. Đọc phần callbacks trong `VIETMAP_NAVIGATION_CREATE_ROUTE_GUIDE.md`
2. Implement từng callback một
3. Log ra console để hiểu data flow

### Level 3: Advanced - Custom UI
1. Implement BannerInstructionView
2. Implement BottomActionView
3. Customize route info display
4. Add markers

### Level 4: Expert - Integration
1. Integrate với Clean Architecture
2. Handle edge cases
3. Optimize performance
4. Add error handling

---

## 💡 BEST PRACTICES SUMMARY

### ✅ DO - Nên Làm

```dart
// ✅ Check null trước khi gọi
if (_controller != null) {
  await _controller?.buildRoute(waypoints: waypoints);
}

// ✅ Gọi buildRoute sau khi map rendered
NavigationView(
  onMapRendered: () {
    _buildRoute();
  },
)

// ✅ Check location permission
final permission = await Geolocator.requestPermission();

// ✅ Handle errors
NavigationView(
  onRouteBuildFailed: (error) {
    _showError('Không tìm thấy đường');
  },
)

// ✅ Dispose controller
@override
void dispose() {
  _controller?.onDispose();
  super.dispose();
}
```

### ❌ DON'T - Không Nên Làm

```dart
// ❌ Gọi ngay trong initState
@override
void initState() {
  super.initState();
  _buildRoute(); // Map chưa ready!
}

// ❌ Không check null
_controller.buildRoute(waypoints: waypoints); // Crash nếu null

// ❌ Không handle errors
// Code không có error handling

// ❌ Quên dispose
@override
void dispose() {
  // Forgot to dispose controller
  super.dispose();
}

// ❌ Hardcode API key
navigationOptions.apiKey = 'abc123xyz'; // Không an toàn
```

---

## 🆘 COMMON ERRORS & QUICK FIXES

| Error | Quick Fix |
|-------|-----------|
| Controller is null | Check `onMapCreated` callback đã lưu controller chưa |
| Route build failed | Check API key, waypoints hợp lệ chưa |
| Voice not working | Test trên real device, check permissions |
| Map not showing | Check API key trong `mapStyle` URL |
| App crashes on start | Check Android minSdk >= 24, iOS >= 12 |
| Navigation not starting | Call `startNavigation()` sau `onRouteBuilt` |

---

## 📞 HỖ TRỢ

### Khi Gặp Vấn Đề

1. **Check tài liệu**:
   - [VIETMAP_NAVIGATION_CREATE_ROUTE_GUIDE.md](./VIETMAP_NAVIGATION_CREATE_ROUTE_GUIDE.md)
   - [FIX_NAVIGATION_AND_POLYLINE_ERRORS.md](./FIX_NAVIGATION_AND_POLYLINE_ERRORS.md)

2. **Check example code**:
   - GitHub: https://github.com/vietmap-company/vietmap-flutter-navigation
   - Example App: https://github.com/vietmap-company/flutter-navigation-example

3. **Liên hệ VietMap**:
   - Email: maps-api.support@vietmap.vn
   - Website: https://vietmap.vn/lien-he

4. **Report bug**:
   - GitHub Issues: https://github.com/vietmap-company/flutter-map-sdk/issues

---

## 🎯 NEXT STEPS

### Bước Tiếp Theo Cho Dự Án Của Bạn

1. **Ngay Bây Giờ**:
   - [ ] Đọc `VIETMAP_NAVIGATION_CREATE_ROUTE_GUIDE.md`
   - [ ] Copy code mẫu vào project
   - [ ] Test với simulate mode

2. **Tuần Này**:
   - [ ] Integrate với existing search feature
   - [ ] Add custom UI components
   - [ ] Test trên real device

3. **Tuần Sau**:
   - [ ] Add error handling
   - [ ] Optimize UX
   - [ ] Add analytics

4. **Production**:
   - [ ] Test thoroughly
   - [ ] Handle edge cases
   - [ ] Deploy

---

## 🌟 CONCLUSION

Package `vietmap_flutter_navigation` rất powerful và dễ sử dụng. Key points:

- **3 dòng code** để có navigation cơ bản
- **5 phương pháp** tạo route linh hoạt
- **Built-in UI components** tiết kiệm thời gian
- **Voice instructions** miễn phí
- **Vietnamese support** native

Chúc bạn success với project! 🚀

---

*Tài liệu được tạo: December 2024*
*Version: 1.0*
*Package version: vietmap_flutter_navigation ^4.1.0*

