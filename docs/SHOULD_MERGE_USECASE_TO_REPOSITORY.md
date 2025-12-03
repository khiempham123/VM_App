# CÓ NÊN GỘP USECASE VÀO REPOSITORY? - PHÂN TÍCH CHI TIẾT

## ❓ CÂU HỎI

> "Ta có thể tín gọn hơn bằng việc kết hợp UseCases vào Repository và chuyển đổi logic kiểm tra vào bên trong Data Repository trước bước call API hay không? Vì một phần logic phức tạp cũng sẽ được xử lý ở UI thông qua Provider."

---

## 🎯 TRẢ LỜI NGẮN GỌN

### ❌ **KHÔNG NÊN** gộp UseCase vào Repository

**Lý do:**
1. ❌ Vi phạm Clean Architecture
2. ❌ Vi phạm SOLID Principles
3. ❌ Khó test, khó maintain
4. ❌ Logic business bị rải rác (Repository + Provider)
5. ❌ Repository làm quá nhiều việc (God Object anti-pattern)

---

## 📊 SO SÁNH: KIẾN TRÚC HIỆN TẠI vs KIẾN TRÚC "GỘP USECASE"

### ✅ KIẾN TRÚC HIỆN TẠI (ĐÚNG - CLEAN ARCHITECTURE)

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                     │
│  ├── ProfileProvider                                    │
│  │   - Quản lý UI state (loading, error)               │
│  │   - Gọi UseCase                                      │
│  │   - Update UI khi có data                           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  DOMAIN LAYER (Business Logic)                         │
│  ├── LogoutUseCase                                      │
│  │   - Validate business rules                         │
│  │   - Orchestrate repository calls                    │
│  │   - Transform data nếu cần                          │
│  │   - Log analytics                                    │
│  │   - Handle cache                                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  DATA LAYER (Data Access)                              │
│  ├── AuthRepositoryImpl                                 │
│  │   - Convert Request → DTO                           │
│  │   - Call Service (API)                              │
│  │   - Convert Response (DTO → Entity)                 │
│  │   - KHÔNG chứa business logic                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  SERVICE LAYER (API Call)                              │
│  ├── AuthService                                        │
│  │   - Pure API calls                                   │
│  │   - Retrofit annotations                            │
└─────────────────────────────────────────────────────────┘
```

**Ưu điểm:**
- ✅ Mỗi layer có trách nhiệm rõ ràng (Single Responsibility)
- ✅ Business logic tập trung ở UseCase
- ✅ Dễ test từng layer riêng biệt
- ✅ Dễ thay đổi implementation (VD: đổi API → Database)
- ✅ Tuân thủ Dependency Rule (Domain không phụ thuộc Data)

---

### ❌ KIẾN TRÚC "GỘP USECASE" (SAI)

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                     │
│  ├── ProfileProvider                                    │
│  │   - Quản lý UI state                                │
│  │   - ⚠️ Một phần business logic ở đây               │
│  │   - Gọi trực tiếp Repository                        │
└────────────────────┬────────────────────────────────────┘
                     │ (Bỏ qua UseCase)
                     ▼
┌─────────────────────────────────────────────────────────┐
│  DATA LAYER (Quá nhiều trách nhiệm!)                   │
│  ├── AuthRepositoryImpl                                 │
│  │   - Convert Request → DTO                           │
│  │   - ⚠️ Validate business rules                     │
│  │   - ⚠️ Handle cache                                │
│  │   - ⚠️ Log analytics                               │
│  │   - Call Service (API)                              │
│  │   - Convert Response                                │
│  │   - ⚠️ Transform data                              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  SERVICE LAYER                                          │
│  ├── AuthService                                        │
└─────────────────────────────────────────────────────────┘
```

**Vấn đề:**
- ❌ Business logic rải rác (Provider + Repository)
- ❌ Repository làm quá nhiều việc (God Object)
- ❌ Vi phạm Single Responsibility Principle
- ❌ Khó test (phải mock cả API lẫn business logic)
- ❌ Không tuân thủ Clean Architecture
- ❌ Khó tái sử dụng logic (business logic gắn chặt với Repository)

---

## 🔍 PHÂN TÍCH CHI TIẾT

### 1. VI PHẠM CLEAN ARCHITECTURE

#### Clean Architecture Rules:

```
┌────────────────────────────────────────────────────┐
│  Dependency Rule:                                  │
│  Outer layers → Inner layers (một chiều)          │
│                                                     │
│  Presentation → Domain → Data                     │
│                                                     │
│  - Domain KHÔNG phụ thuộc Data                    │
│  - Business logic PHẢI ở Domain                   │
└────────────────────────────────────────────────────┘
```

#### Khi gộp UseCase vào Repository:

```
❌ Business logic ở Data Layer
    ↓
❌ Data Layer chứa business rules
    ↓
❌ Thay đổi business → phải sửa Data Layer
    ↓
❌ Vi phạm Dependency Rule
```

**Ví dụ cụ thể:**

```dart
// ❌ SAI: Business logic trong Repository
class AuthRepositoryImpl {
  Future<AuthInfo> login(LoginRequest request) async {
    // ❌ Validation ở Data Layer - SAI!
    if (request.email.isEmpty) {
      throw ValidationException('Email required');
    }
    if (!_isValidEmail(request.email)) {
      throw ValidationException('Invalid email format');
    }
    
    // ❌ Business rule ở Data Layer - SAI!
    if (_loginAttempts >= 3) {
      throw TooManyAttemptsException();
    }
    
    // ❌ Cache logic ở Data Layer - SAI!
    final cachedUser = await _cache.getUser(request.email);
    if (cachedUser != null && !cachedUser.isExpired) {
      return cachedUser;
    }
    
    // ❌ Analytics ở Data Layer - SAI!
    _analytics.logEvent('login_attempt');
    
    // OK: Chỉ nên có phần này
    final dto = LoginDto(email: request.email, password: request.password);
    final response = await authService.login(dto);
    return response.toEntity();
  }
}
```

**Tại sao SAI?**
- Repository là **Data Access Layer** - chỉ nên truy xuất dữ liệu
- Validation, business rules, cache, analytics là **Business Logic** - thuộc Domain Layer
- Khi business thay đổi (VD: cho phép 5 lần login), phải sửa Data Layer → sai nguyên tắc

---

### 2. VI PHẠM SINGLE RESPONSIBILITY PRINCIPLE (SOLID)

```
┌────────────────────────────────────────────────────┐
│  Single Responsibility Principle (SRP):            │
│  "Mỗi class chỉ nên có 1 lý do để thay đổi"       │
└────────────────────────────────────────────────────┘
```

#### Repository khi gộp UseCase:

```
AuthRepositoryImpl có nhiều lý do để thay đổi:

1. API endpoint thay đổi → sửa Repository
2. Business rule thay đổi → sửa Repository
3. Validation rule thay đổi → sửa Repository
4. Cache strategy thay đổi → sửa Repository
5. Analytics event thay đổi → sửa Repository
6. DTO format thay đổi → sửa Repository

❌ VI PHẠM SRP!
```

#### Kiến trúc đúng:

```
✅ UseCase: Thay đổi khi business logic thay đổi
✅ Repository: Thay đổi khi data source thay đổi
✅ Service: Thay đổi khi API thay đổi
```

---

### 3. KHÓ TEST

#### Với UseCase riêng biệt:

```dart
// ✅ DỄ TEST: Mock Repository
test('LogoutUseCase should call repository', () async {
  // Arrange
  final mockRepo = MockAuthRepository();
  final useCase = LogoutUseCase(mockRepo);
  
  when(mockRepo.logout()).thenAnswer((_) async => Future.value());
  
  // Act
  await useCase.execute();
  
  // Assert
  verify(mockRepo.logout()).called(1);
});

// ✅ DỄ TEST: Test business logic riêng
test('LoginUseCase should validate email', () async {
  final mockRepo = MockAuthRepository();
  final useCase = LoginUseCase(mockRepo);
  
  // Test validation WITHOUT calling API
  expect(
    () => useCase.execute(LoginRequest(email: '', password: '123')),
    throwsA(isA<ValidationException>()),
  );
  
  // Repository KHÔNG được gọi nếu validation fail
  verifyNever(mockRepo.login(any));
});
```

#### Khi gộp vào Repository:

```dart
// ❌ KHÓ TEST: Phải mock cả API
test('AuthRepository should validate and login', () async {
  // ❌ Phải setup mock API response
  final mockDio = MockDio();
  final service = AuthService(mockDio);
  final repo = AuthRepositoryImpl(storage, service);
  
  // ❌ Phải mock API response dù chỉ test validation
  when(mockDio.post(any, data: any)).thenAnswer(
    (_) async => Response(data: {...}, statusCode: 200),
  );
  
  // ❌ Test lẫn lộn business logic và data access
  final result = await repo.login(LoginRequest(...));
  
  // Không biết lỗi từ validation hay từ API?
});
```

**Vấn đề:**
- ❌ Không thể test business logic riêng biệt
- ❌ Phải mock API ngay cả khi test validation
- ❌ Test chậm (phải setup nhiều mock)
- ❌ Test phức tạp, khó maintain

---

### 4. LOGIC BUSINESS BỊ RẢI RÁC

Theo đề xuất của bạn: "Một phần logic phức tạp cũng sẽ được xử lý ở UI thông qua Provider"

```
┌────────────────────────────────────────────────────┐
│  Logic business rải rác:                           │
│                                                     │
│  Provider:                                         │
│    - Validation UI input                           │
│    - Check permissions                             │
│    - Format data                                   │
│                                                     │
│  Repository:                                       │
│    - Validation business rules                     │
│    - Check rate limiting                           │
│    - Handle cache                                  │
│                                                     │
│  ❌ KẾT QUẢ: Logic rải rác khắp nơi!             │
└────────────────────────────────────────────────────┘
```

**Ví dụ cụ thể:**

```dart
// ❌ SAI: Logic rải rác

// Provider (Presentation)
class LoginProvider {
  Future<void> login(String email, String password) async {
    // ❌ Validation ở Provider
    if (email.isEmpty || password.isEmpty) {
      _error = 'Fields required';
      return;
    }
    
    // ❌ Business logic ở Provider
    if (password.length < 6) {
      _error = 'Password too short';
      return;
    }
    
    // Gọi Repository
    await _repository.login(LoginRequest(email: email, password: password));
  }
}

// Repository (Data)
class AuthRepositoryImpl {
  Future<AuthInfo> login(LoginRequest request) async {
    // ❌ Validation ở Repository
    if (!_isValidEmail(request.email)) {
      throw ValidationException('Invalid email');
    }
    
    // ❌ Business logic ở Repository
    if (_loginAttempts >= 3) {
      throw TooManyAttemptsException();
    }
    
    // Call API...
  }
}

// ❌ VẤN ĐỀ:
// - Không biết validation nào ở đâu
// - Duplicate logic (email empty check ở 2 nơi?)
// - Khó maintain: thay đổi rule phải sửa nhiều nơi
```

**Đúng cách:**

```dart
// ✅ ĐÚNG: Logic tập trung ở UseCase

// Provider (Presentation) - CHỈ UI logic
class LoginProvider {
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // ✅ GỌI UseCase - business logic ở đây
      await _loginUseCase.execute(
        LoginRequest(email: email, password: password)
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// UseCase (Domain) - TẤT CẢ business logic
class LoginUseCase {
  Future<AuthInfo> execute(LoginRequest request) async {
    // ✅ TẤT CẢ validation và business logic ở đây
    _validateEmail(request.email);
    _validatePassword(request.password);
    _checkRateLimit(request.email);
    
    // Check cache
    final cached = await _cache.getUser(request.email);
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    
    // Call repository (chỉ data access)
    final authInfo = await _repository.login(request);
    
    // Post-processing
    await _cache.saveUser(authInfo);
    _analytics.logEvent('login_success');
    
    return authInfo;
  }
  
  void _validateEmail(String email) {
    if (email.isEmpty) throw ValidationException('Email required');
    if (!_emailRegex.hasMatch(email)) throw ValidationException('Invalid email');
  }
  
  void _validatePassword(String password) {
    if (password.isEmpty) throw ValidationException('Password required');
    if (password.length < 6) throw ValidationException('Password too short');
  }
  
  void _checkRateLimit(String email) {
    if (_loginAttempts[email] ?? 0 >= 3) {
      throw TooManyAttemptsException();
    }
  }
}

// Repository (Data) - CHỈ data access
class AuthRepositoryImpl {
  Future<AuthInfo> login(LoginRequest request) async {
    // ✅ CHỈ data access: convert → call API → convert
    final dto = LoginDto(email: request.email, password: request.password);
    final response = await authService.login(dto);
    return response.toEntity();
  }
}
```

**Ưu điểm:**
- ✅ Business logic TẤT CẢ ở UseCase
- ✅ Provider chỉ quản lý UI state
- ✅ Repository chỉ data access
- ✅ Dễ tìm, dễ sửa, dễ test

---

### 5. KHÓ TÁI SỬ DỤNG

#### Khi gộp vào Repository:

```dart
// ❌ Business logic gắn chặt với Repository
class AuthRepositoryImpl {
  Future<AuthInfo> login(LoginRequest request) async {
    // Validation + Business logic + API call gộp chung
    
    if (_loginAttempts >= 3) { ... }
    if (!_isValidEmail(...)) { ... }
    
    final response = await authService.login(...);
    return response.toEntity();
  }
}

// ❌ Muốn dùng logic "check login attempts" cho register?
// → Phải duplicate code hoặc extract ra method → lộn xộn

// ❌ Muốn dùng login logic cho OAuth login?
// → Phải copy-paste business logic → duplicate
```

#### Với UseCase riêng:

```dart
// ✅ Dễ tái sử dụng và compose

class LoginUseCase {
  final AuthRepository _repo;
  final ValidateEmailUseCase _validateEmail;
  final CheckRateLimitUseCase _checkRateLimit;
  
  Future<AuthInfo> execute(LoginRequest request) async {
    // ✅ Compose các UseCase nhỏ
    await _validateEmail.execute(request.email);
    await _checkRateLimit.execute(request.email);
    
    return await _repo.login(request);
  }
}

class RegisterUseCase {
  final AuthRepository _repo;
  final ValidateEmailUseCase _validateEmail;  // ✅ Reuse
  
  Future<AuthInfo> execute(RegisterRequest request) async {
    await _validateEmail.execute(request.email);  // ✅ Same logic
    
    return await _repo.register(request);
  }
}

class OAuthLoginUseCase {
  final AuthRepository _repo;
  final CheckRateLimitUseCase _checkRateLimit;  // ✅ Reuse
  
  Future<AuthInfo> execute(String token) async {
    await _checkRateLimit.execute(token);  // ✅ Same logic
    
    return await _repo.oauthLogin(token);
  }
}
```

---

## 📊 BẢNG SO SÁNH

| Khía cạnh | Với UseCase (✅ Đúng) | Gộp vào Repository (❌ Sai) |
|-----------|----------------------|---------------------------|
| **Tuân thủ Clean Architecture** | ✅ Đúng | ❌ Vi phạm |
| **Single Responsibility** | ✅ Mỗi layer 1 trách nhiệm | ❌ Repository làm quá nhiều |
| **Testability** | ✅ Test riêng từng layer | ❌ Khó test, phải mock nhiều |
| **Maintainability** | ✅ Dễ tìm và sửa logic | ❌ Logic rải rác |
| **Reusability** | ✅ Compose UseCase dễ dàng | ❌ Duplicate code |
| **Dependency Rule** | ✅ Domain không phụ thuộc Data | ❌ Vi phạm |
| **Code organization** | ✅ Logic rõ ràng, tập trung | ❌ Lộn xộn |
| **Scalability** | ✅ Dễ mở rộng | ❌ Khó mở rộng |
| **Team collaboration** | ✅ Dễ phân chia công việc | ❌ Conflict code nhiều |

---

## 💡 KHI NÀO CÓ THỂ BỎ QUA USECASE?

### Trường hợp DUY NHẤT có thể bỏ qua UseCase:

```
┌────────────────────────────────────────────────────┐
│  CÓ THỂ bỏ qua UseCase khi:                       │
│                                                     │
│  1. ✅ CRUD đơn giản, KHÔNG có business logic     │
│  2. ✅ Chỉ là data access thuần túy               │
│  3. ✅ Không cần validation                        │
│  4. ✅ Không cần transform data                    │
│  5. ✅ Không cần cache/analytics                   │
│                                                     │
│  Ví dụ: Simple CRUD app, admin panel             │
└────────────────────────────────────────────────────┘
```

**Ví dụ có thể bỏ UseCase:**

```dart
// App CRUD đơn giản: Quản lý danh sách todo
// KHÔNG có: validation phức tạp, business rules, cache, analytics

class TodoProvider {
  final TodoRepository _repo;
  
  // ✅ OK: Đơn giản, không cần UseCase
  Future<void> getTodos() async {
    _todos = await _repo.getTodos();
  }
  
  Future<void> addTodo(String title) async {
    await _repo.addTodo(Todo(title: title));
  }
}
```

### Nhưng trong app của bạn:

```
❌ KHÔNG thể bỏ UseCase vì:

1. ❌ Có authentication (business logic phức tạp)
2. ❌ Có validation (email, password, rate limiting)
3. ❌ Có state management (token, session)
4. ❌ Có cache (lưu user info)
5. ❌ Có analytics (log events)
6. ❌ Có error handling phức tạp

→ BẮT BUỘC phải có UseCase!
```

---

## 🎯 KẾT LUẬN

### Câu trả lời cho câu hỏi:

**"Có thể gộp UseCase vào Repository để đơn giản hóa không?"**

### ❌ **KHÔNG - KHÔNG NÊN LÀM THẾ**

**Lý do:**

1. **Vi phạm Clean Architecture**
   - Business logic PHẢI ở Domain Layer (UseCase)
   - Repository CHỈ nên data access

2. **Vi phạm SOLID Principles**
   - Single Responsibility: Repository làm quá nhiều việc
   - Open/Closed: Khó extend mà không modify
   - Dependency Inversion: Logic phụ thuộc vào Data Layer

3. **Khó maintain**
   - Logic rải rác (Provider + Repository)
   - Không biết logic ở đâu
   - Duplicate code

4. **Khó test**
   - Không test business logic riêng
   - Phải mock API cho mọi test
   - Test chậm, phức tạp

5. **Khó scale**
   - Thêm feature mới → Repository phình to
   - Khó reuse logic
   - Team conflict code nhiều

---

## ✅ KHUYẾN NGHỊ

### Giữ nguyên kiến trúc hiện tại:

```
Provider → UseCase → Repository → Service
```

**Lý do:**
- ✅ Đúng Clean Architecture
- ✅ Đúng SOLID Principles
- ✅ Dễ test, dễ maintain
- ✅ Dễ scale, dễ extend
- ✅ Industry standard

### Nếu thấy UseCase "đơn giản":

```dart
// Dù đơn giản VẪN NÊN có UseCase
class LogoutUseCase {
  Future<void> execute() async {
    // Hiện tại đơn giản
    await _repository.logout();
    
    // Sau này dễ thêm:
    // - Clear biometric
    // - Revoke push token
    // - Clear cache
    // - Log analytics
    // MÀ KHÔNG SỬA Repository!
  }
}
```

**→ UseCase là "placeholder" cho business logic tương lai!**

---

## 📝 TÓM TẮT

### Nguyên tắc vàng:

```
┌────────────────────────────────────────────────────┐
│  Provider: UI State Management                     │
│      ↓                                              │
│  UseCase: Business Logic                          │
│      ↓                                              │
│  Repository: Data Access                          │
│      ↓                                              │
│  Service: API Calls                                │
│                                                     │
│  KHÔNG BAO GIỜ gộp UseCase vào Repository!        │
└────────────────────────────────────────────────────┘
```

### Khi nào đơn giản hóa?

```
✅ CÓ THỂ đơn giản: Bỏ unnecessary abstractions
   - Bỏ interface nếu chỉ có 1 implementation
   - Bỏ DTO nếu giống hệt Entity
   - Bỏ wrapper class không cần thiết

❌ KHÔNG BAO GIỜ đơn giản: Bỏ layers trong Clean Architecture
   - KHÔNG gộp UseCase vào Repository
   - KHÔNG bỏ qua Domain Layer
   - KHÔNG đặt business logic ở Data Layer
```

---

## 🎓 QUOTE

> **"Keep the business logic where it belongs: in the domain layer. The data layer should be dumb and only know how to fetch and store data."**
> 
> — Robert C. Martin (Uncle Bob), Clean Architecture

---

✅ **Kết luận: Giữ nguyên kiến trúc hiện tại với UseCase. Đừng gộp vào Repository!**

