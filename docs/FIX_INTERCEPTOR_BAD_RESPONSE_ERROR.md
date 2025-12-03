# PHÂN TÍCH LỖI: InterceptorState DioException [bad response]

## ❌ LỖI ĐANG GẶP

```
Unhandled Exception: InterceptorState<DioException>(
  type: InterceptorResultType.reject, 
  data: DioException [bad response]: Error: 
)

Stack Trace:
#0  Options.compose
#1  _AuthService.login (auth_service.g.dart:31:12)
#2  AuthRepositoryImpl.login (auth_repository.dart:48:40)
#3  AppProvider.login
#4  LoginProvider.login
```

---

## 🔍 NGUYÊN NHÂN

### Vấn đề 1: Backend Response Format KHÔNG KHỚP với DTO

**Backend thực tế trả về:**
```json
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

**AuthResponseDto hiện tại expect:**
```dart
class AuthResponseDto {
  final String? accessToken;    // ← Expect ở root level
  final String? refreshToken;   // ← Expect ở root level
  final int? expiresIn;        // ← Expect ở root level
  final UserDto? user;         // ← Expect ở root level
}

// Mapping:
factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
  return AuthResponseDto(
    accessToken: json['accessToken'],  // ❌ NULL! Vì thực tế ở json['data']['accessToken']
    refreshToken: json['refreshToken'], // ❌ NULL!
    expiresIn: json['expiresIn'],      // ❌ NULL!
    user: json['user'] != null         // ❌ NULL!
        ? UserDto.fromJson(json['user'])
        : null,
  );
}
```

**Kết quả:**
- ✅ Retrofit parse thành công (vì có fromJson)
- ❌ Nhưng tất cả fields đều NULL
- ❌ `response.toEntity()` tạo AuthInfo với accessToken = null
- ❌ Crash hoặc lỗi khi dùng

---

### Vấn đề 2: ResponseValidatorInterceptor Reject Quá Sớm

**Hiện tại:**
```dart
// ResponseValidatorInterceptor
if (code != null && code.isNotEmpty) {
  // Reject ngay khi thấy code != ""
  handler.reject(DioException(...));
  return;
}
```

**Vấn đề:**
- Interceptor reject → Retrofit KHÔNG parse response
- DioException được throw trước khi data được extract
- `auth_service.g.dart` line 31 gặp lỗi khi compose Options

---

### Vấn đề 3: DTO Không Parse Đúng Structure

**Backend structure:**
```
Response {
  code: ""
  message: "Success"
  data: {              ← DATA Ở ĐÂY!
    userId: "..."
    accessToken: "..."
    refreshToken: "..."
    user: { ... }
  }
}
```

**DTO structure hiện tại:**
```
AuthResponseDto {
  accessToken: null   ← Expect ở root, nhưng thực tế ở data.accessToken
  refreshToken: null
  user: null
}
```

---

## 💡 GIẢI PHÁP

### Option 1: SỬA DTO ĐỂ MATCH VỚI BACKEND FORMAT (KHUYẾN NGHỊ) ⭐⭐⭐

#### Tạo Wrapper DTO cho format chuẩn của backend

**File mới:** `lib/data/dto/base_response_dto.dart`

```dart
/// Base Response DTO cho TẤT CẢ API
/// Backend luôn trả về format:
/// {
///   "code": "",
///   "message": "Success",
///   "data": { ... }
/// }
class BaseResponseDto<T> {
  final String code;
  final String message;
  final T? data;

  BaseResponseDto({
    required this.code,
    required this.message,
    this.data,
  });

  factory BaseResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return BaseResponseDto(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Check nếu response thành công
  bool get isSuccess => code.isEmpty;

  /// Throw error nếu không thành công
  void throwIfError() {
    if (!isSuccess) {
      throw Exception(message);
    }
  }
}
```

#### Tạo AuthDataDto để parse phần "data"

**File:** `lib/data/dto/auth_dto.dart`

```dart
/// DTO cho phần "data" trong response
class AuthDataDto {
  final String? userId;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final UserDto? user;

  AuthDataDto({
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.user,
  });

  factory AuthDataDto.fromJson(Map<String, dynamic> json) {
    return AuthDataDto(
      userId: json['userId'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert AuthDataDto → AuthInfo (Entity)
  AuthInfo toEntity() {
    return AuthInfo(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
      expiresIn: expiresIn ?? 0,
      user: user?.toEntity() ?? UserEntity(
        id: '',
        email: '',
        firstName: '',
        lastName: '',
      ),
    );
  }
}
```

#### Cập nhật AuthService để return BaseResponseDto

**File:** `lib/data/services/auth_service.dart`

```dart
import 'package:vm_first_app/data/dto/base_response_dto.dart';
import 'package:vm_first_app/data/dto/auth_dto.dart';

@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio, {String? baseUrl}) = _AuthService;

  /// Login API
  /// Backend trả về: { "code": "", "message": "...", "data": {...} }
  @POST('/fw-api/settings/login')
  Future<Map<String, dynamic>> login(@Body() LoginDto request);
  
  @POST('/fw-api/settings/register')
  Future<Map<String, dynamic>> register(@Body() RegisterDto request);
  
  @POST('/fw-api/settings/logout')
  Future<void> logout();
}
```

#### Cập nhật AuthRepository để parse BaseResponseDto

**File:** `lib/data/repository/auth_repository.dart`

```dart
@override
Future<AuthInfo> login(LoginRequest request) async {
  // Step 1: Convert Domain Request → DTO
  final dto = LoginDto(
    email: request.email,
    password: request.password,
  );

  // Step 2: Call API → Nhận Map<String, dynamic>
  final responseJson = await authService.login(dto);

  // Step 3: Parse BaseResponseDto
  final baseResponse = BaseResponseDto.fromJson(
    responseJson,
    (json) => AuthDataDto.fromJson(json),
  );

  // Step 4: Check error
  if (!baseResponse.isSuccess) {
    // code != "" → Là error
    throw Exception(baseResponse.message);
  }

  // Step 5: Extract data và convert → Entity
  if (baseResponse.data == null) {
    throw Exception('No data in response');
  }

  return baseResponse.data!.toEntity();
}
```

---

### Option 2: XỬ LÝ TRONG INTERCEPTOR (BACKUP)

Nếu không muốn sửa DTO, có thể transform response trong interceptor:

**File:** `lib/core/network/response_validator_interceptor.dart`

```dart
class ResponseValidatorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode != null && 
        response.statusCode! >= 200 && 
        response.statusCode! < 300) {
      
      final data = response.data;
      
      if (data is Map<String, dynamic>) {
        final code = data['code'] as String?;
        final message = data['message'] as String?;
        final responseData = data['data'];
        
        // Check error
        if (code != null && code.isNotEmpty) {
          // ❌ Error: code != ""
          final error = DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: message ?? code,
          );
          handler.reject(error);
          return;
        }
        
        // ✅ Success: code == ""
        // Transform response để Retrofit parse đúng
        if (responseData != null) {
          // Đưa data lên root level để DTO parse được
          response.data = responseData;
        }
      }
    }
    
    handler.next(response);
  }
}
```

**Vấn đề của Option 2:**
- ❌ Phải transform response → Thay đổi structure
- ❌ Khó maintain
- ❌ Khó debug
- ❌ Không rõ ràng

---

## 📊 SO SÁNH OPTIONS

| Khía cạnh | Option 1: Sửa DTO | Option 2: Transform Interceptor |
|-----------|-------------------|--------------------------------|
| **Rõ ràng** | ✅ DTO match với backend | ❌ Transform không rõ |
| **Maintain** | ✅ Dễ | ❌ Khó |
| **Debug** | ✅ Dễ | ❌ Khó |
| **Reusable** | ✅ Dùng cho mọi API | ❌ Hack-ish |
| **Type-safe** | ✅ Strongly typed | ⚠️ Có thể mất type |
| **Khuyến nghị** | ⭐⭐⭐ | ⭐ |

---

## 🎯 LUỒNG SAU KHI SỬA (Option 1)

### Login thành công:

```
User login
    ↓
POST /fw-api/settings/login
    ↓
Backend Response:
{
  "code": "",
  "message": "Success",
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "user": {...}
  }
}
    ↓
ResponseValidatorInterceptor:
    code == "" → ✅ SUCCESS, pass through
    ↓
AuthService.login() returns Map<String, dynamic>
    ↓
Repository parse BaseResponseDto:
    BaseResponseDto<AuthDataDto> {
      code: "",
      message: "Success",
      data: AuthDataDto {
        accessToken: "...",
        refreshToken: "...",
        user: UserDto {...}
      }
    }
    ↓
Check: baseResponse.isSuccess? → YES
    ↓
Extract: baseResponse.data.toEntity()
    ↓
Return AuthInfo {
  accessToken: "...",
  user: UserEntity {...}
}
    ↓
✅ Login thành công!
```

### Login thất bại:

```
User login với sai password
    ↓
POST /fw-api/settings/login
    ↓
Backend Response:
{
  "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG",
  "message": "Invalid username/password",
  "data": null
}
    ↓
ResponseValidatorInterceptor:
    code != "" → ❌ ERROR
    → Reject với DioException
    ↓
DioFailure parse:
    "MSG_USER_PASSWORD_OR_USERNAME_WRONG"
    → "Email hoặc mật khẩu không đúng"
    ↓
LoginProvider catch exception
    ↓
✅ UI hiển thị: "Email hoặc mật khẩu không đúng"
```

---

## 🔑 KEY POINTS

### 1. Backend Format Nhất Quán

```json
// ✅ MỌI API đều trả về format này
{
  "code": "",        // "" = success, "MSG_XXX" = error
  "message": "...",
  "data": { ... }    // Actual data ở đây
}
```

### 2. DTO Phải Match Backend

```dart
// ❌ SAI: Expect data ở root
class AuthResponseDto {
  final String? accessToken;  // Expect json['accessToken']
}

// ✅ ĐÚNG: Parse đúng structure
class BaseResponseDto<T> {
  final String code;
  final String message;
  final T? data;             // Data ở json['data']
}
```

### 3. Generic DTO Cho Mọi API

```dart
// Reusable cho TẤT CẢ API
BaseResponseDto<AuthDataDto>    // Login/Register
BaseResponseDto<UserDto>        // Get Profile
BaseResponseDto<List<JobDto>>   // Get Jobs
BaseResponseDto<JobDto>         // Get Job Detail
```

### 4. Error Handling Tách Biệt

```dart
// Check error TRƯỚC khi parse data
if (!baseResponse.isSuccess) {
  throw Exception(baseResponse.message);
}

// Parse data SAU KHI confirm success
return baseResponse.data!.toEntity();
```

---

## 📝 CHECKLIST IMPLEMENTATION

### Option 1: Sửa DTO (Khuyến nghị)

- [ ] Tạo `BaseResponseDto<T>` generic class
- [ ] Tạo `AuthDataDto` cho phần "data"
- [ ] Sửa `AuthService` return `Map<String, dynamic>`
- [ ] Sửa `AuthRepository` parse `BaseResponseDto`
- [ ] Update `ResponseValidatorInterceptor` (nếu cần)
- [ ] Test login thành công
- [ ] Test login thất bại
- [ ] Apply cho register()
- [ ] Apply cho các API khác

### Option 2: Transform Interceptor (Backup)

- [ ] Sửa `ResponseValidatorInterceptor`
- [ ] Transform response.data
- [ ] Test kỹ với nhiều trường hợp
- [ ] Document rõ ràng

---

## ✅ TÓM TẮT

### Nguyên nhân lỗi:

1. **DTO không match backend format**
   - Backend: `{ code, message, data: { accessToken, ... } }`
   - DTO expect: `{ accessToken, ... }` ở root level

2. **ResponseValidatorInterceptor reject quá sớm**
   - Reject trước khi Retrofit parse
   - DioException không có data đầy đủ

3. **AuthResponseDto parse null**
   - Tất cả fields NULL vì path không đúng
   - `json['accessToken']` thay vì `json['data']['accessToken']`

### Giải pháp:

**Option 1: Sửa DTO** ⭐⭐⭐ (Khuyến nghị)
- Tạo `BaseResponseDto<T>` wrapper
- Tạo `AuthDataDto` cho data
- Parse đúng structure: `code → data → accessToken`
- Reusable cho mọi API

**Option 2: Transform Interceptor**
- Sửa response trong interceptor
- Đưa data lên root level
- Không khuyến nghị (hack-ish)

### Kết quả mong đợi:

✅ Login thành công → Parse đúng accessToken
✅ Login thất bại → Hiển thị "Email hoặc mật khẩu không đúng"
✅ Không còn InterceptorState exception
✅ Type-safe, dễ maintain

---

## 🚀 NEXT STEPS

1. Implement Option 1 (BaseResponseDto)
2. Test với login thành công/thất bại
3. Apply cho register() và các API khác
4. Update document
5. Remove ResponseValidatorInterceptor nếu không cần (vì check ở Repository)

---

✅ **Đã phân tích xong nguyên nhân và đưa ra giải pháp chi tiết!**

