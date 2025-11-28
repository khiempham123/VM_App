# Hướng Dẫn Sửa Lỗi place_entity.dart (Giữ fromJson/toJson trong Entity)

## 📋 TỔNG QUAN

Bạn muốn xử lý `fromJson()` và `toJson()` trực tiếp trong entities (không qua DTOs). Đây là cách sửa các lỗi hiện tại:

---

## 🐛 CÁC LỖI CẦN SỬA

### Lỗi 1: Type Mismatch - `boundaries`
**Dòng 28**:
```dart
boundaries: BoundaryEntity.fromJson(json['boundaries'] as Map<String, dynamic>),
```

**Vấn đề**:
- API trả về `boundaries` là **Array** (List)
- Code đang parse như 1 object đơn
- Cần parse từng item trong array

**Sửa thành**:
```dart
boundaries: (json['boundaries'] as List<dynamic>)
    .map((item) => BoundaryEntity.fromJson(item as Map<String, dynamic>))
    .toList(),
```

---

### Lỗi 2: Type Mismatch - `categories`
**Dòng 29**:
```dart
categories: json['categories'],
```

**Vấn đề**:
- `json['categories']` trả về `dynamic`
- Cần cast sang `List<String>`

**Sửa thành**:
```dart
categories: (json['categories'] as List<dynamic>?)
    ?.map((item) => item as String)
    .toList() ?? [],
```

---

### Lỗi 3: Type Mismatch - `entryPoints`
**Dòng 30**:
```dart
entryPoints: json['entryPoints'],
```

**Vấn đề**:
- `json['entryPoints']` là array of objects
- Cần parse từng item thành `EntryPointEntity`

**Sửa thành**:
```dart
entryPoints: (json['entry_points'] as List<dynamic>?)
    ?.map((item) => EntryPointEntity.fromJson(item as Map<String, dynamic>))
    .toList() ?? [],
```

---

### Lỗi 4: JSON Key Naming (snake_case)
API response dùng **snake_case**, code đang dùng **camelCase**:

**Các key cần đổi**:
- `json['refId']` → `json['ref_id']`
- `json['fullName']` → `json['full_name']`
- `json['entryPoints']` → `json['entry_points']`

---

### Lỗi 5: Sai định nghĩa `EntryPointEntity`
**Hiện tại**:
```dart
class EntryPointEntity {
  final int refId;
  final String name;
}
```

**API thực tế**:
```json
{
  "latitude": 10.7722,
  "longitude": 106.6980,
  "type": "main"
}
```

**Phải đổi thành**:
```dart
class EntryPointEntity {
  final double latitude;
  final double longitude;
  final String? type;
}
```

---

### Lỗi 6: Nullable Fields
**Vấn đề**:
- `distance` có thể null trong response
- Cần đổi thành `double?`

---

## ✅ CODE HOÀN CHỈNH SAU KHI SỬA

```dart
// filepath: lib/domain/entities/place_entity.dart

/// Entity đại diện cho một địa điểm từ Vietmap Place API
class PlaceEntity {
  final String refId;
  final String name;
  final String display;
  final String address;
  final double? distance;                       // Nullable
  final List<BoundaryEntity> boundaries;
  final List<String> categories;
  final List<EntryPointEntity> entryPoints;

  PlaceEntity({
    required this.refId,
    required this.name,
    required this.display,
    required this.address,
    this.distance,
    required this.boundaries,
    required this.categories,
    required this.entryPoints,
  });

  /// Parse JSON từ API response
  factory PlaceEntity.fromJson(Map<String, dynamic> json) {
    return PlaceEntity(
      refId: json['ref_id'] as String,                    // snake_case
      name: json['name'] as String,
      display: json['display'] as String,
      address: json['address'] as String,
      distance: json['distance'] as double?,              // nullable
      
      // Parse boundaries array
      boundaries: (json['boundaries'] as List<dynamic>?)
          ?.map((item) => BoundaryEntity.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      
      // Parse categories array
      categories: (json['categories'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ?? [],
      
      // Parse entry_points array
      entryPoints: (json['entry_points'] as List<dynamic>?)  // snake_case
          ?.map((item) => EntryPointEntity.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Convert entity sang JSON
  Map<String, dynamic> toJson() {
    return {
      'ref_id': refId,
      'name': name,
      'display': display,
      'address': address,
      'distance': distance,
      'boundaries': boundaries.map((b) => b.toJson()).toList(),
      'categories': categories,
      'entry_points': entryPoints.map((e) => e.toJson()).toList(),
    };
  }

  // Getters tiện ích cho UI
  String? get ward => boundaries
      .where((b) => b.type == 2)
      .map((b) => b.fullName)
      .firstOrNull;

  String? get city => boundaries
      .where((b) => b.type == 0)
      .map((b) => b.fullName)
      .firstOrNull;
}

/// Entity đại diện cho boundary (địa giới hành chính)
class BoundaryEntity {
  final int type;          // 0: City, 1: District, 2: Ward
  final int id;
  final String name;
  final String prefix;     // "Phường", "Quận", "Thành Phố"
  final String fullName;

  BoundaryEntity({
    required this.type,
    required this.id,
    required this.name,
    required this.prefix,
    required this.fullName,
  });

  /// Parse JSON từ API response
  factory BoundaryEntity.fromJson(Map<String, dynamic> json) {
    return BoundaryEntity(
      type: json['type'] as int,
      id: json['id'] as int,
      name: json['name'] as String,
      prefix: json['prefix'] as String,
      fullName: json['full_name'] as String,      // snake_case
    );
  }

  /// Convert entity sang JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'prefix': prefix,
      'full_name': fullName,
    };
  }
}

/// Entity đại diện cho entry point (điểm vào địa điểm)
class EntryPointEntity {
  final double latitude;
  final double longitude;
  final String? type;      // "main", "side", etc. (optional)

  EntryPointEntity({
    required this.latitude,
    required this.longitude,
    this.type,
  });

  /// Parse JSON từ API response
  factory EntryPointEntity.fromJson(Map<String, dynamic> json) {
    return EntryPointEntity(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      type: json['type'] as String?,
    );
  }

  /// Convert entity sang JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
    };
  }
}

/// Entity mở rộng cho chi tiết địa điểm (Place Detail API)
class PlaceDetailEntity extends PlaceEntity {
  final String? phone;
  final String? website;
  final String? openingHours;
  final double? rating;
  final int? reviewCount;
  final String? street;
  final String? ward;
  final String? district;
  final String? city;

  PlaceDetailEntity({
    required super.refId,
    required super.name,
    required super.display,
    required super.address,
    super.distance,
    required super.boundaries,
    required super.categories,
    required super.entryPoints,
    this.phone,
    this.website,
    this.openingHours,
    this.rating,
    this.reviewCount,
    this.street,
    this.ward,
    this.district,
    this.city,
  });

  /// Parse JSON từ Place Detail API response
  factory PlaceDetailEntity.fromJson(Map<String, dynamic> json) {
    return PlaceDetailEntity(
      // Inherited fields
      refId: json['ref_id'] as String,
      name: json['name'] as String,
      display: json['display'] as String,
      address: json['address'] as String,
      distance: json['distance'] as double?,
      boundaries: (json['boundaries'] as List<dynamic>?)
          ?.map((item) => BoundaryEntity.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      categories: (json['categories'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ?? [],
      entryPoints: (json['entry_points'] as List<dynamic>?)
          ?.map((item) => EntryPointEntity.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      
      // Extended fields
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      openingHours: json['opening_hours'] as String?,
      rating: json['rating'] as double?,
      reviewCount: json['review_count'] as int?,
      street: json['street'] as String?,
      ward: json['ward'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
    );
  }

  /// Convert entity sang JSON
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'phone': phone,
      'website': website,
      'opening_hours': openingHours,
      'rating': rating,
      'review_count': reviewCount,
      'street': street,
      'ward': ward,
      'district': district,
      'city': city,
    });
    return json;
  }
}
```

---

## 🎯 CHECKLIST SỬA LỖI

### ✅ Trong `PlaceEntity.fromJson()`:
- [ ] Đổi `json['refId']` → `json['ref_id']`
- [ ] Đổi `json['entryPoints']` → `json['entry_points']`
- [ ] Thêm cast `as String`, `as double?`
- [ ] Sửa `boundaries`: parse từ List thay vì single object
- [ ] Sửa `categories`: cast sang `List<String>`
- [ ] Sửa `entryPoints`: parse từ List với fromJson
- [ ] Thêm `?? []` để handle null cho lists

### ✅ Trong `BoundaryEntity.fromJson()`:
- [ ] Đổi `json['fullName']` → `json['full_name']`
- [ ] Thêm cast `as int`, `as String`

### ✅ Trong `EntryPointEntity`:
- [ ] XÓA fields: `refId`, `name`
- [ ] THÊM fields: `latitude`, `longitude`, `type`
- [ ] Tạo `factory fromJson()` và `toJson()`

### ✅ Trong `PlaceEntity`:
- [ ] Đổi `distance` từ `double` → `double?`
- [ ] Thêm getters: `ward` và `city`
- [ ] Tạo method `toJson()`

### ✅ Thêm mới:
- [ ] Tạo class `PlaceDetailEntity` extends `PlaceEntity`
- [ ] Thêm các fields mở rộng (phone, website, rating, etc.)
- [ ] Implement `fromJson()` và `toJson()`

---

## 🔍 GIẢI THÍCH CHI TIẾT

### 1. Parse List từ JSON

**Khi API trả về array**:
```json
{
  "boundaries": [
    { "type": 2, "name": "..." },
    { "type": 0, "name": "..." }
  ]
}
```

**Cách parse đúng**:
```dart
boundaries: (json['boundaries'] as List<dynamic>?)  // Cast sang List
    ?.map((item) =>                                 // Map từng item
        BoundaryEntity.fromJson(item as Map<String, dynamic>))
    .toList() ?? [],                                // Convert sang List, default []
```

**Giải thích từng bước**:
1. `json['boundaries']` → `dynamic`
2. `as List<dynamic>?` → Cast sang List, nullable nếu key không tồn tại
3. `?.map(...)` → Nếu not null, map từng item
4. `item as Map<String, dynamic>` → Cast item sang Map để pass vào fromJson
5. `.toList()` → Convert Iterable sang List
6. `?? []` → Nếu null thì trả về empty list

### 2. Parse List String từ JSON

```json
{
  "categories": ["market", "landmark"]
}
```

**Cách parse**:
```dart
categories: (json['categories'] as List<dynamic>?)
    ?.map((item) => item as String)
    .toList() ?? [],
```

**Đơn giản hơn vì không cần fromJson**, chỉ cast từng item sang String.

### 3. Handle Nullable Fields

```dart
// Field có thể null trong response
final double? distance;

// Trong fromJson
distance: json['distance'] as double?,  // Cast với ? để allow null
```

### 4. Snake_case vs camelCase

**API dùng snake_case**:
- `ref_id`
- `full_name`
- `entry_points`
- `opening_hours`

**Dart dùng camelCase**:
- `refId`
- `fullName`
- `entryPoints`
- `openingHours`

**Trong fromJson phải map**:
```dart
refId: json['ref_id'],        // Read từ snake_case
fullName: json['full_name'],
```

**Trong toJson phải map ngược**:
```dart
'ref_id': refId,              // Write về snake_case
'full_name': fullName,
```

### 5. Inheritance với fromJson

**PlaceDetailEntity extends PlaceEntity**:
```dart
factory PlaceDetailEntity.fromJson(Map<String, dynamic> json) {
  return PlaceDetailEntity(
    // Phải parse lại tất cả inherited fields
    refId: json['ref_id'],
    name: json['name'],
    ...
    
    // Thêm extended fields
    phone: json['phone'],
    website: json['website'],
    ...
  );
}
```

**Không thể tái sử dụng `super.fromJson()`** vì constructors không được inherit.

---

## ⚠️ LƯU Ý QUAN TRỌNG

### 1. Type Safety với Casting

**LUÔN CAST** để tránh runtime errors:
```dart
// ĐÚNG
name: json['name'] as String,
distance: json['distance'] as double?,
boundaries: (json['boundaries'] as List<dynamic>?)

// SAI - không cast, có thể runtime error
name: json['name'],
distance: json['distance'],
```

### 2. Handle Null cho Lists

**Empty list ≠ null**:
```dart
// ĐÚNG - default empty list nếu null
categories: (json['categories'] as List<dynamic>?)?.map(...).toList() ?? [],

// SAI - có thể trả về null
categories: (json['categories'] as List<dynamic>?)?.map(...).toList(),
```

### 3. JSON Key Consistency

**Luôn nhất quán giữa fromJson và toJson**:
```dart
// fromJson
refId: json['ref_id']

// toJson
'ref_id': refId
```

### 4. Testing với Real API Data

Sau khi sửa, test với data thực:
```dart
final json = {
  "ref_id": "geocode:RAkPc...",
  "distance": 0,
  "address": "Phường Chợ Quán,Thành Phố Hồ Chí Minh",
  "name": "197 Trần Phú",
  "display": "197 Trần Phú Phường Chợ Quán,Thành Phố Hồ Chí Minh",
  "boundaries": [
    {
      "type": 2,
      "id": 18700,
      "name": "Chợ Quán",
      "prefix": "Phường",
      "full_name": "Phường Chợ Quán"
    }
  ],
  "categories": [],
  "entry_points": []
};

try {
  final place = PlaceEntity.fromJson(json);
  print('Success: ${place.name}');
} catch (e) {
  print('Error: $e');
}
```

---

## 🚀 NEXT STEPS

1. **Apply code vào file** `lib/domain/entities/place_entity.dart`
2. **Run app và test** với real API
3. **Kiểm tra logs** xem có runtime errors không
4. **Test edge cases**:
   - Response với `categories` = `[]`
   - Response với `entry_points` = `[]`
   - Response với `distance` = `null`
   - Response với missing fields

---

## 📚 TÀI LIỆU THAM KHẢO

- **API Response Sample**: Xem trong `PLACE_SEARCH_IMPLEMENTATION_GUIDE.md`
- **Dart Type Casting**: https://dart.dev/language/operators#type-test-operators
- **List Operations**: https://api.dart.dev/stable/dart-core/List-class.html

