# Kiến Trúc Dự Án & Hướng Dẫn Kỹ Thuật Chi Tiết

## 1. Tổng Quan Cấu Trúc Dự Án

Dự án được xây dựng dựa trên **Clean Architecture** (Kiến trúc Sạch), phân tách rõ ràng các lớp (layers) để đảm bảo tính bảo trì, mở rộng và khả năng kiểm thử.

```
lib/
├── app/                    # Cấu hình cấp ứng dụng
│   └── app_provider.dart   # Quản lý trạng thái toàn cục (Auth, Session)
├── core/                   # Các chức năng cốt lõi dùng chung
│   ├── constants/          # Hằng số (API keys, chuỗi ký tự, v.v.)
│   ├── dependencies/       # Thiết lập Dependency Injection (GetIt)
│   ├── exception/          # Xử lý ngoại lệ tùy chỉnh
│   ├── network/            # Các client mạng (Dio) cho các API khác nhau
│   ├── route/              # Cấu hình điều hướng (AutoRoute)
│   ├── theme/              # Giao diện và phong cách ứng dụng
│   ├── utils/              # Các hàm tiện ích và extensions
│   └── widgets/            # Các thành phần UI tái sử dụng
├── data/                   # Lớp dữ liệu (Triển khai Repository)
│   ├── database/           # Lưu trữ cục bộ (Hive, SecureStorage)
│   ├── dto/                # Đối tượng chuyển dữ liệu (JSON parsing)
│   ├── repository/         # Triển khai các Repository
│   └── services/           # Định nghĩa dịch vụ API (Retrofit)
├── domain/                 # Lớp nghiệp vụ (Định nghĩa logic kinh doanh)
│   ├── entities/           # Đối tượng thuần Dart (Business models)
│   └── repositories/       # Giao diện Repository
└── modules/                # Các module tính năng (Màn hình & Providers)
    ├── auth/               # Xác thực (Đăng nhập, Đăng ký, v.v.)
    ├── home/               # Màn hình chính
    ├── main/               # Container chính (Bottom Navigation)
    ├── metro_go/           # Tính năng bản đồ Metro
    ├── metro_go_navigation/# Tính năng dẫn đường
    ├── my_trip_route/      # Tính năng lập kế hoạch chuyến đi
    └── profile/            # Quản lý hồ sơ người dùng
```

## 2. TechStack

### 2.1. Clean Architecture & Provider State Management
- **Clean Architecture:** Tách biệt rõ ràng giữa Data, Domain và Presentation layers.
- **Provider Pattern:** Sử dụng `ChangeNotifierProvider` để quản lý trạng thái trong từng module.
  - *Triển khai:* Mỗi màn hình (Screen) có một Provider tương ứng xử lý logic nghiệp vụ và cập nhật UI.
- **Dependency Injection (DI):** Sử dụng `GetIt` để quản lý và xử lý DI (Repositories, Services, Storage).
  - *Triển khai:* `AppDependencies` khởi tạo và đăng ký các singleton khi ứng dụng bắt đầu.
- **Repository Pattern:** Trừu tượng hóa nguồn dữ liệu. UI chỉ gọi đến Repository Interface mà không cần biết dữ liệu đến từ API hay Local DB.

### 2.2. Navigation
- **AutoRoute:** Sử dụng cho điều hướng an toàn kiểu (type-safe), deep linking và điều hướng lồng nhau.
  - Sử dụng `AutoTabsRouter` để quản lý Bottom Navigation Bar giữ trạng thái các tab.
  - *Guards:* `AuthGuard` (nếu có) để kiểm tra trạng thái đăng nhập trước khi vào các màn hình yêu cầu login.

### 2.3. Network for client & API
- **Dio:** Client HTTP mạnh mẽ.
- **Retrofit:** Tự động sinh code cho REST client từ các interface Dart.
- **Multi-Client:**
  - `HttpClient`: Dùng cho backend chính (Auth, User data).
  - `MapClient`: Dùng riêng cho các dịch vụ Vietmap.
- **Interceptors:**
  - `AuthRequestInterceptor`: Tự động thêm Bearer Token vào header, xử lý refresh token.
  - `MapRequestInterceptor`: Tự động thêm API Key vào các request tới Vietmap.
  - `ErrorHandlerInterceptor`: Xử lý lỗi tập trung, hiển thị thông báo lỗi chung.

### 2.4. Local Storage & Caching
- **Flutter Secure Storage:** Lưu trữ dữ liệu nhạy cảm như Access Token, Refresh Token.
- **Shared Preferences:** Lưu trữ các cài đặt đơn giản, cờ (flags).
- **Hive (nếu có):** Lưu trữ dữ liệu phức tạp, cache offline.

### 2.5. Tích hợp Vietmap
- **vietmap_flutter_gl:** Engine hiển thị bản đồ vector.
- **vietmap_flutter_navigation:** SDK dẫn đường turn-by-turn.
- **vietmap_flutter_plugin:** Các tiện ích bản đồ bổ sung.

## 3. Chi Tiết Triển Khai Các Module

### 3.1. Module Xác Thực (`modules/auth`)
- **Login / Register:**
  - UI: Form validation sử dụng `GlobalKey<FormState>`.
  - Logic: Gọi `AuthRepository.login()`, lưu token vào Secure Storage.
  - Xử lý lỗi: Hiển thị thông báo lỗi cụ thể từ API (sai mật khẩu, tài khoản không tồn tại).
- **Reset Password:**
  - Logic: Gọi API reset mật khẩu, yêu cầu xác thực lại nếu cần.
- **User Remider:**
  - Logic: Lưu trữ access-token & refesh-token trong flutter secure storage nếu user click chọn Remember checkbox. Gọi tới api refesh-token khi access token hết hạn.
- **Session Management:**
  - Tự động: `AppProvider` lắng nghe sự kiện lỗi 401 (Unauthorized) từ `AuthRequestInterceptor` để tự động đăng xuất người dùng khi token hết hạn.

### 3.2. Module My Trip (`modules/my_trip_route`)

- **Lập Kế Hoạch Chuyến Đi:**
  - Tạo mới: Khởi tạo danh sách điểm trống.
  - Lưu trữ: Sử dụng `RouteRepository.setMyRouteTrip` để lưu danh sách điểm vào Local Storage dưới dạng JSON.
  - Tải lại: `RouteRepository.getTripByName` đọc và parse JSON để khôi phục trạng thái.

- **Tương Tác Bản Đồ:**
  - Thêm điểm: Sự kiện `onMapLongClick` lấy tọa độ, gọi API Reverse Geocoding để lấy địa chỉ, sau đó thêm Marker.
  - Marker: Sử dụng `vietmapController.addSymbol` với icon tùy chỉnh.
  - Polyline: Vẽ đường đi giữa các điểm sử dụng `vietmapController.addPolyline`.

- **Tính Toán Lộ Trình:**
  - API: Gọi `RouteService.getRoute` với danh sách tọa độ.
  - Xử lý: Nhận về `RouteEntity` chứa geometry (encoded polyline), giải mã và vẽ lên bản đồ.
  - Tối ưu hóa: Hỗ trợ tham số `optimize` để sắp xếp lại thứ tự điểm đi qua tối ưu nhất.

- **Quản Lý Chuyến Đi (Trip Management):**
  - Danh sách: Hiển thị danh sách chuyến đi đã lưu trong `_TripsMenuAnchor`.
  - Xử lý xung đột: Logic thông minh khi chuyển đổi giữa các chuyến đi (lưu, hủy bỏ, ghi đè) để tránh mất dữ liệu chưa lưu.
  - Kỹ thuật: Sử dụng `_originalKey` để theo dõi chuyến đi gốc, đảm bảo cập nhật đúng record khi đổi tên hoặc sửa đổi.

### 3.3. Module Metro Go (`modules/metro_go`)
- **Hiển Thị Bản Đồ Metro:**
  - Dữ liệu: Danh sách cứng (hardcoded) các nhà ga Metro Bến Thành - Suối Tiên.
  - Marker: Vẽ các icon nhà ga lên bản đồ.
- **Chi Tiết Nhà Ga:**
  - Bottom Sheet: Hiển thị thông tin chi tiết khi click vào marker nhà ga.
- **Tìm Đường Metro:**
  - Logic: Tìm đường đi ngắn nhất từ vị trí người dùng đến nhà ga gần nhất, sau đó hướng dẫn đi tàu.

### 3.4. Module Navigation (`modules/metro_go_navigation`)
- **Dẫn Đường Turn-by-Turn:**
  - SDK: Sử dụng `VietMapNavigationPlugin`.
  - Khởi tạo: Cấu hình `MapOptions` với API Key, chế độ mô phỏng (simulate).
  - Sự kiện: Lắng nghe `RouteProgressEvent` để cập nhật UI (khoảng cách, thời gian còn lại, hướng rẽ tiếp theo).
- **Xem Trước Lộ Trình (Route Preview):**
  - Camera: Tự động điều chỉnh camera để bao quát toàn bộ lộ trình (`buildRoute`).
- **Mô Phỏng (Simulation):**
  - Tính năng: Cho phép chạy thử dẫn đường mà không cần di chuyển thực tế (hữu ích cho debug và demo).

## 4. Sử dụng các package code generation

- **Code Generation (Sinh mã tự động):** Giảm thiểu boilerplate code.
  - `freezed`: Tạo immutable classes, unions, copyWith, equality comparison.
  - `json_serializable`: Tự động sinh code `fromJson`/`toJson`.
  - `retrofit_generator`: Sinh code gọi API từ interface.
  - `auto_route_generator`: Sinh code cấu hình router.
  - *Sử dụng:* `flutter pub run build_runner build --delete-conflicting-outputs`

- **Linting:**
  - Sử dụng `flutter_lints` để tuân thủ các quy tắc coding standard của Dart/Flutter.

- **Biến Môi Trường:**
  - Sử dụng `flutter_dotenv` để quản lý API Keys, Base URL, tránh hardcode trong source code.

- **Xử Lý Lỗi (Error Handling):**
  - Tập trung tại `ErrorHandlerInterceptor` và các `Repository`.
  - Sử dụng `Either<Failure, Success>` (từ package `dartz`) hoặc cơ chế `try-catch` để quản lý luồng lỗi.

## 5. Cải Tiến Trong Tương Lai / TODOs

- [ ] **Unit Testing:** Viết unit test cho các UseCase, Repository và Provider.
- [ ] **Widget Testing:** Viết test cho các widget quan trọng (nút bấm, form, map view).
- [ ] **CI/CD:** Thiết lập pipeline tự động build, test và deploy (GitHub Actions, Codemagic).
- [ ] **Chế Độ Offline:** Cải thiện khả năng lưu cache bản đồ và lộ trình để hoạt động khi không có mạng.
- [ ] **Tối Ưu Hiệu Năng:**
  - Sử dụng `Isolate` cho các tác vụ nặng (parse JSON lớn).
  - Tối ưu hóa việc render marker số lượng lớn (Clustering).

