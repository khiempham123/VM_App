# Hướng Dẫn Sửa Lỗi MetroMapService

## 📋 Các Lỗi Được Xác Định

### 1. **Lỗi: GET Request Nhưng Sử Dụng @Body()**
**Vấn đề:**
```dart
@GET('/api/search/v4')
Future<List<PlaceDtoResponse>> getPlaces(@Body() PlaceDto request);
```

**Nguyên nhân:**
- HTTP GET request **không được phép** gửi body theo chuẩn HTTP.
- API endpoint `api/search/v4` của Vietmap yêu cầu **query parameters**, không phải body.
- Hiện tại, code đang cố gắng gửi toàn bộ `PlaceDto` làm body, nhưng GET sẽ bỏ qua nó hoặc gây lỗi.

**Tác động:**
- Request sẽ không gửi được các tham số tìm kiếm lên server.
- API trả về lỗi hoặc kết quả không chính xác.
- Logs hiển thị: `"unable to create a CURL representation of the requestOptions"`

---

### 2. **Thiếu API Key Trong Request**
**Vấn đề:**
- `MetroMapService` không tự động gắn `apikey` vào request.
- API Key được thêm bởi `MapRequestInterceptor` ở mức `queryParameters`.

**Vấn đề Con:**
- `MapRequestInterceptor` chạy ở cấp `MapClient`, nhưng nếu service không gọi qua `MapClient.dio` đúng cách, API key sẽ không được tự động thêm.

---

### 3. **Cấu Hình Base URL Không Rõ Ràng**
**Vấn đề:**
```dart
@RestApi()
abstract class MetroMapService {
  factory MetroMapService(Dio dio, {String? mapBaseUrl}) = _MetroMapService;
  
  @GET('/api/search/v4')
  Future<List<PlaceDtoResponse>> getPlaces(@Body() PlaceDto request);
}
```

**Nguyên nhân:**
- Constructor nhận `mapBaseUrl` nhưng không sử dụng nó.
- `@RestApi()` decorator không được cấu hình rõ ràng với `baseUrl`.
- Khi Retrofit generate code, nó sẽ sử dụng `baseUrl` từ `Dio`, nhưng factory constructor không xử lý tham số `mapBaseUrl`.

---

## ✅ Giải Pháp

### **Bước 1: Thay Đổi HTTP Method Từ GET → POST**

API Vietmap Place Search v4 thực chất cần sử dụng **POST** hoặc **GET với query parameters**. Để gửi dữ liệu complex như `PlaceDto`, nên dùng **POST**.

**Cách làm:**
- Thay `@GET('/api/search/v4')` → `@POST('/api/search/v4')`
- Giữ `@Body() PlaceDto request` để gửi body
- Hoặc nếu API yêu cầu GET, chuyển tất cả field của `PlaceDto` thành `@Query()` parameters

**Pseudo-code:**
```
Option A: Dùng POST (Khuyên dùng)
  @POST('/api/search/v4')
  Future<List<PlaceDtoResponse>> getPlaces(@Body() PlaceDto request);

Option B: Dùng GET với Query Parameters
  @GET('/api/search/v4')
  Future<List<PlaceDtoResponse>> getPlaces(
    @Query('text') String text,
    @Query('focus') String? focus,
    @Query('displayType') int? displayType,
    // ... thêm các field khác
  );
```

**Khuyến cáo:** Dùng **Option A (POST)** vì:
- Sạch sẽ hơn, tập trung logic ở `PlaceDto.toJson()`
- Dễ mở rộng khi thêm query parameter mới
- Phù hợp với chuẩn RESTful API

---

### **Bước 2: Đảm Bảo BaseUrl Được Cấu Hình Đúng**

**Kiểm tra:**
```dart
@RestApi(baseUrl: "https://maps.vietmap.vn/")  // ← Thêm baseUrl rõ ràng
abstract class MetroMapService {
  factory MetroMapService(Dio dio, {String? baseUrl}) = _MetroMapService;
  
  @POST('/api/search/v4')
  Future<List<PlaceDtoResponse>> getPlaces(@Body() PlaceDto request);
}
```

**Hoặc** giữ constructor như cũ, nhưng đảm bảo `MapClient.dio` đã có `baseUrl` được set:
```dart
// Kiểm tra map_client.dart - BaseOptions đã có baseUrl: kBaseMapUrl
```

---

### **Bước 3: Xác Thực Flow API Key**

**Luồng hiện tại:**
1. `MetroMapService` sử dụng `MapClient.dio`
2. `MapClient` khởi tạo `MapRequestInterceptor`
3. `MapRequestInterceptor.onRequest()` → Thêm `apikey` vào `queryParameters`
4. Request được gửi kèm API key

**Kiểm tra:**
- Trong `app_repository.dart`, `metroMapServices()` đã register `MetroMapService(locator<MapClient>().dio)` → ✅ Đúng
- `MapRequestInterceptor` đã được add vào `MapClient` → ✅ Đúng
- API key được load từ `.env` qua `dotenv.env['VM_API_KEY']` → ✅ Kiểm tra xem file `.env` có chứa `VM_API_KEY` không

---

### **Bước 4: Xử Lý Response Type Là List**

**Vấn đề hiện tại:**
```dart
Future<List<PlaceDtoResponse>> getPlaces(@Body() PlaceDto request);
```

Khi API trả về response là một **JSON Array** trực tiếp:
```json
[
  { "ref_id": "...", "distance": 0, ... },
  { "ref_id": "...", "distance": 0, ... }
]
```

**Retrofit** sẽ tự động parse vào `List<PlaceDtoResponse>` ✅ Đúng cách.

**Nhưng kiểm tra:**
- `PlaceDtoResponse.fromJson()` phải được sử dụng tự động bởi Retrofit
- Retrofit sẽ gọi `fromJson()` cho mỗi item trong array

---

## 📝 Tóm Tắt Các Thay Đổi Cần Làm

| Vấn đề | Thay Đổi | File | Ghi Chú |
|--------|----------|------|--------|
| GET không hỗ trợ @Body | Thay `@GET` → `@POST` | `metro_map_service.dart` | Sửa dòng 12 |
| BaseUrl không rõ ràng | Thêm `baseUrl` vào `@RestApi()` | `metro_map_service.dart` | Sửa dòng 8 |
| Kiểm tra API Key flow | Xác minh `.env` có `VM_API_KEY` | `.env` | Không cần sửa code |
| PlaceDto.toJson() | Kiểm tra field mapping với API | `place_dto.dart` | Đã đúng cách |

---

## 🔍 Checklist Kiểm Tra

- [ ] Thay `@GET` → `@POST` ở `MetroMapService`
- [ ] Thêm `baseUrl` vào `@RestApi()` decorator hoặc xác minh `MapClient.createDio()` đã set `baseUrl`
- [ ] Run `flutter pub run build_runner build` để regenerate `metro_map_service.g.dart`
- [ ] Kiểm tra `.env` file có chứa `VM_API_KEY=<your_api_key>`
- [ ] Test call API: Request phải chứa header `apikey=<key>` ở query parameter
- [ ] Verify response được parse đúng thành `List<PlaceDtoResponse>`

---

## 🎯 Kết Quả Mong Đợi

**Trước sửa:**
```
Request: GET /api/search/v4 (không có body, không có apikey)
Response: Error hoặc dữ liệu không đúng
```

**Sau sửa:**
```
Request: POST /api/search/v4?apikey=<key>
Body: {"text": "...", "focus": "..."}
Response: [{"ref_id": "...", "distance": 0, ...}]
Parse: List<PlaceDtoResponse> ✅
```

