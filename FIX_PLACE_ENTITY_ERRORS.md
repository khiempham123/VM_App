# Hướng Dẫn Sửa Lỗi trong place_entity.dart

## 🐛 CÁC LỖI HIỆN TẠI

### Lỗi 1: Type Mismatch cho `boundaries`
**Dòng 28**: 
```dart
boundaries: BoundaryEntity.fromJson(json['boundaries'] as Map<String, dynamic>),
```

**Lỗi**: 
- Field `boundaries` được khai báo là `List<BoundaryEntity>`
- Nhưng đang gán giá trị `BoundaryEntity` (single object) từ `BoundaryEntity.fromJson()`
- Type không khớp: `BoundaryEntity` ≠ `List<BoundaryEntity>`

**Nguyên nhân**:
Theo API response mẫu:
```json
{
  "boundaries": [
    {
      "type": 2,
      "id": 18700,
      "name": "Chợ Quán",
      "prefix": "Phường",
      "full_name": "Phường Chợ Quán"
    },
    {
      "type": 0,
      "id": 12,
      "name": "Hồ Chí Minh",
      "prefix": "Thành Phố",
      "full_name": "Thành Phố Hồ Chí Minh"
    }
  ]
}
```
→ `boundaries` là một **Array** chứa nhiều objects, không phải 1 object đơn

---

### Lỗi 2: Type Mismatch cho `categories`
**Dòng 29**:
```dart
categories: json['categories'],
```

**Lỗi**:
- Field `categories` được khai báo là `List<String>`
- `json['categories']` trả về `dynamic`
- Cần cast sang `List<String>` hoặc xử lý null

**Nguyên nhân**:
API có thể trả về `[]` (empty array) hoặc `["market", "landmark"]`, cần xử lý casting

---

### Lỗi 3: Type Mismatch cho `entryPoints`
**Dòng 30**:
```dart
entryPoints: json['entryPoints'],
```

**Lỗi tương tự categories**:
- Field `entryPoints` khai báo là `List<EntryPointEntity>`
- `json['entryPoints']` trả về `dynamic` (có thể là array of objects)
- Cần parse từng item thành `EntryPointEntity`

---

### Lỗi 4: Định nghĩa sai `EntryPointEntity`
**Dòng 54-60**:
```dart
class EntryPointEntity {
  final int refId;
  final String name;

  EntryPointEntity({
    required this.refId,
    required this.name,
  });
}
```

**Lỗi**:
- Theo API response, `entry_points` là array rỗng `[]` hoặc chứa objects dạng:
  ```json
  {
    "latitude": 10.7722,
    "longitude": 106.6980,
    "type": "main"
  }
  ```
- Hiện tại khai báo `refId` và `name` là SAI
- Phải là `latitude`, `longitude`, `type`

---

### Lỗi 5: JSON Key Naming Convention
**Dòng 27**:
```dart
refId: json['refId'],
```

**Lỗi**:
- API response key là `ref_id` (snake_case)
- Code đang access `json['refId']` (camelCase)
- Sẽ trả về `null` → Runtime error

**Tương tự với**:
- `json['fullName']` → phải là `json['full_name']`

---

### Lỗi 6: Nullable Fields
**Dòng 3-9**:
```dart
final String refId;
final double distance;
final String address;
final String name;
final String display;
final List<BoundaryEntity> boundaries;
final List<String> categories;
```

**Lỗi**:
- Tất cả fields đang `required` và non-nullable
- Theo API response, một số fields có thể `null`:
  - `distance` có thể là `0` hoặc `null`
  - `categories` có thể empty array `[]`
  - `entry_points` có thể empty array `[]`

---

## ✅ CÁCH SỬA CHI TIẾT

### Bước 1: Vi phạm quy tắc Domain Layer

**VẤN ĐỀ NGHIÊM TRỌNG**: 
File `place_entity.dart` nằm trong **Domain Layer** nhưng đang có:
1. `factory PlaceEntity.fromJson()` → Đây là logic parsing, thuộc **Data Layer**
2. Entity không được phụ thuộc vào cấu trúc JSON của API

**THEO QUY TẮC CLEAN ARCHITECTURE**:
- ✅ Domain entities = Pure Dart objects, không có parsing logic
- ✅ Parsing JSON → DTO được xử lý trong Data Layer
- ✅ Conversion DTO → Entity thông qua extension methods

**GIẢI PHÁP**:
1. **XÓA** tất cả `factory fromJson()` khỏi `place_entity.dart`
2. Giữ entities thuần túy chỉ với constructors
3. Tạo DTOs trong Data Layer để handle JSON parsing

---

### Bước 2: Sửa `PlaceEntity`

**Thay thế toàn bộ class `PlaceEntity`** với code sau:

```dart
class PlaceEntity {
  final String refId;
  final String name;
  final String display;
  final String address;
  final double? distance;              // Nullable vì có thể không có
  final List<BoundaryEntity> boundaries;
  final List<String> categories;
  final List<EntryPointEntity> entryPoints;

  const PlaceEntity({
    required this.refId,
    required this.name,
    required this.display,
    required this.address,
    this.distance,                      // Optional
    required this.boundaries,
    required this.categories,
    required this.entryPoints,
  });

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
```

**THAY ĐỔI**:
- ✅ `distance` → nullable `double?`
- ✅ Constructor thành `const` (best practice)
- ✅ **XÓA** `factory fromJson()` (vi phạm Clean Architecture)
- ✅ Thêm getters `ward` và `city` để UI dễ dùng
- ✅ Sắp xếp fields theo thứ tự quan trọng

---

### Bước 3: Sửa `BoundaryEntity`

**Thay thế toàn bộ class `BoundaryEntity`**:

```dart
class BoundaryEntity {
  final int type;          // 0: City, 1: District, 2: Ward
  final int id;
  final String name;
  final String prefix;     // "Phường", "Quận", "Thành Phố"
  final String fullName;

  const BoundaryEntity({
    required this.type,
    required this.id,
    required this.name,
    required this.prefix,
    required this.fullName,
  });
}
```

**THAY ĐỔI**:
- ✅ **XÓA** `factory fromJson()`
- ✅ Constructor thành `const`
- ✅ Thêm comments giải thích `type` values

---

### Bước 4: Sửa `EntryPointEntity`

**Thay thế toàn bộ class `EntryPointEntity`**:

```dart
class EntryPointEntity {
  final double latitude;
  final double longitude;
  final String? type;      // "main", "side", etc. (optional)

  const EntryPointEntity({
    required this.latitude,
    required this.longitude,
    this.type,
  });
}
```

**THAY ĐỔI**:
- ❌ XÓA `refId` và `name` (không có trong API)
- ✅ THÊM `latitude`, `longitude`, `type`
- ✅ `type` nullable vì optional trong API
- ✅ Constructor thành `const`

---

### Bước 5: Thêm `PlaceDetailEntity` (Optional nhưng nên có)

**Thêm class mới** ở cuối file:

```dart
/// Entity mở rộng cho chi tiết địa điểm (khi gọi Place Detail API)
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

  const PlaceDetailEntity({
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
}
```

**LÝ DO**:
- Khi gọi Place Detail API, response có thêm nhiều fields
- Tránh tạo class mới, extend từ `PlaceEntity`
- Tất cả extended fields đều nullable

---

## 📝 CODE HOÀN CHỈNH SAU KHI SỬA

```dart
// filepath: lib/domain/entities/place_entity.dart

/// Entity đại diện cho một địa điểm từ Vietmap Place API
class PlaceEntity {
  final String refId;
  final String name;
  final String display;
  final String address;
  final double? distance;
  final List<BoundaryEntity> boundaries;
  final List<String> categories;
  final List<EntryPointEntity> entryPoints;

  const PlaceEntity({
    required this.refId,
    required this.name,
    required this.display,
    required this.address,
    this.distance,
    required this.boundaries,
    required this.categories,
    required this.entryPoints,
  });

  // Getters tiện ích
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

  const BoundaryEntity({
    required this.type,
    required this.id,
    required this.name,
    required this.prefix,
    required this.fullName,
  });
}

/// Entity đại diện cho entry point (điểm vào địa điểm)
class EntryPointEntity {
  final double latitude;
  final double longitude;
  final String? type;      // "main", "side", etc. (optional)

  const EntryPointEntity({
    required this.latitude,
    required this.longitude,
    this.type,
  });
}

/// Entity mở rộng cho chi tiết địa điểm
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

  const PlaceDetailEntity({
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
}
```

---

## 🔄 BỔ SUNG: CÁCH XỬ LÝ JSON PARSING (TRONG DATA LAYER)

Vì đã XÓA `fromJson()` khỏi entities, bạn cần tạo DTOs trong **Data Layer**:

### File: `lib/data/dto/place_dto.dart`

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:vm_first_app/domain/entities/place_entity.dart';

part 'place_dto.g.dart';

@JsonSerializable(createToJson: false)
class PlacePropertiesDto {
  @JsonKey(name: 'ref_id')           // ← Mapping snake_case
  final String refId;
  
  final String name;
  final String display;
  final String address;
  final double? distance;
  
  final List<BoundaryDto> boundaries;
  final List<String> categories;
  
  @JsonKey(name: 'entry_points')     // ← Mapping snake_case
  final List<EntryPointDto> entryPoints;

  PlacePropertiesDto({
    required this.refId,
    required this.name,
    required this.display,
    required this.address,
    this.distance,
    required this.boundaries,
    required this.categories,
    required this.entryPoints,
  });

  factory PlacePropertiesDto.fromJson(Map<String, dynamic> json) =>
      _$PlacePropertiesDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class BoundaryDto {
  final int type;
  final int id;
  final String name;
  final String prefix;
  
  @JsonKey(name: 'full_name')        // ← Mapping snake_case
  final String fullName;

  BoundaryDto({
    required this.type,
    required this.id,
    required this.name,
    required this.prefix,
    required this.fullName,
  });

  factory BoundaryDto.fromJson(Map<String, dynamic> json) =>
      _$BoundaryDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class EntryPointDto {
  final double latitude;
  final double longitude;
  final String? type;

  EntryPointDto({
    required this.latitude,
    required this.longitude,
    this.type,
  });

  factory EntryPointDto.fromJson(Map<String, dynamic> json) =>
      _$EntryPointDtoFromJson(json);
}

// Extension methods để convert DTO → Entity
extension PlacePropertiesDtoX on PlacePropertiesDto {
  PlaceEntity toEntity() {
    return PlaceEntity(
      refId: refId,
      name: name,
      display: display,
      address: address,
      distance: distance,
      boundaries: boundaries.map((b) => b.toEntity()).toList(),
      categories: categories,
      entryPoints: entryPoints.map((e) => e.toEntity()).toList(),
    );
  }
}

extension BoundaryDtoX on BoundaryDto {
  BoundaryEntity toEntity() {
    return BoundaryEntity(
      type: type,
      id: id,
      name: name,
      prefix: prefix,
      fullName: fullName,
    );
  }
}

extension EntryPointDtoX on EntryPointDto {
  EntryPointEntity toEntity() {
    return EntryPointEntity(
      latitude: latitude,
      longitude: longitude,
      type: type,
    );
  }
}
```

---

## 🎯 CHECKLIST SỬA LỖI

### ✅ Trong file `place_entity.dart`:
- [ ] XÓA tất cả `factory fromJson()` methods
- [ ] Sửa `distance` thành nullable `double?`
- [ ] Thêm `const` cho tất cả constructors
- [ ] Sửa `EntryPointEntity` với `latitude`, `longitude`, `type`
- [ ] Thêm getters `ward` và `city` cho `PlaceEntity`
- [ ] Thêm class `PlaceDetailEntity` extends `PlaceEntity`

### ✅ Tạo mới trong Data Layer:
- [ ] Tạo file `lib/data/dto/place_dto.dart`
- [ ] Tạo `PlacePropertiesDto` với `@JsonKey` annotations
- [ ] Tạo `BoundaryDto` với `@JsonKey` annotations
- [ ] Tạo `EntryPointDto`
- [ ] Tạo extension methods để convert DTO → Entity
- [ ] Chạy `fvm flutter pub run build_runner build --delete-conflicting-outputs`

---

## ⚠️ LƯU Ý QUAN TRỌNG

### 1. Tại sao XÓA `fromJson()` khỏi Entity?

**Theo Clean Architecture Rules**:
```
Domain Layer must not import from Data or Modules
Domain entities = Pure business objects
JSON parsing = Infrastructure concern → belongs to Data Layer
```

**Lợi ích**:
- ✅ Domain không phụ thuộc vào cấu trúc API (có thể đổi API mà không sửa domain)
- ✅ Testability tốt hơn (entities thuần túy dễ test)
- ✅ Tuân thủ Dependency Rule của Clean Architecture

### 2. JSON Key Mapping

API response dùng **snake_case**:
```json
{
  "ref_id": "...",
  "full_name": "...",
  "entry_points": []
}
```

DTO phải mapping:
```dart
@JsonKey(name: 'ref_id')
final String refId;

@JsonKey(name: 'full_name')
final String fullName;

@JsonKey(name: 'entry_points')
final List<EntryPointDto> entryPoints;
```

### 3. Handling Lists

Khi parse list từ JSON:
```dart
// ĐÚNG - sử dụng json_serializable
final List<BoundaryDto> boundaries;

// SAI - parse thủ công trong entity
boundaries: (json['boundaries'] as List)
    .map((e) => BoundaryEntity.fromJson(e))
    .toList(),
```

### 4. Nullable vs Required

**Luật chung**:
- Fields luôn có trong API response → `required`, non-nullable
- Fields có thể missing hoặc null → nullable `Type?`
- Lists có thể empty `[]` → non-nullable `List<T>` (empty list ≠ null)

---

## 🚀 NEXT STEPS

Sau khi sửa file `place_entity.dart`:

1. **Tạo DTOs trong Data Layer** (như hướng dẫn ở trên)
2. **Run build_runner** để generate parsing code:
   ```bash
   fvm flutter pub run build_runner build --delete-conflicting-outputs
   ```
3. **Tạo Repository & Service** theo PLACE_SEARCH_IMPLEMENTATION_GUIDE.md
4. **Test** với real API để verify JSON parsing

---

## 📚 TÀI LIỆU LIÊN QUAN

- **Clean Architecture Rules**: `Rules.md`
- **Full Implementation Guide**: `PLACE_SEARCH_IMPLEMENTATION_GUIDE.md`
- **Example Auth Entity** (tham khảo): `lib/domain/entities/auth_entity.dart`
- **Example DTO**: `lib/data/dto/auth_dto.dart`

