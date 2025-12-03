# Giải Pháp: Truyền Complex Objects Qua Auto Route

## 🎯 Vấn Đề

**Auto Route không thể serialize/deserialize complex objects** như `LatLng` từ package `vietmap_flutter_gl` vì:
- `LatLng` là class từ external package
- Không có constructor đơn giản với primitive types
- Auto Route không biết cách serialize/deserialize nó

**Lỗi gặp phải**:
```dart
// ❌ SAI - Auto Route không nhận diện được LatLng
@RoutePage()
class MetroGoNavigationScreen extends StatelessWidget {
  final LatLng currentLocation;  // ❌ Complex object
  final LatLng selectedLocation; // ❌ Complex object
  
  const MetroGoNavigationScreen({
    required this.currentLocation,
    required this.selectedLocation,
  });
}
```

---

## ✅ Giải Pháp: Wrapper Class (LocationData)

### Bước 1: Tạo Wrapper Class Đơn Giản

**File**: `lib/domain/entities/location_data.dart`

```dart
// Location data wrapper for auto_route serialization
class LocationData {
  final double latitude;   // ✅ Primitive type
  final double longitude;  // ✅ Primitive type

  const LocationData({
    required this.latitude,
    required this.longitude,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationData) return false;
    return latitude == other.latitude && longitude == other.longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'LocationData(lat: $latitude, lng: $longitude)';
}
```

**Đặc điểm của LocationData**:
- ✅ Chỉ chứa **primitive types** (double)
- ✅ Immutable (final fields)
- ✅ Implement `==` và `hashCode` operators
- ✅ Auto Route có thể serialize/deserialize dễ dàng

---

### Bước 2: Export LocationData

**File**: `lib/domain/domain.dart`

```dart
export 'entities/location_data.dart';
```

---

### Bước 3: Update Screen Để Nhận LocationData

**File**: `metro_go_navigation_screen.dart`

```dart
import 'package:vm_first_app/domain/entities/location_data.dart';

@RoutePage()
class MetroGoNavigationScreen extends StatelessWidget {
  final LocationData currentLocation;   // ✅ Wrapper class
  final LocationData selectedLocation;  // ✅ Wrapper class

  const MetroGoNavigationScreen({
    super.key,
    required this.currentLocation,
    required this.selectedLocation,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Convert LocationData → LatLng khi cần dùng
    final currentLatLng = LatLng(
      currentLocation.latitude,
      currentLocation.longitude,
    );
    final selectedLatLng = LatLng(
      selectedLocation.latitude,
      selectedLocation.longitude,
    );
    
    return ChangeNotifierProvider(
      create: (context) => MetroGoNavigationProvider(
        currentLocation: currentLatLng,    // Pass LatLng to provider
        selectedLocation: selectedLatLng,
      ),
      child: const _MetroGoNavigationView(),
    );
  }
}
```

**Key Point**: Screen nhận `LocationData`, convert sang `LatLng` khi cần.

---

### Bước 4: Update Navigation Logic Để Convert

**File**: `metro_map_provider.dart`

```dart
import 'package:vm_first_app/domain/entities/location_data.dart';

class MetroMapProvider extends ChangeNotifier {
  LatLng? _currentPlaceLatLng;    // Internal: LatLng
  LatLng? _selectedPlaceLatLng;   // Internal: LatLng
  
  /// Navigate to full navigation screen
  void navigateToFullNavigation(BuildContext context) {
    if (_currentPlaceLatLng == null || _selectedPlaceLatLng == null) {
      debugPrint('❌ Missing locations');
      return;
    }

    debugPrint('🚀 Navigating to MetroGoNavigationScreen...');

    // ✅ Convert LatLng → LocationData for auto_route
    final currentLocationData = LocationData(
      latitude: _currentPlaceLatLng!.latitude,
      longitude: _currentPlaceLatLng!.longitude,
    );
    
    final selectedLocationData = LocationData(
      latitude: _selectedPlaceLatLng!.latitude,
      longitude: _selectedPlaceLatLng!.longitude,
    );

    // ✅ Navigate với LocationData
    context.router.push(
      MetroGoNavigationRoute(
        currentLocation: currentLocationData,
        selectedLocation: selectedLocationData,
      ),
    );
  }
}
```

---

### Bước 5: Run Build Runner

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Generated Code**: `router.gr.dart`

```dart
/// Route với LocationData parameters
class MetroGoNavigationRoute extends PageRouteInfo<MetroGoNavigationRouteArgs> {
  MetroGoNavigationRoute({
    Key? key,
    required LocationData currentLocation,   // ✅ LocationData
    required LocationData selectedLocation,  // ✅ LocationData
    List<PageRouteInfo>? children,
  }) : super(
         MetroGoNavigationRoute.name,
         args: MetroGoNavigationRouteArgs(
           key: key,
           currentLocation: currentLocation,
           selectedLocation: selectedLocation,
         ),
         initialChildren: children,
       );

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MetroGoNavigationRouteArgs>();
      return MetroGoNavigationScreen(
        key: args.key,
        currentLocation: args.currentLocation,    // ✅ Pass LocationData
        selectedLocation: args.selectedLocation,
      );
    },
  );
}

/// Args class với LocationData
class MetroGoNavigationRouteArgs {
  const MetroGoNavigationRouteArgs({
    this.key,
    required this.currentLocation,
    required this.selectedLocation,
  });

  final Key? key;
  final LocationData currentLocation;   // ✅ Can serialize
  final LocationData selectedLocation;  // ✅ Can serialize

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MetroGoNavigationRouteArgs) return false;
    return key == other.key &&
        currentLocation == other.currentLocation &&
        selectedLocation == other.selectedLocation;
  }

  @override
  int get hashCode =>
      key.hashCode ^ currentLocation.hashCode ^ selectedLocation.hashCode;
}
```

---

## 🔄 Data Flow Diagram

```
Old Screen (MetroMapScreen)
    ↓
Internal state: LatLng objects
_currentPlaceLatLng: LatLng(10.76, 106.67)
_selectedPlaceLatLng: LatLng(10.77, 106.68)
    ↓
User clicks Navigation button
    ↓
navigateToFullNavigation(context)
    ↓
Convert LatLng → LocationData
currentLocationData = LocationData(lat: 10.76, lng: 106.67)
selectedLocationData = LocationData(lat: 10.77, lng: 106.68)
    ↓
context.router.push(
  MetroGoNavigationRoute(
    currentLocation: currentLocationData,  // ✅ Simple object
    selectedLocation: selectedLocationData,
  ),
)
    ↓
Auto Route serializes LocationData ✅
(Only primitive types: double, double)
    ↓
Navigate to New Screen
    ↓
Auto Route deserializes LocationData ✅
    ↓
New Screen (MetroGoNavigationScreen)
Receives LocationData parameters
    ↓
Convert LocationData → LatLng
currentLatLng = LatLng(
  currentLocation.latitude,   // 10.76
  currentLocation.longitude,  // 106.67
)
    ↓
Pass to Provider/Widget
    ↓
Use LatLng for navigation ✅
```

---

## 🎨 Pattern: Wrapper Class for Complex Objects

### Khi Nào Cần Wrapper Class?

Cần wrapper class khi object có:
- ❌ Complex constructors
- ❌ Non-primitive fields
- ❌ Methods và logic
- ❌ Từ external packages

### Ví Dụ Các Complex Objects Cần Wrapper

#### 1. Color Object

```dart
// ❌ SAI - Color is complex
@RoutePage()
class ThemeScreen extends StatelessWidget {
  final Color primaryColor;  // ❌
}

// ✅ ĐÚNG - Wrapper class
class ColorData {
  final int value;  // ✅ Primitive
  
  const ColorData(this.value);
  
  Color toColor() => Color(value);
  
  factory ColorData.fromColor(Color color) => ColorData(color.value);
}

@RoutePage()
class ThemeScreen extends StatelessWidget {
  final ColorData primaryColor;  // ✅
  
  @override
  Widget build(BuildContext context) {
    final color = primaryColor.toColor();  // Convert khi dùng
    return Container(color: color);
  }
}
```

#### 2. DateTime Object

```dart
// ❌ SAI - DateTime is complex
@RoutePage()
class EventScreen extends StatelessWidget {
  final DateTime eventDate;  // ❌
}

// ✅ ĐÚNG - Use timestamp (primitive)
@RoutePage()
class EventScreen extends StatelessWidget {
  final int eventTimestamp;  // ✅ Primitive int
  
  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.fromMillisecondsSinceEpoch(eventTimestamp);
    return Text(eventDate.toString());
  }
}
```

#### 3. Custom Entity

```dart
// ❌ SAI - Complex entity
@RoutePage()
class ProfileScreen extends StatelessWidget {
  final UserEntity user;  // ❌ Complex object with many fields
}

// ✅ ĐÚNG - Pass ID, fetch in screen
@RoutePage()
class ProfileScreen extends StatelessWidget {
  final String userId;  // ✅ Just ID
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserEntity>(
      future: fetchUser(userId),  // Fetch từ DB/API
      builder: (context, snapshot) {
        final user = snapshot.data;
        return UserProfile(user: user);
      },
    );
  }
}
```

---

## 💡 Best Practices

### 1. ✅ Keep Wrapper Classes Simple

```dart
// ✅ GOOD - Only primitive types
class LocationData {
  final double latitude;
  final double longitude;
}

// ❌ BAD - Still complex
class LocationData {
  final LatLng latLng;  // ❌ Still complex object
}
```

### 2. ✅ Implement Equality Operators

```dart
class LocationData {
  // ...fields...
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationData) return false;
    return latitude == other.latitude && 
           longitude == other.longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
```

### 3. ✅ Add Conversion Methods

```dart
class LocationData {
  final double latitude;
  final double longitude;
  
  const LocationData({
    required this.latitude,
    required this.longitude,
  });
  
  // ✅ Convert từ LatLng
  factory LocationData.fromLatLng(LatLng latLng) {
    return LocationData(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );
  }
  
  // ✅ Convert sang LatLng
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}
```

Usage:
```dart
// Convert khi navigate
final locationData = LocationData.fromLatLng(myLatLng);
context.router.push(MyRoute(location: locationData));

// Convert khi dùng
final latLng = locationData.toLatLng();
```

### 4. ✅ Document Wrapper Purpose

```dart
/// Wrapper class for LatLng to enable auto_route serialization.
/// 
/// Auto Route can't serialize complex objects like LatLng,
/// so we wrap lat/lng as primitive doubles.
/// 
/// Usage:
/// ```dart
/// // Old screen: Convert LatLng → LocationData
/// final data = LocationData.fromLatLng(latLng);
/// context.router.push(MyRoute(location: data));
/// 
/// // New screen: Convert LocationData → LatLng
/// final latLng = data.toLatLng();
/// ```
class LocationData {
  // ...
}
```

---

## 🐛 Troubleshooting

### Lỗi 1: "Cannot serialize LatLng"

**Nguyên nhân**: Truyền trực tiếp complex object

**Giải pháp**: Dùng wrapper class
```dart
// ❌ SAI
context.router.push(MyRoute(location: latLng));

// ✅ ĐÚNG
final data = LocationData.fromLatLng(latLng);
context.router.push(MyRoute(location: data));
```

### Lỗi 2: "The method 'navigateToFullNavigation' isn't defined"

**Nguyên nhân**: IDE cache chưa update

**Giải pháp**:
1. Restart IDE
2. Run `flutter pub get`
3. Hot restart app (not hot reload)

### Lỗi 3: "Router not generated with new parameters"

**Nguyên nhân**: Chưa run build_runner

**Giải pháp**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📊 Comparison Table

| Approach | Pros | Cons | Recommended |
|----------|------|------|-------------|
| **Pass LatLng directly** | Simple | ❌ Can't serialize | ❌ No |
| **Pass as Map** | Works | ⚠️ Not type-safe | ⚠️ Avoid |
| **Wrapper Class** | ✅ Type-safe<br>✅ Clean<br>✅ Serializable | Need extra class | ✅✅ Yes |
| **Pass ID, fetch later** | ✅ Always works | ⚠️ Need network call | ⭐ For DB objects |

---

## 🎓 Summary

### Vấn Đề
- Auto Route không thể serialize complex objects như `LatLng`

### Giải Pháp
- Tạo **wrapper class** (`LocationData`) với primitive types
- Convert trước khi navigate: `LatLng → LocationData`
- Convert sau khi nhận: `LocationData → LatLng`

### Benefits
- ✅ Type-safe routing
- ✅ Auto Route serialization works
- ✅ Clean architecture
- ✅ Easy to maintain

### Flow
```
LatLng → LocationData → Auto Route → LocationData → LatLng
(Internal) (Transfer)   (Serialize)  (Deserialize) (Use)
```

---

## 📚 Related Patterns

### 1. DTO Pattern (Data Transfer Object)
```dart
// Similar concept: Separate transfer object from domain object
class UserDTO {
  final String id;
  final String name;
  
  UserEntity toDomain() => UserEntity(...);
}
```

### 2. Adapter Pattern
```dart
// LocationData is an adapter between LatLng and Auto Route
class LocationDataAdapter {
  static LocationData fromLatLng(LatLng latLng) => ...;
  static LatLng toLatLng(LocationData data) => ...;
}
```

---

*Tài liệu được tạo: December 3, 2024*
*Pattern: Wrapper Class for Complex Object Serialization*
*Package: auto_route ^10.2.2*

