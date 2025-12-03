# GIẢI THÍCH CHI TIẾT: DATA LAYER VÀ CÁCH PHÂN BIỆT ENTITY

## ❓ CÂU HỎI

> "Giải thích kỹ hơn về cách mà lớp Data làm việc khi call tới API. Hiện tại tôi chưa hiểu tại sao Data có thể nhận biết được thông tin đâu là UserEntity và đâu là AuthEntity?"

---

## 🎯 LUỒNG ĐẦY ĐỦ: TỪ API → ENTITY

### Bức tranh tổng quan:

```
Backend API Response (JSON)
    ↓
AuthService.g.dart (Retrofit auto-generated) → Parse JSON
    ↓
AuthResponseDto (Data Transfer Object)
    ↓
AuthResponseDto.toEntity() (Extension method) → Convert DTO → Entity
    ↓
AuthInfo (Domain Entity) + UserEntity (Domain Entity)
    ↓
Trả về cho UseCase/Repository
```

---

## 📦 STEP 1: API RESPONSE (JSON từ Backend)

Khi gọi API `/fw-api/settings/login`, backend trả về JSON:

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_here",
  "expiresIn": 3600,
  "user": {
    "id": "user123",
    "firstName": "Khiem",
    "lastName": "Pham",
    "email": "khiempg@vietmap.vn",
    "phone": "0123456789"
  },
  "success": true,
  "message": "Login successful"
}
```

**Lưu ý:**
- `user` là **nested object** bên trong response
- Backend định nghĩa structure này

---

## 🔧 STEP 2: AUTHSERVICE - RETROFIT AUTO-PARSE

### File: `auth_service.dart`

```dart
@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio, {String? baseUrl}) = _AuthService;

  @POST('/fw-api/settings/login')
  Future<AuthResponseDto> login(@Body() LoginDto request);
  //                ↑
  // Retrofit sẽ tự động parse JSON response → AuthResponseDto
}
```

### File auto-generated: `auth_service.g.dart`

Retrofit tự động generate code parse JSON:

```dart
// Simplified version của auth_service.g.dart
class _AuthService implements AuthService {
  Future<AuthResponseDto> login(LoginDto request) async {
    final response = await _dio.post('/fw-api/settings/login', data: request.toJson());
    
    // ✅ Retrofit tự động gọi AuthResponseDto.fromJson()
    return AuthResponseDto.fromJson(response.data);
  }
}
```

**→ Retrofit biết phải parse thành `AuthResponseDto` vì:**
- Method `login()` return type là `Future<AuthResponseDto>`
- Retrofit tự động gọi `AuthResponseDto.fromJson(json)`

---

## 📋 STEP 3: DTO - PARSE JSON → OBJECT

### File: `auth_dto.dart`

```dart
class AuthResponseDto {
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final UserDto? user;  // ← ĐÂY! UserDto nested object
  final bool? success;
  final String? message;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
      
      // ✅ Parse nested "user" object → UserDto
      user: json['user'] != null 
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>) 
          : null,
      
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }
}
```

**→ Cách nhận biết:**
1. JSON có key `"user"` → lấy value (là Map<String, dynamic>)
2. Pass vào `UserDto.fromJson()` để parse
3. Kết quả: `UserDto` object

### Parse UserDto:

```dart
class UserDto {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}
```

**→ Data Layer biết `user` là UserDto vì:**
- Developer định nghĩa: `final UserDto? user;`
- Trong `fromJson()`: `UserDto.fromJson(json['user'])`

---

## 🔄 STEP 4: DTO → ENTITY CONVERSION

### Extension Method: `toEntity()`

```dart
extension AuthResponseDtoX on AuthResponseDto {
  AuthInfo toEntity() {
    return AuthInfo(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
      expiresIn: expiresIn ?? 0,
      
      // ✅ Convert UserDto → UserEntity
      user: user?.toEntity() ?? UserEntity(...),
    );
  }
}

extension UserDtoX on UserDto {
  UserEntity toEntity() {
    return UserEntity(
      id: id ?? '',
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      email: email ?? '',
      phone: phone,
    );
  }
}
```

**→ Cách hoạt động:**

1. `AuthResponseDto.toEntity()` được gọi
2. Tạo `AuthInfo` (Domain Entity)
3. Trong đó, gọi `user?.toEntity()` → convert `UserDto` → `UserEntity`
4. Gắn `UserEntity` vào `AuthInfo`

---

## 📊 STEP 5: REPOSITORY - ORCHESTRATE

### File: `auth_repository.dart` (Data Layer)

```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;

  @override
  Future<AuthInfo> login(LoginRequest request) async {
    // 1. Convert Domain Request → DTO
    final dto = LoginDto(
      email: request.email,
      password: request.password,
    );
    
    // 2. Gọi API qua Service
    final response = await authService.login(dto);
    //    ↑ response là AuthResponseDto (đã parse từ JSON)
    
    // 3. Convert DTO → Entity
    return response.toEntity();
    //              ↑ Gọi extension method
    //     AuthResponseDto → AuthInfo (chứa UserEntity)
  }
}
```

**→ Luồng đầy đủ:**

```
LoginRequest (Domain)
    ↓
LoginDto (Data)
    ↓
AuthService.login() → API call
    ↓
JSON Response từ Backend
    ↓
Retrofit auto-parse → AuthResponseDto (chứa UserDto)
    ↓
response.toEntity() → AuthInfo (chứa UserEntity)
    ↓
Return về UseCase/AppProvider
```

---

## 🎓 TẠI SAO DATA LAYER BIẾT ĐÂU LÀ USER, ĐÂU LÀ AUTH?

### Trả lời ngắn gọn:

**Developer định nghĩa!**

### Chi tiết:

#### 1. **Backend API định nghĩa structure:**

```json
{
  "accessToken": "...",
  "user": { ... }  ← Backend quy định key "user" chứa thông tin user
}
```

#### 2. **DTO mapping theo Backend:**

```dart
class AuthResponseDto {
  final UserDto? user;  // ← Map key "user" từ JSON
  
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    user: json['user'] != null ? UserDto.fromJson(json['user']) : null,
    //     ↑ Lấy key "user" từ JSON
  }
}
```

#### 3. **Entity conversion theo business rule:**

```dart
extension AuthResponseDtoX on AuthResponseDto {
  AuthInfo toEntity() {
    return AuthInfo(
      user: user?.toEntity() ?? defaultUser,
      //     ↑ Convert UserDto → UserEntity
    );
  }
}
```

---

## 🔍 SO SÁNH: DTO vs ENTITY

### DTO (Data Transfer Object) - Data Layer

**Mục đích:**
- Match với JSON structure từ Backend
- Có thể nullable (`String?`) vì API có thể trả null
- Chỉ dùng trong Data Layer

```dart
class UserDto {
  final String? id;        // ← Nullable vì API có thể null
  final String? firstName;
  final String? email;
  
  // Parse từ JSON
  factory UserDto.fromJson(Map<String, dynamic> json) { ... }
}
```

### Entity - Domain Layer

**Mục đích:**
- Đại diện business object
- Non-nullable nếu business yêu cầu
- Dùng xuyên suốt app (Presentation, Domain)

```dart
class UserEntity {
  final String id;        // ← Non-nullable vì business yêu cầu
  final String firstName;
  final String email;
  final String? phone;    // ← Nullable nếu optional
  
  // Computed properties
  String get fullName => '$firstName $lastName';
}
```

### Tại sao tách DTO và Entity?

```
┌────────────────────────────────────────────────────┐
│  API structure ≠ Business logic structure         │
│                                                     │
│  DTO: Phụ thuộc Backend                           │
│  Entity: Phụ thuộc Business Logic                 │
└────────────────────────────────────────────────────┘
```

**Ví dụ:**

Backend trả:
```json
{
  "first_name": "Khiem",  // ← snake_case
  "last_name": "Pham"
}
```

DTO:
```dart
class UserDto {
  @JsonKey(name: 'first_name')
  final String? firstName;  // ← Map snake_case → camelCase
}
```

Entity:
```dart
class UserEntity {
  final String firstName;  // ← Clean, không quan tâm Backend format
}
```

---

## 🎯 DIAGRAM: LUỒNG ĐẦY ĐỦ

```
┌─────────────────────────────────────────────────────────────┐
│                     BACKEND API                              │
│  POST /fw-api/settings/login                                │
│  Response: {                                                 │
│    "accessToken": "...",                                     │
│    "user": { "id": "...", "firstName": "...", ... }         │
│  }                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │ JSON
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              RETROFIT (auth_service.g.dart)                  │
│  - Nhận JSON từ API                                         │
│  - Auto-parse: AuthResponseDto.fromJson(json)               │
└────────────────────────┬────────────────────────────────────┘
                         │ AuthResponseDto
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                   AuthResponseDto (DTO)                      │
│  {                                                           │
│    accessToken: "...",                                       │
│    user: UserDto { id: "...", firstName: "..." }  ← Nested  │
│  }                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │ .toEntity()
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Extension: toEntity()                           │
│  - AuthResponseDto → AuthInfo                               │
│  - UserDto → UserEntity                                     │
└────────────────────────┬────────────────────────────────────┘
                         │ AuthInfo (Entity)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                   AuthInfo (Entity)                          │
│  {                                                           │
│    accessToken: "...",                                       │
│    user: UserEntity { id: "...", firstName: "..." }         │
│  }                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │ Return
                         ↓
┌─────────────────────────────────────────────────────────────┐
│            UseCase / AppProvider / UI                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 CÁCH NHẬN BIẾT USER vs AUTH

### 1. **Theo cấu trúc JSON từ Backend:**

```json
{
  // ← ĐÂY LÀ AUTH INFO (level 1)
  "accessToken": "...",
  "refreshToken": "...",
  "expiresIn": 3600,
  
  // ← ĐÂY LÀ USER INFO (level 2, nested)
  "user": {
    "id": "...",
    "firstName": "...",
    ...
  }
}
```

### 2. **Theo mapping trong DTO:**

```dart
class AuthResponseDto {
  // Auth-related fields
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  
  // User nested object
  final UserDto? user;  // ← Định nghĩa rõ ràng
}
```

### 3. **Theo business logic trong Entity:**

```dart
class AuthInfo {
  // Authentication tokens
  final String accessToken;
  final String refreshToken;
  
  // User information
  final UserEntity user;  // ← AuthInfo "có" (contains) UserEntity
}
```

**→ Relationship:**

```
AuthInfo (1) ──── chứa ───→ (1) UserEntity

"Một AuthInfo chứa thông tin của một User"
```

---

## 🔑 KEY POINTS

### 1. **Retrofit auto-parse JSON:**
- Return type `Future<AuthResponseDto>` → Retrofit gọi `AuthResponseDto.fromJson()`

### 2. **DTO có nested object:**
- `AuthResponseDto` chứa `UserDto`
- Parse theo structure JSON từ Backend

### 3. **Extension method convert DTO → Entity:**
- `AuthResponseDto.toEntity()` → `AuthInfo`
- `UserDto.toEntity()` → `UserEntity`

### 4. **Repository orchestrate:**
- Nhận `LoginRequest` (Domain)
- Convert → `LoginDto` (Data)
- Call API → nhận `AuthResponseDto` (Data)
- Convert → `AuthInfo` (Domain)
- Return về UseCase

### 5. **Tách biệt concerns:**
- **DTO:** Phụ thuộc Backend structure
- **Entity:** Phụ thuộc Business logic
- **Repository:** Bridge giữa Data và Domain

---

## 📝 CODE EXAMPLE: FULL FLOW

### Step 1: Domain Request
```dart
// UseCase gọi Repository
final request = LoginRequest(email: 'khiempg@vietmap.vn', password: '123456');
final authInfo = await authRepository.login(request);
```

### Step 2: Repository convert Request → DTO
```dart
final dto = LoginDto(email: request.email, password: request.password);
```

### Step 3: Service call API
```dart
final response = await authService.login(dto);
// Retrofit auto-parse: AuthResponseDto.fromJson(jsonResponse)
```

### Step 4: DTO structure
```dart
AuthResponseDto {
  accessToken: "eyJhbG...",
  refreshToken: "refresh...",
  expiresIn: 3600,
  user: UserDto {
    id: "user123",
    firstName: "Khiem",
    lastName: "Pham",
    email: "khiempg@vietmap.vn",
    phone: "0123456789"
  }
}
```

### Step 5: Convert DTO → Entity
```dart
final authInfo = response.toEntity();

// Internally:
// 1. Create AuthInfo
// 2. Convert user (UserDto) → UserEntity via user.toEntity()
// 3. Return AuthInfo(accessToken: ..., user: UserEntity(...))
```

### Step 6: Result Entity
```dart
AuthInfo {
  accessToken: "eyJhbG...",
  refreshToken: "refresh...",
  expiresIn: 3600,
  user: UserEntity {
    id: "user123",
    firstName: "Khiem",
    lastName: "Pham",
    email: "khiempg@vietmap.vn",
    phone: "0123456789"
  }
}
```

---

## ✅ TÓM TẮT

### Câu trả lời cho câu hỏi:

**"Tại sao Data Layer biết đâu là UserEntity, đâu là AuthEntity?"**

**Trả lời:**

1. **Backend định nghĩa structure JSON** với key `"user"` nested trong response

2. **Developer map DTO theo Backend:**
   ```dart
   class AuthResponseDto {
     final UserDto? user;  // ← Mapping key "user"
   }
   ```

3. **Extension method convert DTO → Entity:**
   ```dart
   AuthInfo toEntity() {
     return AuthInfo(
       user: user?.toEntity(),  // UserDto → UserEntity
     );
   }
   ```

4. **Retrofit auto-parse** dựa trên return type của method

5. **Repository orchestrate** toàn bộ flow: Request → DTO → API → DTO → Entity

### Nguyên tắc:

```
┌──────────────────────────────────────────────────────┐
│  Backend Structure (JSON)                            │
│      ↓ định nghĩa                                    │
│  DTO (Data Layer) - Match với JSON                  │
│      ↓ convert                                       │
│  Entity (Domain Layer) - Match với Business Logic   │
└──────────────────────────────────────────────────────┘
```

**Data Layer không tự "nhận biết" mà được Developer định nghĩa rõ ràng qua:**
- DTO class structure
- fromJson() mapping
- toEntity() conversion
- Retrofit annotation

---

✅ **Hy vọng giải thích này giúp bạn hiểu rõ luồng Data Layer!**

