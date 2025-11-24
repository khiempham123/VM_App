# 📋 HƯỚNG DẪN CHI TIẾT: THÊM MÀN HÌNH MỚI VÀO DỰ ÁN

> **Tài liệu này hướng dẫn cách thêm màn hình mới tuân thủ Clean Architecture và coding rules của dự án**

---

## 📚 MỤC LỤC

1. [Phân Tích Logic Flow Hiện Tại](#1-phân-tích-logic-flow-hiện-tại)
2. [Cấu Trúc Dự Án Theo Clean Architecture](#2-cấu-trúc-dự-án-theo-clean-architecture)
3. [Ví Dụ: Thêm Profile Screen Với Logout Feature](#3-ví-dụ-thêm-profile-screen-với-logout-feature)
4. [Template Tổng Quát Cho Màn Hình Mới](#4-template-tổng-quát-cho-màn-hình-mới)

---

## 1. PHÂN TÍCH LOGIC FLOW HIỆN TẠI

### 🔄 **Flow Khởi Động App (Initialization Flow)**

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. main() - lib/main.dart                                       │
│    - WidgetsFlutterBinding.ensureInitialized()                  │
│    - EasyLocalization.ensureInitialized()                       │
│    - SharedPreferencesKeyValueStorage.newInstance()             │
│    - AppDependencies.init(kvStorage) ← Đăng ký tất cả services  │
│    - AppProvider.restore() ← Kiểm tra auth session đã lưu       │
│    - runApp(LocalizationWidget(child: MyApp()))                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. AppDependencies.init() - lib/core/dependencies/              │
│    app_dependencies.dart                                         │
│                                                                  │
│    Đăng ký các dependencies theo thứ tự:                         │
│    ✓ RootRouter                                                  │
│    ✓ FlutterSecureStorage                                        │
│    ✓ KeyValueStorage                                             │
│    ✓ LocaleHandler                                               │
│    ✓ HttpClient (với baseUrl: https://dricon.fastmap.vn)        │
│    ✓ AuthRequestInterceptor                                      │
│    ✓ registerServices() ← Đăng ký các Retrofit Services         │
│    ✓ registerRepositories() ← Đăng ký các Repository            │
│    ✓ AppProvider                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. AppProvider.restore() - lib/app/app_provider.dart            │
│                                                                  │
│    try {                                                         │
│      savedAuthInfo = await _authRepo.getAuthInfo()              │
│      if (savedAuthInfo != null) {                               │
│        // Có session đã lưu                                      │
│        httpClient.setSession(...)                                │
│        authInfo.add(savedAuthInfo)                               │
│        isLoggedIn.add(true) ← Emit true                         │
│      } else {                                                    │
│        // Không có session                                       │
│        isLoggedIn.add(false) ← Emit false                       │
│      }                                                           │
│    }                                                             │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. MyApp - lib/app/app.dart                                     │
│    MaterialApp.router(                                           │
│      routerConfig: RootRouter.appConfig()                        │
│    )                                                             │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. RootPage - lib/app/root_route.dart                           │
│                                                                  │
│    StreamBuilder<bool>(                                          │
│      stream: provider.isLoggedIn,                                │
│      builder: (context, snapshot) {                              │
│        if (!snapshot.hasData) {                                  │
│          return CircularProgressIndicator(); ← Loading           │
│        }                                                         │
│                                                                  │
│        return AutoRouter.declarative(                            │
│          routes: (_) {                                           │
│            if (snapshot.data == true) {                          │
│              return [MainRootRoute()]; ← Đã đăng nhập            │
│            } else {                                              │
│              return [LoginRootRoute()]; ← Chưa đăng nhập         │
│            }                                                     │
│          },                                                      │
│        );                                                        │
│      }                                                           │
│    )                                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

### 🔐 **Flow Login (Login Flow)**

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. LoginScreen - lib/modules/auth/login/login_screen.dart       │
│    - User nhập email & password                                  │
│    - Nhấn nút "Login"                                            │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. LoginProvider.login() - lib/modules/auth/login/              │
│    login_provider.dart                                           │
│                                                                  │
│    - Validate form                                               │
│    - Tạo LoginRequest(email, password)                           │
│    - Gọi _appProvider.login(request)                             │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. AppProvider.login() - lib/app/app_provider.dart              │
│                                                                  │
│    - authResponse = await _authRepo.login(request)               │
│    - await _authRepo.setAuthInfo(authResponse) ← Lưu vào storage│
│    - httpClient.setSession(accessToken, refreshToken...)         │
│    - authInfo.add(authResponse)                                  │
│    - isLoggedIn.add(true) ← Emit true                           │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. AuthRepositoryImpl.login() - lib/data/repository/            │
│    auth_repository_impl.dart                                     │
│                                                                  │
│    - loginDto = LoginDto.fromEntity(request)                     │
│    - authResponseDto = await _authService.login(loginDto)        │
│      ↓ HTTP POST https://dricon.fastmap.vn/fw-api/login         │
│    - return authResponseDto.toEntity() ← Convert DTO → Entity    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. AuthService.login() - lib/data/services/auth_service.dart    │
│    @POST('/fw-api/login')                                        │
│    Future<AuthResponseDto> login(@Body() LoginDto request)       │
│                                                                  │
│    → Retrofit gọi API và parse response thành AuthResponseDto    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. RootPage StreamBuilder nhận isLoggedIn = true                │
│    → AutoRouter.declarative chuyển sang MainRootRoute            │
│    → MainScreen với BottomNavigationBar hiển thị                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### 📝 **Flow Register (Register Flow)**

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. RegisterScreen - lib/modules/auth/register/register_screen   │
│    - User nhập firstName, lastName, email, password, phone       │
│    - Nhấn nút "Register"                                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. RegisterProvider.register() - lib/modules/auth/register/     │
│    register_provider.dart                                        │
│                                                                  │
│    - Validate form                                               │
│    - Tạo RegisterRequest(firstName, lastName, email, password)   │
│    - Gọi _appProvider.register(request)                          │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. AppProvider.register() - lib/app/app_provider.dart           │
│                                                                  │
│    - authResponse = await _authRepo.register(request)            │
│    - await _authRepo.setAuthInfo(authResponse)                   │
│    - httpClient.setSession(accessToken, refreshToken...)         │
│    - authInfo.add(authResponse)                                  │
│    - isLoggedIn.add(true) ← Emit true                           │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. AuthRepositoryImpl.register() - lib/data/repository/         │
│    auth_repository_impl.dart                                     │
│                                                                  │
│    - registerDto = RegisterDto.fromEntity(request)               │
│    - authResponseDto = await _authService.register(registerDto)  │
│      ↓ HTTP POST https://dricon.fastmap.vn/fw-api/register      │
│    - return authResponseDto.toEntity()                           │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. AuthService.register() - lib/data/services/auth_service.dart │
│    @POST('/fw-api/register')                                     │
│    Future<AuthResponseDto> register(@Body() RegisterDto request) │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. RootPage StreamBuilder nhận isLoggedIn = true                │
│    → Chuyển sang MainRootRoute → MainScreen                      │
└─────────────────────────────────────────────────────────────────┘
```

---

### 🏠 **Flow Home Screen (MainScreen với Bottom Navigation)**

```
┌─────────────────────────────────────────────────────────────────┐
│ MainScreen - lib/modules/main/main_screen.dart                  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ AutoTabsRouter(                                           │  │
│  │   routes: MainBottomTab.values.allRoutes(),               │  │
│  │   // [HomeRoute(), ProfileRoute()]                        │  │
│  │   homeIndex: 1,                                           │  │
│  │   builder: (context, child) {                             │  │
│  │     return Scaffold(                                      │  │
│  │       body: child, ← Tab content                          │  │
│  │       bottomNavigationBar: VBottomNavigationBar(...)      │  │
│  │     );                                                     │  │
│  │   }                                                        │  │
│  │ )                                                          │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ MainBottomTab Enum - lib/modules/main/main_utils.dart           │
│                                                                  │
│  enum MainBottomTab {                                            │
│    kHome,     ← Tab 1: Home                                      │
│    kAccount   ← Tab 2: Account/Profile                          │
│  }                                                               │
│                                                                  │
│  allRoutes() {                                                   │
│    kHome → HomeRoute()                                           │
│    kAccount → ProfileRoute()                                     │
│  }                                                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. CẤU TRÚC DỰ ÁN THEO CLEAN ARCHITECTURE

### 📁 **Phân Tầng Layers**

```
lib/
├── core/                    ← CORE LAYER
│   ├── constants/           - Hằng số chung (API endpoints, configs)
│   ├── dependencies/        - Dependency Injection (GetIt)
│   │   ├── app_dependencies.dart
│   │   └── app_repository.dart
│   ├── exception/           - Error handling
│   │   ├── dio_failure.dart
│   │   ├── error_codes.dart
│   │   └── error_handler_interceptor.dart
│   ├── handler/             - Handlers (Locale, Permission, etc.)
│   ├── network/             - HttpClient, Interceptors
│   │   ├── http_client.dart
│   │   ├── auth_request_interceptor.dart
│   │   └── curl_interceptor.dart
│   ├── theme/               - AppColors, AppTextStyles, AppTheme
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   └── widgets/             - Shared widgets (buttons, inputs, etc.)
│       └── localization_widget.dart
│
├── domain/                  ← DOMAIN LAYER (Pure Dart - No Flutter)
│   ├── entities/            - Business objects
│   │   ├── auth_entity.dart (AuthInfo, UserEntity)
│   │   └── ...
│   ├── repository/          - Abstract repository interfaces
│   │   ├── auth_repository.dart
│   │   └── ...
│   └── usecases/            - Business logic use cases (optional)
│       └── ...
│
├── data/                    ← DATA LAYER (Implementation)
│   ├── database/            - Local database (Hive, SQLite, etc.)
│   ├── dto/                 - Data Transfer Objects (API models)
│   │   ├── auth_dto.dart (LoginDto, RegisterDto, AuthResponseDto)
│   │   └── base_dto/
│   ├── repository/          - Repository implementations
│   │   ├── auth_repository_impl.dart
│   │   └── ...
│   └── services/            - Retrofit API services
│       ├── auth_service.dart
│       ├── auth_service.g.dart (generated)
│       └── ...
│
├── modules/                 ← PRESENTATION LAYER (UI)
│   ├── auth/                - Authentication feature
│   │   ├── login/
│   │   │   ├── login_screen.dart      ← UI
│   │   │   └── login_provider.dart    ← State Management
│   │   └── register/
│   │       ├── register_screen.dart
│   │       └── register_provider.dart
│   ├── home/                - Home feature
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   └── provider/
│   │       └── home_provider.dart (optional)
│   ├── profile/             - Profile feature
│   │   ├── profile_screen.dart
│   │   └── profile_provider.dart
│   └── main/                - Main navigation container
│       ├── main_screen.dart           ← Container với BottomNav
│       ├── main_utils.dart            ← MainBottomTab enum
│       └── bottom_navigation_bar.dart
│
└── app/                     ← APP LAYER (Router & Global Config)
    ├── main.dart            - Entry point
    ├── app.dart             - MaterialApp.router
    ├── app_provider.dart    - Global auth state management
    ├── root_route.dart      - Root routing logic (login/logout switching)
    ├── router.dart          - Route definitions
    ├── router.gr.dart       - Generated routes (auto_route)
    └── route_path.dart      - Route path constants
```

---

### 🔄 **Quy Tắc Import Giữa Các Layers**

```
┌──────────────────────────────────────────────────────────┐
│ PRESENTATION (modules/)                                   │
│ ✓ có thể import                                           │
│   - domain/     (entities, repository interfaces)         │
│   - core/       (shared utilities, widgets, theme)        │
│ ✗ KHÔNG được import                                       │
│   - data/       (DTO, services, repository impl)          │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ DATA (data/)                                              │
│ ✓ có thể import                                           │
│   - domain/     (để implement interfaces)                 │
│   - core/       (network, exceptions)                     │
│ ✗ KHÔNG được import                                       │
│   - modules/    (presentation)                            │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ DOMAIN (domain/)                                          │
│ ✗ KHÔNG import gì từ các layer khác                      │
│   Pure Dart code only - Không phụ thuộc Flutter          │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ CORE (core/)                                              │
│ ✓ Có thể được import bởi TẤT CẢ các layers               │
│   Chứa utilities, configs, shared widgets                │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ APP (app/)                                                │
│ ✓ có thể import TẤT CẢ                                   │
│   Vì đây là layer điều phối toàn bộ app                  │
└──────────────────────────────────────────────────────────┘
```

---

## 3. VÍ DỤ: THÊM PROFILE SCREEN VỚI LOGOUT FEATURE

### 🎯 **Mục Tiêu:**
- Tạo Profile Screen hiển thị thông tin user
- Thêm nút Logout gọi API: `POST https://dricon.fastmap.vn/fw-api/settings/logout`
- Thêm vào Bottom Navigation Bar

### 🔄 **Flow Logout:**

```
ProfileScreen → ProfileProvider.logout() 
  → AppProvider.logout() 
    → AuthRepository.logout() (Call API)
      → AuthService.logout() (POST /fw-api/settings/logout)
    → Clear local session
    → isLoggedIn.add(false)
      → RootPage nhận false → Chuyển về LoginRootRoute
```

---

### 📝 **BƯỚC 1: Tạo Domain Layer cho Logout**

#### **1.1. Repository Interface**

**File:** `lib/domain/repository/auth_repository.dart`

```dart
abstract class AuthRepository {
  Future<AuthInfo> login(LoginRequest request);
  Future<AuthInfo> register(RegisterRequest request);
  Future<AuthInfo?> getAuthInfo();
  Future<void> setAuthInfo(AuthInfo? authInfo);
  
  Future<void> logout(); // ← THÊM METHOD NÀY
}
```

---

### 📝 **BƯỚC 2: Tạo Data Layer cho Logout**

#### **2.1. Service - Retrofit API**

**File:** `lib/data/services/auth_service.dart`

```dart
@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio, {String? baseUrl}) = _AuthService;

  @POST('/fw-api/login')
  Future<AuthResponseDto> login(@Body() LoginDto request);

  @POST('/fw-api/register')
  Future<AuthResponseDto> register(@Body() RegisterDto request);
  
  @POST('/fw-api/settings/logout') // ← THÊM ENDPOINT NÀY
  Future<void> logout();
}
```

**Sau đó chạy:**
```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

#### **2.2. Repository Implementation**

**File:** `lib/data/repository/auth_repository_impl.dart`

```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._authService, this._storage);

  // ...existing methods...
  
  @override
  Future<void> logout() async {
    try {
      // Gọi API logout
      await _authService.logout();
      debugPrint('✅ Logout API thành công');
    } catch (e) {
      // Log error nhưng vẫn cho phép logout local
      debugPrint('⚠️ Logout API error: $e');
    }
  }
}
```

---

### 📝 **BƯỚC 3: Cập Nhật AppProvider**

**File:** `lib/app/app_provider.dart`

```dart
// Method logout() đã có sẵn, chỉ cần update để call API

Future logout() async {
  debugPrint('🚪 [APP_PROVIDER] Bắt đầu logout...');
  
  try {
    // Gọi API logout trước
    await _authRepo.logout();
  } catch (e) {
    debugPrint('⚠️ [APP_PROVIDER] Logout API error: $e');
    // Vẫn tiếp tục clear local session
  }
  
  // Clear local session
  isLoggedIn.add(false);
  authInfo.add(null);
  await _authRepo.setAuthInfo(null);
  locator<HttpClient>().clearSession();
  await _storage.clear();
  
  debugPrint('✅ [APP_PROVIDER] Logout hoàn tất');
}
```

---

### 📝 **BƯỚC 4: Tạo Profile Module**

#### **4.1. ProfileProvider - State Management**

**File:** `lib/modules/profile/profile_provider.dart` (**TẠO MỚI**)

```dart
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  final AppProvider _appProvider;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProfileProvider(this._appProvider);

  // Lấy thông tin user từ AppProvider
  UserEntity? get currentUser => _appProvider.authInfo.value?.user;

  Future<void> logout() async {
    debugPrint('🚪 [PROFILE_PROVIDER] Bắt đầu logout...');
    _isLoading = true;
    notifyListeners();

    try {
      await _appProvider.logout();
      debugPrint('✅ [PROFILE_PROVIDER] Logout thành công');
      // Không cần navigate, RootPage sẽ tự động chuyển về Login
    } catch (e) {
      debugPrint('❌ [PROFILE_PROVIDER] Logout thất bại: $e');
      // Có thể show error dialog
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

#### **4.2. ProfileScreen - UI**

**File:** `lib/modules/profile/profile_screen.dart` (**CẬP NHẬT**)

```dart
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/app/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/modules/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileProvider(locator<AppProvider>()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: '${user.firstName} ${user.lastName}',
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email,
                          ),
                          if (user.phone != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: user.phone!,
                            ),
                          ],
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.badge_outlined,
                            label: 'User ID',
                            value: user.id,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () => _showLogoutDialog(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: Text(
                        provider.isLoading ? 'Logging out...' : 'Logout',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
```

---

### 📝 **BƯỚC 5: Cập Nhật Router**

#### **5.1. Import ProfileScreen**

**File:** `lib/app/router.dart`

```dart
import 'package:auto_route/auto_route.dart';
import 'package:vm_first_app/app/root_route.dart';
import 'package:vm_first_app/app/route_path.dart';
import 'package:vm_first_app/modules/auth/login/login_screen.dart';
import 'package:vm_first_app/modules/auth/register/register_screen.dart';
import 'package:vm_first_app/modules/home/screens/home_screen.dart';
import 'package:vm_first_app/modules/main/main_screen.dart';
import 'package:vm_first_app/modules/profile/profile_screen.dart'; // ← THÊM IMPORT
import 'package:flutter/cupertino.dart';

export 'package:auto_route/auto_route.dart';

part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class RootRouter extends RootStackRouter {
  // ...existing code...

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      initial: true,
      path: RoutePath.kRoot,
      page: RootRoute.page,
      children: [mainRoute, loginRoute],
    ),
    RedirectRoute(path: '*', redirectTo: RoutePath.kRoot),
  ];
}

final mainRoute = AutoRoute(
  path: RoutePath.kMain,
  page: MainRootRoute.page,
  children: [
    AutoRoute(
      page: MainRoute.page,
      path: '',
      children: [
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: ProfileRoute.page), // ← THÊM ProfileRoute
      ],
    ),
    RedirectRoute(path: '*', redirectTo: ''),
  ],
);

// ...existing code...
```

#### **5.2. Chạy Code Generator**

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 📝 **BƯỚC 6: Cập Nhật Bottom Navigation**

**File:** `lib/modules/main/main_utils.dart`

```dart
import 'package:vm_first_app/app/router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum MainBottomTab { kHome, kAccount }

extension ListMainBottomTabExt on List<MainBottomTab> {
  List<PageRouteInfo<dynamic>> allRoutes() {
    return map((e) {
      switch (e) {
        case MainBottomTab.kHome:
          return const HomeRoute();
        case MainBottomTab.kAccount:
          return const ProfileRoute(); // ← ĐỔI từ HomeRoute() → ProfileRoute()
      }
    }).cast<PageRouteInfo<dynamic>>().toList();
  }

  List<BottomNavigationBarItem> allItems() {
    return map((e) {
      switch (e) {
        case MainBottomTab.kHome:
          return BottomNavigationBarItem(
            icon: const Icon(Icons.home, size: 20),
            activeIcon: const Icon(Icons.home_filled, size: 20),
            label: "home_tab".tr(),
          );
        case MainBottomTab.kAccount:
          return BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline, size: 20), // ← ĐỔI ICON
            activeIcon: const Icon(Icons.person, size: 20),
            label: "profile_tab".tr(), // ← ĐỔI LABEL
          );
      }
    }).toList();
  }
}
```

---

### 📝 **BƯỚC 7: Thêm Localization (Optional)**

**File:** `resources/langs/en.json`

```json
{
  "home_tab": "Home",
  "profile_tab": "Profile"
}
```

**File:** `resources/langs/vi.json`

```json
{
  "home_tab": "Trang chủ",
  "profile_tab": "Hồ sơ"
}
```

---

## 4. TEMPLATE TỔNG QUÁT CHO MÀN HÌNH MỚI

### 🎯 **Khi nào cần tạo layer nào?**

```
┌─────────────────────────────────────────────────────────────────┐
│ MÀN HÌNH CHỈ HIỂN THỊ DỮ LIỆU (Read-only)                       │
│ Ví dụ: Profile, Settings, About                                 │
│                                                                  │
│ ✓ Cần:                                                           │
│   - Presentation: Screen + Provider                              │
│   - Sử dụng data có sẵn từ AppProvider hoặc Repository          │
│                                                                  │
│ ✗ Không cần:                                                     │
│   - Domain: Entity, Repository interface (dùng lại existing)    │
│   - Data: Service, DTO (nếu không có API mới)                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ MÀN HÌNH CÓ TƯƠNG TÁC VỚI API (Create/Update/Delete)            │
│ Ví dụ: Job List, Job Details, Edit Profile                      │
│                                                                  │
│ ✓ Cần tạo đầy đủ:                                                │
│   1. Domain: Entity, Repository interface                        │
│   2. Data: DTO, Service (Retrofit), Repository implementation   │
│   3. Presentation: Screen + Provider                             │
│   4. Router: Thêm route vào router.dart                          │
│   5. Dependencies: Đăng ký Service & Repository vào GetIt       │
└─────────────────────────────────────────────────────────────────┘
```

---

### 📝 **TEMPLATE: THÊM FEATURE MỚI (VÍ DỤ: JOB MANAGEMENT)**

#### **Bước 1: Domain Layer**

**File:** `lib/domain/entities/job_entity.dart` (**TẠO MỚI**)

```dart
class JobEntity {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;

  JobEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory JobEntity.fromJson(Map<String, dynamic> json) {
    return JobEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

**File:** `lib/domain/repository/job_repository.dart` (**TẠO MỚI**)

```dart
abstract class JobRepository {
  Future<List<JobEntity>> getJobs();
  Future<JobEntity> getJobById(String id);
  Future<JobEntity> createJob(CreateJobRequest request);
  Future<void> deleteJob(String id);
}

class CreateJobRequest {
  final String title;
  final String description;

  CreateJobRequest({
    required this.title,
    required this.description,
  });
}
```

**File:** `lib/domain/domain.dart` (**CẬP NHẬT**)

```dart
// Export entities
export 'entities/auth_entity.dart';
export 'entities/job_entity.dart'; // ← THÊM

// Export repositories
export 'repository/auth_repository.dart';
export 'repository/job_repository.dart'; // ← THÊM
```

---

#### **Bước 2: Data Layer**

**File:** `lib/data/dto/job_dto.dart` (**TẠO MỚI**)

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:vm_first_app/domain/domain.dart';

part 'job_dto.g.dart';

@JsonSerializable()
class JobDto {
  final String id;
  final String title;
  final String description;
  final String status;
  final String createdAt;

  JobDto({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory JobDto.fromJson(Map<String, dynamic> json) => _$JobDtoFromJson(json);
  Map<String, dynamic> toJson() => _$JobDtoToJson(this);
}

extension JobDtoMapper on JobDto {
  JobEntity toEntity() {
    return JobEntity(
      id: id,
      title: title,
      description: description,
      status: status,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

@JsonSerializable()
class CreateJobDto {
  final String title;
  final String description;

  CreateJobDto({
    required this.title,
    required this.description,
  });

  factory CreateJobDto.fromJson(Map<String, dynamic> json) => _$CreateJobDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CreateJobDtoToJson(this);

  factory CreateJobDto.fromEntity(CreateJobRequest request) {
    return CreateJobDto(
      title: request.title,
      description: request.description,
    );
  }
}
```

**File:** `lib/data/services/job_service.dart` (**TẠO MỚI**)

```dart
import 'package:vm_first_app/data/dto/job_dto.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'job_service.g.dart';

@RestApi()
abstract class JobService {
  factory JobService(Dio dio, {String? baseUrl}) = _JobService;

  @GET('/fw-api/jobs')
  Future<List<JobDto>> getJobs();

  @GET('/fw-api/jobs/{id}')
  Future<JobDto> getJobById(@Path('id') String id);

  @POST('/fw-api/jobs')
  Future<JobDto> createJob(@Body() CreateJobDto request);

  @DELETE('/fw-api/jobs/{id}')
  Future<void> deleteJob(@Path('id') String id);
}
```

**File:** `lib/data/repository/job_repository_impl.dart` (**TẠO MỚI**)

```dart
import 'package:vm_first_app/data/services/job_service.dart';
import 'package:vm_first_app/data/dto/job_dto.dart';
import 'package:vm_first_app/domain/domain.dart';

class JobRepositoryImpl implements JobRepository {
  final JobService _jobService;

  JobRepositoryImpl(this._jobService);

  @override
  Future<List<JobEntity>> getJobs() async {
    final dtos = await _jobService.getJobs();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<JobEntity> getJobById(String id) async {
    final dto = await _jobService.getJobById(id);
    return dto.toEntity();
  }

  @override
  Future<JobEntity> createJob(CreateJobRequest request) async {
    final dto = CreateJobDto.fromEntity(request);
    final responseDto = await _jobService.createJob(dto);
    return responseDto.toEntity();
  }

  @override
  Future<void> deleteJob(String id) async {
    await _jobService.deleteJob(id);
  }
}
```

**Chạy build_runner:**
```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

#### **Bước 3: Đăng ký Dependencies**

**File:** `lib/core/dependencies/app_repository.dart` (**CẬP NHẬT**)

```dart
import 'package:flutter/foundation.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/data/data.dart';
import 'package:vm_first_app/domain/domain.dart';

void registerServices() {
  debugPrint('  → Đăng ký AuthService...');
  locator.registerLazySingleton(
    () => AuthService(locator<HttpClient>().dio),
  );
  debugPrint('  ✓ AuthService đã đăng ký');
  
  // ← THÊM JobService
  debugPrint('  → Đăng ký JobService...');
  locator.registerLazySingleton(
    () => JobService(locator<HttpClient>().dio),
  );
  debugPrint('  ✓ JobService đã đăng ký');
}

void registerRepositories() {
  debugPrint('  → Đăng ký AuthRepository...');
  try {
    locator.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(locator(), locator()),
    );
    debugPrint('  ✓ AuthRepository đã đăng ký');
  } catch (e) {
    debugPrint('  ❌ Lỗi khi đăng ký AuthRepository: $e');
    rethrow;
  }
  
  // ← THÊM JobRepository
  debugPrint('  → Đăng ký JobRepository...');
  try {
    locator.registerLazySingleton<JobRepository>(
      () => JobRepositoryImpl(locator()),
    );
    debugPrint('  ✓ JobRepository đã đăng ký');
  } catch (e) {
    debugPrint('  ❌ Lỗi khi đăng ký JobRepository: $e');
    rethrow;
  }
}
```

---

#### **Bước 4: Presentation Layer**

**File:** `lib/modules/job/provider/job_list_provider.dart` (**TẠO MỚI**)

```dart
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class JobListProvider extends ChangeNotifier {
  final JobRepository _jobRepository;

  List<JobEntity> _jobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<JobEntity> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  JobListProvider(this._jobRepository);

  Future<void> loadJobs() async {
    debugPrint('📋 [JOB_LIST_PROVIDER] Bắt đầu load jobs...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _jobs = await _jobRepository.getJobs();
      debugPrint('✅ [JOB_LIST_PROVIDER] Load ${_jobs.length} jobs thành công');
    } catch (e) {
      debugPrint('❌ [JOB_LIST_PROVIDER] Load jobs thất bại: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteJob(String id) async {
    debugPrint('🗑️ [JOB_LIST_PROVIDER] Xóa job $id...');
    try {
      await _jobRepository.deleteJob(id);
      _jobs.removeWhere((job) => job.id == id);
      debugPrint('✅ [JOB_LIST_PROVIDER] Xóa job thành công');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [JOB_LIST_PROVIDER] Xóa job thất bại: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
```

**File:** `lib/modules/job/screens/job_list_screen.dart` (**TẠO MỚI**)

```dart
import 'package:vm_first_app/app/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/modules/job/provider/job_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => JobListProvider(locator())..loadJobs(),
      child: const _JobListView(),
    );
  }
}

class _JobListView extends StatelessWidget {
  const _JobListView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobListProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text('Error: ${provider.errorMessage}'))
              : provider.jobs.isEmpty
                  ? const Center(child: Text('No jobs found'))
                  : RefreshIndicator(
                      onRefresh: provider.loadJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.jobs.length,
                        itemBuilder: (context, index) {
                          final job = provider.jobs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(job.title),
                              subtitle: Text(job.description),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => provider.deleteJob(job.id),
                              ),
                              onTap: () {
                                // Navigate to job details
                                context.router.push(JobDetailRoute(jobId: job.id));
                              },
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create job
          context.router.push(const CreateJobRoute());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

#### **Bước 5: Thêm vào Router**

**File:** `lib/app/router.dart` (**CẬP NHẬT**)

```dart
import 'package:vm_first_app/modules/job/screens/job_list_screen.dart';

// Thêm vào mainRoute children:
final mainRoute = AutoRoute(
  path: RoutePath.kMain,
  page: MainRootRoute.page,
  children: [
    AutoRoute(
      page: MainRoute.page,
      path: '',
      children: [
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: ProfileRoute.page),
        AutoRoute(page: JobListRoute.page), // ← THÊM
      ],
    ),
    RedirectRoute(path: '*', redirectTo: ''),
  ],
);
```

**Chạy code generator:**
```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

#### **Bước 6: Thêm vào Bottom Navigation (Optional)**

**File:** `lib/modules/main/main_utils.dart` (**CẬP NHẬT**)

```dart
enum MainBottomTab { kHome, kJobs, kAccount } // ← THÊM kJobs

extension ListMainBottomTabExt on List<MainBottomTab> {
  List<PageRouteInfo<dynamic>> allRoutes() {
    return map((e) {
      switch (e) {
        case MainBottomTab.kHome:
          return const HomeRoute();
        case MainBottomTab.kJobs:
          return const JobListRoute(); // ← THÊM
        case MainBottomTab.kAccount:
          return const ProfileRoute();
      }
    }).cast<PageRouteInfo<dynamic>>().toList();
  }

  List<BottomNavigationBarItem> allItems() {
    return map((e) {
      switch (e) {
        case MainBottomTab.kHome:
          return BottomNavigationBarItem(
            icon: const Icon(Icons.home, size: 20),
            activeIcon: const Icon(Icons.home_filled, size: 20),
            label: "home_tab".tr(),
          );
        case MainBottomTab.kJobs:
          return BottomNavigationBarItem(
            icon: const Icon(Icons.work_outline, size: 20),
            activeIcon: const Icon(Icons.work, size: 20),
            label: "jobs_tab".tr(),
          );
        case MainBottomTab.kAccount:
          return BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline, size: 20),
            activeIcon: const Icon(Icons.person, size: 20),
            label: "profile_tab".tr(),
          );
      }
    }).toList();
  }
}
```

---

## 📋 **CHECKLIST THÊM FEATURE MỚI**

```
☐ BƯỚC 1: Domain Layer
   ☐ 1.1. Tạo Entity (lib/domain/entities/xxx_entity.dart)
   ☐ 1.2. Tạo Repository interface (lib/domain/repository/xxx_repository.dart)
   ☐ 1.3. Export trong domain.dart

☐ BƯỚC 2: Data Layer
   ☐ 2.1. Tạo DTO (lib/data/dto/xxx_dto.dart)
   ☐ 2.2. Tạo Service Retrofit (lib/data/services/xxx_service.dart)
   ☐ 2.3. Tạo Repository implementation (lib/data/repository/xxx_repository_impl.dart)
   ☐ 2.4. Chạy build_runner để generate code

☐ BƯỚC 3: Dependencies
   ☐ 3.1. Đăng ký Service trong registerServices()
   ☐ 3.2. Đăng ký Repository trong registerRepositories()

☐ BƯỚC 4: Presentation Layer
   ☐ 4.1. Tạo Provider (lib/modules/xxx/provider/xxx_provider.dart)
   ☐ 4.2. Tạo Screen (lib/modules/xxx/screens/xxx_screen.dart)
   ☐ 4.3. Thêm debug logs vào Provider

☐ BƯỚC 5: Router
   ☐ 5.1. Import Screen vào router.dart
   ☐ 5.2. Thêm AutoRoute vào routes
   ☐ 5.3. Chạy build_runner để generate routes

☐ BƯỚC 6: Bottom Navigation (Nếu cần)
   ☐ 6.1. Thêm enum value vào MainBottomTab
   ☐ 6.2. Update allRoutes() và allItems()
   ☐ 6.3. Thêm localization keys

☐ BƯỚC 7: Testing
   ☐ 7.1. Test API calls
   ☐ 7.2. Test navigation
   ☐ 7.3. Test error handling
   ☐ 7.4. Test loading states
```

---

## 🎯 **KEY POINTS CẦN NHỚ**

### **1. Tuân Thủ Clean Architecture:**
- **Domain:** Interface only, pure Dart, không phụ thuộc Flutter
- **Data:** Implementation với DTO, Service (Retrofit), Repository
- **Presentation:** UI + State Management (Provider)
- **Core:** Shared utilities accessible to all layers

### **2. Naming Convention:**
- **Screen:** `job_list_screen.dart` → Class: `JobListScreen`
- **Provider:** `job_list_provider.dart` → Class: `JobListProvider`
- **Entity:** `job_entity.dart` → Class: `JobEntity`
- **DTO:** `job_dto.dart` → Class: `JobDto`
- **Service:** `job_service.dart` → Class: `JobService`
- **Repository:** 
  - Interface: `job_repository.dart` → `abstract class JobRepository`
  - Implementation: `job_repository_impl.dart` → `class JobRepositoryImpl`

### **3. File Organization:**
```
lib/modules/feature_name/
  ├── screens/           (hoặc đặt trực tiếp nếu feature nhỏ)
  │   ├── feature_list_screen.dart
  │   └── feature_detail_screen.dart
  └── provider/          (hoặc providers/)
      ├── feature_list_provider.dart
      └── feature_detail_provider.dart
```

### **4. State Management Flow:**
- **Screen** → **Provider** (local state) → **Repository** (business logic) → **Service** (API)
- Provider sử dụng `ChangeNotifier` và `notifyListeners()`
- Screen sử dụng `context.watch<Provider>()` hoặc `context.read<Provider>()`

### **5. Error Handling:**
- Try-catch trong Provider
- Set `_errorMessage` và `notifyListeners()`
- Show error dialog/SnackBar trong UI
- Log errors với `debugPrint()` cho debugging

### **6. Loading States:**
- `_isLoading` flag trong Provider
- Disable buttons/inputs khi loading
- Show CircularProgressIndicator khi loading
- Always set `_isLoading = false` trong `finally` block

### **7. Dependency Injection:**
- Tất cả dependencies đăng ký trong `AppDependencies.init()`
- Service và Repository đăng ký `lazy singleton`
- Truy cập qua `locator<T>()` (GetIt)
- Provider nhận dependencies qua constructor

---

## 🚀 **BEST PRACTICES**

### **1. Code Generation:**
```bash
# Chạy build_runner sau mỗi lần thay đổi:
# - DTO (@JsonSerializable)
# - Service (@RestApi)
# - Router (@RoutePage)
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

### **2. Debug Logs:**
- Thêm debug logs ở mọi method quan trọng
- Format: `debugPrint('🔑 [PROVIDER_NAME] Action description')`
- Sử dụng emoji để dễ phân biệt: 🔑 login, 🚪 logout, 📋 load, ✅ success, ❌ error

### **3. Import Organization:**
```dart
// External packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Project imports
import 'package:vm_first_app/app/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/domain/domain.dart';
```

### **4. Null Safety:**
- Sử dụng `?` cho nullable types
- Sử dụng `!` cẩn thận, chỉ khi chắc chắn not null
- Prefer `??` operator cho default values
- Sử dụng `if (value != null)` thay vì force unwrap

### **5. Async/Await:**
- Always use `try-catch` với async methods
- Set loading state trước async call
- Reset loading state trong `finally` block
- Handle errors gracefully

---

## 📚 **TÀI LIỆU THAM KHẢO**

- **Clean Architecture:** [Robert C. Martin - Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- **Auto Route:** [auto_route package](https://pub.dev/packages/auto_route)
- **Provider:** [provider package](https://pub.dev/packages/provider)
- **Retrofit:** [retrofit package](https://pub.dev/packages/retrofit)
- **GetIt:** [get_it package](https://pub.dev/packages/get_it)

---

**🎉 Chúc bạn phát triển ứng dụng thành công!**

_Last updated: November 24, 2025_

