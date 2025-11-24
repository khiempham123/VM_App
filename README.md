# VM First App

Dự án Flutter sử dụng kiến trúc phân tầng (**Layered Architecture**) với Clean Architecture patterns.

---

## 📚 Mục Lục

- [Tech Stack Tổng Quan](#tech-stack-tổng-quan)
- [Kiến Trúc Dự Án](#kiến-trúc-dự-án)
  - [1. App Layer](#1-app-layer)
  - [2. Core Layer](#2-core-layer)
  - [3. Data Layer](#3-data-layer)
  - [4. Domain Layer](#4-domain-layer)
  - [5. Modules Layer](#5-modules-layer)
- [Chi Tiết Hệ Thống Routing](#chi-tiết-hệ-thống-routing)
- [Case Study: Màn hình Profile & Logout](#case-study-màn-hình-profile--logout)
- [Getting Started](#getting-started)

---

## Tech Stack Tổng Quan

| Hạng mục | Thư viện | Phiên bản | Mục đích |
|:---|:---|:---|:---|
| **Ngôn ngữ** | Dart | SDK >=3.10.0 | Ngôn ngữ lập trình chính |
| **Framework** | Flutter | - | Framework UI đa nền tảng |
| **State Management** | `provider` | ^6.1.5+1 | Quản lý state (ChangeNotifier pattern) |
| **Reactive Programming** | `rxdart` | 0.28.0 | Streams & BehaviorSubject cho state toàn cục |
| **Routing** | `auto_route` | ^10.2.2 | Quản lý điều hướng với code generation |
| **Dependency Injection** | `get_it` | ^8.0.2 | Service Locator pattern |
| **Networking** | `dio` | ^5.9.0 | HTTP Client |
| **API Client** | `retrofit` | ^4.0.3 | Type-safe REST API client |
| **Local Storage** | `flutter_secure_storage` | ^9.2.4 | Lưu trữ dữ liệu nhạy cảm (tokens) |
| **Key-Value Storage** | `shared_preferences` | ^2.5.3 | Lưu trữ cài đặt đơn giản |
| **Database** | `hive`, `hive_flutter` | ^2.2.3 | NoSQL Database cục bộ |
| **Localization** | `easy_localization` | ^3.0.8 | Đa ngôn ngữ (i18n) |
| **Code Generation** | `freezed`, `json_serializable` | ^3.2.3, ^6.8.0 | Immutable data classes & JSON parsing |
| **Utilities** | `equatable`, `dartz` | ^2.0.5, ^0.10.1 | Value equality & Functional programming |

---

## Kiến Trúc Dự Án

```
lib/
├── main.dart                    # Entry point
├── app/                         # 🔷 App Layer - Khởi tạo & Routing
├── core/                        # 🔷 Core Layer - Thành phần dùng chung
├── data/                        # 🔷 Data Layer - API & Local Storage
├── domain/                      # 🔷 Domain Layer - Business Logic
└── modules/                     # 🔷 Modules Layer - Features/Screens
```

### 1. App Layer
**Mục đích**: Khởi tạo ứng dụng, cấu hình routing và quản lý state toàn cục.

| File | Chức năng |
|:---|:---|
| `app.dart` | Widget gốc (`MyApp`) - cấu hình MaterialApp với router |
| `app_provider.dart` | Quản lý trạng thái xác thực toàn cục (login/logout) |
| `router.dart` | Cấu hình routes với `@AutoRouterConfig` annotation |
| `router.gr.dart` | **File sinh tự động** - chứa các Route classes |
| `route_path.dart` | Định nghĩa các path constants |
| `root_route.dart` | Route gốc với logic điều hướng dựa trên auth state |

### 2. Core Layer
**Mục đích**: Chứa các thành phần dùng chung không phụ thuộc vào business logic.

| Thư mục | Chức năng | Tech Stack |
|:---|:---|:---|
| `constants/` | Hằng số ứng dụng | - |
| `dependencies/` | Đăng ký DI (GetIt) | `get_it` |
| `exception/` | Xử lý lỗi & interceptors | `dio`, `dartz` |
| `handler/` | Xử lý locale | `easy_localization` |
| `network/` | HTTP Client & Interceptors | `dio`, `retrofit` |
| `theme/` | Colors, TextStyles, Theme | Flutter |
| `widgets/` | Reusable widgets | Flutter |

### 3. Data Layer
**Mục đích**: Làm việc trực tiếp với nguồn dữ liệu (API, Local Storage).

| Thư mục | Chức năng | Tech Stack |
|:---|:---|:---|
| `database/` | KeyValue Storage abstraction | `shared_preferences`, `hive` |
| `dto/` | Data Transfer Objects (JSON mapping) | `json_serializable` |
| `repository/` | Triển khai Repository interfaces | - |
| `services/` | API Service definitions | `retrofit` |

**Ví dụ `AuthService`:**
```dart
@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio, {String? baseUrl}) = _AuthService;

  @POST('/fw-api/settings/login')
  Future<AuthResponseDto> login(@Body() LoginDto request);

  @POST('/fw-api/settings/logout')
  Future<void> logout();
}
```

### 4. Domain Layer
**Mục đích**: Chứa business logic cốt lõi, không phụ thuộc framework.

| Thư mục | Chức năng | Mô tả |
|:---|:---|:---|
| `entities/` | **Entities + Request Models** | Chứa cả data models lẫn request objects |
| `repository/` | Repository Interfaces (Contracts) | Abstract classes định nghĩa hành vi |

#### 📁 Cách tổ chức `entities/`

Trong dự án này, folder `entities/` **kết hợp cả Entities và Request Objects**:

| File | Loại | Mô tả |
|:---|:---|:---|
| `auth_entity.dart` | **Entities** | `AuthInfo`, `UserEntity` - Data models đại diện cho nghiệp vụ |
| `auth_request.dart` | **Request Objects** | `LoginRequest`, `RegisterRequest` - Input cho các use cases |

**Ví dụ `auth_entity.dart`:**
```dart
class AuthInfo {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserEntity user;
  // ...
}

class UserEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  // ...
}
```

**Ví dụ `auth_request.dart`:**
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
  // ...
}
```

#### 📁 Repository Interface

```dart
// lib/domain/repository/auth_repository.dart
abstract class AuthRepository {
  Future<void> setAuthInfo(AuthInfo? authInfo);
  Future<AuthInfo?> getAuthInfo();
  Future<AuthInfo> login(LoginRequest request);
  Future<AuthInfo> register(RegisterRequest request);
  Future<void> logout();
}
```

> **Lưu ý**: Dự án này **không sử dụng tầng UseCases riêng biệt**. Logic nghiệp vụ được đặt trực tiếp trong `AppProvider` và các `Provider` của từng module.

### 5. Modules Layer
**Mục đích**: Chứa các features/màn hình của ứng dụng.

| Module | Màn hình | Provider |
|:---|:---|:---|
| `auth/login/` | `LoginScreen` | `LoginProvider` |
| `auth/register/` | `RegisterScreen` | `RegisterProvider` |
| `home/` | `HomeScreen` | - |
| `profile/` | `ProfileScreen` | `ProfileProvider` |
| `main/` | `MainScreen` (Bottom Navigation) | - |

---

## Chi Tiết Hệ Thống Routing

### Tổng quan Auto Route

`auto_route` là thư viện routing mạnh mẽ cho Flutter, sử dụng **code generation** để tạo ra các route type-safe.

### Cách hoạt động

```
┌─────────────────────────────────────────────────────────────────┐
│                      1. ĐỊNH NGHĨA                              │
│  router.dart (Developer viết) + Screen với @RoutePage()        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ flutter pub run build_runner build
┌─────────────────────────────────────────────────────────────────┐
│                      2. CODE GENERATION                         │
│  router.gr.dart (Tự động sinh) - Chứa các Route classes         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      3. SỬ DỤNG                                 │
│  context.router.push(ProfileRoute())                            │
└─────────────────────────────────────────────────────────────────┘
```

### Bước 1: Định nghĩa Screen với Annotation

Mỗi màn hình cần annotation `@RoutePage()`:

```dart
// lib/modules/profile/profile_screen.dart
@RoutePage()  // ← Annotation bắt buộc
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  // ...
}
```

### Bước 2: Cấu hình Router

```dart
// lib/app/router.dart
@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class RootRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.cupertino();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      initial: true,
      path: RoutePath.kRoot,    // "/"
      page: RootRoute.page,     // ← Sử dụng Route class được sinh tự động
      children: [mainRoute, loginRoute],
    ),
  ];
}
```

### Bước 3: Code Generation sinh ra Route Classes

Sau khi chạy `flutter pub run build_runner build`, file `router.gr.dart` được sinh:

```dart
// lib/app/router.gr.dart (TỰ ĐỘNG SINH - KHÔNG SỬA)
part of 'router.dart';

/// generated route for [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileScreen();  // ← Builder trả về Widget thực tế
    },
  );
}
```

### Cách Widget Tree nhận biết màn hình đích

**Luồng điều hướng:**

1. **`MaterialApp.router`** nhận `routerConfig` từ `RootRouter`:
   ```dart
   // lib/app/app.dart
   MaterialApp.router(
     routerConfig: locator<RootRouter>().appConfig(),
   )
   ```

2. **`RootPage`** (route gốc) lắng nghe `isLoggedIn` stream từ `AppProvider`:
   ```dart
   // lib/app/root_route.dart
   return AutoRouter.declarative(
     routes: (_) {
       return [
         if (isLoggedIn)
           const MainRootRoute()   // ← Nếu đã login → Main
         else
           const LoginRootRoute(), // ← Chưa login → Login
       ];
     },
   );
   ```

3. **Nested Routes**: `MainRoute` chứa `HomeRoute` và `ProfileRoute` như children:
   ```dart
   final mainRoute = AutoRoute(
     path: RoutePath.kMain,
     page: MainRootRoute.page,
     children: [
       AutoRoute(
         page: MainRoute.page,
         children: [
           AutoRoute(page: HomeRoute.page),
           AutoRoute(page: ProfileRoute.page),  // ← ProfileScreen
         ],
       ),
     ],
   );
   ```

4. **Điều hướng thủ công**:
   ```dart
   context.router.push(const ProfileRoute());  // ← Type-safe navigation
   ```

### Cây Route trong dự án

```
RootRoute (/)
├── MainRootRoute (/main)
│   └── MainRoute
│       ├── HomeRoute        → HomeScreen
│       └── ProfileRoute     → ProfileScreen
│
└── LoginRootRoute (/login)
    ├── LoginRoute           → LoginScreen
    └── RegisterRoute        → RegisterScreen
```

---

## Case Study: Màn hình Profile & Logout

### Luồng dữ liệu

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ProfileScreen │───▶│ ProfileProvider │───▶│   AppProvider   │
│   (UI Layer)    │    │   (State Mgmt)  │    │  (Global State) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                      │
                                                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AuthService   │◀───│ AuthRepository  │◀───│   Domain Layer  │
│   (Retrofit)    │    │   (Data Layer)  │    │   (Interface)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### ProfileScreen - UI Layer

**File**: `lib/modules/profile/profile_screen.dart`

**Widgets sử dụng:**

| Widget | Mục đích |
|:---|:---|
| `ElevatedButton.icon` | Nút Logout với icon |
| `AlertDialog` | Hộp thoại xác nhận |
| `CircularProgressIndicator` | Loading indicator |
| `Card` | Hiển thị thông tin user |

**Cách cung cấp Provider:**
```dart
@RoutePage()
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileProvider(locator<AppProvider>()),
      child: const _ProfileView(),
    );
  }
}
```

**UI lắng nghe state:**
```dart
class _ProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();  // ← Lắng nghe thay đổi
    final user = provider.currentUser;

    return ElevatedButton.icon(
      onPressed: provider.isLoading
          ? null  // ← Disable khi loading
          : () => _showLogoutDialog(context, provider),
      icon: provider.isLoading
          ? const CircularProgressIndicator()  // ← Hiện loading
          : const Icon(Icons.logout),
      label: Text(provider.isLoading ? 'Logging out...' : 'Logout'),
    );
  }
}
```

### ProfileProvider - State Management

**File**: `lib/modules/profile/profile_provider.dart`

```dart
class ProfileProvider extends ChangeNotifier {
  final AppProvider _appProvider;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Lấy user từ AppProvider (global state)
  UserEntity? get currentUser => _appProvider.authInfo.value?.user;

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();  // ← Trigger UI rebuild

    try {
      await _appProvider.logout();  // ← Gọi global logout
    } finally {
      _isLoading = false;
      notifyListeners();  // ← Trigger UI rebuild
    }
  }
}
```

### AppProvider - Global State

**File**: `lib/app/app_provider.dart`

```dart
class AppProvider extends ChangeNotifier {
  final authInfo = BehaviorSubject<AuthInfo?>.seeded(null);
  final isLoggedIn = BehaviorSubject<bool>.seeded(false);

  Future logout() async {
    await _authRepo.logout();           // ← Gọi API logout
    isLoggedIn.add(false);              // ← Update stream → RootPage rebuild
    authInfo.add(null);
    await _authRepo.setAuthInfo(null);  // ← Xóa auth từ storage
    locator<HttpClient>().clearSession();
    await _storage.clear();
  }
}
```

### Kết quả sau Logout

Khi `isLoggedIn.add(false)` được gọi:

1. `RootPage` đang lắng nghe stream `isLoggedIn`
2. Stream emit giá trị `false`
3. `AutoRouter.declarative` rebuild với `LoginRootRoute()`
4. Ứng dụng tự động điều hướng về màn hình Login

---

## Getting Started

### Cài đặt dependencies

```bash
flutter pub get
```

### Chạy code generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Chạy ứng dụng

```bash
flutter run
```

### Tài liệu tham khảo

- [Flutter Documentation](https://docs.flutter.dev/)
- [Auto Route Package](https://pub.dev/packages/auto_route)
- [Provider Package](https://pub.dev/packages/provider)
- [Retrofit Package](https://pub.dev/packages/retrofit)
- [GetIt Package](https://pub.dev/packages/get_it)
