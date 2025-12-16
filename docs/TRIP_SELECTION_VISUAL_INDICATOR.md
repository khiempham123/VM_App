# Trip Selection Visual Indicator Implementation

## Yêu cầu (Requirement)
Hiển thị background color cho row của trip được chọn trong danh sách My Trips để người dùng biết trip nào đang được hiển thị trên bản đồ.

## Triển khai (Implementation)

### 1. Tracking Selected Trip
Provider đã có sẵn biến `_currentTripName` để track trip đang được chọn:
```dart
String? _currentTripName;
String? get currentTripName => _currentTripName;
```

### 2. Visual Changes
Trong `my_trip_route_screen.dart`, trip list builder đã được cập nhật với các thay đổi sau:

#### a. Background Color & Border
```dart
final isSelected = provider.currentTripName == tripName;

Container(
  decoration: BoxDecoration(
    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: isSelected 
      ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
      : null,
  ),
  ...
)
```

#### b. Icon Style
```dart
Icon(
  isSelected ? Icons.route : Icons.route_outlined,
  color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.7),
  size: 18,
)
```

#### c. Text Style
```dart
Text(
  TripNameParser.getTripName(tripName),
  style: TextStyle(
    fontSize: 14,
    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    color: isSelected ? AppColors.primary : Colors.black87,
  ),
  ...
)
```

## Visual Design Decisions

### Selected Trip:
- **Background**: Primary color với opacity 0.1 (light tint)
- **Border**: Primary color với opacity 0.3 và width 1px
- **Icon**: Filled route icon (`Icons.route`)
- **Icon Color**: Full primary color
- **Text**: Font weight 600 (semi-bold) với primary color

### Unselected Trip:
- **Background**: White
- **Border**: None
- **Icon**: Outlined route icon (`Icons.route_outlined`)
- **Icon Color**: Primary color với opacity 0.7
- **Text**: Font weight 500 (medium) với black87 color

## User Experience
1. Khi user chọn một trip từ dropdown menu, trip đó sẽ được highlight
2. Background color nhẹ nhàng không làm mất tập trung
3. Border giúp phân biệt rõ ràng trip được chọn
4. Icon và text màu primary giúp nhấn mạnh selection
5. Các trip khác vẫn dễ đọc với màu đen nhạt

## Files Changed
- `/lib/modules/my_trip_route/my_trip_route_screen.dart` - Updated trip list item builder

## Testing
1. Mở dropdown "Your trip"
2. Chọn một trip
3. Xác nhận trip được chọn có background color và border
4. Chọn trip khác và xác nhận highlight chuyển sang trip mới
5. Kiểm tra các trip không được chọn vẫn hiển thị bình thường

