# Hướng Dẫn Tự Động Thêm API Key Vào Vietmap API Requests

## 🎯 YÊU CẦU

**Hiện tại:**
- User phải nhập API key mỗi khi search
- API key là tham số bắt buộc trong query params

**Mong muốn:**
- User chỉ nhập text tìm kiếm
- Hệ thống TỰ ĐỘNG thêm API key vào mọi request
- API key được lưu an toàn, không hardcode

---

## 📊 SO SÁNH VỚI AUTH FLOW (REFERENCE)

### Auth Flow (Backend API):
```dart
// 1. AuthRequestInterceptor tự động thêm Authorization header
class AuthRequestInterceptor extends QueuedInterceptor {
  String? accessToken;
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';  // ← Tự động thêm
    }
    super.onRequest(options, handler);
  }
}

// 2. User KHÔNG cần quan tâm đến token
final response = await authService.changePassword(dto);  // Token tự động thêm
```

### Vietmap API Flow (Cần implement tương tự):
```dart
// 1. VietmapApiKeyInterceptor tự động thêm apikey vào query params
class VietmapApiKeyInterceptor extends Interceptor {
  final String apiKey;
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters['apikey'] = apiKey;  // ← Tự động thêm
    super.onRequest(options, handler);
  }
}

// 2. User KHÔNG cần truyền apikey
final response = await placeService.searchPlaces(
  PlaceSearchDto(text: 'vietmap')  // ← Không có apikey
);
```

---

## 🏗️ KIẾN TRÚC GIẢI PHÁP

### Tổng Quan:
```
┌─────────────────────────────────────────────────────────────┐
│ UI Layer (Provider/Screen)                                  │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ User input: "vietmap"                                   │ │
│ │ PlaceSearchRequest(query: "vietmap")  ← Không có apikey │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Domain Layer (Repository)                                   │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ PlaceSearchDto(text: "vietmap")  ← Không có apikey     │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Data Layer (Service)                                        │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ @GET('/api/autocomplete/v3')                            │ │
│ │ Future<List<PlaceDtoResponse>> searchPlaces(            │ │
│ │   @Queries() PlaceSearchDto request                     │ │
│ │ );                                                       │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Network Layer (Interceptor) ← API KEY ĐƯỢC THÊM Ở ĐÂY     │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ VietmapApiKeyInterceptor                                │ │
│ │                                                          │ │
│ │ onRequest() {                                            │ │
│ │   options.queryParameters['apikey'] = _apiKey;  ← TỰ ĐỘNG│ │
│ │ }                                                        │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ HTTP Request                                                 │
│ GET https://maps.vietmap.vn/api/autocomplete/v3?            │
│     text=vietmap&apikey=YOUR_API_KEY  ← Đã có apikey        │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 BƯỚC 1: TẠO MapClient (Tương tự HttpClient)

### Mục đích:
- Quản lý Dio instance riêng cho Vietmap API
- Cấu hình interceptors (API key, logging, error handling)
- Tách biệt với HttpClient (backend API)

### File: `lib/core/network/map_client.dart`

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:vm_first_app/core/core.dart';

/// Base URL cho Vietmap API
const String kBaseMapUrl = "https://maps.vietmap.vn";
String get baseMapUrlHandler => kBaseMapUrl;

/// API Key cho Vietmap (từ Vietmap Console)
/// 
/// **LƯU Ý BẢO MẬT:**
/// - KHÔNG nên hardcode trực tiếp như này trong production
/// - Nên lưu trong .env file hoặc Firebase Remote Config
/// - Đây chỉ là demo, cần migrate sang secure storage
const String kVietmapApiKey = "YOUR_VIETMAP_API_KEY_HERE";

/// MapClient - Quản lý HTTP requests cho Vietmap API
/// 
/// **Tương tự HttpClient nhưng dành riêng cho Vietmap:**
/// - Dio instance riêng với base URL của Vietmap
/// - Interceptors tự động thêm API key
/// - Logging cho debug
/// - Error handling
/// 
/// **Pattern giống HttpClient:**
/// ```dart
/// // HttpClient cho backend
/// final httpClient = HttpClient(
///   dio: HttpClient.createDio(localeStr: 'en'),
///   storage: storage,
///   onForceLogout: () {},
/// );
/// 
/// // MapClient cho Vietmap
/// final mapClient = MapClient(
///   dio: MapClient.createDio(),
/// );
/// ```
class MapClient {
  final Dio dio;
  late final String baseUrl;

  MapClient({
    required this.dio,
    List<Interceptor>? interceptors,
  }) {
    baseUrl = baseMapUrlHandler;
    _initInterceptors(interceptors);
  }

  /// Khởi tạo interceptors cho Dio
  /// 
  /// **Thứ tự quan trọng:**
  /// 1. VietmapApiKeyInterceptor - Thêm API key vào query params
  /// 2. CurlInterceptor - Log CURL command (debug only)
  /// 3. PrettyDioLogger - Log request/response (debug only)
  /// 
  /// **Tương tự HttpClient.initInterceptors()**
  void _initInterceptors(List<Interceptor>? interceptors) {
    dio.interceptors.addAll([
      // Custom interceptors (nếu có)
      if (interceptors != null) ...interceptors,
      
      // Tự động thêm API key vào mọi request
      VietmapApiKeyInterceptor(),
      
      // Debug logging (chỉ trong development)
      if (!kReleaseMode) ...[
        CurlInterceptor(convertFormData: true, printOnSuccess: false),
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
        ),
      ],
    ]);
  }

  /// Factory method tạo Dio instance cho Vietmap API
  /// 
  /// **Tương tự HttpClient.createDio():**
  /// - Base URL: https://maps.vietmap.vn
  /// - Headers: Content-Type, accept
  /// - Timeouts: 30s connect, 60s receive
  /// 
  /// **Called by:** Dependency injection setup (app_dependencies.dart)
  static Dio createDio() {
    return Dio(
      BaseOptions(
        baseUrl: kBaseMapUrl,
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
      ),
    );
  }
}
```

**KEY POINTS:**
- ✅ Tương tự `HttpClient` cho backend API
- ✅ Dio instance riêng với base URL Vietmap
- ✅ `VietmapApiKeyInterceptor` tự động thêm API key
- ✅ Logging cho debug

---

## 📝 BƯỚC 2: TẠO VietmapApiKeyInterceptor

### Mục đích:
- Tự động thêm `apikey` vào query parameters của MỌI request
- User không cần quan tâm đến API key

### File: `lib/core/network/vietmap_api_key_interceptor.dart` (File mới)

```dart
import 'package:dio/dio.dart';
import 'package:vm_first_app/core/network/map_client.dart';

/// Interceptor tự động thêm API key vào mọi request đến Vietmap API
/// 
/// **Pattern tương tự AuthRequestInterceptor:**
/// ```dart
/// // AuthRequestInterceptor thêm Authorization header
/// class AuthRequestInterceptor extends QueuedInterceptor {
///   @override
///   void onRequest(options, handler) {
///     if (accessToken != null) {
///       options.headers['Authorization'] = 'Bearer $accessToken';
///     }
///   }
/// }
/// 
/// // VietmapApiKeyInterceptor thêm apikey query param
/// class VietmapApiKeyInterceptor extends Interceptor {
///   @override
///   void onRequest(options, handler) {
///     options.queryParameters['apikey'] = kVietmapApiKey;
///   }
/// }
/// ```
/// 
/// **Tại sao dùng Interceptor?**
/// 1. **DRY Principle:** Không cần thêm apikey ở mọi service method
/// 2. **Separation of Concerns:** API key là infrastructure concern, không phải business logic
/// 3. **Easy to Update:** Đổi API key chỉ cần sửa 1 chỗ
/// 4. **Consistent:** Đảm bảo MỌI request đều có apikey
/// 
/// **Use Case:**
/// ```dart
/// // Service method KHÔNG cần apikey parameter
/// @GET('/api/autocomplete/v3')
/// Future<List<PlaceDtoResponse>> searchPlaces(
///   @Queries() PlaceSearchDto request  // ← Không có apikey
/// );
/// 
/// // Interceptor tự động thêm
/// // Request: GET /api/autocomplete/v3?text=vietmap&apikey=YOUR_KEY
/// ```
class VietmapApiKeyInterceptor extends Interceptor {
  /// onRequest được gọi TRƯỚC KHI request được gửi đi
  /// 
  /// **Flow:**
  /// 1. Service method gọi API: `placeService.searchPlaces(dto)`
  /// 2. Dio chuẩn bị request với query params từ `@Queries()`
  /// 3. **onRequest được gọi** ← Thêm apikey ở đây
  /// 4. Request được gửi với đầy đủ query params
  /// 
  /// **Tham số:**
  /// - `options`: RequestOptions chứa tất cả thông tin request
  ///   - `options.queryParameters`: Map query params hiện tại
  ///   - `options.headers`: Map headers
  ///   - `options.path`: Endpoint path
  /// - `handler`: RequestInterceptorHandler để continue hoặc reject request
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Thêm apikey vào query parameters
    // Nếu đã có apikey (unlikely), sẽ bị overwrite
    // Map.putIfAbsent() nếu muốn giữ existing value
    options.queryParameters['apikey'] = kVietmapApiKey;
    
    // Log để debug (optional)
    print('🔑 [Vietmap] Added apikey to: ${options.path}');
    
    // Continue với request
    // handler.next(options) = cho phép request tiếp tục
    // handler.reject(error) = reject request
    super.onRequest(options, handler);
  }
  
  /// onResponse được gọi KHI nhận được response thành công
  /// Có thể dùng để log hoặc transform response
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Optional: Log success
    print('✅ [Vietmap] Response from: ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }
  
  /// onError được gọi KHI request bị lỗi
  /// Có thể dùng để handle specific errors (API key invalid, etc.)
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Optional: Handle API key errors
    if (err.response?.statusCode == 401) {
      print('❌ [Vietmap] API Key invalid or missing');
    }
    super.onError(err, handler);
  }
}
```

**KEY POINTS:**
- ✅ Extends `Interceptor` (không phải `QueuedInterceptor` vì không cần queue)
- ✅ Override `onRequest()` để modify query params
- ✅ Tự động thêm `apikey` vào MỌI request
- ✅ Pattern giống `AuthRequestInterceptor`

---

## 📝 BƯỚC 3: CẬP NHẬT PlaceSearchDto (BỎ apikey field)

### Mục đích:
- User không cần truyền API key khi search
- API key được interceptor tự động thêm

### File: `lib/data/dto/place_dto.dart`

#### ❌ HIỆN TẠI (có apikey):
```dart
class PlaceDto {
  final String apikey;     // ← BỎ field này
  final String? focus;
  final String text;
  ...

  PlaceDto({
    required this.apikey,  // ← BỎ parameter này
    this.focus,
    required this.text,
    ...
  });

  Map<String, dynamic> toJson() {
    return {
      'apikey': apikey,    // ← BỎ dòng này
      'text': text,
      ...
    };
  }
}
```

#### ✅ SAU KHI SỬA (không có apikey):
```dart
/// DTO cho request parameters của Vietmap Place Search API
/// 
/// **LƯU Ý:** Không có field `apikey`
/// - API key được VietmapApiKeyInterceptor tự động thêm
/// - User chỉ cần truyền text và các filters
/// 
/// **Pattern giống LoginDto:**
/// ```dart
/// // LoginDto không có Authorization header
/// class LoginDto {
///   final String email;
///   final String password;
///   // ← Không có accessToken field
/// }
/// 
/// // AuthRequestInterceptor tự động thêm header
/// 
/// // PlaceSearchDto không có apikey field
/// class PlaceSearchDto {
///   final String text;
///   final String? focus;
///   // ← Không có apikey field
/// }
/// 
/// // VietmapApiKeyInterceptor tự động thêm query param
/// ```
class PlaceSearchDto {
  // ❌ BỎ: final String apikey;
  
  final String text;
  final String? focus;
  final String? circleCenter;
  final double? circleRadius;
  final int? limit;
  final String? categories;
  final String? boundaries;

  PlaceSearchDto({
    // ❌ BỎ: required this.apikey,
    
    required this.text,
    this.focus,
    this.circleCenter,
    this.circleRadius,
    this.limit,
    this.categories,
    this.boundaries,
  });

  /// Convert sang Map để gửi lên API
  /// 
  /// **VietmapApiKeyInterceptor sẽ thêm apikey vào query params**
  /// Kết quả cuối cùng:
  /// ```
  /// {
  ///   'text': 'vietmap',
  ///   'focus': '10.762,106.660',
  ///   'apikey': 'YOUR_API_KEY'  ← Interceptor thêm
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      // ❌ BỎ: 'apikey': apikey,
      
      'text': text,
      if (focus != null) 'focus': focus,
      if (circleCenter != null) 'circleCenter': circleCenter,
      if (circleRadius != null) 'circleRadius': circleRadius,
      if (limit != null) 'limit': limit,
      if (categories != null) 'categories': categories,
      if (boundaries != null) 'boundaries': boundaries,
    };
  }
}
```

**KEY POINTS:**
- ❌ BỎ field `apikey`
- ❌ BỎ parameter `required this.apikey` trong constructor
- ❌ BỎ `'apikey': apikey` trong `toJson()`
- ✅ Interceptor tự động thêm `apikey` vào query params

---

## 📝 BƯỚC 4: CẬP NHẬT PlaceService

### Mục đích:
- Service sử dụng MapClient thay vì HttpClient
- Không cần truyền apikey parameter

### File: `lib/data/services/place_service.dart`

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vm_first_app/data/dto/place_dto.dart';

part 'place_service.g.dart';

/// Retrofit service cho Vietmap Place API
/// 
/// **Sử dụng MapClient.dio (có VietmapApiKeyInterceptor)**
/// 
/// **Pattern giống AuthService:**
/// ```dart
/// // AuthService dùng HttpClient.dio
/// @RestApi()
/// abstract class AuthService {
///   factory AuthService(Dio dio, {String? baseUrl}) = _AuthService;
///   
///   @POST('/fw-api/settings/login')
///   Future<AuthResponseDto> login(@Body() LoginDto request);
/// }
/// 
/// // Register trong DI
/// locator.registerLazySingleton(
///   () => AuthService(locator<HttpClient>().dio),  // ← HttpClient.dio
/// );
/// 
/// // PlaceService dùng MapClient.dio
/// @RestApi()
/// abstract class PlaceService {
///   factory PlaceService(Dio dio, {String? baseUrl}) = _PlaceService;
///   
///   @GET('/api/autocomplete/v3')
///   Future<List<PlaceDtoResponse>> searchPlaces(...);
/// }
/// 
/// // Register trong DI
/// locator.registerLazySingleton(
///   () => PlaceService(locator<MapClient>().dio),  // ← MapClient.dio
/// );
/// ```
@RestApi()
abstract class PlaceService {
  /// Factory constructor cho Retrofit
  /// 
  /// **Tham số:**
  /// - `dio`: Dio instance từ MapClient (có VietmapApiKeyInterceptor)
  /// - `baseUrl`: Optional, default từ Dio baseUrl
  factory PlaceService(Dio dio, {String? baseUrl}) = _PlaceService;
  
  /// Search places API (Autocomplete)
  /// 
  /// **API Endpoint:** GET /api/autocomplete/v3
  /// **API Response:** Array of place objects
  /// 
  /// **Query Parameters:**
  /// - Từ `@Queries() PlaceSearchDto`: text, focus, limit, etc.
  /// - VietmapApiKeyInterceptor tự động thêm: apikey
  /// 
  /// **Final Request URL:**
  /// ```
  /// GET https://maps.vietmap.vn/api/autocomplete/v3?
  ///     text=vietmap&
  ///     focus=10.762,106.660&
  ///     limit=10&
  ///     apikey=YOUR_API_KEY  ← Interceptor thêm
  /// ```
  /// 
  /// **Retrofit auto-parse:**
  /// - Loop qua JSON array
  /// - Call PlaceDtoResponse.fromJson() cho từng item
  /// - Return List<PlaceDtoResponse>
  @GET('/api/autocomplete/v3')
  Future<List<PlaceDtoResponse>> searchPlaces(
    @Queries() PlaceSearchDto request,  // ← Không có apikey parameter
  );
  
  /// Get place detail API
  /// 
  /// **API Endpoint:** GET /api/place/v3
  /// **API Response:** Single place object
  /// 
  /// **Query Parameters:**
  /// - `refid`: Place reference ID
  /// - `apikey`: Tự động thêm bởi interceptor
  @GET('/api/place/v3')
  Future<PlaceDtoResponse> getPlaceDetail(
    @Query('refid') String refId,  // ← Không cần @Query('apikey')
  );
  
  /// Reverse geocode API
  /// 
  /// **API Endpoint:** GET /api/reverse/v3
  /// **API Response:** Single place object
  /// 
  /// **Query Parameters:**
  /// - Từ `@Queries() ReverseGeocodeDto`: lat, lng
  /// - `apikey`: Tự động thêm bởi interceptor
  @GET('/api/reverse/v3')
  Future<PlaceDtoResponse> reverseGeocode(
    @Queries() ReverseGeocodeDto request,  // ← Không có apikey parameter
  );
}
```

**KEY POINTS:**
- ✅ Sử dụng `MapClient.dio` (có interceptor)
- ❌ KHÔNG có `@Query('apikey')` parameter
- ✅ Interceptor tự động thêm `apikey` vào query params

---

## 📝 BƯỚC 5: ĐĂNG KÝ DEPENDENCIES

### Mục đích:
- Tạo MapClient instance
- Đăng ký PlaceService với MapClient.dio

### File: `lib/core/dependencies/app_dependencies.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vm_first_app/core/network/http_client.dart';
import 'package:vm_first_app/core/network/map_client.dart';  // ← Import
import 'package:vm_first_app/data/services/auth_service.dart';
import 'package:vm_first_app/data/services/place_service.dart';  // ← Import
import 'package:vm_first_app/data/repository/auth_repository.dart';
import 'package:vm_first_app/data/repository/place_repository_impl.dart';  // ← Import
import 'package:vm_first_app/domain/repository/auth_repository.dart';
import 'package:vm_first_app/domain/repository/place_repository.dart';  // ← Import

final locator = GetIt.instance;

/// Setup Dependency Injection
/// 
/// **Thứ tự đăng ký:**
/// 1. Core dependencies (Storage, HttpClient, MapClient)
/// 2. Services (AuthService, PlaceService)
/// 3. Repositories (AuthRepository, PlaceRepository)
/// 4. Providers (registered in app)
Future<void> setupDependencies() async {
  // ========== CORE DEPENDENCIES ==========
  
  // Storage
  locator.registerLazySingleton(() => const FlutterSecureStorage());
  
  // HttpClient cho backend API
  locator.registerLazySingleton<HttpClient>(
    () => HttpClient(
      dio: HttpClient.createDio(localeStr: 'en'),
      storage: locator<FlutterSecureStorage>(),
      onForceLogout: () {
        // Handle force logout
      },
    ),
  );
  
  // MapClient cho Vietmap API ← THÊM MỚI
  locator.registerLazySingleton<MapClient>(
    () => MapClient(
      dio: MapClient.createDio(),  // ← Tạo Dio với VietmapApiKeyInterceptor
    ),
  );
  
  // ========== SERVICES ==========
  
  // AuthService dùng HttpClient.dio (backend)
  locator.registerLazySingleton<AuthService>(
    () => AuthService(locator<HttpClient>().dio),
  );
  
  // PlaceService dùng MapClient.dio (Vietmap) ← THÊM MỚI
  locator.registerLazySingleton<PlaceService>(
    () => PlaceService(locator<MapClient>().dio),  // ← Dùng MapClient.dio
  );
  
  // ========== REPOSITORIES ==========
  
  // AuthRepository
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      locator<FlutterSecureStorage>(),
      locator<AuthService>(),
    ),
  );
  
  // PlaceRepository ← THÊM MỚI
  locator.registerLazySingleton<PlaceRepository>(
    () => PlaceRepositoryImpl(
      locator<PlaceService>(),
    ),
  );
}
```

**KEY POINTS:**
- ✅ Đăng ký `MapClient` với `MapClient.createDio()`
- ✅ `PlaceService` dùng `MapClient.dio` (có interceptor)
- ✅ `AuthService` dùng `HttpClient.dio` (backend)
- ✅ Tách biệt 2 HTTP clients

---

## 📝 BƯỚC 6: SỬ DỤNG TRONG REPOSITORY & PROVIDER

### Repository (KHÔNG ĐỔI - Already correct):

```dart
// lib/data/repository/place_repository_impl.dart

@override
Future<List<PlaceEntity>> searchPlaces(PlaceSearchRequest request) async {
  // B1: Convert Domain Request → DTO
  final dto = PlaceSearchDto(
    // ❌ BỎ: apikey: kVietmapApiKey,  // Không cần truyền
    text: request.query,
    focus: request.focus,
    limit: request.limit,
  );
  
  // B2: Call API
  // VietmapApiKeyInterceptor TỰ ĐỘNG thêm apikey vào query params
  final responseDtoList = await placeService.searchPlaces(dto);
  
  // B3: Convert DTO → Entity
  return responseDtoList.map((dto) => dto.toEntity()).toList();
}
```

### Provider (KHÔNG ĐỔI - Already correct):

```dart
// lib/modules/metro_go/metro_map_provider.dart

Future<void> searchPlaces({
  required String query,
  String? focus,
  int limit = 10,
}) async {
  try {
    final request = PlaceSearchRequest(
      // ❌ BỎ: apikey không cần ở đây
      query: query,
      focus: focus,
      limit: limit,
    );
    
    _searchResults = await _placeRepo.searchPlaces(request);
  } catch (e) {
    print('Error: $e');
  }
}
```

### UI (KHÔNG ĐỔI - User chỉ nhập text):

```dart
// lib/modules/metro_go/metro_map_screen.dart

TextField(
  onChanged: (value) {
    // User chỉ nhập text
    // KHÔNG cần nhập API key
    context.read<MetroMapProvider>().searchPlaces(
      query: value,  // ← Chỉ có text
      limit: 10,
    );
  },
)
```

---

## 🔄 FLOW HOÀN CHỈNH

### 1. User Input:
```dart
User nhập: "vietmap"
     ↓
TextField.onChanged("vietmap")
     ↓
provider.searchPlaces(query: "vietmap")  // ← Không có apikey
```

### 2. Domain Layer:
```dart
PlaceSearchRequest(query: "vietmap")  // ← Không có apikey
     ↓
Repository.searchPlaces(request)
     ↓
PlaceSearchDto(text: "vietmap")  // ← Không có apikey
```

### 3. Data Layer:
```dart
placeService.searchPlaces(dto)
     ↓
Retrofit chuẩn bị request:
  - Path: /api/autocomplete/v3
  - Query params: {text: "vietmap"}  // ← Chưa có apikey
```

### 4. Network Layer (Interceptor):
```dart
VietmapApiKeyInterceptor.onRequest()
     ↓
options.queryParameters['apikey'] = kVietmapApiKey  // ← THÊM apikey
     ↓
Final query params: {
  text: "vietmap",
  apikey: "YOUR_API_KEY"  // ← ĐÃ CÓ apikey
}
```

### 5. HTTP Request:
```
GET https://maps.vietmap.vn/api/autocomplete/v3?text=vietmap&apikey=YOUR_KEY
                                                  ↑            ↑
                                            User input   Auto-added
```

---

## ✅ CHECKLIST THỰC HIỆN

### Bước 1: Tạo MapClient
- [ ] Tạo file `lib/core/network/map_client.dart`
- [ ] Define constants: `kBaseMapUrl`, `kVietmapApiKey`
- [ ] Implement class `MapClient` với `createDio()` và `_initInterceptors()`
- [ ] Thêm comments giải thích

### Bước 2: Tạo VietmapApiKeyInterceptor
- [ ] Tạo file `lib/core/network/vietmap_api_key_interceptor.dart`
- [ ] Implement class `VietmapApiKeyInterceptor extends Interceptor`
- [ ] Override `onRequest()` để thêm apikey vào `options.queryParameters`
- [ ] Optional: Override `onResponse()` và `onError()` cho logging

### Bước 3: Cập nhật PlaceSearchDto
- [ ] Mở file `lib/data/dto/place_dto.dart`
- [ ] XÓA field `final String apikey`
- [ ] XÓA parameter `required this.apikey` trong constructor
- [ ] XÓA `'apikey': apikey` trong `toJson()`
- [ ] Thêm comments giải thích

### Bước 4: Cập nhật PlaceService
- [ ] Tạo/Mở file `lib/data/services/place_service.dart`
- [ ] Implement Retrofit service với `@RestApi()`
- [ ] Không có `@Query('apikey')` parameter
- [ ] Thêm comments giải thích

### Bước 5: Đăng ký Dependencies
- [ ] Mở file `lib/core/dependencies/app_dependencies.dart`
- [ ] Register `MapClient` với `MapClient.createDio()`
- [ ] Register `PlaceService` với `locator<MapClient>().dio`
- [ ] Register `PlaceRepository`

### Bước 6: Build Runner
- [ ] Chạy: `fvm flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Verify file `place_service.g.dart` được generate

### Bước 7: Testing
- [ ] Test search places với real API
- [ ] Verify CURL log có `apikey` parameter
- [ ] Verify response thành công

---

## 🔐 BẢO MẬT API KEY

### ❌ KHÔNG NÊN (Hiện tại):
```dart
// Hardcode trong source code
const String kVietmapApiKey = "YOUR_API_KEY_HERE";
```

**Vấn đề:**
- API key visible trong source code
- Có thể bị reverse engineer từ APK/IPA
- Khó rotate key khi cần

### ✅ NÊN (Production):

#### Option 1: Environment Variables (.env file)
```dart
// pubspec.yaml
dependencies:
  flutter_dotenv: ^5.0.2

// .env (không commit vào Git)
VIETMAP_API_KEY=YOUR_API_KEY_HERE

// .gitignore
.env

// map_client.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final kVietmapApiKey = dotenv.env['VIETMAP_API_KEY'] ?? '';
```

#### Option 2: Firebase Remote Config
```dart
// Fetch từ Firebase Remote Config
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();
final apiKey = remoteConfig.getString('vietmap_api_key');
```

#### Option 3: Build Flavors
```dart
// Different API keys for different environments
// Dev: dev_api_key
// Prod: prod_api_key
```

---

## 📊 SO SÁNH TRƯỚC & SAU

### TRƯỚC (User phải nhập API key):
```dart
// UI
TextField(
  label: 'API Key',
  onChanged: (value) => apiKey = value,
),
TextField(
  label: 'Search',
  onChanged: (value) {
    provider.searchPlaces(
      query: value,
      apiKey: apiKey,  // ← User nhập
    );
  },
),

// DTO
class PlaceSearchDto {
  final String apikey;  // ← Bắt buộc
  final String text;
}

// Service
@GET('/api/autocomplete/v3')
Future<List<PlaceDtoResponse>> searchPlaces(
  @Query('apikey') String apiKey,  // ← Phải truyền
  @Query('text') String text,
);
```

### SAU (Hệ thống tự động):
```dart
// UI
TextField(
  label: 'Search',  // ← Chỉ có search
  onChanged: (value) {
    provider.searchPlaces(
      query: value,  // ← Không có apiKey
    );
  },
),

// DTO
class PlaceSearchDto {
  // ❌ Không có apikey field
  final String text;
}

// Service
@GET('/api/autocomplete/v3')
Future<List<PlaceDtoResponse>> searchPlaces(
  @Queries() PlaceSearchDto request,  // ← Không có apikey
);

// Interceptor tự động thêm
class VietmapApiKeyInterceptor extends Interceptor {
  @override
  void onRequest(options, handler) {
    options.queryParameters['apikey'] = kVietmapApiKey;  // ← TỰ ĐỘNG
  }
}
```

---

## 🎯 TÓM TẮT

### Giải pháp:
1. **Tạo MapClient** - Dio instance riêng cho Vietmap API
2. **Tạo VietmapApiKeyInterceptor** - Tự động thêm API key vào query params
3. **Bỏ apikey khỏi DTO** - User không cần truyền
4. **Đăng ký MapClient** - Dependency injection
5. **PlaceService dùng MapClient.dio** - Có interceptor

### Lợi ích:
- ✅ User chỉ nhập text search
- ✅ API key tự động thêm vào MỌI request
- ✅ DRY - không repeat API key ở mọi nơi
- ✅ Easy to update - đổi API key chỉ 1 chỗ
- ✅ Consistent - đảm bảo mọi request đều có apikey
- ✅ Pattern giống AuthRequestInterceptor

### Pattern tương tự:
```
AuthRequestInterceptor     →  VietmapApiKeyInterceptor
  |                             |
  ├─ Thêm Authorization         ├─ Thêm apikey query param
  ├─ Cho backend API            ├─ Cho Vietmap API
  └─ HttpClient.dio             └─ MapClient.dio
```

---

## 🚀 NEXT STEPS

1. **Implement theo checklist** (7 bước)
2. **Test với real API**
3. **Migrate API key sang .env** (bảo mật)
4. **Document cho team**


