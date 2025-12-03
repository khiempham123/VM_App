# Route API Implementation - Quick Start Guide

## ✅ Implementation Complete!

Route API đã được implement hoàn chỉnh theo Clean Architecture, follow đúng pattern của Place API.

## 📁 Files Created

### Domain Layer
1. `/lib/domain/entities/route_entity.dart` - Route entities
2. `/lib/domain/entities/route_request.dart` - Request models
3. `/lib/domain/repository/route_repository.dart` - Repository interface

### Data Layer
4. `/lib/data/dto/route_dto.dart` - DTOs with fromJson and toEntity()
5. `/lib/data/services/route_service.dart` - Retrofit service
6. `/lib/data/services/route_service.g.dart` - Generated Retrofit code
7. `/lib/data/repository/route_repository.dart` - Repository implementation

### Modified Files
8. `/lib/domain/domain.dart` - Added exports
9. `/lib/core/dependencies/app_repository.dart` - Added DI registration
10. `/lib/modules/metro_go/metro_map_provider.dart` - Using RouteRepository

## 🚀 How to Use

### Step 1: Run Build Runner (if needed)

```bash
cd /Users/khiempg/Develop/vm_first_app
dart run build_runner build --delete-conflicting-outputs
```

### Step 2: Test in Provider

The code is already integrated in `MetroMapProvider.onRouteSelected()`:

```dart
Future<void> onRouteSelected() async {
  // 1. Create request with 2 points
  final routeRequest = RouteRequest(
    points: [
      RoutePointRequest(
        lat: _currentPlaceLatLng!.latitude,
        lng: _currentPlaceLatLng!.longitude,
      ),
      RoutePointRequest(
        lat: _selectedPlaceLatLng!.latitude,
        lng: _selectedPlaceLatLng!.longitude,
      ),
    ],
    vehicle: 'car',
    pointsEncoded: true,
    locale: 'vi',
    instructions: true,
  );

  // 2. Call repository (Clean Architecture!)
  final routeEntity = await _routeRepository.getRoute(routeRequest);

  // 3. Use the data
  if (routeEntity != null && routeEntity.paths.isNotEmpty) {
    final path = routeEntity.paths.first;
    _routeDistance = path.distance / 1000; // km
    _routeDuration = path.time / 60000; // minutes
    
    // Decode polyline
    final latLngList = VietmapPolylineDecoder.decodePolyline(
      path.points,
      false,
    );
    
    // Draw on map
    _drawRouteOnMap(latLngList);
  }
}
```

### Step 3: Run the App

```bash
flutter run
```

### Step 4: Test Flow

1. **Mở app** → Metro Map Screen
2. **Search địa điểm** → Chọn một địa điểm
3. **Nhấn nút Direction** (icon directions)
4. **Xem route** được vẽ lên map với thông tin:
   - Khoảng cách (km)
   - Thời gian (phút)
   - Polyline màu xanh

## 📊 API Request/Response Example

### Request
```
GET https://maps.vietmap.vn/api/route?point=10.762622,106.660172&point=10.772461,106.698055&vehicle=car&points_encoded=true&locale=vi&instructions=true&apikey=YOUR_API_KEY
```

### Response
```json
{
  "paths": [
    {
      "distance": 5234.5,
      "time": 420000,
      "ascend": 0,
      "descend": 0,
      "points": "encoded_polyline_string",
      "bbox": [106.660172, 10.762622, 106.698055, 10.772461],
      "instructions": [
        {
          "distance": 150.0,
          "sign": 2,
          "time": 30000,
          "text": "Turn left",
          "interval": [0, 5],
          "street_name": "Nguyễn Huệ"
        }
      ],
      "points_encoded": true,
      "weight": 420.0
    }
  ],
  "info": {
    "copyrights": ["VietMap"],
    "took": 45
  }
}
```

### Parsed to Entity
```dart
RouteEntity(
  paths: [
    RoutePathEntity(
      distance: 5234.5,        // meters
      time: 420000,            // milliseconds
      points: "encoded...",    // polyline string
      instructions: [...],
      // ...
    )
  ],
  info: RouteInfoEntity(...)
)
```

## 🔍 Debug Tips

### Check logs:
```dart
print('✅ Route calculated successfully');
print('Distance: ${_routeDistance?.toStringAsFixed(2)} km');
print('Duration: ${_routeDuration?.toStringAsFixed(0)} minutes');
print('Points: ${latLngList.length}');
```

### If route not showing:
1. Check current location is available
2. Check selected place has coordinates
3. Check API key in `.env` file
4. Check network logs in Pretty Dio Logger
5. Check console for error messages

### Common Issues:

**"RouteService not found"**
→ Run `dart run build_runner build`

**"No route found"**
→ Check points format and vehicle type

**"Cannot decode polyline"**  
→ Ensure `points_encoded: true` in request

**"Repository null"**
→ Check DI registration in `app_repository.dart`

## 📦 Architecture Layers

```
┌─────────────────────────────────────┐
│   Presentation Layer (Provider)    │
│  - MetroMapProvider                 │
│  - Uses: RouteRepository (interface)│
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer (Business Logic)    │
│  - RouteEntity, RouteRequest        │
│  - RouteRepository interface        │
│  - Pure Dart, no dependencies       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Implementation)      │
│  - RouteDtoResponse                 │
│  - RouteService (Retrofit)          │
│  - RouteRepositoryImpl              │
│  - Talks to Vietmap API             │
└─────────────────────────────────────┘
```

## ✨ Benefits

✅ **Clean Architecture**: Separation of concerns  
✅ **Testable**: Mock repositories easily  
✅ **Maintainable**: Change API without breaking domain  
✅ **Consistent**: Same pattern as Place API  
✅ **Scalable**: Easy to add more endpoints  

## 🎯 Next Steps

1. **Test thoroughly** with different locations
2. **Add error handling UI** (show error messages to user)
3. **Add loading indicators** while calculating route
4. **Add route alternatives** (multiple paths)
5. **Add turn-by-turn navigation** using instructions
6. **Implement other Vietmap APIs**:
   - Geocoding
   - Reverse Geocoding  
   - Matrix API
   - Isochrone API

## 📚 Documentation

- `ROUTE_API_CLEAN_ARCHITECTURE.md` - Detailed implementation guide
- `CLEAN_ARCHITECTURE_COMPARISON.md` - Place vs Route comparison
- `VIETMAP_ROUTING_GUIDE.md` - Original vietmap_flutter_plugin guide

## 🎉 You're Ready!

Route API implementation hoàn tất! Bạn có thể chạy app và test ngay.

Nếu gặp vấn đề, check logs và xem các guide documents đã tạo.

Happy Coding! 🚀

