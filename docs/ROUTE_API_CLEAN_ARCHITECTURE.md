# Route API Implementation - Clean Architecture

## Tổng quan

Đã implement **Vietmap Route API v3** theo đúng kiến trúc **Clean Architecture** giống với cách thiết kế Place API.

## Cấu trúc Implementation

### 1. Domain Layer

#### Entities (`/lib/domain/entities/`)

**route_entity.dart** - Các entity đại diện cho route data:
- `RouteEntity` - Entity chính chứa thông tin route
- `RoutePathEntity` - Thông tin chi tiết về một path
- `RouteBboxEntity` - Bounding box của route
- `RouteInstructionEntity` - Hướng dẫn từng bước
- `RouteInfoEntity` - Metadata về request

**route_request.dart** - Request parameters:
- `RouteRequest` - Chứa tất cả params để gọi API
- `RoutePointRequest` - Tọa độ điểm (lat, lng)

#### Repository Interface (`/lib/domain/repository/`)

**route_repository.dart**:
```dart
abstract class RouteRepository {
  Future<RouteEntity?> getRoute(RouteRequest request);
}
```

### 2. Data Layer

#### DTOs (`/lib/data/dto/`)

**route_dto.dart** - Data Transfer Objects với extensions:
- `RouteDtoResponse.fromJson()` - Parse từ API response
- `RouteDtoResponseX.toEntity()` - Convert DTO → Entity
- Extensions cho tất cả nested objects

#### Services (`/lib/data/services/`)

**route_service.dart** - Retrofit service:
```dart
@RestApi()
abstract class RouteService {
  @GET('/api/route')
  Future<RouteDtoResponse> getRoute(
    @Query('point') List<String> points,
    @Query('vehicle') String? vehicle,
    // ... other params
  );
}
```

#### Repository Implementation (`/lib/data/repository/`)

**route_repository.dart** - Implement interface:
```dart
class RouteRepositoryImpl implements RouteRepository {
  final RouteService routeService;
  
  @override
  Future<RouteEntity?> getRoute(RouteRequest request) async {
    // Convert request → API call → DTO → Entity
  }
}
```

### 3. Dependency Injection

**app_repository.dart** - Register services & repositories:
```dart
void metroMapServices() {
  locator.registerLazySingleton<RouteService>(
    () => RouteService(locator<MapClient>().dio),
  );
}

void metroMapRepositories() {
  locator.registerLazySingleton<RouteRepository>(
    () => RouteRepositoryImpl(locator()),
  );
}
```

### 4. Presentation Layer

**metro_map_provider.dart** - Sử dụng RouteRepository:
```dart
class MetroMapProvider extends ChangeNotifier {
  late final RouteRepository _routeRepository;
  
  Future<void> onRouteSelected() async {
    final routeRequest = RouteRequest(
      points: [
        RoutePointRequest(lat: ..., lng: ...),
        RoutePointRequest(lat: ..., lng: ...),
      ],
      vehicle: 'car',
      pointsEncoded: true,
      locale: 'vi',
      instructions: true,
    );
    
    final routeEntity = await _routeRepository.getRoute(routeRequest);
    // Process route entity...
  }
}
```

## API Parameters Mapping

### Route Request Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| points | List<String> | Danh sách tọa độ "lat,lng" | Required |
| vehicle | String | Loại phương tiện: car, motorcycle, bicycle, foot | 'car' |
| points_encoded | bool | Encode polyline hay không | true |
| locale | String | Ngôn ngữ (vi, en) | 'vi' |
| instructions | bool | Có trả về hướng dẫn không | true |
| elevation | bool | Có tính độ cao không | false |
| optimize | String | Tối ưu hóa route | null |
| details | List<String> | Chi tiết bổ sung | null |
| algorithm | String | Thuật toán tính route | null |

### Route Response Structure

```dart
RouteEntity {
  paths: [
    RoutePathEntity {
      distance: 5234.5,  // meters
      time: 420000,      // milliseconds (7 phút)
      points: "encoded_polyline_string",
      instructions: [
        RouteInstructionEntity {
          text: "Turn left at ...",
          distance: 150.0,
          time: 30000,
          sign: 2,
        }
      ],
      bbox: RouteBboxEntity { ... }
    }
  ],
  info: RouteInfoEntity {
    copyrights: ["VietMap"],
    took: 45
  }
}
```

## Data Flow

```
User Action (onRouteSelected)
    ↓
MetroMapProvider (Presentation)
    ↓
RouteRepository Interface (Domain)
    ↓
RouteRepositoryImpl (Data)
    ↓
RouteService (Retrofit)
    ↓
Vietmap API (https://maps.vietmap.vn/api/route)
    ↓
RouteDtoResponse (Data)
    ↓
.toEntity() Extension
    ↓
RouteEntity (Domain)
    ↓
MetroMapProvider (Process & Display)
```

## So sánh với Place API Implementation

| Aspect | Place API | Route API |
|--------|-----------|-----------|
| **Domain Entities** | PlaceEntity, PlaceDetailEntity | RouteEntity, RoutePathEntity |
| **Domain Request** | PlaceRequest, PlaceDetailsRequest | RouteRequest, RoutePointRequest |
| **Data DTOs** | PlaceDtoResponse, PlaceDetailsDtoResponse | RouteDtoResponse, RoutePathDto |
| **Service** | MetroMapService | RouteService |
| **Repository** | MetroMapRepository | RouteRepository |
| **DI Registration** | metroMapServices(), metroMapRepositories() | Cùng methods |

## Ưu điểm của Clean Architecture

✅ **Separation of Concerns**: Domain logic tách biệt khỏi implementation details  
✅ **Testability**: Dễ dàng mock repositories cho testing  
✅ **Maintainability**: Thay đổi API không ảnh hưởng domain logic  
✅ **Scalability**: Dễ dàng thêm features mới  
✅ **Consistency**: Follow cùng pattern với Place API  

## Usage Example

```dart
// 1. Create request
final request = RouteRequest(
  points: [
    RoutePointRequest(lat: 10.762622, lng: 106.660172),
    RoutePointRequest(lat: 10.772461, lng: 106.698055),
  ],
  vehicle: 'car',
  locale: 'vi',
);

// 2. Get route
final routeEntity = await _routeRepository.getRoute(request);

// 3. Access data
if (routeEntity != null) {
  final path = routeEntity.paths.first;
  final distanceKm = path.distance / 1000;
  final timeMinutes = path.time / 60000;
  final encodedPolyline = path.points;
  
  // Decode polyline and draw on map
  final coordinates = VietmapPolylineDecoder.decodePolyline(
    encodedPolyline, 
    false
  );
}
```

## Files Created/Modified

### Created:
- `/lib/domain/entities/route_entity.dart`
- `/lib/domain/entities/route_request.dart`
- `/lib/domain/repository/route_repository.dart`
- `/lib/data/dto/route_dto.dart`
- `/lib/data/services/route_service.dart`
- `/lib/data/services/route_service.g.dart`
- `/lib/data/repository/route_repository.dart`

### Modified:
- `/lib/domain/domain.dart` - Added route exports
- `/lib/core/dependencies/app_repository.dart` - Added DI registration
- `/lib/modules/metro_go/metro_map_provider.dart` - Use RouteRepository

## Next Steps

1. ✅ Run `dart run build_runner build` để generate Retrofit code
2. ✅ Test API call với real data
3. ✅ Handle errors properly
4. ⏳ Add caching layer if needed
5. ⏳ Add use cases nếu business logic phức tạp

## API Documentation Reference

- **Base URL**: `https://maps.vietmap.vn`
- **Endpoint**: `/api/route`
- **Method**: GET
- **Auth**: API Key in query parameter
- **Documentation**: https://maps.vietmap.vn/docs/map-api/route-version/route-v3/

## Notes

- API trả về polyline đã encoded, cần decode trước khi vẽ
- Distance tính bằng meters, cần chia 1000 để ra km
- Time tính bằng milliseconds, chia 60000 để ra phút
- Instructions có sign code để biết loại chỉ dẫn (rẽ trái, phải, đi thẳng...)
- Bbox dùng để fit camera hiển thị toàn bộ route

## Troubleshooting

### Lỗi thường gặp:

1. **"RouteService not found"**
   - Chạy `dart run build_runner build`
   
2. **"No route found"**
   - Kiểm tra points có đúng format "lat,lng"
   - Kiểm tra vehicle type hợp lệ
   
3. **"Cannot decode polyline"**
   - points_encoded phải = true
   - Dùng VietmapPolylineDecoder.decodePolyline()

4. **"Null response"**
   - Kiểm tra API key
   - Kiểm tra network connectivity
   - Check logs để xem error message

