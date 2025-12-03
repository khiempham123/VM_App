# Phân Tích Token Format & Authorization Header

## 🔍 Vấn Đề Cần Kiểm Tra

Bạn nhận được response từ API login với format:
```json
{
  "userId": "3d8d98e7-da9f-49bb-b3d6-4d9bc47efb65",
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOi...",
  "expires_in": 604800,
  "refresh_token": "eyJhbGciOiJIUzUxMiIsInR5cCIgOi...",
  "token_type": "Bearer",
  ...
}
```

**Câu hỏi cần trả lời**:
1. ✅ Token có được lưu đúng không?
2. ✅ Token có được gửi vào header đúng cú pháp `Bearer {access_token}` không?
3. ❌ **PHÁT HIỆN VẤN ĐỀ**: Format response từ API **KHÁC** với format DTO hiện tại!

---

## ❌ VẤN ĐỀ NGHIÊM TRỌNG: API Response Format Mismatch

### **Format Response THỰC TẾ từ API**
```json
{
  "userId": "3d8d98e7-da9f-49bb-b3d6-4d9bc47efb65",
  "deviceId": null,
  "access_token": "eyJhbG...",        ← Snake_case
  "expires_in": 604800,                ← Snake_case
  "refresh_expires_in": 604800,
  "refresh_token": "eyJhbG...",        ← Snake_case
  "token_type": "Bearer",              ← Snake_case
  "notbeforepolicy": 0,
  "session_state": "716e588f-7dce-4fe8-ac2c-fb337264d91a",
  "scope": "openid profile email"
}
```

**Đặc điểm**:
- ✅ Sử dụng **snake_case** (`access_token`, `refresh_token`, `expires_in`)
- ✅ Token nằm ở **root level**, KHÔNG có nested object `user`
- ✅ User info được parse từ JWT token, KHÔNG trả về trực tiếp
- ✅ Có `userId` ở root level
- ✅ Có `token_type: "Bearer"` để chỉ định loại token

---

### **Format DTO HIỆN TẠI trong Code**
```dart
class AuthResponseDto {
  final String? accessToken;           // ← CamelCase
  final String? refreshToken;          // ← CamelCase
  final int? expiresIn;                // ← CamelCase
  final UserDto? user;                 // ← Nested object (KHÔNG TỒN TẠI trong API)
  
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['accessToken'] as String?,    // ← Tìm 'accessToken' (KHÔNG TỒN TẠI)
      refreshToken: json['refreshToken'] as String?,  // ← Tìm 'refreshToken' (KHÔNG TỒN TẠI)
      expiresIn: json['expiresIn'] as int?,          // ← Tìm 'expiresIn' (KHÔNG TỒN TẠI)
      user: json['user'] != null                     // ← Tìm 'user' (KHÔNG TỒN TẠI)
          ? UserDto.fromJson(json['user'])
          : null,
    );
  }
}
```

**Vấn đề**:
- ❌ DTO tìm `accessToken` nhưng API trả về `access_token` → **accessToken = null**
- ❌ DTO tìm `refreshToken` nhưng API trả về `refresh_token` → **refreshToken = null**
- ❌ DTO tìm `expiresIn` nhưng API trả về `expires_in` → **expiresIn = null**
- ❌ DTO tìm nested object `user` nhưng API KHÔNG có → **user = null**
- ✅ API trả về `userId` ở root level, không phải nested

---

## 🎯 Tác Động Đến Flow Login

### **Flow Hiện Tại (ĐANG BỊ LỖI)**

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Login                                                │
├─────────────────────────────────────────────────────────────┤
│ UI → LoginProvider → AppProvider → AuthRepository           │
│ → AuthService.login(LoginDto)                               │
│                                                              │
│ API Response:                                                │
│ {                                                            │
│   "access_token": "eyJhbG...",  ← Snake_case                │
│   "refresh_token": "eyJhbG...",                             │
│   "expires_in": 604800,                                     │
│   "userId": "3d8d98e7-...",                                 │
│   "token_type": "Bearer"                                    │
│ }                                                            │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Retrofit Parse JSON → AuthResponseDto.fromJson()         │
├─────────────────────────────────────────────────────────────┤
│ accessToken = json['accessToken']  // ← Tìm key SAI       │
│            → json['accessToken'] = null  ❌                │
│            → accessToken = null                             │
│                                                              │
│ refreshToken = json['refreshToken']  // ← Tìm key SAI     │
│             → refreshToken = null  ❌                       │
│                                                              │
│ expiresIn = json['expiresIn']  // ← Tìm key SAI           │
│          → expiresIn = null  ❌                             │
│                                                              │
│ user = json['user']  // ← Key không tồn tại               │
│     → user = null  ❌                                       │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Convert DTO → Entity (response.toEntity())                │
├─────────────────────────────────────────────────────────────┤
│ AuthInfo(                                                    │
│   accessToken: accessToken ?? '',   // → '' (empty)  ❌    │
│   refreshToken: refreshToken ?? '', // → '' (empty)  ❌    │
│   expiresIn: expiresIn ?? 0,       // → 0  ❌              │
│   user: user?.toEntity() ??        // → default user ❌    │
│         UserEntity(id: '', firstName: '', ...)              │
│ )                                                            │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Save AuthInfo & Set Session                               │
├─────────────────────────────────────────────────────────────┤
│ await _authRepo.setAuthInfo(authResponse);                   │
│ // → Lưu EMPTY token vào storage  ❌                        │
│                                                              │
│ locator<HttpClient>().setSession(                            │
│   accessToken: authResponse.accessToken,  // → ''  ❌       │
│   refreshToken: authResponse.refreshToken, // → ''  ❌      │
│   expiresIn: authResponse.expiresIn,      // → 0   ❌       │
│ );                                                           │
│ // → Interceptor có accessToken = ''  ❌                    │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Protected API Call (Change Password)                     │
├─────────────────────────────────────────────────────────────┤
│ AuthRequestInterceptor.onRequest():                          │
│                                                              │
│ if (accessToken?.isNotEmpty == true) {  // → false ❌      │
│   options.headers.addAll(authHeader);                        │
│ }                                                            │
│                                                              │
│ // → Header KHÔNG có Authorization  ❌                     │
│ // → API trả về 401 Unauthorized  ❌                        │
└─────────────────────────────────────────────────────────────┘
```

**Kết quả**:
- ❌ Token KHÔNG được lưu (vì parse sai)
- ❌ Header KHÔNG có Authorization (vì token empty)
- ❌ Protected APIs FAIL với 401

---

## ✅ GIẢI PHÁP: Sửa AuthResponseDto Mapping

### **Bước 1: Sửa AuthResponseDto.fromJson()**

**File**: `lib/data/dto/auth_dto.dart`

**Vấn đề**: JSON keys không match với property names

**Giải pháp**: Map đúng key từ API response

```dart
class AuthResponseDto {
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String? userId;          // ✅ THÊM: userId từ root level
  final String? tokenType;       // ✅ THÊM: Bearer
  final UserDto? user;           // ❓ GIỮ hoặc XÓA (tùy logic)

  AuthResponseDto({
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.userId,               // ✅ THÊM
    this.tokenType,            // ✅ THÊM
    this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      // ✅ SỬA: Map từ snake_case → camelCase
      accessToken: json['access_token'] as String?,      // ← 'access_token'
      refreshToken: json['refresh_token'] as String?,    // ← 'refresh_token'
      expiresIn: json['expires_in'] as int?,            // ← 'expires_in'
      
      // ✅ THÊM: Parse userId và tokenType
      userId: json['userId'] as String?,
      tokenType: json['token_type'] as String?,         // ← 'token_type'
      
      // ❓ User info: Backend KHÔNG trả nested object
      // Option 1: Parse từ JWT token (cần decode)
      // Option 2: Tạo UserDto từ userId + thông tin trong JWT
      // Option 3: Call thêm API /settings/users để lấy user info
      user: _parseUserFromResponse(json),
    );
  }
  
  // ✅ Helper method: Parse user info
  static UserDto? _parseUserFromResponse(Map<String, dynamic> json) {
    // Option 1: Nếu có userId, tạo UserDto tối thiểu
    final userId = json['userId'] as String?;
    if (userId != null) {
      // Parse thông tin từ JWT token (nếu cần)
      // Hoặc return UserDto với chỉ có id
      return UserDto(
        id: userId,
        // firstName, lastName, email sẽ được fetch sau từ API khác
        // Hoặc decode từ JWT token
      );
    }
    return null;
  }
}
```

**Lưu ý về User Info**:
- API login KHÔNG trả nested object `user`
- Backend sử dụng JWT token chứa user claims (name, email...)
- **3 Options để lấy user info**:
  1. **Decode JWT token** trong app (cần thêm package `dart_jsonwebtoken`)
  2. **Call API riêng** `/settings/users` sau khi login
  3. **Chỉ lưu userId**, fetch user info khi cần

---

### **Bước 2: Option 1 - Decode JWT Token (RECOMMENDED)**

**Tại sao chọn option này?**
- ✅ User info ĐÃ CÓ trong JWT token (xem response log)
- ✅ Không cần call API thêm
- ✅ Fast và efficient
- ✅ Backend đã include data trong token

**User info trong JWT (từ log)**:
```json
{
  "email_verified": true,
  "name": "k p",
  "preferred_username": "khiempg@vietmap.vn",
  "given_name": "k",
  "family_name": "p",
  "email": "khiempg@vietmap.vn"
}
```

**Thêm package**:

File: `pubspec.yaml`
```yaml
dependencies:
  dart_jsonwebtoken: ^2.13.0  # ✅ THÊM: Parse JWT
```

**Implement JWT Parser**:

File: `lib/core/utils/jwt_decoder.dart` (MỚI)
```dart
import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Utility class để decode JWT token
/// Tuân thủ Clean Architecture: Đặt trong core/utils (accessible by all layers)
class JwtDecoder {
  /// Decode JWT token và trả về payload (claims)
  /// Không verify signature (vì backend đã verify khi issue token)
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      // Split token: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode base64 payload (part 2)
      final payload = parts[1];
      
      // Thêm padding nếu cần (base64 yêu cầu length chia hết cho 4)
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      // Parse JSON
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      // Invalid token format
      return null;
    }
  }
  
  /// Extract user info từ JWT claims
  static Map<String, dynamic>? extractUserInfo(String token) {
    final claims = decodeToken(token);
    if (claims == null) return null;
    
    return {
      'id': claims['sub'] as String?,                        // userId
      'email': claims['email'] as String?,
      'firstName': claims['given_name'] as String?,
      'lastName': claims['family_name'] as String?,
      'name': claims['name'] as String?,
    };
  }
}
```

**Sửa AuthResponseDto sử dụng JWT Decoder**:

File: `lib/data/dto/auth_dto.dart`
```dart
import 'package:vm_first_app/core/utils/jwt_decoder.dart';  // ✅ THÊM

class AuthResponseDto {
  // ...existing fields...
  
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      userId: json['userId'] as String?,
      tokenType: json['token_type'] as String?,
      
      // ✅ Parse user từ JWT token
      user: _parseUserFromJwt(json),
    );
  }
  
  static UserDto? _parseUserFromJwt(Map<String, dynamic> json) {
    final accessToken = json['access_token'] as String?;
    if (accessToken == null) return null;
    
    // Decode JWT và extract user info
    final userInfo = JwtDecoder.extractUserInfo(accessToken);
    if (userInfo == null) return null;
    
    return UserDto(
      id: userInfo['id'] as String?,
      firstName: userInfo['firstName'] as String?,
      lastName: userInfo['lastName'] as String?,
      email: userInfo['email'] as String?,
      phone: null,  // JWT không có phone
    );
  }
}
```

---

### **Bước 3: Option 2 - Gọi API Riêng (Alternative)**

**Khi nào dùng**:
- Backend KHÔNG include user info trong JWT
- Cần thông tin chi tiết hơn (avatar, phone...)

**Flow**:
```dart
// Trong AppProvider.login()
Future<void> login(LoginRequest request) async {
  // 1. Login và nhận token
  final authResponse = await _authRepo.login(request);
  
  // 2. Set session để có Authorization header
  locator<HttpClient>().setSession(
    accessToken: authResponse.accessToken,
    ...
  );
  
  // 3. ✅ Gọi API lấy user info (CÓ Authorization header)
  final userInfo = await _profileRepo.getUserProfile(
    authResponse.userId
  );
  
  // 4. Tạo AuthInfo với user info đầy đủ
  final completeAuthInfo = AuthInfo(
    accessToken: authResponse.accessToken,
    refreshToken: authResponse.refreshToken,
    expiresIn: authResponse.expiresIn,
    user: userInfo,  // ← UserEntity từ API /settings/users
  );
  
  // 5. Lưu và update state
  await _authRepo.setAuthInfo(completeAuthInfo);
  authInfo.add(completeAuthInfo);
  isLoggedIn.add(true);
}
```

**Nhược điểm**: 
- Cần thêm 1 API call → slower
- Logic phức tạp hơn

---

### **Bước 4: Option 3 - Chỉ Lưu userId (Simplest)**

**Khi nào dùng**:
- User info không cần thiết ngay lập tức
- Fetch user info khi vào Profile screen

**Sửa UserDto & UserEntity**:
```dart
// Cho phép nullable fields
class UserEntity {
  final String id;
  final String? firstName;   // ← nullable
  final String? lastName;    // ← nullable
  final String? email;       // ← nullable
  final String? phone;

  UserEntity({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
  });
}
```

**Parse trong AuthResponseDto**:
```dart
static UserDto? _parseUserFromResponse(Map<String, dynamic> json) {
  final userId = json['userId'] as String?;
  if (userId != null) {
    return UserDto(
      id: userId,
      // Các field khác null, fetch sau
    );
  }
  return null;
}
```

**Fetch user info trong ProfileScreen**:
```dart
@override
void initState() {
  super.initState();
  // Fetch user info khi vào profile
  context.read<ProfileProvider>().fetchUserProfile();
}
```

---

## 🔐 Kiểm Tra Authorization Header Format

### **Code Hiện Tại (ĐÚNG)**

File: `lib/core/network/auth_request_interceptor.dart`

```dart
Map<String, String> get authHeader {
  return {'Authorization': 'Bearer $accessToken'};  // ✅ ĐÚNG FORMAT
}

@override
void onRequest(
  RequestOptions options,
  RequestInterceptorHandler handler,
) async {
  if (accessToken?.isNotEmpty == true &&
      !options.headers.containsKey("Authorization")) {
    options.headers.addAll(authHeader);  // ✅ Add "Authorization: Bearer {token}"
  }
  return handler.next(options);
}
```

**Format header**:
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOi...
               ↑      ↑
               Type   Space + Token
```

**✅ Đúng theo chuẩn OAuth 2.0 / RFC 6750**

**KHÔNG CẦN SỬA** - Logic này đã đúng.

---

### **Vấn Đề: Token Type Không Match?**

API trả về:
```json
{
  "token_type": "Bearer",
  "access_token": "eyJhbG..."
}
```

**Câu hỏi**: Có cần dùng `token_type` từ API không?

**Trả lời**: 
- ✅ **KHÔNG CẦN** - Luôn luôn là "Bearer" cho OAuth 2.0
- ✅ Hard-code "Bearer" trong interceptor là **best practice**
- ✅ Backend trả về `token_type` chỉ để inform, không cần parse

---

## 📋 So Sánh: Trước & Sau Fix

### **Trước Fix**

```json
// API Response
{
  "access_token": "eyJhbG...",
  "userId": "3d8d98e7-..."
}
```
↓
```dart
// AuthResponseDto.fromJson()
accessToken: json['accessToken']  // ← Tìm key SAI
// → accessToken = null ❌
```
↓
```dart
// AuthInfo
AuthInfo(
  accessToken: '',  // ← Empty ❌
  ...
)
```
↓
```dart
// AuthRequestInterceptor
if (''.isNotEmpty == true) {  // ← false ❌
  // KHÔNG add header
}
```
↓
```
// HTTP Request
PUT /fw-api/settings/password
Headers: {}  // ← Không có Authorization ❌
```
↓
```
// API Response
401 Unauthorized ❌
```

---

### **Sau Fix**

```json
// API Response
{
  "access_token": "eyJhbG...",
  "userId": "3d8d98e7-..."
}
```
↓
```dart
// AuthResponseDto.fromJson()
accessToken: json['access_token']  // ← Đúng key ✅
// → accessToken = "eyJhbG..." ✅
```
↓
```dart
// Parse user từ JWT
user: JwtDecoder.extractUserInfo(accessToken)
// → UserDto với firstName, lastName, email ✅
```
↓
```dart
// AuthInfo
AuthInfo(
  accessToken: 'eyJhbG...',  // ← Có token ✅
  user: UserEntity(...)      // ← Có user info ✅
)
```
↓
```dart
// AuthRequestInterceptor
if ('eyJhbG...'.isNotEmpty == true) {  // ← true ✅
  options.headers.addAll({
    'Authorization': 'Bearer eyJhbG...'  // ← Add header ✅
  });
}
```
↓
```
// HTTP Request
PUT /fw-api/settings/password
Headers: {
  Authorization: Bearer eyJhbG...  // ← Có Authorization ✅
}
```
↓
```
// API Response
200 OK ✅
{
  "message": "Password changed successfully"
}
```

---

## 🏗️ Tuân Thủ Clean Architecture

### **Layer Responsibilities**

```
┌─────────────────────────────────────────────────────────────┐
│ CORE (core/utils/)                                           │
│ JwtDecoder                                                   │
│  → Utility: Decode JWT token                                │
│  → Không phụ thuộc vào layer nào                            │
│  → Reusable cho nhiều features                              │
└─────────────────────────────────────────────────────────────┘
                        ↓ Import
┌─────────────────────────────────────────────────────────────┐
│ DATA (data/dto/)                                             │
│ AuthResponseDto                                              │
│  → Parse JSON từ API                                        │
│  → Sử dụng JwtDecoder để extract user info                  │
│  → Convert DTO → Entity (toEntity())                        │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ DOMAIN (domain/entities/)                                    │
│ AuthInfo, UserEntity                                         │
│  → Pure Dart entities                                       │
│  → Không biết về JWT, API response format                  │
└─────────────────────────────────────────────────────────────┘
```

**Tuân thủ Rules.md**:
- ✅ `core/` accessible by all layers
- ✅ `data/` imports from `core/` và `domain/`
- ✅ `domain/` KHÔNG import từ `data/` hay `core/utils/`
- ✅ DTOs never leak into domain or UI

---

## ⚠️ Lưu Ý Quan Trọng

### **1. JWT Token Security**

**Không decode JWT trên production** nếu:
- Token chứa sensitive data (credit card, password...)
- Cần verify signature (hiện tại chỉ decode, không verify)

**An toàn vì**:
- ✅ Token đã được backend verify khi issue
- ✅ Chỉ extract public claims (name, email...)
- ✅ Không lưu token vào log/analytics

---

### **2. Token Expiration Handling**

API trả về:
```json
{
  "expires_in": 604800,        // 7 days
  "refresh_expires_in": 604800
}
```

**Cần implement** (nếu chưa có):
- Auto refresh token trước khi expire
- Logout khi refresh token expire
- Xem file `auth_request_interceptor.dart` đã có `scheduleRefreshToken()`

---

### **3. Multiple Response Formats**

Nếu backend có nhiều formats khác nhau:

```dart
factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
  return AuthResponseDto(
    // ✅ Try both snake_case và camelCase
    accessToken: json['access_token'] as String? ?? 
                 json['accessToken'] as String?,
    
    // ✅ Fallback logic
    userId: json['userId'] as String? ?? 
            json['user_id'] as String?,
  );
}
```

---

## 🎯 Checklist Triển Khai

### **Critical (BẮT BUỘC)**
- [ ] **Sửa AuthResponseDto.fromJson()**
  - [ ] Map `access_token` → `accessToken`
  - [ ] Map `refresh_token` → `refreshToken`
  - [ ] Map `expires_in` → `expiresIn`
  - [ ] Parse `userId` từ root level

### **User Info (CHỌN 1 TRONG 3)**
- [ ] **Option 1: Decode JWT** (RECOMMENDED)
  - [ ] Thêm package `dart_jsonwebtoken`
  - [ ] Tạo `JwtDecoder` trong `core/utils/`
  - [ ] Parse user từ JWT trong `_parseUserFromJwt()`
  
- [ ] **Option 2: Call API riêng**
  - [ ] Thêm endpoint `/settings/users` trong service
  - [ ] Call sau khi login thành công
  
- [ ] **Option 3: Chỉ lưu userId**
  - [ ] Nullable fields trong UserEntity
  - [ ] Fetch user info trong ProfileScreen

### **Testing**
- [ ] Test login → verify token được lưu
- [ ] Test app restart → verify token được restore
- [ ] Test change password → verify có Authorization header
- [ ] Test với invalid token → verify logout

### **Verification**
- [ ] Add debug log trong `AuthRequestInterceptor.onRequest()`
- [ ] Verify header format: `Authorization: Bearer {token}`
- [ ] Check token không empty
- [ ] Check user info được parse đúng

---

## 📝 Debug Commands

**Check token trong storage**:
```dart
// Trong AppProvider.restore()
debugPrint('🔍 Restored token: ${savedAuthInfo?.accessToken?.substring(0, 20)}...');
debugPrint('🔍 User: ${savedAuthInfo?.user.email}');
```

**Check token trong interceptor**:
```dart
// Trong AuthRequestInterceptor.onRequest()
debugPrint('🔐 Token: ${accessToken?.substring(0, 20) ?? "NULL"}...');
debugPrint('🔐 Header: ${options.headers["Authorization"]}');
```

**Check API request**:
```dart
// CurlInterceptor already logs this
// Look for: Authorization: Bearer eyJhbG...
```

---

## 🎓 Kết Luận

**Nguyên nhân chính**: 
- API response sử dụng **snake_case** (`access_token`)
- DTO mapping sử dụng **camelCase** (`accessToken`)
- → Parse failed → Token = null → Header không có Authorization

**Giải pháp**:
1. ✅ Sửa `AuthResponseDto.fromJson()` để map đúng keys
2. ✅ Parse user info từ JWT token (option 1) hoặc call API riêng (option 2)
3. ✅ Verify Authorization header format (đã đúng, không cần sửa)

**Authorization Header Format**:
- ✅ Format: `Authorization: Bearer {access_token}`
- ✅ Interceptor đã implement đúng
- ✅ Chỉ cần fix parsing để có token

**Tuân thủ Clean Architecture**: ✅
- JWT decoder trong `core/utils/` (accessible by all)
- DTO parsing trong `data/dto/`
- Entity không biết về JWT hay API format
- Import rules được tuân thủ

---

## 📚 Tài Liệu Tham Khảo

- RFC 6750: OAuth 2.0 Bearer Token Usage
- JWT.io: JSON Web Token Introduction
- Keycloak Documentation (backend sử dụng Keycloak)
- `Rules.md` - Project coding standards
- `FIX_CHANGE_PASSWORD_AUTH_HEADER.md` - Token flow

