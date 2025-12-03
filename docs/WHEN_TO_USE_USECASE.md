# KHI NÀO CẦN USECASE? - HƯỚNG DẪN CHI TIẾT

## 🎯 TRẢ LỜI CÂU HỎI

**Câu hỏi của bạn:**
> "Luồng xử lý auth khá đơn giản nên không cần xử lý trong usecase, nhưng với trường hợp profile screen cần gọi API để lấy thông tin user đã đăng nhập thì có cần implement trong usecase không? Hay xử lý logic trực tiếp trong entities?"

**Trả lời:**

### ✅ **BẮT BUỘC dùng UseCase khi gọi API**
### ❌ **KHÔNG BAO GIỜ xử lý logic trong Entity**

---

## 📋 QUY TẮC VÀNG

```
┌─────────────────────────────────────────────────────┐
│  NẾU CÓ GỌI API/DATABASE → LUÔN LUÔN CẦN USECASE   │
└─────────────────────────────────────────────────────┘
```

### Lý do:

1. **Entity chỉ là data model** - không chứa business logic
2. **UseCase là nơi duy nhất chứa business logic**
3. **Clean Architecture bắt buộc**: Presentation → UseCase → Repository
4. **Dễ test, dễ maintain, dễ mở rộng**

---

## ❌ SAI LẦM THƯỜNG GẶP

### Sai lầm 1: Xử lý logic trong Entity

```dart
// ❌ TUYỆT ĐỐI KHÔNG LÀM THẾ NÀY
class UserEntity {
  final String id;
  final String email;
  
  // ❌ SAI: Entity không nên có async method
  // ❌ SAI: Entity không nên gọi API/Repository
  Future<UserEntity> loadProfile() async {
    final response = await api.getProfile();
    return UserEntity.fromJson(response);
  }
  
  // ❌ SAI: Business logic không nên ở Entity
  bool isAdmin() {
    return email.endsWith('@admin.com');
  }
}
```

**Tại sao sai?**
- Entity là **Pure Data Model** - chỉ chứa dữ liệu
- Không tuân thủ Clean Architecture
- Khó test, khó maintain
- Tạo circular dependency

---

### Sai lầm 2: Provider gọi trực tiếp Repository

```dart
// ❌ SAI: Bỏ qua UseCase layer
class ProfileProvider extends ChangeNotifier {
  final UserRepository _repository;  // ❌ Gọi trực tiếp Repository
  
  Future<void> loadProfile() async {
    final user = await _repository.getUserProfile();  // ❌ SAI
    // ...
  }
}
```

**Tại sao sai?**
- Bỏ qua Domain Layer (UseCase)
- Business logic bị rải rác ở Provider
- Vi phạm Clean Architecture

---

### Sai lầm 3: "Logic đơn giản nên không cần UseCase"

```dart
// ❌ SAI: Nghĩ rằng logic đơn giản không cần UseCase
class ProfileProvider extends ChangeNotifier {
  Future<void> loadProfile() async {
    // "Logic đơn giản mà, gọi thẳng API luôn"
    final response = await dio.get('/api/profile');  // ❌ SAI
    final user = UserEntity.fromJson(response.data);
  }
}
```

**Tại sao sai?**
- Dù đơn giản vẫn phải tuân thủ architecture
- Sau này thêm logic (cache, validation) sẽ phức tạp
- Không thể test riêng business logic

---

## ✅ CÁCH ĐÚNG: LUÔN DÙNG USECASE

### Ví dụ: Profile Screen cần lấy thông tin user

#### 1. **Entity** (Data Model)
```dart
// ✅ ĐÚNG: Chỉ chứa data, không có logic
class UserEntity {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;

  UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  // ✅ OK: Chỉ có factory method để parse data
  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
    );
  }
  
  // ✅ OK: Computed properties (không gọi API)
  String get fullName => '$firstName $lastName';
}
```

---

#### 2. **Repository Interface** (Domain)
```dart
// ✅ ĐÚNG: Interface ở Domain Layer
abstract class UserRepository {
  Future<UserEntity> getUserProfile();
  Future<UserEntity> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
  });
}
```

---

#### 3. **UseCase** (Business Logic)
```dart
// ✅ ĐÚNG: UseCase chứa business logic
class GetUserProfileUseCase {
  final UserRepository _repository;

  GetUserProfileUseCase(this._repository);

  Future<UserEntity> execute() async {
    // ✅ Có thể thêm logic ở đây:
    
    // 1. Check cache trước
    // final cachedUser = await _cache.getUser();
    // if (cachedUser != null && !cachedUser.isExpired) {
    //   return cachedUser;
    // }
    
    // 2. Gọi API
    final user = await _repository.getUserProfile();
    
    // 3. Save cache
    // await _cache.saveUser(user);
    
    // 4. Log analytics
    // _analytics.logEvent('profile_loaded');
    
    return user;
  }
}
```

**Ưu điểm:**
- ✅ Business logic tập trung ở 1 chỗ
- ✅ Dễ thêm cache, validation, logging
- ✅ Dễ test (mock repository)
- ✅ Tuân thủ Clean Architecture

---

#### 4. **Repository Implementation** (Data)
```dart
// ✅ ĐÚNG: Implementation ở Data Layer
class UserRepositoryImpl implements UserRepository {
  final UserService _service;

  UserRepositoryImpl(this._service);

  @override
  Future<UserEntity> getUserProfile() async {
    // 1. Gọi API
    final dto = await _service.getUserProfile();
    
    // 2. Convert DTO → Entity
    return dto.toEntity();
  }
}
```

---

#### 5. **Service** (API Call)
```dart
// ✅ ĐÚNG: Service chỉ gọi API
@RestApi()
abstract class UserService {
  factory UserService(Dio dio) = _UserService;

  @GET('/fw-api/settings/profile')
  Future<UserDto> getUserProfile();
}
```

---

#### 6. **Provider** (Presentation)
```dart
// ✅ ĐÚNG: Provider gọi UseCase
class ProfileProvider extends ChangeNotifier {
  final GetUserProfileUseCase _getUserProfileUseCase;  // ← Inject UseCase

  UserEntity? _user;
  bool _isLoading = false;
  String? _error;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProfileProvider(this._getUserProfileUseCase);

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ Gọi UseCase
      _user = await _getUserProfileUseCase.execute();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## 🎓 LUỒNG ĐẦY ĐỦ

```
ProfileScreen (UI)
    ↓ tap "Load Profile"
ProfileProvider.loadProfile()
    ↓ call execute()
GetUserProfileUseCase.execute()
    ↓ call getUserProfile()
UserRepository (interface)
    ↓ implement
UserRepositoryImpl.getUserProfile()
    ↓ call API
UserService.getUserProfile()
    ↓ HTTP GET
Backend API: /fw-api/settings/profile
    ↓ response
UserDto
    ↓ convert
UserEntity
    ↓ return qua các layer
ProfileProvider
    ↓ update UI
ProfileScreen hiển thị thông tin user
```

---

## 📊 BẢNG PHÂN LOẠI: KHI NÀO CẦN USECASE?

| Tình huống | Cần UseCase? | Lý do | Ví dụ |
|------------|--------------|-------|-------|
| **Gọi API** | ✅ CÓ | Luôn luôn cần | `getUserProfile()`, `logout()` |
| **Gọi Database** | ✅ CÓ | Luôn luôn cần | `saveUserLocal()`, `getUsers()` |
| **Business logic phức tạp** | ✅ CÓ | Tách logic ra UseCase | Validate, calculate, transform |
| **Combine nhiều repository** | ✅ CÓ | UseCase điều phối | Get user + posts + comments |
| **Cần cache** | ✅ CÓ | Check cache trước API | Get profile with cache |
| **Cần retry logic** | ✅ CÓ | Retry khi API fail | Auto retry 3 lần |
| **Getter đơn giản** | ❌ KHÔNG | Không có logic | `user.fullName` |
| **Pure UI logic** | ❌ KHÔNG | Chỉ liên quan UI | Animation, navigation |
| **Constant values** | ❌ KHÔNG | Static data | Config, constants |

---

## 🔍 CÂU TRẢ LỜI CHO TỪNG TRƯỜNG HỢP

### Case 1: Auth khá đơn giản

**Bạn nói:** "Luồng auth đơn giản nên không cần UseCase"

**Trả lời:** ❌ **SAI**

Dù đơn giản vẫn phải có UseCase vì:
- ✅ Gọi API → BẮT BUỘC phải có UseCase
- ✅ Sau này có thể thêm logic: biometric, 2FA, remember me
- ✅ Tuân thủ architecture nhất quán

```dart
// ✅ ĐÚNG: Dù đơn giản vẫn cần UseCase
class LogoutUseCase {
  final AuthRepository _repository;

  Future<void> execute() async {
    // Hiện tại đơn giản
    await _repository.logout();
    
    // Sau này có thể thêm:
    // - Clear biometric data
    // - Revoke push notification token
    // - Clear analytics data
    // - etc.
  }
}
```

---

### Case 2: Profile screen cần gọi API

**Bạn hỏi:** "Profile cần gọi API lấy user info, có cần UseCase không?"

**Trả lời:** ✅ **CÓ - BẮT BUỘC**

Vì:
- ✅ Gọi API → Luôn cần UseCase
- ✅ Có thể thêm cache
- ✅ Có thể thêm offline mode
- ✅ Tuân thủ Clean Architecture

```dart
// ✅ ĐÚNG
class GetUserProfileUseCase {
  final UserRepository _repository;
  final CacheRepository _cache;

  Future<UserEntity> execute() async {
    // Check cache trước
    final cached = await _cache.getUser();
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    
    // Gọi API
    final user = await _repository.getUserProfile();
    
    // Save cache
    await _cache.saveUser(user);
    
    return user;
  }
}
```

---

### Case 3: Xử lý logic trong Entity?

**Bạn hỏi:** "Hay xử lý logic trực tiếp trong entities?"

**Trả lời:** ❌ **KHÔNG BAO GIỜ**

Entity chỉ là data model:

```dart
// ✅ Entity CHỈ có data
class UserEntity {
  final String email;
  
  // ✅ OK: Computed property (không gọi external service)
  String get domain => email.split('@').last;
  
  // ❌ KHÔNG: Gọi API/Repository
  // Future<List<Post>> getPosts() async { ... }
  
  // ❌ KHÔNG: Business logic phức tạp
  // bool canAccessAdminPanel() { ... }
}
```

Nếu cần logic → Tạo UseCase:

```dart
// ✅ ĐÚNG: Logic ở UseCase
class CanAccessAdminPanelUseCase {
  final UserRepository _repository;
  final PermissionRepository _permissionRepo;

  Future<bool> execute(UserEntity user) async {
    // Business logic phức tạp
    final permissions = await _permissionRepo.getPermissions(user.id);
    return permissions.contains('admin_access');
  }
}
```

---

## 🎯 KẾT LUẬN

### Nguyên tắc đơn giản:

```
┌──────────────────────────────────────────────┐
│  GỌI API/DATABASE → LUÔN DÙNG USECASE       │
│  LOGIC PHỨC TẠP → LUÔN DÙNG USECASE         │
│  ENTITY → CHỈ CHỨA DATA, KHÔNG LOGIC        │
└──────────────────────────────────────────────┘
```

### Đừng nghĩ:
- ❌ "Logic đơn giản nên không cần UseCase"
- ❌ "Chỉ call API thôi, gọi trực tiếp đi"
- ❌ "Entity có thể có method load data"

### Hãy nhớ:
- ✅ **Mọi API call đều qua UseCase**
- ✅ **Entity chỉ là data model**
- ✅ **Architecture nhất quán > Tiết kiệm vài dòng code**
- ✅ **Dễ maintain sau này > Nhanh bây giờ**

---

## 📝 CHECKLIST

Khi thêm feature mới, hãy tự hỏi:

- [ ] Có gọi API/Database? → **Tạo UseCase**
- [ ] Có business logic? → **Tạo UseCase**
- [ ] Có combine nhiều data sources? → **Tạo UseCase**
- [ ] Chỉ là getter/computed property? → **Để trong Entity**
- [ ] Chỉ là UI logic? → **Để trong Provider/Widget**

---

## ✅ TÓM TẮT NGẮN GỌN

| Câu hỏi | Trả lời |
|---------|---------|
| Auth đơn giản, có cần UseCase? | ✅ CÓ - Vì gọi API |
| Profile gọi API, có cần UseCase? | ✅ CÓ - Vì gọi API |
| Xử lý logic trong Entity? | ❌ KHÔNG - Entity chỉ chứa data |
| Khi nào dùng UseCase? | ✅ Khi có: API, Database, Business logic |
| Khi nào KHÔNG cần UseCase? | ❌ Getter, UI logic, constants |

**Quy tắc vàng:**
> **Nếu có gọi API hoặc Database → BẮT BUỘC phải có UseCase**

---

✅ **Trong dự án của bạn, đã implement đúng với các UseCases cho auth và profile!**

