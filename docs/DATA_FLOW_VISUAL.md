# VISUAL DIAGRAM: DATA LAYER FLOW

## 🎨 LUỒNG HOÀN CHỈNH: LOGIN API CALL

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. UI/PROVIDER: User nhấn "Login"                                  │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  2. UseCase: LoginUseCase.execute()                                 │
│     Input: LoginRequest { email, password }                         │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  3. Repository: AuthRepositoryImpl.login(request)                   │
│     ┌──────────────────────────────────────────────────────────┐   │
│     │ STEP 1: Convert Request → DTO                            │   │
│     │ LoginRequest (Domain) → LoginDto (Data)                  │   │
│     │                                                           │   │
│     │ LoginDto {                                               │   │
│     │   email: "khiempg@vietmap.vn",                          │   │
│     │   password: "123456"                                     │   │
│     │ }                                                         │   │
│     └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  4. Service: AuthService.login(dto)                                 │
│     POST /fw-api/settings/login                                     │
│     Body: { "email": "...", "password": "..." }                     │
└────────────────────────┬────────────────────────────────────────────┘
                         │ HTTP Request
                         ▼
╔═════════════════════════════════════════════════════════════════════╗
║                      🌐 BACKEND API                                 ║
║  Xử lý login → Tạo token → Trả về JSON                             ║
╚═════════════════════════╦═══════════════════════════════════════════╝
                         │ JSON Response
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  5. JSON Response từ Backend:                                       │
│  {                                                                   │
│    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",       │
│    "refreshToken": "refresh_token_here",                            │
│    "expiresIn": 3600,                                               │
│    "user": {                    ◄─── NESTED OBJECT                  │
│      "id": "user123",                                               │
│      "firstName": "Khiem",                                          │
│      "lastName": "Pham",                                            │
│      "email": "khiempg@vietmap.vn",                                │
│      "phone": "0123456789"                                          │
│    },                                                                │
│    "success": true,                                                 │
│    "message": "Login successful"                                    │
│  }                                                                   │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  6. Retrofit (auth_service.g.dart) Auto-Parse:                     │
│     ┌──────────────────────────────────────────────────────────┐   │
│     │ AuthResponseDto.fromJson(jsonResponse)                   │   │
│     │                                                           │   │
│     │ Parse "accessToken" → String                             │   │
│     │ Parse "refreshToken" → String                            │   │
│     │ Parse "expiresIn" → int                                  │   │
│     │ Parse "user" → UserDto.fromJson(json['user']) ◄─ KEY!   │   │
│     └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  7. AuthResponseDto (Parsed Object):                                │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ AuthResponseDto {                                          │    │
│  │   accessToken: "eyJhbG...",                               │    │
│  │   refreshToken: "refresh...",                             │    │
│  │   expiresIn: 3600,                                        │    │
│  │   user: UserDto {              ◄─── NESTED DTO            │    │
│  │     id: "user123",                                        │    │
│  │     firstName: "Khiem",                                   │    │
│  │     lastName: "Pham",                                     │    │
│  │     email: "khiempg@vietmap.vn",                         │    │
│  │     phone: "0123456789"                                   │    │
│  │   },                                                       │    │
│  │   success: true,                                          │    │
│  │   message: "Login successful"                             │    │
│  │ }                                                          │    │
│  └────────────────────────────────────────────────────────────┘    │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  8. Repository: response.toEntity()                                 │
│     ┌──────────────────────────────────────────────────────────┐   │
│     │ Extension: AuthResponseDtoX.toEntity()                   │   │
│     │                                                           │   │
│     │ AuthInfo {                                               │   │
│     │   accessToken: "eyJhbG...",                             │   │
│     │   refreshToken: "refresh...",                           │   │
│     │   expiresIn: 3600,                                      │   │
│     │   user: user?.toEntity() ◄─ Gọi UserDtoX.toEntity()    │   │
│     │ }                                                         │   │
│     └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  9. Extension: UserDtoX.toEntity()                                  │
│     ┌──────────────────────────────────────────────────────────┐   │
│     │ UserDto → UserEntity                                     │   │
│     │                                                           │   │
│     │ UserEntity {                                             │   │
│     │   id: "user123",                                         │   │
│     │   firstName: "Khiem",                                    │   │
│     │   lastName: "Pham",                                      │   │
│     │   email: "khiempg@vietmap.vn",                          │   │
│     │   phone: "0123456789"                                    │   │
│     │ }                                                         │   │
│     └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  10. AuthInfo (Final Domain Entity):                                │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ AuthInfo {                                                 │    │
│  │   accessToken: "eyJhbG...",                               │    │
│  │   refreshToken: "refresh...",                             │    │
│  │   expiresIn: 3600,                                        │    │
│  │   user: UserEntity {          ◄─── NESTED ENTITY          │    │
│  │     id: "user123",                                        │    │
│  │     firstName: "Khiem",                                   │    │
│  │     lastName: "Pham",                                     │    │
│  │     email: "khiempg@vietmap.vn",                         │    │
│  │     phone: "0123456789"                                   │    │
│  │   }                                                        │    │
│  │ }                                                          │    │
│  └────────────────────────────────────────────────────────────┘    │
└────────────────────────┬────────────────────────────────────────────┘
                         │ Return
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  11. UseCase trả về AuthInfo cho Provider                           │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  12. Provider update UI state                                       │
│      - authInfo.add(authInfo)                                       │
│      - isLoggedIn.add(true)                                         │
│      - Navigate to Home                                             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔍 ĐIỂM QUAN TRỌNG: CÁCH NHẬN BIẾT USER vs AUTH

### 📍 Tại Backend (JSON):

```json
{
  // ← CẤP 1: Auth Info
  "accessToken": "...",
  "refreshToken": "...",
  "expiresIn": 3600,
  
  // ← CẤP 2: User Info (Nested)
  "user": {
    "id": "...",
    ...
  }
}
```

### 📍 Tại DTO (Data Layer):

```dart
class AuthResponseDto {
  // Auth fields
  final String? accessToken;
  final String? refreshToken;
  
  // User nested object
  final UserDto? user;  // ← Developer định nghĩa
  
  factory AuthResponseDto.fromJson(Map json) {
    return AuthResponseDto(
      user: json['user'] != null 
          ? UserDto.fromJson(json['user'])  // ← Parse nested
          : null,
    );
  }
}
```

### 📍 Tại Entity (Domain Layer):

```dart
class AuthInfo {
  // Auth fields
  final String accessToken;
  final String refreshToken;
  
  // User entity
  final UserEntity user;  // ← Relationship
}

// Extension convert
extension AuthResponseDtoX on AuthResponseDto {
  AuthInfo toEntity() {
    return AuthInfo(
      user: user?.toEntity(),  // ← Convert UserDto → UserEntity
    );
  }
}
```

---

## 🎯 TẠI SAO BIẾT ĐÂU LÀ USER?

```
┌────────────────────────────────────────────────────┐
│  1. Backend định nghĩa key "user" trong JSON      │
│         ↓                                          │
│  2. Developer map DTO theo Backend structure       │
│         ↓                                          │
│  3. fromJson() parse key "user" → UserDto         │
│         ↓                                          │
│  4. toEntity() convert UserDto → UserEntity       │
└────────────────────────────────────────────────────┘

KHÔNG có "tự động nhận biết" - Developer định nghĩa TẤT CẢ!
```

---

## 📊 DATA FLOW TABLE

| Bước | Layer | Input | Process | Output |
|------|-------|-------|---------|--------|
| 1 | Presentation | User action | Call UseCase | LoginRequest |
| 2 | Domain | LoginRequest | Pass to Repository | LoginRequest |
| 3 | Data | LoginRequest | Convert to LoginDto | LoginDto |
| 4 | Data | LoginDto | Call API | HTTP Request |
| 5 | Backend | HTTP Request | Process login | JSON Response |
| 6 | Data | JSON | Retrofit parse | AuthResponseDto |
| 7 | Data | AuthResponseDto | Parse nested "user" | UserDto |
| 8 | Data | AuthResponseDto | toEntity() | AuthInfo |
| 9 | Data | UserDto | toEntity() | UserEntity |
| 10 | Domain | AuthInfo | Return to UseCase | AuthInfo |
| 11 | Presentation | AuthInfo | Update state | UI update |

---

## 🔑 KEY CONCEPTS

### 1. Nested Object Parsing:

```
JSON "user": {...}
    ↓ parse
UserDto
    ↓ convert
UserEntity
```

### 2. Two-Level Structure:

```
AuthResponseDto           AuthInfo
    ├── accessToken   →      ├── accessToken
    ├── refreshToken  →      ├── refreshToken
    └── UserDto       →      └── UserEntity
            ↑                        ↑
        Parse nested            Convert nested
```

### 3. Extension Method Chain:

```dart
response.toEntity()
    ↓ calls
user?.toEntity()
    ↓ returns
UserEntity
    ↓ assigned to
AuthInfo.user
```

---

✅ **Data Layer "biết" đâu là User vì Developer định nghĩa rõ ràng qua:**
- DTO structure match Backend
- fromJson() mapping
- toEntity() conversion
- Extension methods

