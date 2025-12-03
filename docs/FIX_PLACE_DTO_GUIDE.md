# Hướng Dẫn Sửa Lỗi place_dto.dart

## 📊 PHÂN TÍCH DỮ LIỆU API THỰC TẾ

### Cấu trúc JSON từ API:
```json
[
  {
    "ref_id": "geocode:...",
    "distance": 0,                    // ← TYPE: number (int hoặc double)
    "address": "Phường Chợ Quán,Thành Phố Hồ Chí Minh",
    "name": "197 Trần Phú",
    "display": "197 Trần Phú Phường Chợ Quán,Thành Phố Hồ Chí Minh",
    "boundaries": [                   // ← ARRAY of objects
      {
        "type": 2,
        "id": 18700,
        "name": "Chợ Quán",
        "prefix": "Phường",
        "full_name": "Phường Chợ Quán"  // ← snake_case
      }
    ],
    "categories": [],                 // ← ARRAY of strings (có thể empty)
    "entry_points": [],               // ← ARRAY (thường empty)
    "data_old": null,                 // ← Fields không cần thiết
    "data_new": null,
    "partner_code": null
  }
]
```

### Quan sát quan trọng:
1. ✅ API trả về **ARRAY** chứa nhiều objects, không phải 1 object
2. ✅ `distance` là `number` (có thể int hoặc double), giá trị thường là `0`
3. ✅ `categories` là **array of strings**, có thể empty `[]` hoặc `["6001"]`
4. ✅ `entry_points` là **array**, thường empty `[]`
5. ✅ JSON keys dùng **snake_case**: `ref_id`, `full_name`, `entry_points`
6. ✅ Có các fields không cần thiết: `data_old`, `data_new`, `partner_code`

---

## 🐛 CÁC LỖI HIỆN TẠI TRONG place_dto.dart

### Lỗi 1: Sai Type cho `distance`
**Hiện tại:**
```dart
final double distance;
```

**Vấn đề:**
- API trả về `0` (int) hoặc có thể là float
- Cần dùng `num?` để accept cả int và double
- Phải nullable vì có thể không có

**Sửa thành:**
```dart
final num? distance;  // num accept cả int và double, nullable
```

---

### Lỗi 2: Type Casting không an toàn
**Hiện tại:**
```dart
distance: json['distance'],  // Không cast, có thể runtime error
```

**Sửa thành:**
```dart
distance: json['distance'] as num?,  // Type safe casting
```

---

### Lỗi 3: Không handle empty arrays
**Hiện tại:**
```dart
categories: (json['categories'] as List<dynamic>).map(...).toList(),
entryPoints: (json['entry_points'] as List<dynamic>).map(...).toList(),
```

**Vấn đề:**
- Nếu `json['categories']` là `null` → crash
- Không có fallback cho empty array

**Sửa thành:**
```dart
categories: (json['categories'] as List<dynamic>?)
    ?.map((item) => item as String)
    .toList() ?? [],  // Default empty list nếu null

entryPoints: (json['entry_points'] as List<dynamic>?)
    ?.map((item) => EntryPointDto.fromJson(item as Map<String, dynamic>))
    .toList() ?? [],
```

---

### Lỗi 4: EntryPointDto sai cấu trúc
**Hiện tại:**
```dart
class EntryPointDto {
  final int refId;     // ❌ API không có fields này
  final String name;   // ❌ API không có fields này
}
```

**Vấn đề:**
- API response: `"entry_points": []` (luôn empty)
- Không có `ref_id` hay `name` trong entry_points

**Giải pháp:**
```dart
/// DTO cho entry point (API thường trả về empty array)
class EntryPointDto {
  // API không có data cho entry_points trong response hiện tại
  // Giữ structure này để tương thích future-proof
  
  EntryPointDto();
  
  factory EntryPointDto.fromJson(Map<String, dynamic> json) => EntryPointDto();
}
```

---

### Lỗi 5: Extension methods sai cú pháp
**Hiện tại:**
```dart
extension PlaceDtoResponseX on PlaceDtoResponse {
  PlaceEntity toPlaceEntity() {  // ❌ Method name không consistent
    return PlaceEntity(
      boundaries: boundaries?.toEntity(),  // ❌ Gọi method trên List
      entryPoints: entryPoints?.toEntity(), // ❌ Gọi method trên List
    );
  }
}
```

**Vấn đề:**
1. Method name phải là `toEntity()` (theo pattern AuthResponseDto)
2. `boundaries` và `entryPoints` là `List`, không phải single object
3. Không thể gọi `.toEntity()` trên List

**Sửa thành:**
```dart
extension PlaceDtoResponseX on PlaceDtoResponse {
  PlaceEntity toEntity() {  // ✅ Consistent naming
    return PlaceEntity(
      refId: refId,
      distance: (distance ?? 0).toDouble(),  // Convert num? → double
      address: address,
      name: name,
      display: display,
      
      // Convert List<BoundaryDto> → List<BoundaryEntity>
      boundaries: boundaries.map((dto) => dto.toEntity()).toList(),
      
      categories: categories,
      
      // Convert List<EntryPointDto> → List<EntryPointEntity>
      entryPoints: entryPoints.map((dto) => dto.toEntity()).toList(),
    );
  }
}
```

---

### Lỗi 6: Thiếu type casting an toàn trong BoundaryDto
**Hiện tại:**
```dart
factory BoundaryDto.fromJson(Map<String, dynamic> json) => BoundaryDto(
  type: json['type'],          // ❌ Không cast
  id: json['id'],              // ❌ Không cast
  name: json['name'],          // ❌ Không cast
);
```

**Sửa thành:**
```dart
factory BoundaryDto.fromJson(Map<String, dynamic> json) => BoundaryDto(
  type: json['type'] as int,
  id: json['id'] as int,
  name: json['name'] as String,
  prefix: json['prefix'] as String,
  fullName: json['full_name'] as String,  // ✅ snake_case
);
```

---

### Lỗi 7: Thiếu comments giải thích
**Vấn đề:**
- Không có comments giải thích cấu trúc như `auth_dto.dart`
- Không giải thích tại sao tách BoundaryDto riêng
- Không giải thích extension methods

---

## ✅ CODE HOÀN CHỈNH SAU KHI SỬA

### File: `lib/data/dto/place_dto.dart`

```dart
import 'package:vm_first_app/domain/entities/place_entity.dart';

/// DTO cho request parameters của Vietmap Place Search API
/// 
/// **LƯU Ý:** DTO này dùng cho reference, không bắt buộc khi dùng Retrofit
/// vì Retrofit tự động convert query params với @Queries() annotation
/// 
/// **Khi nào cần PlaceDto:**
/// - Custom HTTP client không dùng Retrofit
/// - Logging/debugging request parameters
/// - Unit testing với mock data
class PlaceDto {
  final String apikey;
  final String? focus;
  final String text;
  final int? displayType;
  final int? cityId;
  final int? distId;
  final int? wardId;
  final String? circleCenter;
  final int? circleRadius;
  final String? cats;
  final String? layers;

  PlaceDto({
    required this.apikey,
    this.focus,
    required this.text,
    this.displayType,
    this.cityId,
    this.distId,
    this.wardId,
    this.circleCenter,
    this.circleRadius,
    this.cats,
    this.layers,
  });

  /// Convert sang Map để gửi lên API
  /// Chỉ include fields không null (if conditions)
  Map<String, dynamic> toJson() {
    return {
      'apikey': apikey,
      'text': text,
      if (focus != null) 'focus': focus,
      if (displayType != null) 'displayType': displayType,
      if (cityId != null) 'cityId': cityId,
      if (distId != null) 'distId': distId,
      if (wardId != null) 'wardId': wardId,
      if (circleCenter != null) 'circleCenter': circleCenter,
      if (circleRadius != null) 'circleRadius': circleRadius,
      if (cats != null) 'cats': cats,
      if (layers != null) 'layers': layers,
    };
  }
}

/// DTO cho boundary (địa giới hành chính) từ API
/// 
/// **Được parse từ nested array trong PlaceDtoResponse:**
/// ```json
/// "boundaries": [
///   {
///     "type": 2,              // 0: City, 1: District, 2: Ward
///     "id": 18700,
///     "name": "Chợ Quán",
///     "prefix": "Phường",
///     "full_name": "Phường Chợ Quán"
///   }
/// ]
/// ```
/// 
/// **Tại sao tách riêng BoundaryDto?**
/// - Boundary là nested array, xuất hiện trong nhiều API response
/// - Reusable: Dùng chung cho Search, Place Detail, Reverse Geocode APIs
/// - Single Responsibility: Chỉ parse boundary data
/// - Giống pattern UserDto trong auth_dto.dart
class BoundaryDto {
  final int type;          // 0: City, 1: District, 2: Ward
  final int id;
  final String name;
  final String prefix;     // "Phường", "Quận", "Thành Phố"
  final String fullName;

  BoundaryDto({
    required this.type,
    required this.id,
    required this.name,
    required this.prefix,
    required this.fullName,
  });

  /// Parse JSON từ API response
  /// 
  /// **Called by:** PlaceDtoResponse.fromJson() khi parse nested "boundaries"
  /// **Type Safety:** Cast tất cả fields để tránh runtime errors
  factory BoundaryDto.fromJson(Map<String, dynamic> json) {
    return BoundaryDto(
      type: json['type'] as int,
      id: json['id'] as int,
      name: json['name'] as String,
      prefix: json['prefix'] as String,
      fullName: json['full_name'] as String,  // ← snake_case từ API
    );
  }
}

/// DTO cho entry point (điểm vào địa điểm)
/// 
/// **API Response thực tế:** `"entry_points": []` (luôn empty)
/// 
/// **Tại sao giữ EntryPointDto?**
/// - Future-proof: API có thể thêm data sau này
/// - Tương thích với PlaceEntity structure
/// - Tránh breaking changes khi API update
/// 
/// **TODO:** Cập nhật fields khi API có data thực tế cho entry_points
class EntryPointDto {
  // API hiện tại không trả về data trong entry_points
  // Giữ empty constructor để parse empty array
  
  EntryPointDto();

  /// Parse JSON từ API response
  /// Hiện tại return empty object vì API không có data
  factory EntryPointDto.fromJson(Map<String, dynamic> json) {
    return EntryPointDto();
  }
}

/// DTO cho response từ Vietmap Place API
/// 
/// **Mapping với API response structure:**
/// ```json
/// {
///   "ref_id": "geocode:...",           // ← snake_case
///   "distance": 0,                     // ← number (int hoặc double)
///   "address": "Phường...",
///   "name": "197 Trần Phú",
///   "display": "197 Trần Phú...",
///   "boundaries": [...],               // ← nested array
///   "categories": ["6001"],            // ← array of strings (có thể empty)
///   "entry_points": []                 // ← array (thường empty)
/// }
/// ```
/// 
/// **Theo pattern AuthResponseDto:**
/// - DTOs có nullable fields để handle missing data
/// - Extension methods convert DTO → Entity
/// - Type casting an toàn với `as Type?`
/// - Default values cho nullable fields: `?? []`
class PlaceDtoResponse {
  final String refId;
  final num? distance;              // num accept cả int và double, nullable
  final String address;
  final String name;
  final String display;
  final List<BoundaryDto> boundaries;
  final List<String> categories;
  final List<EntryPointDto> entryPoints;

  PlaceDtoResponse({
    required this.refId,
    this.distance,                   // Optional vì có thể 0 hoặc null
    required this.address,
    required this.name,
    required this.display,
    required this.boundaries,
    required this.categories,
    required this.entryPoints,
  });

  /// Parse JSON từ API response
  /// 
  /// **Type Safety:**
  /// - Cast tất cả fields: `json['key'] as Type?`
  /// - Handle null cho arrays: `?? []`
  /// - Parse nested arrays với map()
  /// 
  /// **Called by:** Retrofit sau khi nhận HTTP response
  factory PlaceDtoResponse.fromJson(Map<String, dynamic> json) {
    return PlaceDtoResponse(
      // Parse primitive fields với type casting
      refId: json['ref_id'] as String,              // snake_case
      distance: json['distance'] as num?,           // num accept int & double
      address: json['address'] as String,
      name: json['name'] as String,
      display: json['display'] as String,
      
      // Parse boundaries array
      // Step 1: Cast sang List<dynamic>?, nullable nếu missing
      // Step 2: Nếu not null, map từng item qua BoundaryDto.fromJson()
      // Step 3: Convert Iterable → List với .toList()
      // Step 4: Nếu null, return empty list []
      boundaries: (json['boundaries'] as List<dynamic>?)
          ?.map((item) => BoundaryDto.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      
      // Parse categories array (có thể empty hoặc ["6001"])
      categories: (json['categories'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ?? [],
      
      // Parse entry_points array (thường empty)
      entryPoints: (json['entry_points'] as List<dynamic>?)
          ?.map((item) => EntryPointDto.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// Extension method: Convert PlaceDtoResponse (Data Layer) → PlaceEntity (Domain Layer)
/// 
/// **Theo pattern AuthResponseDtoX trong auth_dto.dart:**
/// - DTOs có nullable fields
/// - Entities yêu cầu non-nullable với default values
/// - Extension methods handle conversion logic
/// - Method name: `toEntity()` (consistent với codebase)
/// 
/// **Called by:** Repository.searchPlaces() sau khi nhận response từ API
/// ```dart
/// final response = await placeService.searchPlaces(dto);
/// return response.map((dto) => dto.toEntity()).toList();
/// ```
extension PlaceDtoResponseX on PlaceDtoResponse {
  PlaceEntity toEntity() {
    return PlaceEntity(
      refId: refId,
      
      // Convert num? → double với default 0
      // (distance ?? 0) = nếu null thì dùng 0
      // .toDouble() = convert sang double (entity yêu cầu double)
      distance: (distance ?? 0).toDouble(),
      
      address: address,
      name: name,
      display: display,
      
      // Convert List<BoundaryDto> → List<BoundaryEntity>
      // Không thể gọi boundaries.toEntity() vì boundaries là List
      // Phải map từng item: boundaries.map((dto) => dto.toEntity())
      boundaries: boundaries.map((dto) => dto.toEntity()).toList(),
      
      categories: categories,
      
      // Convert List<EntryPointDto> → List<EntryPointEntity>
      entryPoints: entryPoints.map((dto) => dto.toEntity()).toList(),
    );
  }
}

/// Extension method: Convert BoundaryDto → BoundaryEntity
/// 
/// **Simple mapping vì fields giống nhau**
/// **Called by:** PlaceDtoResponse.toEntity() khi convert boundaries
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

/// Extension method: Convert EntryPointDto → EntryPointEntity
/// 
/// **LƯU Ý:** API hiện tại không có data cho entry_points
/// Return entity với default values để tương thích
/// 
/// **TODO:** Cập nhật khi API có data thực tế
extension EntryPointDtoX on EntryPointDto {
  EntryPointEntity toEntity() {
    // Vì EntryPointDto empty, return entity với default values
    // Tương thích với PlaceEntity structure
    return EntryPointEntity(
      refId: 0,        // Default value
      name: '',        // Default value
    );
  }
}
```

---

## 🔄 SO SÁNH VỚI auth_dto.dart (REFERENCE)

### Similarities (Tuân thủ pattern):
| Aspect | auth_dto.dart | place_dto.dart |
|--------|---------------|----------------|
| **Nested objects** | `UserDto` trong `AuthResponseDto` | `BoundaryDto` trong `PlaceDtoResponse` |
| **Extension methods** | `AuthResponseDtoX`, `UserDtoX` | `PlaceDtoResponseX`, `BoundaryDtoX` |
| **Method name** | `.toEntity()` | `.toEntity()` |
| **Nullable handling** | `user?.toEntity() ?? UserEntity(...)` | `(distance ?? 0).toDouble()` |
| **Array parsing** | N/A (không có array) | `boundaries.map((dto) => dto.toEntity()).toList()` |
| **Type casting** | `json['id'] as String?` | `json['ref_id'] as String` |
| **Comments** | ✅ Chi tiết giải thích | ✅ Chi tiết giải thích |

### Key Differences:
1. **auth_dto.dart:** User là nested object → parse thành `UserDto`
2. **place_dto.dart:** Boundaries là nested **array** → parse thành `List<BoundaryDto>`

---

## 📝 CHECKLIST SỬA LỖI

### ✅ Trong PlaceDtoResponse:
- [ ] Đổi `final double distance` → `final num? distance`
- [ ] Thêm type casting: `json['distance'] as num?`
- [ ] Handle null cho arrays: `(json['boundaries'] as List<dynamic>?) ... ?? []`
- [ ] Đổi JSON keys: `json['ref_id']`, `json['entry_points']`
- [ ] Thêm comments giải thích structure

### ✅ Trong BoundaryDto:
- [ ] Thêm type casting cho tất cả fields
- [ ] Đổi `json['fullName']` → `json['full_name']`
- [ ] Thêm comments giải thích

### ✅ Trong EntryPointDto:
- [ ] XÓA fields: `refId`, `name` (API không có)
- [ ] Tạo empty constructor
- [ ] Tạo `fromJson()` return empty object
- [ ] Thêm comments giải thích

### ✅ Trong extension methods:
- [ ] Đổi method name: `toPlaceEntity()` → `toEntity()`
- [ ] Sửa `boundaries?.toEntity()` → `boundaries.map((dto) => dto.toEntity()).toList()`
- [ ] Sửa `entryPoints?.toEntity()` → `entryPoints.map((dto) => dto.toEntity()).toList()`
- [ ] Convert `num?` → `double`: `(distance ?? 0).toDouble()`
- [ ] Thêm comments giải thích

### ✅ Trong PlaceDto (optional):
- [ ] Thêm method `toJson()` với `if` conditions
- [ ] Thêm comments giải thích

---

## ⚠️ LƯU Ý QUAN TRỌNG

### 1. Type Casting là BẮT BUỘC
```dart
// SAI - không cast, có thể runtime error
distance: json['distance'],

// ĐÚNG - type safe
distance: json['distance'] as num?,
```

### 2. Handle Null cho Arrays
```dart
// SAI - crash nếu null
categories: (json['categories'] as List<dynamic>).map(...).toList(),

// ĐÚNG - default empty list
categories: (json['categories'] as List<dynamic>?)?.map(...).toList() ?? [],
```

### 3. Map List Đúng Cách
```dart
// SAI - gọi method trên List
boundaries: boundaries?.toEntity(),

// ĐÚNG - map từng item
boundaries: boundaries.map((dto) => dto.toEntity()).toList(),
```

### 4. Snake_case vs camelCase
```dart
// API response keys (snake_case)
json['ref_id']
json['full_name']
json['entry_points']

// Dart fields (camelCase)
final String refId;
final String fullName;
final List<EntryPointDto> entryPoints;
```

### 5. num vs int vs double
```dart
// num accept cả int và double
final num? distance;

// API có thể trả về:
"distance": 0        // ← int
"distance": 1.5      // ← double
"distance": null     // ← null
```

---

## 🚀 TESTING SAU KHI SỬA

### Test Case 1: Parse single response
```dart
final json = {
  "ref_id": "geocode:...",
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
  final dto = PlaceDtoResponse.fromJson(json);
  final entity = dto.toEntity();
  print('✅ Success: ${entity.name}');
  print('   Distance: ${entity.distance}');
  print('   Boundaries: ${entity.boundaries.length}');
  print('   Categories: ${entity.categories.length}');
} catch (e) {
  print('❌ Error: $e');
}
```

### Test Case 2: Parse array response
```dart
final jsonArray = [...]; // Full API response array

try {
  final dtoList = (jsonArray as List<dynamic>)
      .map((item) => PlaceDtoResponse.fromJson(item as Map<String, dynamic>))
      .toList();
  
  final entities = dtoList.map((dto) => dto.toEntity()).toList();
  
  print('✅ Parsed ${entities.length} places');
  entities.forEach((place) {
    print('   - ${place.name}');
  });
} catch (e) {
  print('❌ Error: $e');
}
```

### Test Case 3: Handle empty/null fields
```dart
final jsonWithNulls = {
  "ref_id": "geocode:...",
  "distance": null,           // ← null
  "address": "...",
  "name": "...",
  "display": "...",
  "boundaries": [],           // ← empty array
  "categories": null,         // ← null (should default to [])
  "entry_points": null        // ← null
};

try {
  final dto = PlaceDtoResponse.fromJson(jsonWithNulls);
  print('✅ Distance: ${dto.distance}');  // Should be null
  print('   Boundaries: ${dto.boundaries.length}');  // Should be 0
  print('   Categories: ${dto.categories.length}');  // Should be 0
} catch (e) {
  print('❌ Error: $e');
}
```

---

## 📚 TÀI LIỆU THAM KHẢO

- **Pattern reference:** `lib/data/dto/auth_dto.dart`
- **Repository pattern:** `lib/data/repository/auth_repository.dart`
- **Rules:** `Rules.md`
- **API data:** Dữ liệu thực tế được cung cấp ở đầu file này

---

## 🎯 TÓM TẮT

### Các lỗi chính cần sửa:
1. ❌ `distance` sai type (`double` → `num?`)
2. ❌ Thiếu type casting an toàn
3. ❌ Không handle null cho arrays
4. ❌ `EntryPointDto` sai structure
5. ❌ Extension methods sai cú pháp
6. ❌ Thiếu comments giải thích

### Sau khi sửa:
✅ Parse đúng cấu trúc API response  
✅ Handle null/empty arrays an toàn  
✅ Type casting đầy đủ  
✅ Extension methods đúng pattern  
✅ Comments chi tiết như auth_dto.dart  
✅ Tuân thủ 100% Rules.md  

### Commands cần chạy:
```bash
# Không cần build_runner vì không dùng json_serializable
# Chỉ cần hot reload
fvm flutter run
```

