# DOMAIN LAYER - ENTITIES VS USECASES

## 📋 TỔNG QUAN CẤU TRÚC

```
lib/domain/
├── entities/           ← Data Models (Pure Data)
│   ├── auth_entity.dart
│   └── auth_request.dart
├── repository/         ← Interfaces (Contracts)
│   └── auth_repository.dart
├── usecases/          ← Business Logic
│   └── auth/
│       ├── login_usecase.dart
│       ├── register_usecase.dart
│       ├── logout_usecase.dart
│       ├── get_auth_info_usecase.dart
│       └── save_auth_info_usecase.dart
└── domain.dart        ← Barrel export file
```

---

## 🎯 SỰ KHÁC BIỆT: ENTITIES VS USECASES

### 1. **ENTITIES** (Thư mục `entities/`)

#### 📝 Định nghĩa:
- **Pure Data Models** - Chỉ chứa dữ liệu, KHÔNG chứa logic
- Đại diện cho các đối tượng nghiệp vụ trong ứng dụng
- Không phụ thuộc vào bất kỳ layer nào khác

#### 🎯 Mục đích:
- Định nghĩa cấu trúc dữ liệu của domain
- Được sử dụng xuyên suốt các layer (Presentation, Domain, Data)
- Tách biệt domain models khỏi DTO (Data Transfer Objects)

#### 📦 Trong dự án của bạn:

**File: `auth_entity.dart`**
```dart
class AuthInfo {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserEntity user;
  
  // Constructor, fromJson, toJson...
}

class UserEntity {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  
  // Constructor, fromJson, toJson...
}
```
**→ Đây là ENTITY vì:** Chỉ chứa data, không có business logic

---

**File: `auth_request.dart`**
```dart
class LoginRequest {
  final String email;
  final String password;
  
  LoginRequest({required this.email, required this.password});
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String password;
  final String email;
  final String? phone;
  
  RegisterRequest({...});
}
```
**→ Đây KHÔNG PHẢI là Entity thuần túy, mà là Input Model**

**⚠️ NHẦM LẪN THƯỜNG GÂP:**
- `LoginRequest` và `RegisterRequest` đang ở trong `entities/` 
- Nhưng chúng là **Input Models** cho UseCases, không phải domain entities
- **Nên để ở:** `domain/models/` hoặc `domain/requests/`

#### ✅ Đặc điểm của Entities:
- ✅ Chỉ chứa properties (fields)
- ✅ Có thể có methods: `toJson()`, `fromJson()`, `copyWith()`, equality
- ❌ KHÔNG có business logic
- ❌ KHÔNG gọi Repository
- ❌ KHÔNG có async operations

---

### 2. **USECASES** (Thư mục `usecases/`)

#### 📝 Định nghĩa:
- **Business Logic của ứng dụng**
- Chứa các "hành động" (actions) mà user có thể thực hiện
- Gọi Repository để lấy/gửi data

#### 🎯 Mục đích:
- Tách biệt business logic khỏi UI (Presentation Layer)
- Single Responsibility: Mỗi UseCase làm 1 việc duy nhất
- Dễ test, dễ maintain
- Tuân thủ Clean Architecture: Presentation → UseCase → Repository

#### 📦 Trong dự án của bạn:

**File: `login_usecase.dart`**
```dart
class LoginUseCase {
  final AuthRepository _authRepository;
  
  LoginUseCase(this._authRepository);
  
  Future<AuthInfo> execute(LoginRequest request) async {
    // Business logic ở đây (validation, analytics, etc.)
    return await _authRepository.login(request);
  }
}
```
**→ Đây là USECASE vì:** 
- Có business logic (execute method)
- Gọi Repository
- Xử lý 1 use case cụ thể: "User muốn login"

---

**File: `logout_usecase.dart`**
```dart
class LogoutUseCase {
  final AuthRepository _authRepository;
  
  LogoutUseCase(this._authRepository);
  
  Future<void> execute() async {
    await _authRepository.logout();
  }
}
```
**→ Đây là USECASE vì:** Xử lý use case "User muốn logout"

#### ✅ Đặc điểm của UseCases:
- ✅ Chứa business logic
- ✅ Gọi Repository (1 hoặc nhiều)
- ✅ Có async operations
- ✅ Có thể combine nhiều repository calls
- ✅ Có thể thêm validation, logging, analytics
- ✅ Method chính thường tên là `execute()` hoặc `call()`
- ❌ KHÔNG trực tiếp gọi API/Database (gọi qua Repository)
- ❌ KHÔNG quản lý UI state (để cho Provider)

---

## 📊 SO SÁNH TRỰC TIẾP

| Khía cạnh | **ENTITIES** | **USECASES** |
|-----------|-------------|--------------|
| **Mục đích** | Định nghĩa data structure | Thực thi business logic |
| **Chứa gì?** | Properties (fields) | Methods (actions) |
| **Có logic?** | ❌ Không | ✅ Có |
| **Gọi Repository?** | ❌ Không | ✅ Có |
| **Async?** | ❌ Thường không | ✅ Thường có |
| **Ví dụ** | `AuthInfo`, `UserEntity` | `LoginUseCase`, `LogoutUseCase` |
| **Tương đương** | Model, DTO, POJO | Service, Interactor |

---

## 🔄 LUỒNG SỬ DỤNG

### ❌ SAI (Không có UseCase):
```
ProfileProvider → AuthRepository.logout() → AuthService (API)
```
**Vấn đề:** Business logic bị nhét vào Provider hoặc Repository

### ✅ ĐÚNG (Có UseCase):
```
ProfileProvider → LogoutUseCase.execute() → AuthRepository.logout() → AuthService
```
**Ưu điểm:** Business logic ở UseCase, dễ test, dễ maintain

---

## 🎓 VÍ DỤ CỤ THỂ

### Scenario: User muốn login

#### 1. **Entity (Data)**
```dart
// Input data
class LoginRequest {
  final String email;
  final String password;
}

// Output data
class AuthInfo {
  final String accessToken;
  final UserEntity user;
}
```

#### 2. **UseCase (Business Logic)**
```dart
class LoginUseCase {
  final AuthRepository _repo;
  
  Future<AuthInfo> execute(LoginRequest request) async {
    // ✅ Có thể validate
    if (!_isValidEmail(request.email)) {
      throw InvalidEmailException();
    }
    
    // ✅ Có thể log analytics
    _analytics.logEvent('login_attempt');
    
    // ✅ Gọi repository
    final authInfo = await _repo.login(request);
    
    // ✅ Có thể xử lý thêm
    _analytics.logEvent('login_success', userId: authInfo.user.id);
    
    return authInfo;
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}
```

#### 3. **Provider (Presentation)**
```dart
class LoginProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final request = LoginRequest(email: email, password: password);
      final authInfo = await _loginUseCase.execute(request); // ← Gọi UseCase
      
      // Update UI state
      _user = authInfo.user;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## 🚨 NHẦM LẪN THƯỜNG GẶP

### ❌ Nhầm 1: Đặt Request Models vào `entities/`
```dart
// ❌ SAI: auth_request.dart trong entities/
class LoginRequest { ... }  // Đây KHÔNG phải Entity
```

**✅ ĐÚNG:**
```
domain/
├── entities/          ← Chỉ domain models
│   ├── user.dart
│   └── auth_info.dart
├── models/           ← Input/Output models
│   ├── login_request.dart
│   └── register_request.dart
└── usecases/
    └── auth/
        └── login_usecase.dart
```

### ❌ Nhầm 2: Nhét business logic vào Entity
```dart
// ❌ SAI
class UserEntity {
  final String email;
  
  Future<bool> isEmailAvailable() async {  // ← KHÔNG nên có async logic
    return await repository.checkEmail(email);
  }
}
```

**✅ ĐÚNG:** Tạo UseCase riêng
```dart
class CheckEmailAvailabilityUseCase {
  Future<bool> execute(String email) async {
    return await repository.checkEmail(email);
  }
}
```

### ❌ Nhầm 3: Provider gọi trực tiếp Repository
```dart
// ❌ SAI
class ProfileProvider {
  final AuthRepository _repo;
  
  Future<void> logout() async {
    await _repo.logout();  // ← Bỏ qua UseCase
  }
}
```

**✅ ĐÚNG:**
```dart
class ProfileProvider {
  final LogoutUseCase _logoutUseCase;
  
  Future<void> logout() async {
    await _logoutUseCase.execute();  // ← Qua UseCase
  }
}
```

---

## 📏 QUY TẮC THIẾT KẾ

### Khi nào tạo Entity?
✅ Khi cần định nghĩa domain model (User, Product, Order, etc.)
✅ Khi cần data structure dùng chung giữa các layer

### Khi nào tạo UseCase?
✅ Mỗi khi có 1 action/feature mới (Login, Logout, GetProfile, UpdateProfile)
✅ Khi có business logic phức tạp cần tách ra
✅ Khi muốn test business logic độc lập

### Khi nào KHÔNG cần UseCase?
❌ Getter/Setter đơn giản không có logic
❌ Pure UI logic (animation, navigation state)
❌ Formatting, parsing đơn giản

---

## ✅ KẾT LUẬN

### Cấu trúc hiện tại của bạn:

```
domain/
├── entities/
│   ├── auth_entity.dart     ✅ ĐÚNG - Là entity
│   └── auth_request.dart    ⚠️ NÊN MOVE - Là input model, không phải entity
├── repository/
│   └── auth_repository.dart ✅ ĐÚNG
└── usecases/
    └── auth/
        ├── login_usecase.dart    ✅ ĐÚNG
        ├── logout_usecase.dart   ✅ ĐÚNG
        └── ...                   ✅ ĐÚNG
```

### ✅ VẪN ĐẢM BẢO CLEAN ARCHITECTURE vì:

1. ✅ **Entities và UseCases tách biệt rõ ràng**
2. ✅ **UseCases không phụ thuộc vào Data layer**
3. ✅ **UseCases gọi Repository (interface), không gọi trực tiếp API**
4. ✅ **Presentation → UseCase → Repository → Data**
5. ✅ **Dependency Rule được tuân thủ**

### 🔧 Gợi ý cải thiện (optional):

Nếu muốn chuẩn hơn, tách `auth_request.dart` ra:

```
domain/
├── entities/          ← Pure domain models
│   ├── user.dart
│   └── auth_info.dart
├── models/           ← Input/Output models
│   └── requests/
│       ├── login_request.dart
│       └── register_request.dart
├── repository/
└── usecases/
```

Nhưng **KHÔNG bắt buộc** - cấu trúc hiện tại vẫn đúng!

---

## 🎯 TÓM TẮT

| **Entities** | **UseCases** |
|-------------|-------------|
| 📦 Data structure | 🎯 Business logic |
| Là danh từ (User, Product) | Là động từ (Login, Logout, GetProfile) |
| Passive (data holder) | Active (executor) |
| Không gọi Repository | Gọi Repository |
| `class UserEntity { ... }` | `class LoginUseCase { execute() {...} }` |

**Câu trả lời cho câu hỏi của bạn:**
- ✅ **UseCases ở đúng chỗ**: `domain/usecases/auth/`
- ✅ **Entities ở đúng chỗ**: `domain/entities/`
- ✅ **VẪN đảm bảo Clean Architecture** vì tách biệt rõ ràng data vs logic
- ⚠️ **Lưu ý nhỏ**: `auth_request.dart` là input models, không hoàn toàn là entities, nhưng vẫn OK để trong `entities/` nếu project nhỏ

✅ **Kết luận: Dự án của bạn tuân thủ Clean Architecture đúng chuẩn!**

