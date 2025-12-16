# Fix Polyline GNU Artifact Issue

## Vấn đề (Problem)
Khi load trip từ local storage và gọi method `_drawRouteForTripLoaded`, xuất hiện một GNU artifact ở điểm cuối của route trên bản đồ.

## Nguyên nhân (Root Cause)
Trip name được lưu với format:
```
trip_{tripName}_{refIdList}_encodedPolyline_{polylineData}_color_{colorHex}
```

Trong method `_drawRouteForTripLoaded`, code cũ sử dụng:
```dart
_encodedPolyline = tripName.split('encodedPolyline_').last;
```

Điều này lấy tất cả nội dung sau `encodedPolyline_`, bao gồm cả phần `_color_{colorHex}`. Khi decode polyline với dữ liệu không hợp lệ (bao gồm cả color suffix), nó tạo ra các điểm lạ ở cuối route, gây ra GNU artifact.

## Giải pháp (Solution)
Thay đổi logic extraction để chỉ lấy dữ liệu polyline giữa `encodedPolyline_` và `_color_`:

```dart
// Extract encoded polyline properly (between 'encodedPolyline_' and '_color_')
final polylineStartIndex = tripName.indexOf('encodedPolyline_') + 'encodedPolyline_'.length;
final colorStartIndex = tripName.indexOf('_color_');
if (polylineStartIndex != -1 && colorStartIndex != -1 && colorStartIndex > polylineStartIndex) {
  _encodedPolyline = tripName.substring(polylineStartIndex, colorStartIndex);
} else {
  // Fallback to old method if format is unexpected
  _encodedPolyline = tripName.split('encodedPolyline_').last.split('_color_').first;
}
```

## Kết quả (Result)
- Polyline data được extract chính xác, không bao gồm color suffix
- Route được vẽ đúng trên bản đồ, không có artifact
- Debug messages được cải thiện để dễ theo dõi

## Files Changed
- `/lib/modules/my_trip_route/my_trip_route_provider.dart` - Method `_drawRouteForTripLoaded`

## Testing
1. Load một trip đã lưu từ local storage
2. Kiểm tra route hiển thị trên bản đồ
3. Xác nhận không còn GNU artifact ở cuối route
4. Kiểm tra debug logs để xác nhận polyline và color được extract đúng

