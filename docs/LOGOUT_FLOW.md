# LUỒNG CALL API LOGOUT - CLEAN ARCHITECTURE

## 📋 TỔNG QUAN

Dự án tuân thủ **Clean Architecture** với 3 layers chính:
- **Presentation Layer**: UI + Provider (State Management)
- **Domain Layer**: Entities + Use Cases + Repository Interfaces
- **Data Layer**: Repository Implementation + Services (API) + DTOs

---

## ✅ LUỒNG LOGOUT ĐÚNG (ĐÃ SỬA)

```
ProfileScreen (UI)
    ↓
ProfileProvider (Presentation)
    ↓
LogoutUseCase (Domain)
    ↓
AuthRepository (Domain Interface)
    ↓
AuthRepositoryImpl (Data)
    ↓
AuthService (API Call)
    ↓
Backend API: POST /fw-api/settings/logout
```

### Chi tiết từng bước:

#### 1. **ProfileScreen** (UI Layer)
```dart
// User click button logout
ElevatedButton.icon(
  onPressed: () => _showLogoutDialog(context, provider),
  // ...
)

// Confirm dialog
void _showLogoutDialog(BuildContext context, ProfileProvider provider) {
  showDialog(
    // ...
    onPressed: () {
      provider.logout(); // Gọi provider
    }
  );
}
```

#### 2. **ProfileProvider** (Presentation Layer)
```dart
class ProfileProvider extends ChangeNotifier {
  final LogoutUseCase _logoutUseCase;
  
  Future<void> logout() async {
    // 1. Call UseCase để logout (gọi API + xóa token)
    await _logoutUseCase.execute();
    
    // 2. Cập nhật state trong AppProvider
    await _appProvider.logout();
  }
}
```

**Nhiệm vụ:**
- Quản lý UI state (loading, error)
- Gọi UseCase để thực hiện business logic
- Cập nhật AppProvider để navigate về login

#### 3. **LogoutUseCase** (Domain Layer)
```dart
class LogoutUseCase {
  final AuthRepository _authRepository;
  
  Future<void> execute() async {
    await _authRepository.logout();
  }
}
```

**Nhiệm vụ:**
- Chứa business logic của logout
- Gọi repository interface (không biết implementation)
- Có thể thêm logic phức tạp: validate, analytics, etc.

#### 4. **AuthRepository** (Domain Interface)
```dart
abstract class AuthRepository {
  Future<void> logout();
}
```

**Nhiệm vụ:**
- Định nghĩa contract cho repository
- Domain layer KHÔNG phụ thuộc vào Data layer

#### 5. **AuthRepositoryImpl** (Data Layer)
```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;
  
  @override
  Future<void> logout() async {
    await authService.logout();
  }
}
```

**Nhiệm vụ:**
- Implement AuthRepository interface
- Gọi AuthService để call API
- Convert DTO ↔ Entity (nếu cần)

#### 6. **AuthService** (API Layer)
```dart
@RestApi()
abstract class AuthService {
  @POST('/fw-api/settings/logout')
  Future<void> logout();
}
```

**Nhiệm vụ:**
- Gọi API backend
- Sử dụng Retrofit + Dio
- Xử lý HTTP request/response

---

## 🔄 SAU KHI LOGOUT API THÀNH CÔNG

**AppProvider.logout()** được gọi để cập nhật state:

```dart
Future logout() async {
  isLoggedIn.add(false);        // → Trigger RootPage rebuild → navigate to Login
  authInfo.add(null);           // → Clear auth info in memory
  locator<HttpClient>().clearSession();  // → Clear HTTP session
  await _storage.clear();       // → Clear all local storage
}
```

**Luồng navigation:**
```
isLoggedIn.add(false) 
    ↓
RootPage.StreamBuilder rebuild
    ↓
auth state = false
    ↓
Navigate to LoginRootRoute
    ↓
User thấy màn hình Login
```

---

## 📊 SO SÁNH LUỒNG CŨ VS MỚI

### ❌ LUỒNG CŨ (SAI):
```
ProfileProvider → AppProvider.logout() → AuthRepository.logout() → AuthService.logout()
```

**Vấn đề:**
- ❌ Không có UseCase layer
- ❌ Presentation gọi trực tiếp AppProvider (không qua Domain)
- ❌ Vi phạm Clean Architecture
- ❌ Khó test, khó maintain

### ✅ LUỒNG MỚI (ĐÚNG):
```
ProfileProvider → LogoutUseCase → AuthRepository → AuthRepositoryImpl → AuthService
                       ↓
                AppProvider.logout() (chỉ update state)
```

**Ưu điểm:**
- ✅ Tuân thủ Clean Architecture
- ✅ Domain layer độc lập, dễ test
- ✅ Tách biệt rõ ràng: Business Logic (UseCase) vs State Management (Provider)
- ✅ Dễ mở rộng, bảo trì

---

## 🎯 DEPENDENCY INJECTION

### Đăng ký trong `app_usecase.dart`:
```dart
void registerAuthUseCases() {
  locator.registerLazySingleton(() => LogoutUseCase(locator()));
  locator.registerLazySingleton(() => LoginUseCase(locator()));
  locator.registerLazySingleton(() => RegisterUseCase(locator()));
  // ...
}
```

### Đăng ký trong `app_dependencies.dart`:
```dart
registerServices();        // AuthService
registerRepositories();    // AuthRepository
registerAuthUseCases();    // LogoutUseCase, etc.
```

### Inject vào ProfileProvider:
```dart
ChangeNotifierProvider(
  create: (context) => ProfileProvider(
    locator<AppProvider>(),
    locator<LogoutUseCase>(),  // ← Inject UseCase
  ),
  child: const _ProfileView(),
)
```

---

## 🧪 TESTING

Với architecture mới, dễ dàng test từng layer:

### Test LogoutUseCase:
```dart
test('should call repository logout', () async {
  final mockRepo = MockAuthRepository();
  final useCase = LogoutUseCase(mockRepo);
  
  await useCase.execute();
  
  verify(mockRepo.logout()).called(1);
});
```

### Test ProfileProvider:
```dart
test('should call useCase and update state', () async {
  final mockUseCase = MockLogoutUseCase();
  final provider = ProfileProvider(mockAppProvider, mockUseCase);
  
  await provider.logout();
  
  verify(mockUseCase.execute()).called(1);
});
```

---

## 📝 QUY TẮC CẦN NHỚ

1. **Presentation → Domain → Data** (một chiều)
2. **KHÔNG BAO GIỜ** gọi Repository trực tiếp từ Provider
3. **LUÔN LUÔN** đi qua UseCase
4. **Domain layer** không phụ thuộc vào Data layer
5. **UseCase** chứa business logic, không phải Provider
6. **Provider** chỉ quản lý UI state
7. **Repository** chỉ xử lý data source (API, Database, Cache)

---

## 🎓 TÓM TẮT

| Layer | Class | Nhiệm vụ |
|-------|-------|----------|
| **Presentation** | ProfileScreen | UI - Hiển thị button, dialog |
| **Presentation** | ProfileProvider | State management - Loading, error |
| **Domain** | LogoutUseCase | Business logic - Thực hiện logout |
| **Domain** | AuthRepository (interface) | Contract - Định nghĩa method |
| **Data** | AuthRepositoryImpl | Implementation - Gọi service |
| **Data** | AuthService | API Call - HTTP request |

**Luồng đơn giản:** UI → Provider → UseCase → Repository → Service → API

---

✅ **LUỒNG ĐÃ ĐƯỢC SỬA ĐÚNG THEO CLEAN ARCHITECTURE!**

