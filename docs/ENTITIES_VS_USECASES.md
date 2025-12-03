# PHÂN BIỆT ENTITIES VÀ USECASES - TÓM TẮT NHANH

## 🎯 CẤU TRÚC DOMAIN LAYER

```
lib/domain/
├── entities/        ← 📦 DATA (danh từ)
│   ├── auth_entity.dart       → AuthInfo, UserEntity
│   └── auth_request.dart      → LoginRequest, RegisterRequest
│
├── usecases/        ← 🎯 LOGIC (động từ)  
│   └── auth/
│       ├── login_usecase.dart      → LoginUseCase
│       ├── logout_usecase.dart     → LogoutUseCase
│       ├── register_usecase.dart   → RegisterUseCase
│       └── ...
│
└── repository/      ← 📝 INTERFACE (contract)
    └── auth_repository.dart
```

---

## 📦 ENTITIES (Data Models)

### Là gì?
- **Pure data structures** - Chỉ chứa dữ liệu
- Đại diện cho các đối tượng nghiệp vụ

### Ví dụ:
```dart
// ✅ Đây là ENTITY
class UserEntity {
  final String id;
  final String email;
  final String firstName;
  
  UserEntity({required this.id, required this.email, required this.firstName});
}

class AuthInfo {
  final String accessToken;
  final UserEntity user;
}
```

### Đặc điểm:
- ✅ Chỉ có properties (fields)
- ✅ Có thể có: `toJson()`, `fromJson()`, `copyWith()`, `==`, `hashCode`
- ❌ KHÔNG có business logic
- ❌ KHÔNG gọi Repository
- ❌ KHÔNG có async methods

---

## 🎯 USECASES (Business Logic)

### Là gì?
- **Business logic của app**
- Mỗi UseCase = 1 hành động user có thể làm

### Ví dụ:
```dart
// ✅ Đây là USECASE
class LoginUseCase {
  final AuthRepository _repository;
  
  LoginUseCase(this._repository);
  
  Future<AuthInfo> execute(LoginRequest request) async {
    // Có thể thêm validation, analytics, logging...
    return await _repository.login(request);
  }
}
```

### Đặc điểm:
- ✅ Chứa business logic
- ✅ Gọi Repository (1 hoặc nhiều)
- ✅ Có async operations
- ✅ Method chính: `execute()` hoặc `call()`
- ❌ KHÔNG trực tiếp gọi API (gọi qua Repository)

---

## 🔄 LUỒNG SỬ DỤNG

```
UI (Screen)
    ↓
Provider (State Management)
    ↓
UseCase (Business Logic)    ← 🎯 Ở đây
    ↓
Repository (Interface)
    ↓
Repository Implementation
    ↓
Service (API Call)
```

### Ví dụ cụ thể - Logout:

```dart
// 1. UI
ElevatedButton(
  onPressed: () => provider.logout(),
  child: Text('Logout'),
)

// 2. Provider
class ProfileProvider {
  final LogoutUseCase _logoutUseCase;  // ← Inject UseCase
  
  Future<void> logout() async {
    await _logoutUseCase.execute();    // ← Gọi UseCase
  }
}

// 3. UseCase
class LogoutUseCase {
  final AuthRepository _repository;
  
  Future<void> execute() async {
    await _repository.logout();        // ← Gọi Repository
  }
}

// 4. Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _service;
  
  Future<void> logout() async {
    await _service.logout();           // ← Gọi API
  }
}
```

---

## 📊 SO SÁNH NHANH

| | **ENTITY** | **USECASE** |
|---|---|---|
| **Kiểu** | Danh từ | Động từ |
| **Chức năng** | Lưu data | Thực thi logic |
| **Ví dụ** | User, Product, Order | Login, Logout, GetProfile |
| **Có logic?** | ❌ Không | ✅ Có |
| **Gọi Repository?** | ❌ Không | ✅ Có |
| **Async?** | ❌ Không | ✅ Có |

---

## ✅ TRẢ LỜI CÂU HỎI CỦA BẠN

### Q: "Entities và UseCases ở cùng thư mục domain có đúng không?"
**A: ✅ ĐÚNG!** Cả 2 đều thuộc **Domain Layer** trong Clean Architecture

### Q: "Điểm nào phân biệt Entities và UseCases?"
**A:**
- **Entities** = 📦 **DATA** (User, Product, AuthInfo)
- **UseCases** = 🎯 **LOGIC** (Login, Logout, GetUser)

### Q: "Có đảm bảo Clean Architecture không?"
**A: ✅ CÓ!** Vì:
1. ✅ Domain Layer độc lập (không depend vào Data/Presentation)
2. ✅ UseCases gọi Repository (interface), không gọi trực tiếp API
3. ✅ Dependency Rule: Presentation → Domain → Data
4. ✅ Business logic ở UseCase, không ở Provider hay Repository

---

## 🎓 GHI NHỚ

```
📦 Entity   = Danh từ  = Data       = UserEntity, AuthInfo
🎯 UseCase  = Động từ  = Logic      = LoginUseCase, LogoutUseCase
📝 Repository = Interface = Contract = AuthRepository
```

**Nguyên tắc vàng:**
> **Provider gọi UseCase, UseCase gọi Repository, Repository gọi Service**

---

✅ **Dự án của bạn tuân thủ đúng Clean Architecture!**

