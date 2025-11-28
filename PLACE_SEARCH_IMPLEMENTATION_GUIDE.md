# Hướng Dẫn Implementation Place Search Feature

## 📋 Tổng Quan

Dựa trên dữ liệu API trả về và kiến trúc Clean Architecture của dự án, đây là hướng dẫn chi tiết từng bước để implement tính năng tìm kiếm địa điểm (Place Search) sử dụng Vietmap Place API v4.

**API Endpoint**: `https://maps.vietmap.vn/api/autocomplete/v3` (hoặc `/api/search/v3`)

**Dữ liệu mẫu API trả về**:
```json
{
  "ref_id": "geocode:RAkPcicmZ3d-NQhac2kADHYlbFAkBiEeAQAkCV0EXwdFbESDiMNbEzMK9ogWVwJMBRgNBwdRFFZWBlIdAQZcCVcFUB5TDwNbAlYDClJSBQIdVQkkU0FHUA",
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
    },
    {
      "type": 0,
      "id": 12,
      "name": "Hồ Chí Minh",
      "prefix": "Thành Phố",
      "full_name": "Thành Phố Hồ Chí Minh"
    }
  ],
  "categories": [],
  "entry_points": [],
  "data_old": null,
  "data_new": null,
  "partner_code": null
}
```

---

## 🏗️ Kiến Trúc Clean Architecture - Luồng Dữ Liệu

```
┌─────────────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER (modules/)                                    │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ metro_map_screen.dart                                       │ │
│ │ - Search TextField với debounce                             │ │
│ │ - Hiển thị danh sách gợi ý                                  │ │
│ │ - Hiển thị marker trên map                                  │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                           ↓ (gọi methods)                        │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ metro_map_provider.dart (State Management)                  │ │
│ │ - searchPlaces(String query)                                │ │
│ │ - getPlaceDetail(String refId)                              │ │
│ │ - reverseGeocode(double lat, double lng)                    │ │
│ │ - Quản lý loading, error state                              │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓ (sử dụng Repository Interface)
┌─────────────────────────────────────────────────────────────────┐
│ DOMAIN LAYER (domain/)                                           │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ repository/place_repository.dart (Abstract Class)          │ │
│ │ abstract class PlaceRepository {                            │ │
│ │   Future<List<PlaceEntity>> searchPlaces(                  │ │
│ │     PlaceSearchRequest request                             │ │
│ │   );                                                         │ │
│ │   Future<PlaceDetailEntity> getPlaceDetail(String refId);  │ │
│ │   Future<PlaceEntity> reverseGeocode(                      │ │
│ │     ReverseGeocodeRequest request                          │ │
│ │   );                                                         │ │
│ │ }                                                            │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ entities/place_entity.dart (Domain Models)                  │ │
│ │ - PlaceEntity: Mô hình data cho UI                          │ │
│ │ - PlaceDetailEntity: Chi tiết địa điểm                      │ │
│ │ - BoundaryEntity: Thông tin địa giới                        │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ entities/place_request.dart (Request Models)                │ │
│ │ - PlaceSearchRequest: Params cho search                     │ │
│ │ - ReverseGeocodeRequest: Params cho reverse geocode        │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓ (implements)
┌─────────────────────────────────────────────────────────────────┐
│ DATA LAYER (data/)                                               │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ repository/place_repository_impl.dart                       │ │
│ │ class PlaceRepositoryImpl implements PlaceRepository {      │ │
│ │   final PlaceService placeService;                          │ │
│ │                                                              │ │
│ │   @override                                                  │ │
│ │   Future<List<PlaceEntity>> searchPlaces(request) async {  │ │
│ │     // B1: Convert Request → DTO                            │ │
│ │     final dto = PlaceSearchDto(                             │ │
│ │       text: request.query,                                  │ │
│ │       focus: request.focus,                                 │ │
│ │       ...                                                    │ │
│ │     );                                                       │ │
│ │                                                              │ │
│ │     // B2: Gọi API qua Service                              │ │
│ │     final response = await placeService.searchPlaces(dto); │ │
│ │                                                              │ │
│ │     // B3: Convert Response DTO → Entity                    │ │
│ │     return response.features                                │ │
│ │       .map((feature) => feature.toEntity())                 │ │
│ │       .toList();                                             │ │
│ │   }                                                          │ │
│ │ }                                                            │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                           ↓ (sử dụng)                            │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ services/place_service.dart (Retrofit Interface)            │ │
│ │ @RestApi()                                                   │ │
│ │ abstract class PlaceService {                               │ │
│ │   factory PlaceService(Dio dio, {String? baseUrl})          │ │
│ │     = _PlaceService;                                         │ │
│ │                                                              │ │
│ │   @GET('/api/autocomplete/v3')                              │ │
│ │   Future<PlaceSearchResponseDto> searchPlaces(              │ │
│ │     @Queries() PlaceSearchDto request                       │ │
│ │   );                                                         │ │
│ │                                                              │ │
│ │   @GET('/api/place/v3')                                     │ │
│ │   Future<PlaceDetailResponseDto> getPlaceDetail(            │ │
│ │     @Query('refid') String refId,                           │ │
│ │     @Query('apikey') String apiKey                          │ │
│ │   );                                                         │ │
│ │                                                              │ │
│ │   @GET('/api/reverse/v3')                                   │ │
│ │   Future<PlaceReverseResponseDto> reverseGeocode(           │ │
│ │     @Queries() ReverseGeocodeDto request                    │ │
│ │   );                                                         │ │
│ │ }                                                            │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                           ↓ (parse JSON)                         │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ dto/place_dto.dart (Data Transfer Objects)                  │ │
│ │ - PlaceSearchDto: Query params cho search                   │ │
│ │ - PlaceSearchResponseDto: Response wrapper                  │ │
│ │ - PlaceFeatureDto: Feature item từ API                      │ │
│ │ - PlacePropertiesDto: Properties của feature                │ │
│ │ - PlaceDetailResponseDto: Response chi tiết                 │ │
│ │ - ReverseGeocodeDto: Query params cho reverse               │ │
│ │ - BoundaryDto: Boundary object                              │ │
│ │                                                              │ │
│ │ Extension methods:                                           │ │
│ │ - extension PlaceFeatureDtoX on PlaceFeatureDto {           │ │
│ │     PlaceEntity toEntity() { ... }                          │ │
│ │   }                                                          │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📝 BƯỚC 1: CẬP NHẬT DOMAIN LAYER

### 1.1. Cập nhật `place_entity.dart`

**File**: `lib/domain/entities/place_entity.dart`

**Nhiệm vụ**: Bổ sung các entities để map với cấu trúc API response

**Cần tạo/cập nhật các classes**:

```dart
/// Entity chính đại diện cho 1 địa điểm từ API
class PlaceEntity {
  final String refId;           // ID duy nhất của địa điểm
  final String name;            // Tên địa điểm: "197 Trần Phú"
  final String display;         // Hiển thị đầy đủ: "197 Trần Phú Phường..."
  final String address;         // Địa chỉ ngắn
  final double? distance;       // Khoảng cách từ điểm focus (optional)
  final List<BoundaryEntity> boundaries;  // Danh sách địa giới
  final List<String> categories;          // Categories (có thể empty)
  final List<EntryPointEntity> entryPoints; // Điểm vào (có thể empty)
  
  // Getters tiện ích
  String? get ward => boundaries.firstWhereOrNull((b) => b.type == 2)?.fullName;
  String? get city => boundaries.firstWhereOrNull((b) => b.type == 0)?.fullName;
}

/// Entity cho boundary (địa giới hành chính)
class BoundaryEntity {
  final int type;          // 0: Thành phố, 1: Quận, 2: Phường
  final int id;            // ID của boundary
  final String name;       // Tên: "Chợ Quán"
  final String prefix;     // Tiền tố: "Phường"
  final String fullName;   // Tên đầy đủ: "Phường Chợ Quán"
}

/// Entity cho entry point (điểm vào - nếu có)
class EntryPointEntity {
  final double latitude;
  final double longitude;
  final String? type;
}

/// Entity chi tiết địa điểm (dùng khi gọi Place Detail API)
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
  
  // Constructor với super parameters
}
```

**Lưu ý tuân thủ quy tắc**:
- ✅ Pure Dart code, không import Flutter hoặc package bên ngoài
- ✅ Immutable classes (final fields)
- ✅ Constructor with named parameters
- ✅ Getters tiện ích cho UI

---

### 1.2. Cập nhật `place_request.dart`

**File**: `lib/domain/entities/place_request.dart`

**Nhiệm vụ**: Tạo request models cho các API calls

```dart
/// Request cho Search/Autocomplete API
class PlaceSearchRequest {
  final String query;           // Text tìm kiếm (bắt buộc)
  final String? focus;          // "lat,lng" - ưu tiên kết quả gần đây
  final String? circleCenter;   // "lat,lng" - tâm vòng tròn search
  final double? circleRadius;   // Bán kính (km)
  final int? limit;             // Số kết quả tối đa (default 10, max 50)
  final List<String>? categories; // Filter theo category
  final String? boundaries;     // Filter theo địa giới
  
  const PlaceSearchRequest({
    required this.query,
    this.focus,
    this.circleCenter,
    this.circleRadius,
    this.limit,
    this.categories,
    this.boundaries,
  });
}

/// Request cho Reverse Geocode API
class ReverseGeocodeRequest {
  final double latitude;
  final double longitude;
  
  const ReverseGeocodeRequest({
    required this.latitude,
    required this.longitude,
  });
}

/// Request cho Place Detail API
class PlaceDetailRequest {
  final String refId;
  
  const PlaceDetailRequest({required this.refId});
}
```

**Lưu ý tuân thủ quy tắc**:
- ✅ Chỉ chứa data, không có logic
- ✅ Const constructors cho immutability
- ✅ Named parameters với required/optional rõ ràng

---

### 1.3. Tạo `place_repository.dart`

**File**: `lib/domain/repository/place_repository.dart`

**Nhiệm vụ**: Định nghĩa contract (abstract class) cho Data Layer implement

```dart
import 'package:vm_first_app/domain/entities/place_entity.dart';
import 'package:vm_first_app/domain/entities/place_request.dart';

/// Repository interface cho Place/Map features
/// Data layer sẽ implement interface này
abstract class PlaceRepository {
  /// Tìm kiếm địa điểm với autocomplete
  /// Sử dụng cho search bar với gợi ý real-time
  /// 
  /// [request] chứa query text và các filter options
  /// Returns: Danh sách PlaceEntity gợi ý
  Future<List<PlaceEntity>> searchPlaces(PlaceSearchRequest request);
  
  /// Lấy thông tin chi tiết của 1 địa điểm
  /// Sử dụng khi user click vào 1 địa điểm trong danh sách
  /// 
  /// [request] chứa refId của địa điểm
  /// Returns: PlaceDetailEntity với đầy đủ thông tin
  Future<PlaceDetailEntity> getPlaceDetail(PlaceDetailRequest request);
  
  /// Chuyển đổi tọa độ thành địa chỉ
  /// Sử dụng khi user long-press trên map
  /// 
  /// [request] chứa latitude và longitude
  /// Returns: PlaceEntity với địa chỉ tương ứng
  Future<PlaceEntity> reverseGeocode(ReverseGeocodeRequest request);
}
```

**Lưu ý tuân thủ quy tắc**:
- ✅ Abstract class, không có implementation
- ✅ Chỉ import từ `domain/` (entities)
- ✅ Không import từ `data/` hay `modules/`
- ✅ Method signatures rõ ràng với documentation

---

## 📝 BƯỚC 2: TẠO DATA LAYER

### 2.1. Tạo DTOs

**File**: `lib/data/dto/place_dto.dart`

**Nhiệm vụ**: Tạo các DTO classes để parse JSON response từ API

**Cần tạo các classes**:

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:vm_first_app/domain/entities/place_entity.dart';

part 'place_dto.g.dart';

// ============== REQUEST DTOs ==============

/// DTO cho query parameters của Search/Autocomplete API
@JsonSerializable(createFactory: false)
class PlaceSearchDto {
  final String text;          // Query text
  final String? focus;        // "lat,lng"
  @JsonKey(name: 'circle_center')
  final String? circleCenter;
  @JsonKey(name: 'circle_radius')
  final double? circleRadius;
  final int? limit;
  final String? categories;   // Join categories với comma
  final String? boundaries;
  
  PlaceSearchDto({
    required this.text,
    this.focus,
    this.circleCenter,
    this.circleRadius,
    this.limit,
    this.categories,
    this.boundaries,
  });
  
  Map<String, dynamic> toJson() => _$PlaceSearchDtoToJson(this);
}

/// DTO cho query parameters của Reverse Geocode API
@JsonSerializable(createFactory: false)
class ReverseGeocodeDto {
  final double lat;
  final double lng;
  
  ReverseGeocodeDto({
    required this.lat,
    required this.lng,
  });
  
  Map<String, dynamic> toJson() => _$ReverseGeocodeDtoToJson(this);
}

// ============== RESPONSE DTOs ==============

/// DTO cho response wrapper (type: "FeatureCollection")
@JsonSerializable(createToJson: false)
class PlaceSearchResponseDto {
  final String type;                        // "FeatureCollection"
  final List<PlaceFeatureDto> features;     // Danh sách kết quả
  
  PlaceSearchResponseDto({
    required this.type,
    required this.features,
  });
  
  factory PlaceSearchResponseDto.fromJson(Map<String, dynamic> json) 
    => _$PlaceSearchResponseDtoFromJson(json);
}

/// DTO cho mỗi feature trong response
@JsonSerializable(createToJson: false)
class PlaceFeatureDto {
  final String type;                        // "Feature"
  final GeometryDto? geometry;              // Tọa độ (có thể null)
  final PlacePropertiesDto properties;      // Thông tin địa điểm
  
  PlaceFeatureDto({
    required this.type,
    this.geometry,
    required this.properties,
  });
  
  factory PlaceFeatureDto.fromJson(Map<String, dynamic> json) 
    => _$PlaceFeatureDtoFromJson(json);
}

/// DTO cho geometry (tọa độ)
@JsonSerializable(createToJson: false)
class GeometryDto {
  final String type;                  // "Point"
  final List<double> coordinates;     // [lng, lat] - CHÚ Ý thứ tự!
  
  GeometryDto({
    required this.type,
    required this.coordinates,
  });
  
  factory GeometryDto.fromJson(Map<String, dynamic> json) 
    => _$GeometryDtoFromJson(json);
  
  // Getters tiện ích
  double get longitude => coordinates[0];
  double get latitude => coordinates[1];
}

/// DTO cho properties của địa điểm (match với API response)
@JsonSerializable(createToJson: false)
class PlacePropertiesDto {
  @JsonKey(name: 'ref_id')
  final String refId;
  final String name;
  final String display;
  final String address;
  final double? distance;
  final List<BoundaryDto> boundaries;
  final List<String> categories;
  @JsonKey(name: 'entry_points')
  final List<EntryPointDto> entryPoints;
  
  // Các trường cho Place Detail (optional)
  final String? phone;
  final String? website;
  @JsonKey(name: 'opening_hours')
  final String? openingHours;
  final double? rating;
  @JsonKey(name: 'review_count')
  final int? reviewCount;
  final String? street;
  final String? ward;
  final String? district;
  final String? city;
  
  PlacePropertiesDto({
    required this.refId,
    required this.name,
    required this.display,
    required this.address,
    this.distance,
    required this.boundaries,
    required this.categories,
    required this.entryPoints,
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
  
  factory PlacePropertiesDto.fromJson(Map<String, dynamic> json) 
    => _$PlacePropertiesDtoFromJson(json);
}

/// DTO cho boundary object
@JsonSerializable(createToJson: false)
class BoundaryDto {
  final int type;
  final int id;
  final String name;
  final String prefix;
  @JsonKey(name: 'full_name')
  final String fullName;
  
  BoundaryDto({
    required this.type,
    required this.id,
    required this.name,
    required this.prefix,
    required this.fullName,
  });
  
  factory BoundaryDto.fromJson(Map<String, dynamic> json) 
    => _$BoundaryDtoFromJson(json);
}

/// DTO cho entry point
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
  
  factory EntryPointDto.fromJson(Map<String, dynamic> json) 
    => _$EntryPointDtoFromJson(json);
}

// ============== EXTENSION METHODS (DTO → Entity) ==============

/// Extension để convert PlaceFeatureDto → PlaceEntity
extension PlaceFeatureDtoX on PlaceFeatureDto {
  PlaceEntity toEntity() {
    return PlaceEntity(
      refId: properties.refId,
      name: properties.name,
      display: properties.display,
      address: properties.address,
      distance: properties.distance,
      boundaries: properties.boundaries.map((b) => b.toEntity()).toList(),
      categories: properties.categories,
      entryPoints: properties.entryPoints.map((e) => e.toEntity()).toList(),
    );
  }
  
  /// Convert sang PlaceDetailEntity (khi có thêm thông tin)
  PlaceDetailEntity toDetailEntity() {
    return PlaceDetailEntity(
      refId: properties.refId,
      name: properties.name,
      display: properties.display,
      address: properties.address,
      distance: properties.distance,
      boundaries: properties.boundaries.map((b) => b.toEntity()).toList(),
      categories: properties.categories,
      entryPoints: properties.entryPoints.map((e) => e.toEntity()).toList(),
      phone: properties.phone,
      website: properties.website,
      openingHours: properties.openingHours,
      rating: properties.rating,
      reviewCount: properties.reviewCount,
      street: properties.street,
      ward: properties.ward,
      district: properties.district,
      city: properties.city,
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

**Lưu ý tuân thủ quy tắc**:
- ✅ DTOs nằm trong `data/dto/`
- ✅ Sử dụng `@JsonSerializable` để auto-generate code
- ✅ Extension methods để convert DTO → Entity
- ✅ DTOs không được leak vào domain/UI

**Sau khi tạo file, cần chạy**:
```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 2.2. Tạo Retrofit Service

**File**: `lib/data/services/place_service.dart`

**Nhiệm vụ**: Định nghĩa Retrofit interface cho API calls

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vm_first_app/data/dto/place_dto.dart';

part 'place_service.g.dart';

@RestApi()
abstract class PlaceService {
  factory PlaceService(Dio dio, {String? baseUrl}) = _PlaceService;
  
  /// Search/Autocomplete API
  /// GET https://maps.vietmap.vn/api/autocomplete/v3
  @GET('/api/autocomplete/v3')
  Future<PlaceSearchResponseDto> searchPlaces(
    @Queries() PlaceSearchDto request,
  );
  
  /// Place Detail API
  /// GET https://maps.vietmap.vn/api/place/v3
  @GET('/api/place/v3')
  Future<PlaceFeatureDto> getPlaceDetail(
    @Query('refid') String refId,
  );
  
  /// Reverse Geocode API
  /// GET https://maps.vietmap.vn/api/reverse/v3
  @GET('/api/reverse/v3')
  Future<PlaceFeatureDto> reverseGeocode(
    @Queries() ReverseGeocodeDto request,
  );
}
```

**Lưu ý tuân thủ quy tắc**:
- ✅ Abstract class với factory constructor
- ✅ Sử dụng `@Queries()` cho multiple query params
- ✅ Sử dụng `@Query()` cho single param
- ✅ Generated file `.g.dart` sẽ nằm cùng folder

**Sau khi tạo file, cần chạy**:
```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 2.3. Implement Repository

**File**: `lib/data/repository/place_repository_impl.dart`

**Nhiệm vụ**: Implement PlaceRepository interface từ domain

```dart
import 'package:vm_first_app/data/dto/place_dto.dart';
import 'package:vm_first_app/data/services/place_service.dart';
import 'package:vm_first_app/domain/entities/place_entity.dart';
import 'package:vm_first_app/domain/entities/place_request.dart';
import 'package:vm_first_app/domain/repository/place_repository.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceService placeService;
  
  PlaceRepositoryImpl(this.placeService);
  
  @override
  Future<List<PlaceEntity>> searchPlaces(PlaceSearchRequest request) async {
    // B1: Convert Domain Request → DTO
    final dto = PlaceSearchDto(
      text: request.query,
      focus: request.focus,
      circleCenter: request.circleCenter,
      circleRadius: request.circleRadius,
      limit: request.limit,
      // Join categories list thành string: ["cafe", "restaurant"] → "cafe,restaurant"
      categories: request.categories?.join(','),
      boundaries: request.boundaries,
    );
    
    // B2: Gọi API qua Service
    // Retrofit auto-parse JSON response → PlaceSearchResponseDto
    final response = await placeService.searchPlaces(dto);
    
    // B3: Convert DTO → Entity
    // Sử dụng extension method PlaceFeatureDtoX.toEntity()
    return response.features
        .map((feature) => feature.toEntity())
        .toList();
  }
  
  @override
  Future<PlaceDetailEntity> getPlaceDetail(PlaceDetailRequest request) async {
    // B1: Gọi API với refId
    final response = await placeService.getPlaceDetail(request.refId);
    
    // B2: Convert DTO → PlaceDetailEntity
    // Sử dụng extension method toDetailEntity() vì cần thêm thông tin
    return response.toDetailEntity();
  }
  
  @override
  Future<PlaceEntity> reverseGeocode(ReverseGeocodeRequest request) async {
    // B1: Convert Domain Request → DTO
    final dto = ReverseGeocodeDto(
      lat: request.latitude,
      lng: request.longitude,
    );
    
    // B2: Gọi API
    final response = await placeService.reverseGeocode(dto);
    
    // B3: Convert DTO → Entity
    return response.toEntity();
  }
}
```

**Lưu ý tuân thủ quy tắc**:
- ✅ File name: `place_repository_impl.dart` (suffix `_impl`)
- ✅ Class name: `PlaceRepositoryImpl`
- ✅ Chỉ import từ `data/` và `domain/`
- ✅ Không có business logic, chỉ convert data

---

### 2.4. Cấu hình Base URL cho Vietmap API

**File**: `lib/core/network/http_client.dart`

**Nhiệm vụ**: Thêm Vietmap API base URL và API key

**Cần cập nhật**:

```dart
class HttpClient {
  // Existing base URL cho backend
  static const String _baseUrl = 'https://dricon.fastmap.vn';
  
  // Thêm base URL cho Vietmap API
  static const String _vietmapBaseUrl = 'https://maps.vietmap.vn';
  
  // Thêm API key (lấy từ Vietmap Console)
  static const String _vietmapApiKey = 'YOUR_VIETMAP_API_KEY_HERE';
  
  late final Dio _dio;
  late final Dio _vietmapDio; // Dio instance riêng cho Vietmap
  
  Dio get dio => _dio;
  Dio get vietmapDio => _vietmapDio;
  
  HttpClient() {
    // Existing Dio for backend
    _dio = Dio(BaseOptions(...));
    
    // Tạo Dio instance riêng cho Vietmap API
    _vietmapDio = Dio(
      BaseOptions(
        baseUrl: _vietmapBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
      ),
    );
    
    // Interceptor để tự động thêm API key vào query params
    _vietmapDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Thêm apikey vào query parameters
          options.queryParameters['apikey'] = _vietmapApiKey;
          return handler.next(options);
        },
      ),
    );
    
    // Thêm logging interceptor
    _vietmapDio.interceptors.add(LoggingInterceptor());
    // Thêm curl interceptor để debug
    _vietmapDio.interceptors.add(CurlInterceptor());
  }
}
```

**Lưu ý**:
- ⚠️ Vietmap API **KHÔNG** cần Authorization header
- ⚠️ Chỉ cần `apikey` trong query parameters
- ✅ Tạo Dio instance riêng để tránh conflict với backend API

---

## 📝 BƯỚC 3: ĐĂNG KÝ DEPENDENCIES

**File**: `lib/core/dependencies/app_repository.dart`

**Nhiệm vụ**: Register PlaceService và PlaceRepository vào Dependency Injection

```dart
void registerServices() {
  // Existing services
  locator.registerLazySingleton(
    () => AuthService(locator<HttpClient>().dio),
  );
  
  // Thêm PlaceService - SỬ DỤNG vietmapDio
  locator.registerLazySingleton(
    () => PlaceService(locator<HttpClient>().vietmapDio),
  );
}

void registerRepositories() {
  // Existing repositories
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(locator(), locator()),
  );
  
  // Thêm PlaceRepository
  locator.registerLazySingleton<PlaceRepository>(
    () => PlaceRepositoryImpl(locator()),
  );
}
```

**Lưu ý tuân thủ quy tắc**:
- ✅ Service đăng ký trước Repository
- ✅ Repository phụ thuộc vào Service thông qua `locator()`
- ✅ Sử dụng `registerLazySingleton` để tạo instance khi cần

---

## 📝 BƯỚC 4: CẬP NHẬT PRESENTATION LAYER

### 4.1. Cập nhật `metro_map_provider.dart`

**File**: `lib/modules/metro_go/metro_map_provider.dart`

**Nhiệm vụ**: Thêm state management cho place search

```dart
import 'package:flutter/foundation.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/domain/domain.dart';

class MetroMapProvider extends ChangeNotifier {
  final PlaceRepository _placeRepo = locator<PlaceRepository>();
  
  // ========== STATE VARIABLES ==========
  
  // Danh sách kết quả search
  List<PlaceEntity> _searchResults = [];
  List<PlaceEntity> get searchResults => _searchResults;
  
  // Loading states
  bool _isSearching = false;
  bool get isSearching => _isSearching;
  
  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;
  
  // Selected place
  PlaceDetailEntity? _selectedPlace;
  PlaceDetailEntity? get selectedPlace => _selectedPlace;
  
  // Error state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // ========== SEARCH METHODS ==========
  
  /// Tìm kiếm địa điểm với query text
  /// Sử dụng debounce trong UI để tránh gọi API liên tục
  Future<void> searchPlaces({
    required String query,
    String? focus,  // "lat,lng" - ưu tiên kết quả gần điểm này
    double? circleRadius,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final request = PlaceSearchRequest(
        query: query,
        focus: focus,
        circleRadius: circleRadius,
        limit: limit,
      );
      
      _searchResults = await _placeRepo.searchPlaces(request);
    } catch (e) {
      _errorMessage = 'Lỗi tìm kiếm: ${e.toString()}';
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  
  /// Lấy chi tiết 1 địa điểm
  /// Gọi khi user click vào item trong danh sách search
  Future<void> getPlaceDetail(String refId) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final request = PlaceDetailRequest(refId: refId);
      _selectedPlace = await _placeRepo.getPlaceDetail(request);
    } catch (e) {
      _errorMessage = 'Lỗi tải chi tiết: ${e.toString()}';
      _selectedPlace = null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }
  
  /// Chuyển tọa độ thành địa chỉ
  /// Gọi khi user long-press trên map
  Future<PlaceEntity?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final request = ReverseGeocodeRequest(
        latitude: latitude,
        longitude: longitude,
      );
      
      return await _placeRepo.reverseGeocode(request);
    } catch (e) {
      _errorMessage = 'Lỗi reverse geocode: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _selectedPlace = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

**Lưu ý tuân thủ quy tắc**:
- ✅ Provider chỉ import từ `domain/`, không import từ `data/`
- ✅ Sử dụng Repository interface qua dependency injection
- ✅ Quản lý loading, error states rõ ràng
- ✅ notifyListeners() sau mỗi state change

---

### 4.2. Cập nhật UI trong `metro_map_screen.dart`

**File**: `lib/modules/metro_go/metro_map_screen.dart`

**Nhiệm vụ**: Thêm UI components cho search feature

**Cần thêm các components**:

#### A. Search TextField với Debounce

```dart
// Trong State class
Timer? _debounce;

Widget _buildSearchBar() {
  return TextField(
    decoration: InputDecoration(
      hintText: 'Tìm kiếm địa điểm...',
      prefixIcon: Icon(Icons.search),
      suffixIcon: context.watch<MetroMapProvider>().isSearching
          ? CircularProgressIndicator()
          : IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                context.read<MetroMapProvider>().clearSearch();
              },
            ),
    ),
    controller: _searchController,
    onChanged: (value) {
      // Cancel previous timer
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      
      // Start new timer (500ms delay)
      _debounce = Timer(const Duration(milliseconds: 500), () {
        // Lấy vị trí hiện tại của map để làm focus point
        final center = _mapController?.cameraPosition?.target;
        final focus = center != null 
            ? '${center.latitude},${center.longitude}' 
            : null;
        
        context.read<MetroMapProvider>().searchPlaces(
          query: value,
          focus: focus,
          circleRadius: 5.0, // 5km radius
        );
      });
    },
  );
}

@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

#### B. Dropdown hiển thị kết quả search

```dart
Widget _buildSearchResults() {
  final provider = context.watch<MetroMapProvider>();
  
  if (provider.searchResults.isEmpty) {
    return SizedBox.shrink();
  }
  
  return Container(
    height: 300,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: ListView.builder(
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final place = provider.searchResults[index];
        return ListTile(
          leading: Icon(Icons.location_on),
          title: Text(place.name),
          subtitle: Text(place.address),
          trailing: place.distance != null
              ? Text('${place.distance!.toStringAsFixed(1)} km')
              : null,
          onTap: () async {
            // Di chuyển map đến vị trí địa điểm
            // CHÚ Ý: Cần lấy tọa độ từ geometry
            // (Chưa có trong entity hiện tại, cần bổ sung)
            
            // Load chi tiết địa điểm
            await provider.getPlaceDetail(place.refId);
            
            // Hiển thị bottom sheet
            _showPlaceDetailBottomSheet(context);
            
            // Clear search
            _searchController.clear();
            provider.clearSearch();
          },
        );
      },
    ),
  );
}
```

#### C. Bottom Sheet hiển thị chi tiết

```dart
void _showPlaceDetailBottomSheet(BuildContext context) {
  final provider = context.read<MetroMapProvider>();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Consumer<MetroMapProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingDetail) {
            return Container(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          final place = provider.selectedPlace;
          if (place == null) {
            return Container(
              height: 200,
              child: Center(child: Text('Không có dữ liệu')),
            );
          }
          
          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên địa điểm
                Text(
                  place.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                
                // Địa chỉ
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16),
                    SizedBox(width: 4),
                    Expanded(child: Text(place.display)),
                  ],
                ),
                
                // Số điện thoại (nếu có)
                if (place.phone != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16),
                      SizedBox(width: 4),
                      Text(place.phone!),
                    ],
                  ),
                ],
                
                // Website (nếu có)
                if (place.website != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.web, size: 16),
                      SizedBox(width: 4),
                      Expanded(child: Text(place.website!)),
                    ],
                  ),
                ],
                
                // Giờ mở cửa (nếu có)
                if (place.openingHours != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16),
                      SizedBox(width: 4),
                      Text(place.openingHours!),
                    ],
                  ),
                ],
                
                // Rating (nếu có)
                if (place.rating != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('${place.rating} (${place.reviewCount} reviews)'),
                    ],
                  ),
                ],
                
                SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.directions),
                        label: Text('Chỉ đường'),
                        onPressed: () {
                          // TODO: Implement navigation
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.favorite_border),
                        label: Text('Yêu thích'),
                        onPressed: () {
                          // TODO: Implement favorite
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
```

#### D. Handle map long-press (Reverse Geocode)

```dart
// Trong VietmapGL Map widget
VietmapGL(
  onMapLongClick: (point, latLng) async {
    final provider = context.read<MetroMapProvider>();
    
    // Gọi reverse geocode
    final place = await provider.reverseGeocode(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );
    
    if (place != null) {
      // Hiển thị marker tại vị trí
      // Hiển thị tooltip với địa chỉ
      _showAddressTooltip(place);
    }
  },
  // ... other properties
)
```

---

## 📝 BƯỚC 5: TESTING & DEBUGGING

### 5.1. Checklist Testing

**Test Cases cần thực hiện**:

1. **Test Search API**
   ```dart
   // Trong provider hoặc repository test
   final request = PlaceSearchRequest(
     query: 'bến thành',
     limit: 5,
   );
   final results = await placeRepo.searchPlaces(request);
   print('Found ${results.length} places');
   results.forEach((place) {
     print('- ${place.name}: ${place.address}');
   });
   ```

2. **Test Place Detail API**
   ```dart
   final request = PlaceDetailRequest(
     refId: 'geocode:RAkPcicmZ3d-NQhac2kADHYlbFAkBiEeAQAkCV0EXwdFbESDiMNbEzMK9ogWVwJMBRgNBwdRFFZWBlIdAQZcCVcFUB5TDwNbAlYDClJSBQIdVQkkU0FHUA',
   );
   final detail = await placeRepo.getPlaceDetail(request);
   print('Place: ${detail.name}');
   print('Phone: ${detail.phone}');
   print('Rating: ${detail.rating}');
   ```

3. **Test Reverse Geocode API**
   ```dart
   final request = ReverseGeocodeRequest(
     latitude: 10.7722,
     longitude: 106.6980,
   );
   final place = await placeRepo.reverseGeocode(request);
   print('Address: ${place.display}');
   ```

### 5.2. Debug với CURL

Kiểm tra request bằng CURL interceptor:

```bash
# Nếu thấy log:
# unable to create a CURL representation of the requestOptions

# Nghĩa là:
# - Query params chưa đúng
# - Base URL chưa đúng
# - Thiếu apikey

# Cần kiểm tra:
1. HttpClient.vietmapDio đã được init đúng chưa
2. Interceptor đã thêm apikey vào query params chưa
3. PlaceService đã sử dụng vietmapDio chưa
```

### 5.3. Xử lý lỗi phổ biến

**Lỗi 1: Missing apikey**
```
Solution: Kiểm tra Interceptor trong HttpClient
```

**Lỗi 2: DTO parsing error**
```
Solution: 
- Chạy lại build_runner
- Kiểm tra @JsonKey annotations
- Kiểm tra nullable fields
```

**Lỗi 3: coordinates null**
```
Solution: 
- Bổ sung geometry field vào PlaceEntity
- Map coordinates từ GeometryDto
```

---

## 📝 BƯỚC 6: BỔ SUNG (OPTIONAL)

### 6.1. Lưu lịch sử tìm kiếm

**File**: `lib/data/database/search_history_dao.dart`

```dart
// Sử dụng Hive hoặc SQLite
class SearchHistoryDao {
  Future<void> saveSearchQuery(String query);
  Future<List<String>> getRecentSearches({int limit = 10});
  Future<void> clearHistory();
}
```

### 6.2. Lưu địa điểm yêu thích

**File**: `lib/data/database/favorite_place_dao.dart`

```dart
class FavoritePlaceDao {
  Future<void> addFavorite(PlaceEntity place);
  Future<void> removeFavorite(String refId);
  Future<List<PlaceEntity>> getAllFavorites();
  Future<bool> isFavorite(String refId);
}
```

### 6.3. Hiển thị marker trên map

```dart
// Trong MetroMapProvider
Future<void> addPlaceMarker(PlaceEntity place) async {
  // Cần có coordinates từ place
  await _mapController?.addSymbol(
    SymbolOptions(
      geometry: LatLng(place.latitude, place.longitude),
      iconImage: 'place-marker',
      textField: place.name,
      textOffset: Offset(0, 1.5),
    ),
  );
}
```

---

## 🎯 TÓM TẮT CHECKLIST

### ✅ Domain Layer
- [ ] Cập nhật `place_entity.dart` với PlaceEntity, BoundaryEntity, EntryPointEntity, PlaceDetailEntity
- [ ] Cập nhật `place_request.dart` với PlaceSearchRequest, ReverseGeocodeRequest, PlaceDetailRequest
- [ ] Tạo `place_repository.dart` (abstract class)

### ✅ Data Layer
- [ ] Tạo `place_dto.dart` với tất cả DTOs và extension methods
- [ ] Tạo `place_service.dart` (Retrofit interface)
- [ ] Tạo `place_repository_impl.dart`
- [ ] Chạy `build_runner` để generate code
- [ ] Cập nhật `http_client.dart` với vietmapDio và apikey interceptor

### ✅ Dependencies
- [ ] Đăng ký PlaceService trong `registerServices()`
- [ ] Đăng ký PlaceRepository trong `registerRepositories()`

### ✅ Presentation Layer
- [ ] Cập nhật `metro_map_provider.dart` với search methods
- [ ] Cập nhật `metro_map_screen.dart` với UI components:
  - Search TextField với debounce
  - Dropdown kết quả search
  - Bottom sheet chi tiết
  - Map long-press handler

### ✅ Testing
- [ ] Test Search API
- [ ] Test Place Detail API
- [ ] Test Reverse Geocode API
- [ ] Kiểm tra CURL logs
- [ ] Xử lý error cases

---

## 🔧 COMMANDS CẦN CHẠY

```bash
# 1. Generate DTOs và Services
fvm flutter pub run build_runner build --delete-conflicting-outputs

# 2. Kiểm tra errors
fvm flutter analyze

# 3. Run app
fvm flutter run
```

---

## 📚 TÀI LIỆU THAM KHẢO

- **Vietmap Place API Docs**: https://maps.vietmap.vn/docs/map-api/place-v4/
- **Clean Architecture Rules**: `Rules.md`
- **Existing Auth Flow**: `lib/data/repository/auth_repository.dart`
- **Provider Pattern**: `lib/modules/auth/login/login_provider.dart`

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **Không được import từ `data/` vào `domain/` hoặc `modules/`**
2. **DTOs chỉ tồn tại trong `data/` layer**
3. **Entities được share giữa `domain/` và `modules/`**
4. **Vietmap API key cần được lưu an toàn (env variables)**
5. **Debounce search để tránh gọi API liên tục**
6. **Handle null/empty response từ API**
7. **Coordinates trong GeoJSON là [lng, lat] - CHÚ Ý thứ tự!**

---

## 🎉 KẾT LUẬN

Hướng dẫn này cung cấp đầy đủ các bước để implement tính năng Place Search theo đúng Clean Architecture và tuân thủ nghiêm ngặt quy tắc coding trong `Rules.md`. 

**Luồng dữ liệu tổng quát**:
```
UI (Screen) 
  → Provider (State Management) 
    → Repository Interface (Domain) 
      → Repository Implementation (Data)
        → Service (Retrofit) 
          → API (Vietmap)
        ← DTO Response
      ← Convert DTO → Entity
    ← Entity
  ← Update UI
```

**Tách biệt layers**:
- **Domain**: Business logic, entities, repository interfaces
- **Data**: Implementation, DTOs, services, API calls
- **Presentation**: UI, state management, user interactions

Follow từng bước một cách tuần tự, test kỹ từng layer trước khi chuyển sang layer tiếp theo.

