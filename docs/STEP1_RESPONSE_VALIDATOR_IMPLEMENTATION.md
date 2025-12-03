# STEP 1: XỬ LÝ LỖI BẰNG KIỂM TRA FIELD "code" TRONG RESPONSE BODY

## ✅ ĐÃ IMPLEMENT

### Backend Response Format:

```json
// ❌ ERROR Response (status 200 OK)
{
  "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG",
  "message": "Invalid username/password",
  "data": null
}

// ✅ SUCCESS Response (status 200 OK)
{
  "code": "",
  "message": "Success",
  "data": {
    "userId": "user123",
    "accessToken": "eyJhbGci...",
    "refreshToken": "refresh...",
    "expiresIn": 3600,
    "user": {
      "id": "user123",
      "email": "khiempg@vietmap.vn",
      "firstName": "Khiem",
      "lastName": "Pham"
    }
  }
}
```

---

## 📝 LOGIC MỚI

### Quy tắc kiểm tra:

```
IF response.status == 200-299:
    IF response.body is JSON Map:
        code = response.body["code"]
        
        IF code != "" (code có giá trị):
            → ❌ ĐÂY LÀ ERROR
            → Throw DioException với message từ response
        
        ELSE IF code == "" (code rỗng):
            → ✅ ĐÂY LÀ SUCCESS
            → Lấy data.userId, data.accessToken, etc.
            → Parse thành AuthInfo
```

---

## 🔧 FILES ĐÃ TẠO/SỬA

### 1. ✅ Tạo mới: `response_validator_interceptor.dart`

**File:** `lib/core/network/response_validator_interceptor.dart`

**Chức năng:**
- Intercept mọi response từ backend
- Check field `code` trong response body
- Nếu `code != ""` → reject với DioException
- Nếu `code == ""` → pass qua (success)

**Code logic:**
```dart
if (code != null && code.isNotEmpty) {
  // ❌ Đây là business error dù status 200
  final error = DioException(
    requestOptions: response.requestOptions,
    response: response,
    type: DioExceptionType.badResponse,
    error: message ?? code,
  );
  handler.reject(error);
  return;
}
// ✅ code == "" → SUCCESS
handler.next(response);
```

### 2. ✅ Sửa: `http_client.dart`

**Thay đổi:**
- Thêm `ResponseValidatorInterceptor()` vào danh sách interceptors
- Đặt TRƯỚC logger để catch error sớm

**Vị trí:**
```dart
dio.interceptors.addAll([
  authRequestInterceptor,
  ResponseValidatorInterceptor(),  // ← THÊM Ở ĐÂY
  CurlInterceptor(),
  PrettyDioLogger(),
  ErrorHandlerInterceptor(),
]);
```

### 3. ✅ Sửa: `dio_failure.dart`

**Thay đổi:**
- Thêm logic parse business error từ ResponseValidatorInterceptor
- Thêm method `_getErrorMessage()` map error code → tiếng Việt

**Logic:**
```dart
// Parse business error
if (respData is Map<String, dynamic>) {
  final code = respData['code'] as String?;
  final message = respData['message'] as String?;
  
  if (code != null && code.isNotEmpty) {
    final userMessage = _getErrorMessage(code, message ?? code);
    return DioFailure(code: code, message: userMessage);
  }
}
```

**Error mapping:**
```dart
'MSG_USER_PASSWORD_OR_USERNAME_WRONG': 'Email hoặc mật khẩu không đúng',
'MSG_USER_NOT_FOUND': 'Tài khoản không tồn tại',
'MSG_TOKEN_EXPIRED': 'Phiên đăng nhập đã hết hạn',
// ... 20+ error codes
```

### 4. ✅ Sửa: `core.dart`

**Thay đổi:**
- Export `ResponseValidatorInterceptor`

---

## 🔄 LUỒNG XỬ LÝ SAU KHI IMPLEMENT

### Scenario 1: Login SAI (code != "")

```
User nhập email/password sai
    ↓
POST /fw-api/settings/login
    ↓
Backend Response:
    Status: 200 OK
    Body: {
        "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG",
        "message": "Invalid username/password",
        "data": null
    }
    ↓
✅ ResponseValidatorInterceptor.onResponse()
    code = "MSG_USER_PASSWORD_OR_USERNAME_WRONG"
    
    CHECK: code.isNotEmpty? → YES!
    
    → REJECT với DioException
    ↓
✅ DioFailure.parse()
    Parse error code
    
    Map: "MSG_USER_PASSWORD_OR_USERNAME_WRONG" 
       → "Email hoặc mật khẩu không đúng"
    
    → Throw Exception
    ↓
✅ LoginProvider.catch()
    errorMessage = "Email hoặc mật khẩu không đúng"
    ↓
✅ UI hiển thị error màu đỏ
    "Email hoặc mật khẩu không đúng" ✅
```

### Scenario 2: Login ĐÚNG (code == "")

```
User nhập email/password đúng
    ↓
POST /fw-api/settings/login
    ↓
Backend Response:
    Status: 200 OK
    Body: {
        "code": "",
        "message": "Success",
        "data": {
            "userId": "user123",
            "accessToken": "eyJhbGci...",
            "refreshToken": "refresh...",
            "user": { ... }
        }
    }
    ↓
✅ ResponseValidatorInterceptor.onResponse()
    code = ""
    
    CHECK: code.isNotEmpty? → NO!
    
    → CONTINUE (pass through)
    ↓
✅ Retrofit Parse
    Parse response.data → AuthResponseDto
    
    AuthResponseDto {
        accessToken: "eyJhbGci...",
        refreshToken: "refresh...",
        user: UserDto { ... }
    }
    ↓
✅ Repository Convert
    AuthResponseDto → AuthInfo (Entity)
    
    AuthInfo {
        accessToken: "eyJhbGci...",
        refreshToken: "refresh...",
        user: UserEntity {
            id: "user123",
            email: "khiempg@vietmap.vn",
            firstName: "Khiem",
            lastName: "Pham"
        }
    }
    ↓
✅ AppProvider Update State
    Save token
    Update session
    isLoggedIn = true
    ↓
✅ Navigate to HomeScreen ✅
```

---

## 📊 SO SÁNH: TRƯỚC vs SAU

### ❌ TRƯỚC (Không có ResponseValidatorInterceptor):

```
Backend: 200 OK + { "code": "MSG_ERROR", "data": null }
    ↓
Retrofit: Parse OK (vì status 200)
    ↓
AuthResponseDto { accessToken: null, ... }
    ↓
❌ response.toEntity() → Error hoặc crash
    ↓
❌ Lỗi không rõ ràng cho user
```

### ✅ SAU (Có ResponseValidatorInterceptor):

```
Backend: 200 OK + { "code": "MSG_ERROR", "data": null }
    ↓
✅ Interceptor: code != "" → ERROR!
    ↓
✅ Reject với DioException
    ↓
✅ DioFailure: Parse → "Email hoặc mật khẩu không đúng"
    ↓
✅ UI: Show error message rõ ràng
```

---

## 🎯 KEY POINTS

### 1. Check field "code" thay vì status code

```dart
// ❌ SAI: Check status code
if (response.statusCode == 200) {
  // Có thể vẫn là error nếu code != ""
}

// ✅ ĐÚNG: Check field "code"
if (code != null && code.isNotEmpty) {
  // Đây là error
} else {
  // Đây là success
}
```

### 2. Backend format nhất quán

```json
// Backend LUÔN trả về format này:
{
  "code": "",  // "" = success, "MSG_XXX" = error
  "message": "...",
  "data": { ... } hoặc null
}
```

### 3. User-friendly error messages

```dart
// Backend: "MSG_USER_PASSWORD_OR_USERNAME_WRONG"
// User thấy: "Email hoặc mật khẩu không đúng"

// Backend: "MSG_TOKEN_EXPIRED"
// User thấy: "Phiên đăng nhập đã hết hạn"
```

### 4. Interceptor order quan trọng

```dart
dio.interceptors.addAll([
  authRequestInterceptor,
  ResponseValidatorInterceptor(),  // ← PHẢI Ở TRƯỚC logger
  CurlInterceptor(),
  PrettyDioLogger(),
  ErrorHandlerInterceptor(),
]);
```

---

## 🧪 TESTING

### Test Case 1: Login sai email/password

```
Input:
  email: "wrong@email.com"
  password: "wrongpass"

Expected:
  ✅ UI hiển thị: "Email hoặc mật khẩu không đúng"
  ✅ TextField không bị clear
  ✅ Không navigate
  ✅ User có thể sửa và thử lại
```

### Test Case 2: Login đúng

```
Input:
  email: "khiempg@vietmap.vn"
  password: "correctpass"

Expected:
  ✅ Login thành công
  ✅ Token được lưu
  ✅ Navigate to HomeScreen
  ✅ Không có error message
```

### Test Case 3: Tài khoản không tồn tại

```
Backend: { "code": "MSG_USER_NOT_FOUND", ... }

Expected:
  ✅ UI hiển thị: "Tài khoản không tồn tại"
```

### Test Case 4: Token hết hạn

```
Backend: { "code": "MSG_TOKEN_EXPIRED", ... }

Expected:
  ✅ UI hiển thị: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại"
  ✅ Force logout
  ✅ Navigate to LoginScreen
```

---

## 🐛 DEBUG

### Nếu error không được catch:

**Kiểm tra:**
1. ResponseValidatorInterceptor đã được đăng ký chưa?
2. Thứ tự interceptor đúng chưa? (phải TRƯỚC logger)
3. Response body có đúng format không? (có field "code")
4. Error code có trong list không?

**Debug logs:**
```
✅ Response Valid:
   Code: "" (empty = success)
   Has data: true

❌ Business Error Detected:
   Code: MSG_USER_PASSWORD_OR_USERNAME_WRONG
   Message: Invalid username/password
```

---

## 📝 CHECKLIST

- [x] Tạo `ResponseValidatorInterceptor`
- [x] Check field `code` trong response body
- [x] Reject nếu `code != ""`
- [x] Đăng ký interceptor trong `HttpClient`
- [x] Thêm logic parse business error trong `DioFailure`
- [x] Map error code → tiếng Việt
- [x] Export trong `core.dart`
- [x] Test với login sai
- [x] Test với login đúng

---

## ✅ TÓM TẮT

### Logic mới:

```
Backend Response:
  ├── code == "" → ✅ SUCCESS (lấy data)
  └── code != "" → ❌ ERROR (show message)
```

### Files changed:

1. **Tạo mới:** `response_validator_interceptor.dart`
2. **Sửa:** `http_client.dart` - đăng ký interceptor
3. **Sửa:** `dio_failure.dart` - parse business error + map tiếng Việt
4. **Sửa:** `core.dart` - export interceptor

### Kết quả:

- ✅ Login sai → Show "Email hoặc mật khẩu không đúng"
- ✅ Login đúng → Navigate to HomeScreen
- ✅ User-friendly error messages
- ✅ Centralized error handling

---

✅ **STEP 1 HOÀN THÀNH! Logic xử lý lỗi đã được implement đúng.**

