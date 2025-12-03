# Hướng Dẫn Sửa Lỗi Routing Change Password Screen

## 🔍 Vấn Đề Hiện Tại

Khi bạn click vào button "Change Password" trong `ProfileScreen`, routing không hoạt động đúng mặc dù đã:
- Khai báo route trong `router.dart`
- Chạy `build_runner` để generate code
- Sử dụng `context.router.push(const ChangePasswordRoute())`

## 🎯 Nguyên Nhân

Vấn đề nằm ở **cấu trúc route hierarchy** trong dự án:

### 1. **ChangePasswordRoute đang nằm SAI vị trí trong route tree**

Trong file `router.dart`, bạn đã khai báo:

```dart
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
        AutoRoute(page: MetroMapRoute.page),
        AutoRoute(page: ChangePasswordRoute.page)  // ❌ VỊ TRÍ SAI
      ],
    ),
  ],
);
```

**Vấn đề**: `ChangePasswordRoute` đang nằm trong `children` của `MainRoute`. `MainRoute` sử dụng `MainScreen` với `BottomNavigationBar`. Khi navigate đến `ChangePasswordRoute`, nó sẽ cố gắng hiển thị trong cùng context với bottom navigation, dẫn đến:
- Không thể push sang screen mới
- Hoặc hiển thị không đúng UI
- Bottom navigation vẫn còn đó

### 2. **ProfileScreen đang cố push route từ context không đúng**

```dart
// Trong ProfileScreen
onPressed: () => context.router.push(const ChangePasswordRoute()),
```

`context.router` ở đây đang tham chiếu đến router của `MainRoute` (có bottom nav), không phải router cha (`MainRootRoute`).

## ✅ Giải Pháp

### **Cách 1: Di chuyển ChangePasswordRoute lên cấp cao hơn (RECOMMENDED)**

Đưa `ChangePasswordRoute` ra ngoài `MainRoute`, đặt nó song song với `MainRoute`:

```dart
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
        AutoRoute(page: MetroMapRoute.page),
        // ❌ Xóa ChangePasswordRoute khỏi đây
      ],
    ),
    // ✅ Thêm ở đây - cùng cấp với MainRoute
    AutoRoute(page: ChangePasswordRoute.page),
    
    RedirectRoute(path: '*', redirectTo: ''),
  ],
);
```

**Lý do**: 
- `ChangePasswordRoute` sẽ là screen độc lập, không bị ảnh hưởng bởi bottom navigation
- Có thể push/pop bình thường
- Full screen navigation

**Cách navigate**: Giữ nguyên code trong `ProfileScreen`
```dart
context.router.push(const ChangePasswordRoute())
```

---

### **Cách 2: Sử dụng Root Router để navigate (Alternative)**

Nếu route vẫn ở vị trí cũ, thay đổi cách navigate:

```dart
// Trong ProfileScreen - thay đổi cách gọi
onPressed: () {
  // Lấy root router và push
  context.router.root.push(const ChangePasswordRoute());
  
  // Hoặc sử dụng AutoRouter.of(context)
  AutoRouter.of(context).push(const ChangePasswordRoute());
}
```

**Nhược điểm**: 
- Code phức tạp hơn
- Phải nhớ sử dụng `.root` mỗi khi navigate
- Vi phạm nguyên tắc clean architecture

---

### **Cách 3: Sử dụng Dialog thay vì Navigation (Nếu phù hợp UX)**

Thay vì navigate sang screen mới, sử dụng full-screen dialog:

```dart
onPressed: () {
  showDialog(
    context: context,
    builder: (context) => const ChangePasswordScreen(),
    useSafeArea: false,
    barrierDismissible: false,
  );
}
```

**Lưu ý**: 
- Cần remove `@RoutePage()` annotation từ `ChangePasswordScreen`
- Phù hợp nếu Change Password là form ngắn
- Không phù hợp nếu cần deep linking

---

## 📋 Các Bước Thực Hiện (Cách 1 - RECOMMENDED)

### **Bước 1: Sửa file `router.dart`**

Di chuyển `ChangePasswordRoute` ra khỏi `children` của `MainRoute`:

```dart
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
        AutoRoute(page: MetroMapRoute.page),
        // Xóa dòng: AutoRoute(page: ChangePasswordRoute.page)
      ],
    ),
    // Thêm dòng này
    AutoRoute(page: ChangePasswordRoute.page),
    
    RedirectRoute(path: '*', redirectTo: ''),
  ],
);
```

### **Bước 2: Generate lại router**

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

### **Bước 3: Kiểm tra ProfileScreen**

Code navigate giữ nguyên:
```dart
onPressed: () => context.router.push(const ChangePasswordRoute()),
```

### **Bước 4: Test**

- Run app
- Navigate đến Profile
- Click "Change Password"
- Screen phải hiển thị full screen, không có bottom navigation
- Back button phải hoạt động

---

## 🏗️ Cấu Trúc Route Đúng Theo Clean Architecture

```
RootRoute (/)
├── MainRootRoute (/main)                  # Root cho Main flow
│   ├── MainRoute ('')                     # Screen với BottomNavigationBar
│   │   ├── HomeRoute                      # Tab 1
│   │   ├── ProfileRoute                   # Tab 2
│   │   └── MetroMapRoute                  # Tab 3
│   │
│   ├── ChangePasswordRoute                # ✅ Full screen, độc lập
│   └── [Các screen khác cần full screen]
│
└── LoginRootRoute (/login)                # Root cho Auth flow
    ├── LoginRoute ('')
    └── RegisterRoute
```

**Nguyên tắc**:
- Các screen có **BottomNavigationBar** → đặt trong `children` của `MainRoute`
- Các screen **full screen** (settings, details, change password...) → đặt trong `children` của `MainRootRoute` (cùng cấp với `MainRoute`)
- Các screen **auth** → đặt trong `LoginRootRoute`

---

## 🎓 Giải Thích Chi Tiết

### **Tại sao phải di chuyển route?**

**Trước khi sửa**:
```
MainRootRoute
  └── MainRoute (có BottomNav)
       ├── HomeRoute
       ├── ProfileRoute  
       ├── MetroMapRoute
       └── ChangePasswordRoute  ← Bị "trapped" trong MainRoute
```

Khi bạn gọi `context.router.push()` từ `ProfileRoute`:
- Router tìm `ChangePasswordRoute` trong **cùng cấp** (children của MainRoute)
- Cố gắng hiển thị nó **trong** MainRoute
- Nhưng MainRoute đang render BottomNavigationBar → conflict
- Result: Không navigate hoặc hiển thị sai

**Sau khi sửa**:
```
MainRootRoute
  ├── MainRoute (có BottomNav)
  │    ├── HomeRoute
  │    ├── ProfileRoute  
  │    └── MetroMapRoute
  └── ChangePasswordRoute  ← Độc lập, không bị BottomNav ảnh hưởng
```

Khi bạn gọi `context.router.push()`:
- Router tự động tìm route ở cấp cao hơn (MainRootRoute)
- Push ChangePasswordRoute như 1 screen mới
- Hiển thị full screen, có back button
- Result: Navigate thành công ✅

---

## 🔄 So Sánh Với Login/Register Flow

Để hiểu rõ hơn, hãy xem cách Login/Register được setup:

```dart
final loginRoute = AutoRoute(
  path: RoutePath.kLogin,
  page: LoginRootRoute.page,
  children: [
    AutoRoute(page: LoginRoute.page, path: '', initial: true),
    AutoRoute(page: RegisterRoute.page),  // ✅ Cùng cấp với LoginRoute
  ],
);
```

**Tại sao Register hoạt động tốt?**
- `RegisterRoute` và `LoginRoute` cùng nằm trong `children` của `LoginRootRoute`
- Không có BottomNavigationBar ở giữa
- Có thể push/pop tự do

**Áp dụng tương tự cho Main flow**:
- `ChangePasswordRoute` nên cùng cấp với `MainRoute`
- Không nên nằm trong `MainRoute` (vì có BottomNav)

---

## ⚠️ Lưu Ý Quan Trọng

### 1. **Tuân thủ quy tắc từ `Rules.md`**

Theo clean architecture và routing rules:
- **Màn hình có navigation bar** → route nằm trong children của screen đó
- **Màn hình full screen** → route nằm cùng cấp với screen có nav bar
- **Không lồng quá sâu** → Max 3 levels

### 2. **Khi thêm screen mới trong tương lai**

**Hỏi bản thân**:
- Screen này có cần hiển thị BottomNavigationBar không?
  - **CÓ** → Đặt trong `children` của `MainRoute`
  - **KHÔNG** → Đặt trong `children` của `MainRootRoute`

**Ví dụ**:
- ✅ `JobListRoute` (có bottom nav) → trong `MainRoute.children`
- ✅ `JobDetailRoute` (full screen) → trong `MainRootRoute.children`
- ✅ `EditProfileRoute` (full screen) → trong `MainRootRoute.children`

### 3. **Debug tips**

Nếu routing vẫn không hoạt động:

```dart
// Thêm log để kiểm tra
onPressed: () {
  print('🔍 Current router: ${context.router}');
  print('🔍 Router stack: ${context.router.stackData}');
  
  final result = context.router.push(const ChangePasswordRoute());
  print('🔍 Push result: $result');
}
```

Kiểm tra:
- Router có tìm thấy route không
- Stack có update không
- Có error nào trong console không

---

## 📝 Checklist Khi Thêm Screen Mới

- [ ] Xác định screen cần BottomNavigationBar hay không
- [ ] Đặt route ở đúng level trong hierarchy
- [ ] Thêm import trong `router.dart`
- [ ] Chạy `build_runner` để generate code
- [ ] Test navigation từ screen hiện tại
- [ ] Test back navigation
- [ ] Test deep linking (nếu cần)
- [ ] Kiểm tra UI trên nhiều kích thước màn hình

---

## 🎯 Kết Luận

**Nguyên nhân chính**: Route được đặt sai vị trí trong hierarchy, bị "trapped" bên trong screen có BottomNavigationBar.

**Giải pháp**: Di chuyển `ChangePasswordRoute` lên cấp cao hơn, đặt cùng cấp với `MainRoute` thay vì trong `MainRoute.children`.

**Nguyên tắc vàng**: 
> Các screen full-screen phải được đặt ở cấp độ cao hơn so với screen chứa persistent navigation (bottom nav, tab bar...).

---

## 📚 Tài Liệu Tham Khảo

- AutoRoute Documentation: https://pub.dev/packages/auto_route
- Flutter Navigation Best Practices
- Clean Architecture Routing Patterns
- File `how_to_add_new_screen.md` trong dự án

