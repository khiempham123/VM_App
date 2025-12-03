# Hướng Dẫn Tạo Route Với Vietmap Flutter Navigation

## 📚 Tổng Quan Package

### Thông Tin Package
- **Package Name**: `vietmap_flutter_navigation`
- **Version**: 4.1.0
- **Publisher**: VietMap Company
- **Pub.dev**: https://pub.dev/packages/vietmap_flutter_navigation
- **GitHub**: https://github.com/vietmap-company/vietmap-flutter-navigation

### Tính Năng Chính
1. ✅ **Turn-by-turn Navigation** - Điều hướng từng bước chi tiết
2. ✅ **Voice Instructions** - Hướng dẫn bằng giọng nói (tiếng Việt)
3. ✅ **Real-time Route Progress** - Theo dõi tiến trình real-time
4. ✅ **Multiple Waypoints** - Hỗ trợ nhiều điểm dừng
5. ✅ **Route Simulation** - Chế độ mô phỏng để test
6. ✅ **Custom Markers** - Thêm marker tùy chỉnh
7. ✅ **Route Overview** - Xem tổng quan toàn bộ route
8. ✅ **Recenter Camera** - Tự động căn giữa camera

---

## 🚀 Cài Đặt và Cấu Hình

### 1. Thêm Package vào `pubspec.yaml`

```yaml
dependencies:
  vietmap_flutter_navigation: ^4.1.0
```

Hoặc chạy lệnh:
```bash
flutter pub add vietmap_flutter_navigation
```

### 2. Cấu Hình Android

#### File: `android/build.gradle`
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "https://jitpack.io" }  // Thêm dòng này
    }
}
```

#### File: `android/app/build.gradle`
```gradle
android {
    defaultConfig {
        minSdkVersion 24  // Tối thiểu phải là 24
    }
}
```

#### File: `android/app/src/main/AndroidManifest.xml`
```xml
<manifest>
    <!-- Thêm các permission -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application>
        <!-- Thêm service cho Android 14+ -->
        <service
            android:name="vn.vietmap.services.android.navigation.v5.navigation.NavigationService"
            android:foregroundServiceType="location"
            android:exported="false">
        </service>
    </application>
</manifest>
```

### 3. Cấu Hình iOS

#### File: `ios/Podfile`
```ruby
platform :ios, '12.0'  # Uncomment và set minimum version
```

#### File: `ios/Runner/Info.plist`
```xml
<dict>
    <!-- API Configuration -->
    <key>VietMapURL</key>
    <string>https://maps.vietmap.vn/api/maps/light/styles.json?apikey=YOUR_API_KEY_HERE</string>
    
    <key>VietMapAPIBaseURL</key>
    <string>https://maps.vietmap.vn/api/navigations/route/</string>
    
    <key>VietMapAccessToken</key>
    <string>YOUR_API_KEY_HERE</string>
    
    <!-- Location Permissions -->
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Ứng dụng cần quyền truy cập vị trí để điều hướng</string>
    
    <key>NSLocationAlwaysUsageDescription</key>
    <string>Ứng dụng cần quyền truy cập vị trí để điều hướng</string>
    
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Ứng dụng cần quyền truy cập vị trí để điều hướng</string>
</dict>
```

**Lưu ý**: Thay `YOUR_API_KEY_HERE` bằng API key thật từ VietMap.

#### Install Pods
```bash
cd ios && pod install
```

Nếu gặp lỗi khi update version:
```bash
# Xóa các file cũ
rm -rf ios/.symlinks ios/Pods Podfile.lock

# Cài lại
pod install --repo-update
```

---

## 📖 Cách Tạo Route Từ 2 Điểm

### Bước 1: Import Package

```dart
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
```

### Bước 2: Khai Báo Biến Cần Thiết

```dart
class MetroMapProvider extends ChangeNotifier {
  // Controller để điều khiển navigation
  MapNavigationViewController? _navigationController;
  
  // Plugin instance
  final _vietmapNavigationPlugin = VietMapNavigationPlugin();
  
  // Map options
  late MapOptions _navigationOption;
  
  // Route progress event - cập nhật real-time
  RouteProgressEvent? _routeProgressEvent;
  
  // Danh sách điểm đi qua (waypoints)
  List<LatLng> waypoints = [];
  
  // Trạng thái
  bool _isRouteBuilt = false;
  bool _isNavigating = false;
}
```

### Bước 3: Khởi Tạo Navigation Options

```dart
Future<void> initialize() async {
  // Lấy default options
  _navigationOption = _vietmapNavigationPlugin.getDefaultOptions();
  
  // Cấu hình
  _navigationOption.simulateRoute = false;  // false = dùng GPS thật, true = mô phỏng
  _navigationOption.apiKey = dotenv.env['VM_API_KEY'] ?? '';
  _navigationOption.mapStyle = 
      "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=${dotenv.env['VM_API_KEY']}";
  
  // Set các options khác
  _navigationOption.zoom = 15.0;
  _navigationOption.tilt = 0.0;
  _navigationOption.bearing = 0.0;
  _navigationOption.language = 'vi';  // Ngôn ngữ tiếng Việt
  _navigationOption.voiceInstructionsEnabled = true;  // Bật voice
  _navigationOption.bannerInstructionsEnabled = true;  // Bật banner instruction
  
  // Apply options
  _vietmapNavigationPlugin.setDefaultOptions(_navigationOption);
}
```

### Bước 4: Hiển Thị NavigationView

```dart
NavigationView(
  mapOptions: _navigationOption,
  
  // Callback khi map được tạo
  onMapCreated: (MapNavigationViewController controller) {
    _navigationController = controller;
    print('✅ Navigation controller initialized');
  },
  
  // Callback khi map được render xong
  onMapRendered: () {
    print('✅ Map rendered successfully');
    // Có thể gọi buildRoute ở đây để đảm bảo map đã sẵn sàng
  },
  
  // Callback khi route được build thành công
  onRouteBuilt: (DirectionRoute route) {
    print('✅ Route built successfully');
    print('Route geometry: ${route.geometry}');
    print('Distance: ${route.distance} meters');
    print('Duration: ${route.duration} seconds');
    
    setState(() {
      _isRouteBuilt = true;
    });
  },
  
  // Callback khi build route thất bại
  onRouteBuildFailed: (error) {
    print('❌ Route build failed: $error');
    _showError('Không thể tìm thấy tuyến đường');
  },
  
  // Callback khi user chọn route khác trên map
  onNewRouteSelected: (DirectionRoute route) {
    print('🔄 New route selected');
    // Xử lý khi user chọn route mới
  },
  
  // Callback khi route progress thay đổi (real-time)
  onRouteProgressChange: (RouteProgressEvent event) {
    setState(() {
      _routeProgressEvent = event;
    });
    
    // Thông tin có sẵn trong event:
    print('Current location: ${event.currentLocation}');
    print('Snapped location: ${event.snappedLocation}');
    print('Distance remaining: ${event.distanceRemaining} meters');
    print('Duration remaining: ${event.durationRemaining} seconds');
    print('Current modifier: ${event.currentModifier}');  // left, right, straight...
    print('Current modifier type: ${event.currentModifierType}');  // turn, arrive...
  },
  
  // Callback khi đến đích
  onArrival: () {
    print('🎯 Arrived at destination!');
    _showSuccess('Bạn đã đến đích');
    setState(() {
      _isNavigating = false;
    });
  },
  
  // Callback khi map di chuyển
  onMapMove: () {
    // Hiện nút recenter khi user drag map
    _showRecenterButton();
  },
  
  // Callback khi click vào map
  onMapClick: (LatLng? latLng, Point? point) async {
    if (latLng != null) {
      print('Map clicked at: ${latLng.latitude}, ${latLng.longitude}');
      // Có thể dùng để chọn điểm đến
    }
  },
  
  // Callback khi long click vào map
  onMapLongClick: (LatLng? latLng, Point? point) async {
    if (latLng != null) {
      print('Map long clicked at: ${latLng.latitude}, ${latLng.longitude}');
      // Dùng để build route đến điểm được chọn
      await buildRouteToLocation(latLng);
    }
  },
  
  // Callback khi click vào marker
  onMarkerClicked: (int? markerId) {
    print('Marker clicked: $markerId');
    // Có thể remove marker
    // _navigationController?.removeMarkers([markerId ?? 0]);
  },
)
```

---

## 🎯 CÁC CÁCH TẠO ROUTE

### Phương Pháp 1: Build Route Đơn Giản (Chỉ Vẽ Route)

```dart
Future<void> buildRoute({
  required LatLng startPoint,
  required LatLng endPoint,
}) async {
  if (_navigationController == null) {
    print('❌ Navigation controller is null');
    return;
  }
  
  // Tạo danh sách waypoints
  final waypoints = [startPoint, endPoint];
  
  // Build route - chỉ vẽ route trên map, KHÔNG bắt đầu navigation
  await _navigationController?.buildRoute(
    waypoints: waypoints,
    profile: DrivingProfile.drivingTraffic,  // Xem phần DrivingProfile bên dưới
  );
  
  print('✅ Route building...');
  // Kết quả sẽ được trả về trong callback onRouteBuilt
}
```

### Phương Pháp 2: Build Route Với Nhiều Điểm (Multiple Waypoints)

```dart
Future<void> buildRouteWithMultipleStops() async {
  final waypoints = [
    LatLng(10.759091, 106.675817),  // Điểm bắt đầu
    LatLng(10.762528, 106.653099),  // Điểm dừng 1
    LatLng(10.770000, 106.660000),  // Điểm dừng 2
    LatLng(11.762528, 107.653099),  // Điểm kết thúc
  ];
  
  await _navigationController?.buildRoute(
    waypoints: waypoints,
    profile: DrivingProfile.driving,
  );
}
```

### Phương Pháp 3: Build Route VÀ Start Navigation Luôn

```dart
Future<void> buildAndStartNavigation({
  required LatLng startPoint,
  required LatLng endPoint,
}) async {
  if (_navigationController == null) {
    print('❌ Navigation controller is null');
    return;
  }
  
  final waypoints = [startPoint, endPoint];
  
  // Build route VÀ tự động start navigation khi có route
  await _navigationController?.buildAndStartNavigation(
    waypoints: waypoints,
    profile: DrivingProfile.drivingTraffic,
  );
  
  setState(() {
    _isNavigating = true;
  });
  
  print('✅ Navigation started automatically');
}
```

### Phương Pháp 4: Build Route Rồi Start Navigation Sau

```dart
// Bước 1: Build route trước
Future<void> buildRoute() async {
  final waypoints = [
    await _getCurrentLocation(),  // Lấy vị trí hiện tại
    _selectedDestination,         // Điểm đích đã chọn
  ];
  
  await _navigationController?.buildRoute(
    waypoints: waypoints,
    profile: DrivingProfile.drivingTraffic,
  );
}

// Bước 2: Start navigation khi user nhấn nút "Bắt đầu"
void startNavigation() {
  if (!_isRouteBuilt) {
    print('❌ Route not built yet');
    return;
  }
  
  _navigationController?.startNavigation();
  
  setState(() {
    _isNavigating = true;
  });
  
  print('✅ Navigation started manually');
}
```

### Phương Pháp 5: Build Route Từ Long Click Trên Map

```dart
NavigationView(
  // ...other configs
  
  onMapLongClick: (LatLng? latLng, Point? point) async {
    if (latLng == null) return;
    
    // Lấy vị trí hiện tại
    final currentLocation = await _getCurrentLocation();
    
    // Build route từ vị trí hiện tại đến điểm được chọn
    await _navigationController?.buildRoute(
      waypoints: [currentLocation, latLng],
      profile: DrivingProfile.cycling,  // Ví dụ: dùng profile cycling
    );
  },
)

Future<LatLng> _getCurrentLocation() async {
  // Sử dụng geolocator hoặc location service
  final position = await Geolocator.getCurrentPosition();
  return LatLng(position.latitude, position.longitude);
}
```

---

## 🚗 Driving Profiles (Loại Phương Tiện)

Package hỗ trợ các loại phương tiện khác nhau:

```dart
enum DrivingProfile {
  drivingTraffic,  // Ô tô - có xét đến traffic (khuyến nghị)
  driving,         // Ô tô - không xét traffic
  cycling,         // Xe đạp
  walking,         // Đi bộ
  motorcycle,      // Xe máy
}
```

### Ví Dụ Sử Dụng Profiles

```dart
// Ô tô với traffic
await _navigationController?.buildRoute(
  waypoints: waypoints,
  profile: DrivingProfile.drivingTraffic,
);

// Xe máy
await _navigationController?.buildRoute(
  waypoints: waypoints,
  profile: DrivingProfile.motorcycle,
);

// Đi bộ
await _navigationController?.buildRoute(
  waypoints: waypoints,
  profile: DrivingProfile.walking,
);
```

---

## 🎮 CÁC HÀM ĐIỀU KHIỂN NAVIGATION

### 1. Start Navigation
```dart
// Bắt đầu navigation sau khi đã build route
_navigationController?.startNavigation();
```

### 2. Stop Navigation
```dart
// Dừng navigation và clear route
_navigationController?.finishNavigation();

setState(() {
  _isNavigating = false;
  _routeProgressEvent = null;
});
```

### 3. Clear Route
```dart
// Xóa route khỏi map (không dừng navigation)
_navigationController?.clearRoute();

setState(() {
  _isRouteBuilt = false;
});
```

### 4. Recenter Camera
```dart
// Căn giữa camera về vị trí hiện tại
_navigationController?.recenter();
```

### 5. Overview Route
```dart
// Xem tổng quan toàn bộ route
_navigationController?.overview();
```

### 6. Mute/Unmute Voice
```dart
// Bật/tắt voice instructions
_navigationController?.mute();
```

### 7. Move Camera
```dart
// Di chuyển camera đến vị trí cụ thể
_navigationController?.moveCamera(
  latLng: LatLng(10.762317, 106.654551),
  zoom: 15.0,
  tilt: 0.0,
  bearing: 0.0,
);
```

### 8. Animate Camera
```dart
// Animate camera đến vị trí cụ thể (mượt hơn moveCamera)
_navigationController?.animateCamera(
  latLng: LatLng(10.762317, 106.654551),
  zoom: 15.0,
  tilt: 45.0,
  bearing: 90.0,
);
```

---

## 📍 THÊM MARKERS VÀO MAP

### Thêm Markers Từ Asset Image

```dart
Future<void> addMarkersToMap() async {
  List<NavigationMarker>? markers = await _navigationController?.addImageMarkers([
    NavigationMarker(
      imagePath: 'assets/markers/start_marker.png',
      latLng: LatLng(10.762317, 106.654551),
      width: 50,
      height: 50,
    ),
    NavigationMarker(
      imagePath: 'assets/markers/end_marker.png',
      latLng: LatLng(10.770000, 106.660000),
      width: 60,
      height: 60,
    ),
  ]);
  
  // markers chứa thông tin các marker đã thêm
  print('Added ${markers?.length} markers');
}
```

**Lưu ý**: 
- `width` và `height` phải cùng null hoặc cùng có giá trị
- Nếu không set width/height, marker sẽ dùng kích thước gốc của image

### Remove Markers

```dart
// Remove marker theo ID
_navigationController?.removeMarkers([markerId]);

// Remove nhiều markers
_navigationController?.removeMarkers([markerId1, markerId2, markerId3]);
```

---

## 🎨 HIỂN THỊ UI COMPONENTS

### 1. Banner Instruction View

Hiển thị instruction (rẽ trái, rẽ phải,...) ở trên cùng:

```dart
Positioned(
  top: MediaQuery.of(context).viewPadding.top,
  left: 0,
  right: 0,
  child: BannerInstructionView(
    routeProgressEvent: routeProgressEvent,
    instructionIcon: instructionImage,
  ),
)
```

#### Tạo Instruction Icon

```dart
Widget instructionImage = const SizedBox.shrink();

void _setInstructionImage(String? modifier, String? type) {
  if (modifier != null && type != null) {
    List<String> data = [
      type.replaceAll(' ', '_'),
      modifier.replaceAll(' ', '_')
    ];
    String path = 'assets/navigation_symbol/${data.join('_')}.svg';
    
    setState(() {
      instructionImage = SvgPicture.asset(path, color: Colors.white);
    });
  }
}

// Gọi trong onRouteProgressChange
onRouteProgressChange: (RouteProgressEvent event) {
  _setInstructionImage(event.currentModifier, event.currentModifierType);
}
```

**Download instruction icons**: [Tại đây](https://vietmapcorp-my.sharepoint.com/:u:/g/personal/thanhdt_vietmap_vn/EU0Heb0gMh1KtgCaoy5oih8BrOL6YKPWJUO-vXeGBp99hA?e=woyAvH)

### 2. Bottom Action View

Hiển thị các nút điều khiển ở dưới cùng:

```dart
Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: BottomActionView(
    recenterButton: recenterButton,
    controller: _navigationController,
    routeProgressEvent: routeProgressEvent,
    onOverviewCallback: () {
      // Callback khi nhấn overview
      _showRecenterButton();
    },
    onStopNavigationCallback: () {
      // Callback khi dừng navigation
      setState(() {
        _isNavigating = false;
        routeProgressEvent = null;
      });
    },
  ),
)
```

### 3. Custom Recenter Button

```dart
Widget recenterButton = const SizedBox.shrink();

void _showRecenterButton() {
  setState(() {
    recenterButton = ElevatedButton.icon(
      onPressed: () {
        _navigationController?.recenter();
        setState(() {
          recenterButton = const SizedBox.shrink();
        });
      },
      icon: Icon(Icons.my_location),
      label: Text('Về giữa'),
    );
  });
}
```

### 4. Custom Route Info Display

```dart
if (routeProgressEvent != null)
  Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Distance remaining
        Row(
          children: [
            Icon(Icons.straighten, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              '${(routeProgressEvent!.distanceRemaining / 1000).toStringAsFixed(1)} km',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 8),
        
        // Duration remaining
        Row(
          children: [
            Icon(Icons.access_time, color: Colors.green),
            SizedBox(width: 8),
            Text(
              '${(routeProgressEvent!.durationRemaining / 60).toStringAsFixed(0)} phút',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 8),
        
        // Current instruction
        Row(
          children: [
            Icon(Icons.turn_right, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '${routeProgressEvent!.currentModifierType} ${routeProgressEvent!.currentModifier}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
```

---

## 💡 BEST PRACTICES VÀ LƯU Ý QUAN TRỌNG

### 1. ⚠️ Gọi buildRoute Sau Khi Map Đã Render

```dart
// ❌ SAI - Gọi ngay trong initState
@override
void initState() {
  super.initState();
  _buildRoute();  // Map chưa sẵn sàng!
}

// ✅ ĐÚNG - Gọi trong onMapRendered
NavigationView(
  onMapRendered: () {
    _buildRoute();  // Map đã sẵn sàng
  },
)

// ✅ ĐÚNG - Gọi từ button click
ElevatedButton(
  onPressed: () {
    _buildRoute();  // User trigger, map đã sẵn sàng
  },
  child: Text('Tìm đường'),
)
```

### 2. ⚠️ Kiểm Tra Location Permission

```dart
Future<void> checkLocationPermission() async {
  // Sử dụng geolocator package
  LocationPermission permission = await Geolocator.checkPermission();
  
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Hướng dẫn user mở settings
    _showPermissionDeniedDialog();
    return;
  }
  
  if (permission == LocationPermission.whileInUse || 
      permission == LocationPermission.always) {
    // OK, có thể bắt đầu navigation
    await _buildRoute();
  }
}
```

### 3. ⚠️ Dispose Navigation Controller

```dart
@override
void dispose() {
  _navigationController?.onDispose();
  super.dispose();
}
```

### 4. ⚠️ Handle Null Safety

```dart
// Luôn check null trước khi gọi
if (_navigationController != null) {
  await _navigationController?.buildRoute(waypoints: waypoints);
} else {
  print('❌ Navigation controller is not initialized');
}
```

### 5. ⚠️ Xử Lý Loading State

```dart
Future<void> buildRoute() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    await _navigationController?.buildRoute(waypoints: waypoints);
  } catch (e) {
    print('Error: $e');
    _showError('Không thể tìm đường');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
```

### 6. ⚠️ Test Với Simulate Mode

```dart
// Trong development, dùng simulate mode
_navigationOption.simulateRoute = true;  // Mô phỏng di chuyển

// Trong production
_navigationOption.simulateRoute = false;  // Dùng GPS thật
```

### 7. ⚠️ Handle Route Build Failed

```dart
NavigationView(
  onRouteBuildFailed: (error) {
    print('❌ Route build failed: $error');
    
    // Hiện thông báo cho user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Không thể tìm thấy đường đi. Vui lòng thử lại.'),
        action: SnackBarAction(
          label: 'Thử lại',
          onPressed: () => _buildRoute(),
        ),
      ),
    );
  },
)
```

---

## 🔧 TROUBLESHOOTING

### Lỗi 1: "Navigation controller is null"

**Nguyên nhân**: Gọi controller trước khi onMapCreated được trigger

**Giải pháp**:
```dart
// Đợi controller được khởi tạo
NavigationView(
  onMapCreated: (controller) {
    _navigationController = controller;
    
    // Có thể gọi các hàm ở đây
    _onControllerReady();
  },
)
```

### Lỗi 2: "Route build failed"

**Nguyên nhân**: 
- API key không hợp lệ
- Waypoints không hợp lệ (cùng vị trí, hoặc quá xa)
- Network error

**Giải pháp**:
```dart
// 1. Kiểm tra API key
print('API Key: ${_navigationOption.apiKey}');

// 2. Kiểm tra waypoints
if (waypoints.length < 2) {
  print('❌ Need at least 2 waypoints');
  return;
}

// 3. Validate waypoints
for (var point in waypoints) {
  if (point.latitude < -90 || point.latitude > 90 ||
      point.longitude < -180 || point.longitude > 180) {
    print('❌ Invalid coordinates: $point');
    return;
  }
}
```

### Lỗi 3: "Voice instructions not working"

**Nguyên nhân**: 
- Voice không hoạt động trên iOS simulator
- Permission audio chưa được cấp

**Giải pháp**:
```dart
// Test trên real device
// Kiểm tra settings
_navigationOption.voiceInstructionsEnabled = true;
_navigationOption.language = 'vi';
```

### Lỗi 4: "Map not showing"

**Nguyên nhân**: API key chưa được set đúng

**Giải pháp**:
```dart
// Kiểm tra mapStyle có chứa API key
_navigationOption.mapStyle = 
    "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=YOUR_REAL_API_KEY";

// Không để YOUR_API_KEY_HERE
```

### Lỗi 5: "App crashes on Android 14+"

**Nguyên nhân**: Chưa khai báo foreground service trong AndroidManifest

**Giải pháp**: Thêm service vào AndroidManifest (xem phần cấu hình ở trên)

---

## 📋 IMPLEMENTATION TRONG PROJECT CỦA BẠN

### Code Hoàn Chỉnh Cho `metro_map_provider.dart`

```dart
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';

class MetroMapProvider extends ChangeNotifier {
  // Controllers
  VietmapController? _vietmapController;
  MapNavigationViewController? _navigationController;
  
  // Plugin
  final _vietmapNavigationPlugin = VietMapNavigationPlugin();
  late MapOptions _navigationOption;
  
  // State
  RouteProgressEvent? _routeProgressEvent;
  bool _isRouteBuilt = false;
  bool _isNavigating = false;
  bool _isLoading = false;
  
  // Locations
  LatLng? _currentPlaceLatLng;
  LatLng? _selectedPlaceLatLng;
  
  // Getters
  VietmapController get vietmapController => _vietmapController!;
  MapNavigationViewController? get navigationController => _navigationController;
  RouteProgressEvent? get routeProgressEvent => _routeProgressEvent;
  bool get isRouteBuilt => _isRouteBuilt;
  bool get isNavigating => _isNavigating;
  bool get isLoading => _isLoading;
  LatLng? get currentPlaceLatLng => _currentPlaceLatLng;
  LatLng? get selectedPlaceLatLng => _selectedPlaceLatLng;
  
  // Constructor
  MetroMapProvider() {
    _initialize();
  }
  
  // Initialize navigation options
  Future<void> _initialize() async {
    _navigationOption = _vietmapNavigationPlugin.getDefaultOptions();
    
    _navigationOption.simulateRoute = false;
    _navigationOption.apiKey = dotenv.env['VM_API_KEY'] ?? '';
    _navigationOption.mapStyle = 
        "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=${dotenv.env['VM_API_KEY']}";
    _navigationOption.zoom = 15.0;
    _navigationOption.tilt = 0.0;
    _navigationOption.bearing = 0.0;
    _navigationOption.language = 'vi';
    _navigationOption.voiceInstructionsEnabled = true;
    _navigationOption.bannerInstructionsEnabled = true;
    
    _vietmapNavigationPlugin.setDefaultOptions(_navigationOption);
  }
  
  // Get navigation options
  MapOptions getNavigationOptions() => _navigationOption;
  
  // On map created
  void onMapCreated(VietmapController controller) {
    _vietmapController = controller;
    notifyListeners();
  }
  
  // On navigation controller created
  void onNavigationControllerCreated(MapNavigationViewController controller) {
    _navigationController = controller;
    notifyListeners();
  }
  
  // Get current location
  Future<void> moveToMyLocation() async {
    if (_vietmapController == null) return;
    
    try {
      _currentPlaceLatLng = await _vietmapController!.requestMyLocationLatLng();
      
      if (_currentPlaceLatLng != null) {
        await _vietmapController!.moveCamera(
          CameraUpdate.newLatLngZoom(_currentPlaceLatLng!, 16.0),
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
    }
  }
  
  // Set selected location
  void setSelectedLocation(LatLng location) {
    _selectedPlaceLatLng = location;
    notifyListeners();
  }
  
  // BUILD ROUTE - Method 1: Chỉ vẽ route
  Future<void> buildRoute() async {
    if (_navigationController == null) {
      debugPrint('❌ Navigation controller is null');
      return;
    }
    
    if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
      debugPrint('❌ Missing start or end location');
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final waypoints = [_currentPlaceLatLng!, _selectedPlaceLatLng!];
      
      await _navigationController?.buildRoute(
        waypoints: waypoints,
        profile: DrivingProfile.drivingTraffic,
      );
      
      debugPrint('✅ Building route...');
    } catch (e) {
      debugPrint('❌ Error building route: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // BUILD AND START NAVIGATION - Method 2: Build và start luôn
  Future<void> buildAndStartNavigation() async {
    if (_navigationController == null) {
      debugPrint('❌ Navigation controller is null');
      return;
    }
    
    if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
      debugPrint('❌ Missing start or end location');
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final waypoints = [_currentPlaceLatLng!, _selectedPlaceLatLng!];
      
      await _navigationController?.buildAndStartNavigation(
        waypoints: waypoints,
        profile: DrivingProfile.drivingTraffic,
      );
      
      _isNavigating = true;
      debugPrint('✅ Navigation started automatically');
    } catch (e) {
      debugPrint('❌ Error starting navigation: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // BUILD ROUTE FROM LONG CLICK
  Future<(LatLng?, Point<num>?)> onMapLongSelected(
    LatLng? latLng, 
    Point<num>? point
  ) async {
    if (latLng == null || _currentPlaceLatLng == null) {
      return (null, null);
    }
    
    try {
      await _navigationController?.buildRoute(
        waypoints: [_currentPlaceLatLng!, latLng],
        profile: DrivingProfile.cycling,
      );
      
      _selectedPlaceLatLng = latLng;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error building route from long click: $e');
    }
    
    return (latLng, point);
  }
  
  // Start navigation (after route is built)
  void startNavigation() {
    if (!_isRouteBuilt) {
      debugPrint('❌ Route not built yet');
      return;
    }
    
    _navigationController?.startNavigation();
    _isNavigating = true;
    notifyListeners();
    
    debugPrint('✅ Navigation started');
  }
  
  // Stop navigation
  void stopNavigation() {
    _navigationController?.finishNavigation();
    _isNavigating = false;
    _routeProgressEvent = null;
    notifyListeners();
    
    debugPrint('⏹️ Navigation stopped');
  }
  
  // Clear route
  void clearRoute() {
    _navigationController?.clearRoute();
    _isRouteBuilt = false;
    notifyListeners();
    
    debugPrint('🗑️ Route cleared');
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
  
  // Toggle mute
  void toggleMute() {
    _navigationController?.mute();
    debugPrint('🔇 Voice toggled');
  }
  
  // On route built callback
  void onRouteBuilt(DirectionRoute route) {
    _isRouteBuilt = true;
    _isLoading = false;
    
    debugPrint('✅ Route built successfully');
    debugPrint('Distance: ${route.distance} meters');
    debugPrint('Duration: ${route.duration} seconds');
    
    notifyListeners();
  }
  
  // On route build failed callback
  void onRouteBuildFailed(dynamic error) {
    _isLoading = false;
    _isRouteBuilt = false;
    
    debugPrint('❌ Route build failed: $error');
    
    notifyListeners();
  }
  
  // On route progress change callback
  void onRouteProgressChange(RouteProgressEvent event) {
    _routeProgressEvent = event;
    notifyListeners();
  }
  
  // On arrival callback
  void onArrival() {
    _isNavigating = false;
    debugPrint('🎯 Arrived at destination!');
    notifyListeners();
  }
  
  @override
  void dispose() {
    _navigationController?.onDispose();
    super.dispose();
  }
}
```

### Code Hoàn Chỉnh Cho `metro_map_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'metro_map_provider.dart';

class MetroMapScreen extends StatelessWidget {
  const MetroMapScreen({super.key});

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
          // Navigation View
          NavigationView(
            mapOptions: provider.getNavigationOptions(),
            
            onMapCreated: (controller) {
              provider.onNavigationControllerCreated(controller);
            },
            
            onMapRendered: () {
              debugPrint('✅ Map rendered');
            },
            
            onRouteBuilt: (route) {
              provider.onRouteBuilt(route);
            },
            
            onRouteBuildFailed: (error) {
              provider.onRouteBuildFailed(error);
            },
            
            onNewRouteSelected: (route) {
              debugPrint('🔄 New route selected');
            },
            
            onRouteProgressChange: (event) {
              provider.onRouteProgressChange(event);
            },
            
            onArrival: () {
              provider.onArrival();
            },
            
            onMapLongClick: provider.onMapLongSelected,
            
            onMapClick: (latLng, point) async {
              if (latLng != null) {
                provider.setSelectedLocation(latLng);
              }
            },
          ),
          
          // Loading indicator
          if (provider.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          
          // Route info card
          if (provider.routeProgressEvent != null && provider.isNavigating)
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 60,
              left: 16,
              right: 16,
              child: _buildRouteInfoCard(provider.routeProgressEvent!),
            ),
          
          // Control buttons
          Positioned(
            bottom: 80,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter button
                FloatingActionButton(
                  mini: true,
                  onPressed: provider.recenterCamera,
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 8),
                
                // Overview button
                if (provider.isRouteBuilt)
                  FloatingActionButton(
                    mini: true,
                    onPressed: provider.overviewRoute,
                    child: Icon(Icons.map),
                  ),
              ],
            ),
          ),
          
          // Start/Stop navigation buttons
          if (provider.isRouteBuilt && !provider.isNavigating)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: provider.startNavigation,
                    icon: Icon(Icons.navigation),
                    label: Text('Bắt đầu'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: provider.clearRoute,
                    icon: Icon(Icons.clear),
                    label: Text('Xóa route'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          
          // Stop button during navigation
          if (provider.isNavigating)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: provider.stopNavigation,
                icon: Icon(Icons.stop),
                label: Text('Dừng điều hướng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
      
      floatingActionButton: !provider.isNavigating
          ? FloatingActionButton.extended(
              onPressed: provider.buildRoute,
              icon: Icon(Icons.directions),
              label: Text('Tìm đường'),
            )
          : null,
    );
  }
  
  Widget _buildRouteInfoCard(RouteProgressEvent event) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distance
            Row(
              children: [
                Icon(Icons.straighten, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '${((event.distanceRemaining ?? 0) / 1000).toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // Duration
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '${((event.durationRemaining ?? 0) / 60).toStringAsFixed(0)} phút',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // Instruction
            if (event.currentModifier != null && event.currentModifierType != null)
              Row(
                children: [
                  Icon(Icons.turn_right, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${event.currentModifierType} ${event.currentModifier}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📚 TÀI LIỆU THAM KHẢO

1. **Official Documentation**
   - Pub.dev: https://pub.dev/packages/vietmap_flutter_navigation
   - GitHub: https://github.com/vietmap-company/vietmap-flutter-navigation
   - Example App: https://github.com/vietmap-company/flutter-navigation-example

2. **VietMap API**
   - API Overview: https://vietmap.vn/maps-api
   - API Documentation: https://maps.vietmap.vn/docs/map-api/overview/
   - Get API Key: https://bit.ly/vietmap-api

3. **Download Links**
   - Demo App: https://vmnavigation.page.link/navigation_demo
   - Navigation Icons: [SharePoint Link](https://vietmapcorp-my.sharepoint.com/:u:/g/personal/thanhdt_vietmap_vn/EU0Heb0gMh1KtgCaoy5oih8BrOL6YKPWJUO-vXeGBp99hA?e=woyAvH)
   - Figma Design: [Figma Link](https://www.figma.com/file/rWyQ5TNtt6E5l8tPEE9Tkl/VietMap-navigation-symbol)

4. **Support**
   - Email: maps-api.support@vietmap.vn
   - Website: https://vietmap.vn/lien-he
   - Report Issues: https://github.com/vietmap-company/flutter-map-sdk/issues

---

## ✅ CHECKLIST IMPLEMENTATION

### Setup
- [ ] Đã cài package `vietmap_flutter_navigation: ^4.1.0`
- [ ] Đã cấu hình Android (build.gradle, AndroidManifest)
- [ ] Đã cấu hình iOS (Podfile, Info.plist)
- [ ] Đã có API key từ VietMap
- [ ] Đã thay API key vào code

### Code Implementation
- [ ] Đã import package
- [ ] Đã khai báo biến cần thiết
- [ ] Đã khởi tạo MapOptions
- [ ] Đã implement NavigationView
- [ ] Đã implement callbacks (onMapCreated, onRouteBuilt, etc.)
- [ ] Đã implement buildRoute method
- [ ] Đã implement start/stop navigation
- [ ] Đã implement dispose

### Testing
- [ ] Test trên simulator với `simulateRoute = true`
- [ ] Test trên real device với `simulateRoute = false`
- [ ] Test location permission
- [ ] Test route building với 2 điểm
- [ ] Test route building với nhiều điểm
- [ ] Test start/stop navigation
- [ ] Test voice instructions
- [ ] Test recenter/overview

### UI/UX
- [ ] Hiện loading indicator khi build route
- [ ] Hiện thông báo khi build route failed
- [ ] Hiện route info (distance, duration)
- [ ] Hiện navigation instructions
- [ ] Có nút start/stop navigation
- [ ] Có nút recenter/overview

---

## 🎉 KẾT LUẬN

Package `vietmap_flutter_navigation` cung cấp đầy đủ tính năng để implement navigation trong Flutter app. Các bước chính:

1. **Setup**: Cấu hình Android/iOS, cài package
2. **Initialize**: Khởi tạo MapOptions và NavigationView
3. **Build Route**: Dùng `buildRoute()` hoặc `buildAndStartNavigation()`
4. **Start Navigation**: Dùng `startNavigation()` sau khi route được build
5. **Handle Events**: Implement callbacks để xử lý events
6. **UI**: Hiển thị route info và controls

**Lưu ý quan trọng**:
- Luôn gọi `buildRoute()` sau khi map đã render
- Check location permission trước khi navigate
- Dispose navigation controller trong dispose()
- Test trên real device để đảm bảo GPS và voice hoạt động

Chúc bạn implement thành công! 🚀

