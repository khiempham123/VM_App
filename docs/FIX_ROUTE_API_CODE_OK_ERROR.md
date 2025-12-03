# FIX: Route API "Bad Response" Error with Code "OK"

## ❌ VẤN ĐỀ

**Error Message:**
```
❌ Error getting route: DioException [bad response]: 
Error: -8
Message from api:
Code from api: OK
```

**API Response (Successful):**
```json
{
  "license": "vietmap",
  "code": "OK",
  "messages": null,
  "paths": [...]
}
```

**Vấn đề:** 
- ✅ API trả về thành công với `code: "OK"`
- ❌ `CurlInterceptor` reject response vì có field `code`
- ❌ Dio throw `DioException` với type `badResponse`
- ❌ App không nhận được kết quả route

---

## 🔍 NGUYÊN NHÂN

### Logic Sai Trong CurlInterceptor (TRƯỚC KHI SỬA):

```dart
if(code !='') {
  // Reject BẤT KỲ response nào có code field
  debugPrint('Message from api: $message');
  debugPrint('Code from api: $code');
  final error = DioException(...);
  handler.reject(error);
  return;
}
```

**Vấn đề:**
- Interceptor reject **TẤT CẢ** response có field `code` (kể cả `code: "OK"`)
- Điều này đúng với Auth API (có `data` nested), nhưng sai với Vietmap Route API

### So Sánh 2 Loại API:

#### 1. Auth API (Backend riêng):
```json
// SUCCESS
{
  "code": "",           // ← Empty = success
  "message": "",
  "data": { ... }       // ← Data nested
}

// ERROR
{
  "code": "MSG_USER_NOT_FOUND",  // ← Non-empty = error
  "message": "User not found",
  "data": null
}
```

#### 2. Vietmap Route API (External):
```json
// SUCCESS
{
  "code": "OK",         // ← "OK" = success
  "messages": null,
  "paths": [...]        // ← Data at root level
}

// ERROR (giả định)
{
  "code": "InvalidRequest",
  "messages": "Missing required parameter",
  "paths": []
}
```

---

## ✅ GIẢI PHÁP

### Sửa Logic Trong CurlInterceptor:

```dart
// Check if code exists and is NOT a success code
if(code != '' && code.toUpperCase() != 'OK') {
  // Chỉ reject khi code KHÁC "OK"
  debugPrint('Message from api: $message');
  debugPrint('Code from api: $code');
  final error = DioException(...);
  handler.reject(error);
  return;
}

// If code is OK or empty, check if there's a 'data' field to unwrap
if(realData != null && code != '' && code.toUpperCase() == 'OK') {
  // Unwrap the data field for OK responses that have nested data
  response.data = realData;
  debugPrint('Exactly data - unwrapped from OK response');
} else if(code == '' && realData != null) {
  // Original behavior for responses without code field
  response.data = realData;
  debugPrint('Exactly data');
} else {
  // Keep response as-is for OK responses without nested data (like Vietmap Route API)
  debugPrint('Response with code: $code - keeping original structure');
}
```

### Logic Mới:

1. **Nếu `code != '' && code != 'OK'`:**
   - → Reject (Business Error)
   - → Throw DioException

2. **Nếu `code == 'OK'` và có `data` nested:**
   - → Unwrap `data` field
   - → Response thành công

3. **Nếu `code == 'OK'` và KHÔNG có `data` nested:**
   - → Giữ nguyên response structure
   - → Response thành công (Vietmap Route API)

4. **Nếu `code == ''` (Auth API success):**
   - → Unwrap `data` field (nếu có)
   - → Response thành công

---

## 📊 LUỒNG XỬ LÝ SAU KHI SỬA

### Vietmap Route API:

```
User request route
    ↓
GET /api/route?point=...&vehicle=car
    ↓
Vietmap trả về:
    Status: 200 OK
    Body: { "code": "OK", "paths": [...] }
    ↓
✅ CurlInterceptor: code == "OK" → Pass through
    ↓
✅ Retrofit parse RouteDtoResponse thành công
    ↓
✅ RouteDtoResponse.toEntity()
    ↓
✅ UI hiển thị route trên map
```

### Auth API (Không bị ảnh hưởng):

```
// SUCCESS CASE
Backend: { "code": "", "data": {...} }
    ↓
✅ CurlInterceptor: code == "" → Unwrap data
    ↓
✅ Response.data = realData
    ↓
✅ Parse thành công

// ERROR CASE
Backend: { "code": "MSG_USER_NOT_FOUND", "message": "..." }
    ↓
✅ CurlInterceptor: code != "" && code != "OK" → Reject
    ↓
✅ Throw DioException
    ↓
✅ UI hiển thị lỗi
```

---

## 🎯 KẾT QUẢ

### Trước Khi Sửa:
- ❌ Route API bị reject dù trả về `code: "OK"`
- ❌ DioException: bad response
- ❌ Không hiển thị route

### Sau Khi Sửa:
- ✅ Route API với `code: "OK"` được accept
- ✅ Parse thành công
- ✅ Hiển thị route trên map
- ✅ Auth API vẫn hoạt động bình thường
- ✅ Business error vẫn được detect và reject

---

## 📝 FILES CHANGED

### 1. `/lib/core/network/curl_interceptor.dart`

**Changes:**
- Sửa điều kiện check `code` field
- Thêm logic xử lý `code: "OK"`
- Giữ nguyên response structure cho external API

---

## 🧪 TEST CASES

### Test Case 1: Vietmap Route API Success
```dart
// Input
Response: { "code": "OK", "paths": [...] }

// Expected
✅ Pass through CurlInterceptor
✅ Parse thành RouteDtoResponse
✅ No DioException
```

### Test Case 2: Auth API Success
```dart
// Input
Response: { "code": "", "data": {...} }

// Expected
✅ Pass through CurlInterceptor
✅ Data được unwrap
✅ Response.data = realData
```

### Test Case 3: Auth API Error
```dart
// Input
Response: { "code": "MSG_USER_NOT_FOUND", "message": "User not found" }

// Expected
✅ Rejected by CurlInterceptor
✅ Throw DioException
✅ UI hiển thị lỗi
```

### Test Case 4: Network Error
```dart
// Input
No response (timeout, no internet, etc.)

// Expected
✅ DioException với type khác
✅ UI hiển thị lỗi network
```

---

## 💡 LƯU Ý

1. **Vietmap API không theo chuẩn của backend riêng:**
   - Backend riêng: `code` empty = success
   - Vietmap: `code: "OK"` = success

2. **Logic interceptor phải linh hoạt:**
   - Xử lý được nhiều format response
   - Không reject nhầm success response

3. **Case-insensitive cho "OK":**
   - Dùng `code.toUpperCase() != 'OK'`
   - Tránh lỗi nếu API trả về "ok", "Ok", "oK"

4. **Backward compatible:**
   - Auth API vẫn hoạt động
   - Không break existing code

---

## 🔗 RELATED DOCS

- `HANDLE_200_OK_WITH_ERROR_CODE.md` - Xử lý business error
- `VIETMAP_ROUTING_GUIDE.md` - Hướng dẫn Vietmap Route API
- `ROUTE_API_CHECKLIST.md` - Checklist implement Route API

