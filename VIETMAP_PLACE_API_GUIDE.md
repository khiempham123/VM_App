# Hướng Dẫn Vietmap Place API v4

## Tổng Quan

Vietmap Place API v4 cung cấp các API để tìm kiếm, gợi ý địa điểm, lấy thông tin chi tiết địa điểm và reverse geocoding (chuyển tọa độ thành địa chỉ). Đây là các API cực kỳ hữu ích cho ứng dụng Metro Map của bạn.

**Base URL**: `https://maps.vietmap.vn/api`

**Yêu cầu**: Tất cả API đều cần `apikey` trong query parameter.

---

## 1. Autocomplete API (Gợi Ý Tìm Kiếm)

### 📍 Mục đích
API này trả về danh sách **gợi ý địa điểm** khi người dùng nhập từ khóa tìm kiếm. Phù hợp cho tính năng search bar với auto-complete.

### 🔗 Endpoint
```
GET /api/autocomplete/v3
```

### 📥 Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `apikey` | string | ✅ Yes | API key của bạn |
| `text` | string | ✅ Yes | Từ khóa tìm kiếm (VD: "bến thành", "quận 1") |
| `focus` | string | ❌ No | Tọa độ ưu tiên `lat,lng` (VD: "10.762,106.660") |
| `circle_center` | string | ❌ No | Tâm vòng tròn tìm kiếm `lat,lng` |
| `circle_radius` | number | ❌ No | Bán kính tìm kiếm (km) |
| `limit` | number | ❌ No | Số lượng kết quả tối đa (default: 10, max: 50) |

### 📤 Response Example
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [106.6980, 10.7722]
      },
      "properties": {
        "ref_id": "65f1234567890abcdef",
        "name": "Chợ Bến Thành",
        "display": "Chợ Bến Thành, Phường Bến Thành, Quận 1, Hồ Chí Minh",
        "address": "Lê Lợi, Phường Bến Thành, Quận 1",
        "boundaries": "Quận 1, Hồ Chí Minh",
        "categories": ["market", "landmark"]
      }
    }
  ]
}
```

### 💡 Ứng Dụng Trong Dự Án

#### Use Case 1: Search Bar Trong Metro Map Screen
- **Chức năng**: Người dùng nhập từ khóa để tìm địa điểm gần trạm metro
- **Flow**:
  1. User nhập "nhà thờ đức bà" vào search bar
  2. Gọi Autocomplete API với `text=nhà thờ đức bà`
  3. Hiển thị danh sách gợi ý trong dropdown
  4. User chọn 1 địa điểm → Di chuyển map đến tọa độ đó

#### Use Case 2: Tìm Địa Điểm Gần Trạm Metro
- **Chức năng**: Gợi ý địa điểm quanh trạm metro đang chọn
- **Flow**:
  1. User chọn trạm "Bến Thành"
  2. Gọi Autocomplete API với:
     - `text=nhà hàng` (hoặc "quán cafe", "siêu thị")
     - `focus=10.7722,106.6980` (tọa độ trạm Bến Thành)
     - `circle_radius=2` (bán kính 2km)
  3. Hiển thị các địa điểm gần trạm

---

## 2. Place Detail API (Chi Tiết Địa Điểm)

### 📍 Mục đích
Lấy **thông tin chi tiết** của 1 địa điểm dựa trên `ref_id` (ID nhận được từ Autocomplete API).

### 🔗 Endpoint
```
GET /api/place/v3
```

### 📥 Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `apikey` | string | ✅ Yes | API key của bạn |
| `refid` | string | ✅ Yes | ID của địa điểm (từ Autocomplete API) |

### 📤 Response Example
```json
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [106.6980, 10.7722]
  },
  "properties": {
    "ref_id": "65f1234567890abcdef",
    "name": "Chợ Bến Thành",
    "display": "Chợ Bến Thành, Phường Bến Thành, Quận 1, Hồ Chí Minh",
    "address": "Lê Lợi, Phường Bến Thành, Quận 1",
    "street": "Lê Lợi",
    "ward": "Phường Bến Thành",
    "district": "Quận 1",
    "city": "Hồ Chí Minh",
    "boundaries": "Quận 1, Hồ Chí Minh",
    "categories": ["market", "landmark", "tourist_attraction"],
    "place_type": "poi",
    "phone": "+84 28 3829 9274",
    "website": "https://chobenthanh.com",
    "opening_hours": "07:00-18:00",
    "rating": 4.5,
    "review_count": 15234
  }
}
```

### 💡 Ứng Dụng Trong Dự Án

#### Use Case 1: Bottom Sheet Chi Tiết Địa Điểm
- **Chức năng**: Khi user click vào 1 địa điểm trên map, hiển thị bottom sheet với đầy đủ thông tin
- **Flow**:
  1. User click vào symbol "Chợ Bến Thành" trên map
  2. Lấy `ref_id` từ symbol data
  3. Gọi Place Detail API
  4. Hiển thị bottom sheet với:
     - Tên địa điểm
     - Địa chỉ đầy đủ
     - Số điện thoại (click để gọi)
     - Website (click để mở browser)
     - Giờ mở cửa
     - Rating & reviews
     - Nút "Chỉ đường" → Navigate đến địa điểm này

#### Use Case 2: Lưu Địa Điểm Yêu Thích
- **Chức năng**: Lưu thông tin chi tiết để offline access
- **Flow**:
  1. User nhấn nút "Yêu thích" trên bottom sheet
  2. Lưu toàn bộ response vào local database (SQLite/Hive)
  3. Hiển thị danh sách yêu thích ngay cả khi offline

---

## 3. Reverse Geocoding API (Tọa Độ → Địa Chỉ)

### 📍 Mục đích
Chuyển đổi **tọa độ (lat, lng)** thành **địa chỉ văn bản**. Hữu ích khi user click vào bất kỳ điểm nào trên map.

### 🔗 Endpoint
```
GET /api/reverse/v3
```

### 📥 Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `apikey` | string | ✅ Yes | API key của bạn |
| `lat` | number | ✅ Yes | Latitude (VD: 10.7722) |
| `lng` | number | ✅ Yes | Longitude (VD: 106.6980) |

### 📤 Response Example
```json
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [106.6980, 10.7722]
  },
  "properties": {
    "ref_id": "reverse_65f1234567890abcdef",
    "name": "152 Lê Lợi",
    "display": "152 Lê Lợi, Phường Bến Thành, Quận 1, Hồ Chí Minh",
    "address": "152 Lê Lợi",
    "street": "Lê Lợi",
    "ward": "Phường Bến Thành",
    "district": "Quận 1",
    "city": "Hồ Chí Minh",
    "place_type": "address"
  }
}
```

### 💡 Ứng Dụng Trong Dự Án

#### Use Case 1: Hiển Thị Địa Chỉ Khi Click Map
- **Chức năng**: User long-press vào map, hiển thị marker + địa chỉ
- **Flow**:
  1. User long-press vào map tại tọa độ (10.7722, 106.6980)
  2. Callback `onMapLongClick` được trigger
  3. Gọi Reverse Geocoding API
  4. Hiển thị marker với tooltip địa chỉ
  5. Nút "Lưu vị trí này" hoặc "Tìm đường đến đây"

#### Use Case 2: Cập Nhật Vị Trí Hiện Tại
- **Chức năng**: Hiển thị địa chỉ hiện tại của user
- **Flow**:
  1. Lấy vị trí hiện tại từ GPS
  2. Gọi Reverse Geocoding API
  3. Hiển thị "Bạn đang ở: 152 Lê Lợi, Quận 1"

---

## 4. Search API (Tìm Kiếm Địa Điểm)

### 📍 Mục đích
Tìm kiếm địa điểm với **bộ lọc chi tiết** hơn Autocomplete (filter theo category, boundaries, etc.).

### 🔗 Endpoint
```
GET /api/search/v3
```

### 📥 Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `apikey` | string | ✅ Yes | API key của bạn |
| `text` | string | ✅ Yes | Từ khóa tìm kiếm |
| `focus` | string | ❌ No | Tọa độ ưu tiên `lat,lng` |
| `categories` | string | ❌ No | Filter theo category (VD: "restaurant,cafe") |
| `boundaries` | string | ❌ No | Filter theo địa giới (VD: "Quận 1,Hồ Chí Minh") |
| `limit` | number | ❌ No | Số lượng kết quả (default: 10, max: 50) |

### 📤 Response Example
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [106.7009, 10.7769]
      },
      "properties": {
        "ref_id": "65f9876543210abcdef",
        "name": "The Workshop Coffee",
        "display": "The Workshop Coffee, Lê Thánh Tôn, Quận 1",
        "address": "27 Lê Thánh Tôn, Quận 1",
        "categories": ["cafe", "restaurant"],
        "rating": 4.6
      }
    }
  ]
}
```

### 💡 Ứng Dụng Trong Dự Án

#### Use Case 1: Filter Địa Điểm Theo Loại
- **Chức năng**: Tìm tất cả quán cafe trong bán kính 1km từ trạm metro
- **Flow**:
  1. User chọn trạm "Bến Thành"
  2. User chọn filter "Quán Cafe"
  3. Gọi Search API với:
     - `text=cafe`
     - `categories=cafe`
     - `focus=10.7722,106.6980`
     - `limit=20`
  4. Hiển thị tất cả cafe trên map bằng symbols

#### Use Case 2: Tìm Địa Điểm Trong Khu Vực
- **Chức năng**: Tìm nhà hàng trong Quận 1
- **Flow**:
  1. User nhập "nhà hàng hải sản"
  2. Chọn filter "Quận 1"
  3. Gọi Search API với:
     - `text=nhà hàng hải sản`
     - `categories=restaurant`
     - `boundaries=Quận 1,Hồ Chí Minh`

---

## 5. Cấu Trúc Implementation Trong Dự Án

### 5.1. Layer Domain (Entities)

#### File: `lib/domain/entities/place_entity.dart`
```dart
/// Entity đại diện cho 1 địa điểm
class PlaceEntity {
  final String refId;
  final String name;
  final String display;
  final String? address;
  final double latitude;
  final double longitude;
  final List<String>? categories;
  final String? phone;
  final String? website;
  final String? openingHours;
  final double? rating;
  final int? reviewCount;
  
  const PlaceEntity({
    required this.refId,
    required this.name,
    required this.display,
    this.address,
    required this.latitude,
    required this.longitude,
    this.categories,
    this.phone,
    this.website,
    this.openingHours,
    this.rating,
    this.reviewCount,
  });
}
```

#### File: `lib/domain/entities/place_suggestion_entity.dart`
```dart
/// Entity đại diện cho gợi ý tìm kiếm
class PlaceSuggestionEntity {
  final String refId;
  final String name;
  final String display;
  final double latitude;
  final double longitude;
  
  const PlaceSuggestionEntity({
    required this.refId,
    required this.name,
    required this.display,
    required this.latitude,
    required this.longitude,
  });
}
```

#### File: `lib/domain/repository/place_repository.dart`
```dart
/// Repository interface cho Place API
abstract class PlaceRepository {
  /// Autocomplete - Gợi ý địa điểm
  Future<Result<List<PlaceSuggestionEntity>>> searchAutocomplete({
    required String text,
    String? focus,
    int? limit,
  });
  
  /// Place Detail - Lấy chi tiết địa điểm
  Future<Result<PlaceEntity>> getPlaceDetail(String refId);
  
  /// Reverse Geocoding - Tọa độ → Địa chỉ
  Future<Result<PlaceEntity>> reverseGeocode({
    required double lat,
    required double lng,
  });
  
  /// Search - Tìm kiếm với filter
  Future<Result<List<PlaceEntity>>> searchPlaces({
    required String text,
    String? focus,
    List<String>? categories,
    String? boundaries,
    int? limit,
  });
}
```

### 5.2. Layer Data (Implementation)

#### File: `lib/data/dto/place_dto.dart`
```dart
@freezed
class PlaceDto with _$PlaceDto {
  const factory PlaceDto({
    @JsonKey(name: 'ref_id') required String refId,
    required String name,
    required String display,
    String? address,
    String? phone,
    String? website,
    @JsonKey(name: 'opening_hours') String? openingHours,
    double? rating,
    @JsonKey(name: 'review_count') int? reviewCount,
    List<String>? categories,
  }) = _PlaceDto;
  
  factory PlaceDto.fromJson(Map<String, dynamic> json) => 
      _$PlaceDtoFromJson(json);
}

@freezed
class PlaceFeatureDto with _$PlaceFeatureDto {
  const factory PlaceFeatureDto({
    required GeometryDto geometry,
    required PlaceDto properties,
  }) = _PlaceFeatureDto;
  
  factory PlaceFeatureDto.fromJson(Map<String, dynamic> json) =>
      _$PlaceFeatureDtoFromJson(json);
}

@freezed
class GeometryDto with _$GeometryDto {
  const factory GeometryDto({
    required List<double> coordinates, // [lng, lat]
  }) = _GeometryDto;
  
  factory GeometryDto.fromJson(Map<String, dynamic> json) =>
      _$GeometryDtoFromJson(json);
}

/// Extension để convert DTO → Entity
extension PlaceDtoX on PlaceFeatureDto {
  PlaceEntity toEntity() {
    return PlaceEntity(
      refId: properties.refId,
      name: properties.name,
      display: properties.display,
      address: properties.address,
      latitude: geometry.coordinates[1], // coordinates = [lng, lat]
      longitude: geometry.coordinates[0],
      categories: properties.categories,
      phone: properties.phone,
      website: properties.website,
      openingHours: properties.openingHours,
      rating: properties.rating,
      reviewCount: properties.reviewCount,
    );
  }
}
```

#### File: `lib/data/services/place_service.dart`
```dart
@RestApi(baseUrl: 'https://maps.vietmap.vn/api')
abstract class PlaceService {
  factory PlaceService(Dio dio) = _PlaceService;
  
  /// Autocomplete
  @GET('/autocomplete/v3')
  Future<PlaceResponseDto> autocomplete(
    @Query('apikey') String apiKey,
    @Query('text') String text,
    @Query('focus') String? focus,
    @Query('limit') int? limit,
  );
  
  /// Place Detail
  @GET('/place/v3')
  Future<PlaceFeatureDto> getPlaceDetail(
    @Query('apikey') String apiKey,
    @Query('refid') String refId,
  );
  
  /// Reverse Geocoding
  @GET('/reverse/v3')
  Future<PlaceFeatureDto> reverseGeocode(
    @Query('apikey') String apiKey,
    @Query('lat') double lat,
    @Query('lng') double lng,
  );
  
  /// Search
  @GET('/search/v3')
  Future<PlaceResponseDto> search(
    @Query('apikey') String apiKey,
    @Query('text') String text,
    @Query('focus') String? focus,
    @Query('categories') String? categories,
    @Query('boundaries') String? boundaries,
    @Query('limit') int? limit,
  );
}

@freezed
class PlaceResponseDto with _$PlaceResponseDto {
  const factory PlaceResponseDto({
    required List<PlaceFeatureDto> features,
  }) = _PlaceResponseDto;
  
  factory PlaceResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PlaceResponseDtoFromJson(json);
}
```

#### File: `lib/data/repository/place_repository_impl.dart`
```dart
class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceService _placeService;
  final String _apiKey;
  
  PlaceRepositoryImpl(this._placeService, this._apiKey);
  
  @override
  Future<Result<List<PlaceSuggestionEntity>>> searchAutocomplete({
    required String text,
    String? focus,
    int? limit,
  }) async {
    try {
      final response = await _placeService.autocomplete(
        _apiKey,
        text,
        focus,
        limit,
      );
      
      final suggestions = response.features
          .map((feature) => PlaceSuggestionEntity(
                refId: feature.properties.refId,
                name: feature.properties.name,
                display: feature.properties.display,
                latitude: feature.geometry.coordinates[1],
                longitude: feature.geometry.coordinates[0],
              ))
          .toList();
      
      return Result.success(suggestions);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  @override
  Future<Result<PlaceEntity>> getPlaceDetail(String refId) async {
    try {
      final response = await _placeService.getPlaceDetail(_apiKey, refId);
      return Result.success(response.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  @override
  Future<Result<PlaceEntity>> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _placeService.reverseGeocode(_apiKey, lat, lng);
      return Result.success(response.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  @override
  Future<Result<List<PlaceEntity>>> searchPlaces({
    required String text,
    String? focus,
    List<String>? categories,
    String? boundaries,
    int? limit,
  }) async {
    try {
      final categoriesStr = categories?.join(',');
      final response = await _placeService.search(
        _apiKey,
        text,
        focus,
        categoriesStr,
        boundaries,
        limit,
      );
      
      final places = response.features
          .map((feature) => feature.toEntity())
          .toList();
      
      return Result.success(places);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
```

### 5.3. Layer Modules (Provider)

#### File: `lib/modules/metro_go/place_search_provider.dart`
```dart
class PlaceSearchProvider extends ChangeNotifier {
  final PlaceRepository _placeRepository;
  
  // State
  List<PlaceSuggestionEntity> _suggestions = [];
  PlaceEntity? _selectedPlace;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<PlaceSuggestionEntity> get suggestions => _suggestions;
  PlaceEntity? get selectedPlace => _selectedPlace;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  PlaceSearchProvider(this._placeRepository);
  
  /// Tìm kiếm gợi ý địa điểm
  Future<void> searchAutocomplete(String text, {String? focus}) async {
    if (text.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    final result = await _placeRepository.searchAutocomplete(
      text: text,
      focus: focus,
      limit: 10,
    );
    
    result.when(
      success: (suggestions) {
        _suggestions = suggestions;
        _isLoading = false;
        notifyListeners();
      },
      failure: (error) {
        _errorMessage = error;
        _isLoading = false;
        notifyListeners();
      },
    );
  }
  
  /// Lấy chi tiết địa điểm
  Future<void> selectPlace(String refId) async {
    _isLoading = true;
    notifyListeners();
    
    final result = await _placeRepository.getPlaceDetail(refId);
    
    result.when(
      success: (place) {
        _selectedPlace = place;
        _isLoading = false;
        notifyListeners();
      },
      failure: (error) {
        _errorMessage = error;
        _isLoading = false;
        notifyListeners();
      },
    );
  }
  
  /// Reverse geocoding
  Future<PlaceEntity?> getAddressFromCoordinates(double lat, double lng) async {
    final result = await _placeRepository.reverseGeocode(lat: lat, lng: lng);
    
    return result.when(
      success: (place) => place,
      failure: (error) {
        _errorMessage = error;
        notifyListeners();
        return null;
      },
    );
  }
  
  /// Clear selection
  void clearSelection() {
    _selectedPlace = null;
    _suggestions = [];
    notifyListeners();
  }
}
```

### 5.4. Layer UI (Widgets)

#### File: `lib/modules/metro_go/widgets/place_search_bar.dart`
```dart
class PlaceSearchBar extends StatefulWidget {
  final Function(PlaceSuggestionEntity) onPlaceSelected;
  final String? focusCoordinates; // "lat,lng"
  
  const PlaceSearchBar({
    super.key,
    required this.onPlaceSelected,
    this.focusCoordinates,
  });
  
  @override
  State<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends State<PlaceSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;
  
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaceSearchProvider>();
    
    return Column(
      children: [
        // Search TextField
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Tìm địa điểm...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      provider.clearSelection();
                    },
                  )
                : null,
          ),
          onChanged: (text) {
            // Debounce 500ms
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              provider.searchAutocomplete(
                text,
                focus: widget.focusCoordinates,
              );
            });
          },
        ),
        
        // Suggestions List
        if (provider.isLoading)
          const CircularProgressIndicator()
        else if (provider.suggestions.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            itemCount: provider.suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = provider.suggestions[index];
              return ListTile(
                leading: const Icon(Icons.place),
                title: Text(suggestion.name),
                subtitle: Text(suggestion.display),
                onTap: () {
                  _controller.text = suggestion.name;
                  widget.onPlaceSelected(suggestion);
                  provider.clearSelection();
                },
              );
            },
          ),
      ],
    );
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
```

#### File: `lib/modules/metro_go/widgets/place_detail_bottom_sheet.dart`
```dart
class PlaceDetailBottomSheet extends StatelessWidget {
  final PlaceEntity place;
  final VoidCallback onNavigate;
  
  const PlaceDetailBottomSheet({
    super.key,
    required this.place,
    required this.onNavigate,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            place.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Address
          Row(
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 4),
              Expanded(child: Text(place.display)),
            ],
          ),
          
          // Rating
          if (place.rating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${place.rating} (${place.reviewCount} đánh giá)'),
              ],
            ),
          ],
          
          // Phone
          if (place.phone != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchPhone(place.phone!),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 4),
                  Text(place.phone!),
                ],
              ),
            ),
          ],
          
          // Opening Hours
          if (place.openingHours != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(place.openingHours!),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Navigate Button
          ElevatedButton.icon(
            onPressed: onNavigate,
            icon: const Icon(Icons.directions),
            label: const Text('Chỉ đường'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
  
  void _launchPhone(String phone) {
    // TODO: Launch phone dialer
  }
}
```

---

## 6. Use Cases Cụ Thể Cho Metro App

### Use Case 1: Tìm Địa Điểm Gần Trạm Metro

**Mô tả**: Khi user chọn 1 trạm metro, hiển thị các địa điểm quan tâm xung quanh (nhà hàng, cafe, ATM, bệnh viện, v.v.)

**Implementation Flow**:

1. **User chọn trạm**: "Bến Thành" (lat: 10.7722, lng: 106.6980)

2. **Provider gọi Search API**:
   ```dart
   final result = await placeRepository.searchPlaces(
     text: 'nhà hàng',
     focus: '10.7722,106.6980',
     categories: ['restaurant', 'cafe'],
     limit: 20,
   );
   ```

3. **Hiển thị symbols trên map**:
   ```dart
   for (final place in places) {
     await mapController.addSymbol(
       SymbolOptions(
         geometry: LatLng(place.latitude, place.longitude),
         iconImage: 'restaurant-icon',
         textField: place.name,
       ),
     );
   }
   ```

4. **User click symbol → Show bottom sheet** với chi tiết

---

### Use Case 2: Search Bar Với Autocomplete

**Mô tả**: User nhập từ khóa để tìm địa điểm và di chuyển map đến đó

**Implementation Flow**:

1. **User nhập "chợ bến thành"** vào search bar

2. **Provider gọi Autocomplete API** (với debounce 500ms):
   ```dart
   await placeSearchProvider.searchAutocomplete(
     'chợ bến thành',
     focus: currentLocation, // Ưu tiên kết quả gần user
   );
   ```

3. **Hiển thị dropdown gợi ý**:
   - Chợ Bến Thành, Quận 1
   - Chợ Bến Thành (Bus Station), Quận 1
   - Bến xe Bến Thành, Quận 1

4. **User chọn "Chợ Bến Thành, Quận 1"**:
   ```dart
   // Di chuyển camera
   await mapProvider.moveToLocation(
     LatLng(suggestion.latitude, suggestion.longitude),
     zoom: 16.0,
   );
   
   // Add marker
   await mapController.addSymbol(...);
   ```

---

### Use Case 3: Reverse Geocoding (Click Map → Hiển Thị Địa Chỉ)

**Mô tả**: User long-press bất kỳ điểm nào trên map, hiển thị địa chỉ và option "Lưu vị trí"

**Implementation Flow**:

1. **User long-press map** tại (10.7750, 106.7000)

2. **Callback onMapLongClick**:
   ```dart
   void onMapLongClick(Point<double> point, LatLng latLng) async {
     // Gọi Reverse Geocoding
     final place = await placeSearchProvider.getAddressFromCoordinates(
       latLng.latitude,
       latLng.longitude,
     );
     
     if (place != null) {
       // Add marker với address label
       await mapController.addSymbol(
         SymbolOptions(
           geometry: latLng,
           iconImage: 'marker-icon',
           textField: place.display,
         ),
       );
       
       // Show snackbar
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(place.display),
           action: SnackBarAction(
             label: 'Lưu',
             onPressed: () => _saveLocation(place),
           ),
         ),
       );
     }
   }
   ```

---

### Use Case 4: Filter Địa Điểm Theo Category

**Mô tả**: User chọn category filter (Restaurant, Cafe, ATM, Hospital) và xem tất cả trên map

**Implementation Flow**:

1. **User chọn filter "Cafe"** từ bottom drawer

2. **Provider gọi Search API**:
   ```dart
   final result = await placeRepository.searchPlaces(
     text: 'cafe',
     focus: '${currentLat},${currentLng}',
     categories: ['cafe'],
     limit: 50,
   );
   ```

3. **Hiển thị tất cả cafe trên map** với icon đặc biệt:
   ```dart
   await mapController.clearSymbols(); // Xóa symbols cũ
   
   for (final cafe in cafes) {
     await mapController.addSymbol(
       SymbolOptions(
         geometry: LatLng(cafe.latitude, cafe.longitude),
         iconImage: 'cafe-icon',
         iconSize: 1.2,
       ),
     );
   }
   ```

4. **User click vào cafe icon** → Show detail bottom sheet

---

### Use Case 5: Route Suggestion (Bonus)

**Mô tả**: Gợi ý địa điểm thú vị khi user đi từ trạm A đến trạm B

**Implementation Flow**:

1. **User chọn route**: Thủ Đức → Bến Thành

2. **Tìm địa điểm gần trạm đích**:
   ```dart
   // Địa điểm gần Bến Thành
   final placesNearDestination = await placeRepository.searchPlaces(
     text: 'du lịch',
     focus: '10.7722,106.6980', // Tọa độ Bến Thành
     categories: ['tourist_attraction', 'museum', 'landmark'],
     limit: 10,
   );
   ```

3. **Hiển thị gợi ý**:
   ```
   "Bạn có thể ghé thăm:"
   - Chợ Bến Thành (5 phút đi bộ)
   - Nhà thờ Đức Bà (10 phút đi bộ)
   - Bưu điện Thành phố (8 phút đi bộ)
   ```

---

## 7. Tuân Thủ Coding Rules

### ✅ Layer Separation
```
domain/
├── entities/
│   ├── place_entity.dart              ✅ Pure Dart
│   └── place_suggestion_entity.dart   ✅ Pure Dart
└── repository/
    └── place_repository.dart           ✅ Abstract interface

data/
├── dto/
│   └── place_dto.dart                  ✅ Freezed + toEntity()
├── services/
│   └── place_service.dart              ✅ Retrofit
└── repository/
    └── place_repository_impl.dart      ✅ Implements domain interface

modules/
└── metro_go/
    ├── place_search_provider.dart      ✅ State management
    └── widgets/
        ├── place_search_bar.dart       ✅ UI widget
        └── place_detail_bottom_sheet.dart ✅ UI widget
```

### ✅ Import Rules
```dart
// ✅ modules/ → domain/
import 'package:vm_first_app/domain/entities/place_entity.dart';
import 'package:vm_first_app/domain/repository/place_repository.dart';

// ✅ data/ → domain/
import 'package:vm_first_app/domain/entities/place_entity.dart';

// ❌ modules/ → data/ (KHÔNG BAO GIỜ)
import 'package:vm_first_app/data/dto/place_dto.dart'; // ❌ SAI!
```

### ✅ Dependency Injection
```dart
// lib/core/dependencies/app_dependencies.dart

void registerDependencies() {
  // Services
  locator.registerLazySingleton<PlaceService>(
    () => PlaceService(locator<Dio>()),
  );
  
  // Repositories
  locator.registerLazySingleton<PlaceRepository>(
    () => PlaceRepositoryImpl(
      locator<PlaceService>(),
      dotenv.env['VM_API_KEY']!,
    ),
  );
}
```

---

## 8. Best Practices

### ✅ DO
- **Debounce search input** (500ms) để tránh spam API
- **Cache kết quả** tìm kiếm để giảm API calls
- **Handle errors** gracefully với user-friendly messages
- **Show loading states** khi gọi API
- **Limit results** hợp lý (10-20 items)
- **Use focus parameter** để ưu tiên kết quả gần user
- **Clear symbols** trước khi add symbols mới
- **Dispose controller** và cancel timers trong dispose()

### ❌ DON'T
- Không gọi API liên tục mà không debounce
- Không expose DTO ra ngoài data layer
- Không hard-code API key trong code (dùng .env)
- Không quên handle null/empty responses
- Không add quá nhiều symbols lên map (gây lag)

---

## 9. Error Handling

### Common Errors

#### 1. Invalid API Key
```json
{
  "error": "Invalid API key",
  "status": 401
}
```
**Solution**: Kiểm tra API key trong `.env` file

#### 2. Rate Limit Exceeded
```json
{
  "error": "Rate limit exceeded",
  "status": 429
}
```
**Solution**: Implement caching và giảm số lượng requests

#### 3. No Results Found
```json
{
  "type": "FeatureCollection",
  "features": []
}
```
**Solution**: Hiển thị message "Không tìm thấy kết quả"

---

## 10. Performance Optimization

### Caching Strategy
```dart
class PlaceRepositoryImpl implements PlaceRepository {
  final Map<String, PlaceEntity> _placeCache = {};
  final Map<String, List<PlaceSuggestionEntity>> _suggestionCache = {};
  
  @override
  Future<Result<PlaceEntity>> getPlaceDetail(String refId) async {
    // Check cache first
    if (_placeCache.containsKey(refId)) {
      return Result.success(_placeCache[refId]!);
    }
    
    // Fetch from API
    final result = await _placeService.getPlaceDetail(_apiKey, refId);
    
    // Cache result
    _placeCache[refId] = result.toEntity();
    
    return Result.success(_placeCache[refId]!);
  }
}
```

### Debounce Search
```dart
Timer? _debounce;

void onSearchTextChanged(String text) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    provider.searchAutocomplete(text);
  });
}

@override
void dispose() {
  _debounce?.cancel();
  super.dispose();
}
```

---

## 11. Tổng Kết

### API Summary
| API | Mục Đích | Use Case Chính |
|-----|----------|----------------|
| **Autocomplete** | Gợi ý tìm kiếm | Search bar với dropdown |
| **Place Detail** | Chi tiết địa điểm | Bottom sheet khi click marker |
| **Reverse Geocoding** | Tọa độ → Địa chỉ | Long-press map, hiển thị vị trí hiện tại |
| **Search** | Tìm kiếm + Filter | Filter theo category, boundaries |

### Implementation Checklist
- [ ] Tạo entities trong `domain/entities/`
- [ ] Tạo repository interface trong `domain/repository/`
- [ ] Tạo DTOs với Freezed trong `data/dto/`
- [ ] Tạo Retrofit service trong `data/services/`
- [ ] Implement repository trong `data/repository/`
- [ ] Register dependencies trong `core/dependencies/`
- [ ] Tạo provider trong `modules/metro_go/`
- [ ] Tạo UI widgets (search bar, bottom sheet)
- [ ] Add error handling và loading states
- [ ] Implement caching và debounce
- [ ] Test với real API key

### Lưu Ý Quan Trọng
- ✅ **API Key**: Lưu trong `.env`, không commit vào Git
- ✅ **Rate Limiting**: Implement caching để tránh vượt quá giới hạn
- ✅ **Clean Architecture**: Tuân thủ nghiêm ngặt layer separation
- ✅ **Error Handling**: Luôn handle lỗi network, timeout, invalid responses
- ✅ **UX**: Debounce, loading states, empty states, error messages

---

**Tài liệu tham khảo**:
- Vietmap Place API v4: https://maps.vietmap.vn/docs/map-api/place-v4/
- Clean Architecture: Rules.md
- VietmapGL Integration: VIETMAP_PROVIDER_STATE_MANAGEMENT_GUIDE.md

