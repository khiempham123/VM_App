# Hướng dẫn vẽ đường đi từ 2 điểm với Vietmap Flutter Plugin

## Tổng quan

Đã implement chức năng vẽ đường đi từ **Current Location** đến **Selected Location** sử dụng `vietmap_flutter_plugin`.

## Các thành phần chính

### 1. State Variables trong MetroMapProvider

```dart
// Route information
Line? _routeLine;              // Polyline hiển thị trên map
double? _routeDistance;        // Khoảng cách (km)
double? _routeDuration;        // Thời gian (phút)
bool _isCalculatingRoute;      // Trạng thái đang tính route
bool _isOnRoute;               // Có đang hiển thị route không
```

### 2. Method onRouteSelected()

Method chính để tính toán và vẽ đường đi:

```dart
Future<void> onRouteSelected() async
```

**Các bước thực hiện:**

1. **Kiểm tra điều kiện:**
   - Map controller đã sẵn sàng
   - Có địa điểm đích (selectedPlaceLatLng)
   - Lấy current location nếu chưa có

2. **Gọi API Routing:**
   ```dart
   final result = await vm_router.Vietmap.routing(
     vm_router.VietMapRoutingParams(
       points: [
         _currentPlaceLatLng!,
         _selectedPlaceLatLng!,
       ],
       vehicle: vm_router.VehicleType.car,
     ),
   );
   ```

3. **Xử lý kết quả (Either<Failure, VietMapRoutingModel>):**
   ```dart
   result.fold(
     (failure) { /* Xử lý lỗi */ },
     (routingModel) { /* Xử lý thành công */ },
   );
   ```

4. **Decode polyline:**
   ```dart
   final latLngList = vm_router.VietmapPolyline.decodePolyline(
     encodedPolyline,
     false,
   );
   ```

5. **Vẽ route lên map:**
   ```dart
   _routeLine = await _vietmapController!.addPolyline(
     PolylineOptions(
       geometry: latLngList,
       polylineColor: Colors.blue,
       polylineWidth: 5.0,
       polylineJoin: 'round',
     ),
   );
   ```

6. **Fit camera để hiển thị toàn bộ route**

### 3. Method hỗ trợ

#### _drawRouteOnMap(List<LatLng> latLngList)
- Xóa route cũ nếu có
- Vẽ polyline mới lên map

#### _fitCameraToRoute()
- Tính bounds từ 2 điểm
- Animate camera để hiển thị toàn bộ route

#### clearRoute()
- Xóa polyline khỏi map
- Reset các state variables

#### clearSelectedPlace()
- Xóa địa điểm đã chọn
- Xóa route

## Cách sử dụng trong UI

### 1. Hiển thị thông tin route

```dart
if (provider.isOnRoute && provider.routeDistance != null)
  Container(
    child: Column(
      children: [
        Text('${provider.routeDistance!.toStringAsFixed(1)} km'),
        Text('${provider.routeDuration!.toStringAsFixed(0)} phút'),
      ],
    ),
  )
```

### 2. Nút tính route

```dart
if (provider.isOnSelectedLocation && !provider.isOnRoute)
  FloatingActionButton(
    onPressed: provider.isCalculatingRoute 
        ? null 
        : provider.onRouteSelected,
    child: provider.isCalculatingRoute
        ? CircularProgressIndicator()
        : Icon(Icons.directions),
  )
```

### 3. Nút xóa route

```dart
if (provider.isOnRoute)
  FloatingActionButton(
    onPressed: provider.clearRoute,
    child: Icon(Icons.close),
  )
```

## Flow hoạt động

1. **User chọn địa điểm từ search** → `onSuggestionSelected()`
   - Lưu địa điểm vào `_selectedPlace`
   - Lưu tọa độ vào `_selectedPlaceLatLng`
   - Di chuyển camera đến địa điểm
   - Set `_isOnSelectedLocation = true`

2. **User nhấn nút "Directions"** → `onRouteSelected()`
   - Lấy vị trí hiện tại
   - Gọi API Vietmap.routing()
   - Decode polyline
   - Vẽ route lên map
   - Hiển thị thông tin khoảng cách & thời gian

3. **User nhấn nút "Clear"** → `clearRoute()`
   - Xóa polyline khỏi map
   - Reset tất cả state

## Lưu ý quan trọng

### Import đúng package
```dart
import 'package:vietmap_flutter_plugin/vietmap_flutter_plugin.dart' as vm_router;
```

### Sử dụng với prefix
```dart
vm_router.Vietmap.getInstance('API_KEY');
vm_router.Vietmap.routing(...);
vm_router.VietmapPolyline.decodePolyline(...);
vm_router.VietMapRoutingParams(...);
vm_router.VehicleType.car;
```

### Kết quả trả về là Either
```dart
Either<Failure, VietMapRoutingModel>

// Xử lý bằng fold:
result.fold(
  (failure) => handleError(failure),
  (success) => handleSuccess(success),
);
```

### API Methods từ VietmapController
- `addPolyline()` - Thêm polyline
- `removePolyline()` - Xóa polyline
- `animateCamera()` - Di chuyển camera có animation

## Tính năng đã implement

✅ Tính toán route từ vị trí hiện tại đến địa điểm đã chọn  
✅ Vẽ polyline hiển thị route lên map  
✅ Hiển thị khoảng cách và thời gian di chuyển  
✅ Tự động zoom camera để hiển thị toàn bộ route  
✅ Xóa route khỏi map  
✅ Loading state khi đang tính route  
✅ Error handling đầy đủ  

## Debug & Troubleshooting

### Logs được in ra:
```
✅ Route calculated successfully
Distance: X.XX km
Duration: XX minutes
Points: XXX
```

### Kiểm tra lỗi:
- `_errorMessage` sẽ chứa thông tin lỗi
- Console sẽ in ra stack trace nếu có exception

### Các lỗi thường gặp:
1. **Map is not ready** - Controller chưa được khởi tạo
2. **Please select a destination first** - Chưa chọn địa điểm đích
3. **Cannot get current location** - Không lấy được vị trí hiện tại
4. **No route found** - API không trả về route
5. **No polyline data in route** - Không có dữ liệu polyline để vẽ

## Tham khảo

- Package: `vietmap_flutter_plugin: ^0.5.2`
- Package: `vietmap_flutter_gl: ^4.1.0`
- API Key: Cần config trong `.env` file với key `VM_API_KEY`

