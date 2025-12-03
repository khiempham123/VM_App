# CACHE EMAIL VỚI REMEMBER ME - HƯỚNG DẪN ĐẦY ĐỦ

## 🎯 YÊU CẦU

**Mục tiêu:**
1. ✅ User chọn checkbox "Remember Me" khi login
2. ✅ Email được lưu vào SharedPreferences
3. ✅ Lần mở app sau, TextField email tự động hiển thị email đã lưu
4. ✅ Checkbox "Remember Me" tự động được check nếu có cached email
5. ✅ User bỏ chọn "Remember Me" → xóa cached email ngay lập tức

---

## 🔄 LUỒNG HOẠT ĐỘNG

### 1. **Lần đăng nhập đầu tiên:**

```
User mở LoginScreen
    ↓
LoginProvider._loadCachedEmail() được gọi
    ↓
Kiểm tra SharedPreferences → KHÔNG có email cached
    ↓
TextField rỗng, Checkbox unchecked
    ↓
User nhập email + password
    ↓
User CHECK "Remember Me" checkbox
    ↓
User nhấn "Sign In"
    ↓
LoginProvider.login() → AppProvider.login()
    ↓
Login thành công
    ↓
if (rememberMe == true) → Cache email vào SharedPreferences
    ↓
Navigate to HomeScreen
```

### 2. **Lần đăng nhập sau (đã có cached email):**

```
User mở LoginScreen
    ↓
LoginProvider._loadCachedEmail() được gọi
    ↓
Kiểm tra SharedPreferences → CÓ email cached
    ↓
✅ TextField tự động điền email: "khiempg@vietmap.vn"
✅ Checkbox "Remember Me" tự động checked
    ↓
User chỉ cần nhập password
    ↓
User nhấn "Sign In"
    ↓
Login thành công
```

### 3. **User bỏ chọn Remember Me:**

```
User UNCHECK "Remember Me" checkbox
    ↓
LoginProvider.toggleRememberMe(false) được gọi
    ↓
AppProvider.clearCachedEmail()
    ↓
Xóa email khỏi SharedPreferences NGAY LẬP TỨC
    ↓
Lần sau mở app → TextField rỗng
```

---

## 💻 IMPLEMENTATION

### 1. **AppProvider - Quản lý SharedPreferences**

```dart
// File: app/app_provider.dart

class AppProvider extends ChangeNotifier {
  final KeyValueStorage _storage;

  /// Lưu email vào SharedPreferences
  Future<void> cachedEmail(String email) async {
    await _storage.setString('email', email);
  }

  /// Lấy cached email từ SharedPreferences
  /// Return null nếu không có
  Future<String?> getCachedEmail() async {
    return await _storage.getString('email');
  }

  /// Xóa cached email
  Future<void> clearCachedEmail() async {
    await _storage.removeKey('email');
  }
}
```

**Tại sao dùng AppProvider?**
- ✅ Centralized: Tất cả logic SharedPreferences ở 1 chỗ
- ✅ Reusable: LoginProvider, RegisterProvider đều dùng được
- ✅ Testable: Dễ mock KeyValueStorage

---

### 2. **LoginProvider - Load và Cache Email**

```dart
// File: modules/auth/login/login_provider.dart

class LoginProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  final emailController = TextEditingController();
  bool _isRememberMe = false;

  LoginProvider(this._appProvider) {
    // ✅ QUAN TRỌNG: Load cached email khi khởi tạo
    _loadCachedEmail();
  }

  /// Load cached email khi mở màn login
  Future<void> _loadCachedEmail() async {
    try {
      final cachedEmail = await _appProvider.getCachedEmail();
      
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        // ✅ Tự động điền email vào TextField
        emailController.text = cachedEmail;
        
        // ✅ Tự động check Remember Me
        _isRememberMe = true;
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load cached email error: $e');
    }
  }

  /// Toggle Remember Me checkbox
  void toggleRememberMe(bool? newState) {
    _isRememberMe = newState ?? false;
    
    // ✅ Nếu user bỏ chọn, xóa cached email NGAY
    if (!_isRememberMe) {
      _appProvider.clearCachedEmail();
    }
    
    notifyListeners();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      final request = LoginRequest(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await _appProvider.login(request);

      // ✅ Nếu Remember Me checked, cache email
      if (_isRememberMe) {
        await _appProvider.cachedEmail(emailController.text.trim());
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }
}
```

**Key Points:**
1. **`_loadCachedEmail()`**: Được gọi trong constructor
2. **`emailController.text = cachedEmail`**: Tự động điền vào TextField
3. **`_isRememberMe = true`**: Tự động check checkbox
4. **`toggleRememberMe()`**: Xóa cache NGAY khi user bỏ chọn
5. **`login()`**: Cache email SAU KHI login thành công

---

### 3. **LoginScreen - UI với Checkbox**

```dart
// File: modules/auth/login/login_screen.dart

class _LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoginProvider>();
    
    return Form(
      child: Column(
        children: [
          // Email TextField - Tự động điền nếu có cached
          TextFormField(
            controller: provider.emailController, // ← Auto-filled
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
          ),
          
          // Password TextField
          TextFormField(
            controller: provider.passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
          
          // Remember Me Checkbox
          CheckboxListTile(
            title: const Text('Remember me'),
            value: provider.isRememberMe, // ← Auto-checked nếu có cached
            onChanged: provider.toggleRememberMe,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          // Login Button
          ElevatedButton(
            onPressed: provider.login,
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📊 DỮ LIỆU LƯU TRỮ

### SharedPreferences Structure:

```json
{
  "email": "khiempg@vietmap.vn"
}
```

**Lưu ý:**
- ✅ **CHỈ lưu email**, KHÔNG lưu password (bảo mật)
- ✅ Key: `'email'`
- ✅ Value: String email
- ✅ Persistence: Tồn tại ngay cả khi app bị đóng

---

## 🔒 BẢO MẬT

### ✅ An toàn:
- Chỉ lưu email (thông tin công khai)
- Không lưu password
- Dùng SharedPreferences (safe cho data không nhạy cảm)

### ❌ KHÔNG làm:
```dart
// ❌ TUYỆT ĐỐI KHÔNG lưu password
await _storage.setString('password', password); // NGUY HIỂM!
```

**Lý do:**
- Password phải được hash trên server
- Không bao giờ lưu plain-text password trên client
- Nếu cần "auto login", dùng token (FlutterSecureStorage)

---

## 🧪 TEST CASES

### Test Case 1: Lần đầu login KHÔNG chọn Remember Me
```
1. Mở app lần đầu
2. TextField email: RỖNG
3. Checkbox: UNCHECKED
4. Nhập email + password
5. KHÔNG check Remember Me
6. Login thành công
7. Đóng app, mở lại
8. TextField email: RỖNG ✅
9. Checkbox: UNCHECKED ✅
```

### Test Case 2: Login VÀ chọn Remember Me
```
1. Mở app
2. Nhập email: "khiempg@vietmap.vn"
3. Nhập password
4. CHECK "Remember Me"
5. Login thành công
6. Đóng app, mở lại
7. TextField email: "khiempg@vietmap.vn" ✅ (TỰ ĐỘNG ĐIỀN)
8. Checkbox: CHECKED ✅ (TỰ ĐỘNG CHECK)
9. Chỉ cần nhập password
```

### Test Case 3: Bỏ chọn Remember Me
```
1. Mở app (có cached email)
2. TextField: "khiempg@vietmap.vn" ✅
3. Checkbox: CHECKED ✅
4. User UNCHECK checkbox
5. Cached email bị XÓA NGAY ✅
6. Đóng app, mở lại
7. TextField: RỖNG ✅
8. Checkbox: UNCHECKED ✅
```

### Test Case 4: Logout
```
1. User đã login với Remember Me
2. User logout
3. Navigate về LoginScreen
4. TextField: "khiempg@vietmap.vn" ✅ (VẪN CÒN)
5. Checkbox: CHECKED ✅
6. Email KHÔNG bị xóa khi logout
7. User có thể login lại dễ dàng
```

---

## 🎯 UX FLOW

### Luồng người dùng tốt nhất:

```
┌─────────────────────────────────────────────────┐
│  Lần 1: User mới                                │
├─────────────────────────────────────────────────┤
│  1. Nhập email + password                       │
│  2. Check "Remember Me"                         │
│  3. Login                                        │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Lần 2: User quay lại                           │
├─────────────────────────────────────────────────┤
│  1. Email đã tự động điền ✅                    │
│  2. Remember Me đã checked ✅                   │
│  3. Chỉ cần nhập password                       │
│  4. Login nhanh hơn!                            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Nếu muốn đổi email:                            │
├─────────────────────────────────────────────────┤
│  1. Xóa email cũ trong TextField                │
│  2. Nhập email mới                              │
│  3. Keep Remember Me checked                    │
│  4. Login → Email mới được cache                │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Nếu KHÔNG muốn remember:                       │
├─────────────────────────────────────────────────┤
│  1. Uncheck "Remember Me"                       │
│  2. Email bị XÓA ngay lập tức                   │
│  3. Lần sau TextField sẽ rỗng                   │
└─────────────────────────────────────────────────┘
```

---

## 🐛 TROUBLESHOOTING

### Problem 1: Email không tự động điền

**Nguyên nhân:**
- `_loadCachedEmail()` không được gọi trong constructor
- SharedPreferences chưa được init

**Giải pháp:**
```dart
LoginProvider(this._appProvider) {
  _loadCachedEmail(); // ← Đảm bảo được gọi
}
```

### Problem 2: Email bị xóa sau khi logout

**Nguyên nhân:**
- `AppProvider.logout()` gọi `_storage.clear()` → xóa tất cả

**Giải pháp:**
- KHÔNG dùng `clear()` cho toàn bộ storage
- Chỉ xóa token, giữ lại cached email

```dart
Future logout() async {
  await _authRepo.setAuthInfo(null); // Xóa token
  // KHÔNG gọi _storage.clear() ← Sẽ xóa cả email
  
  // Hoặc backup email trước khi clear:
  final email = await getCachedEmail();
  await _storage.clear();
  if (email != null) {
    await cachedEmail(email); // Restore email
  }
}
```

### Problem 3: Checkbox không sync với cached email

**Nguyên nhân:**
- Quên set `_isRememberMe = true` khi load cached email

**Giải pháp:**
```dart
if (cachedEmail != null && cachedEmail.isNotEmpty) {
  emailController.text = cachedEmail;
  _isRememberMe = true; // ← Quan trọng!
  notifyListeners();
}
```

---

## ✅ CHECKLIST IMPLEMENTATION

- [x] AppProvider có `cachedEmail()` method
- [x] AppProvider có `getCachedEmail()` method
- [x] AppProvider có `clearCachedEmail()` method
- [x] LoginProvider gọi `_loadCachedEmail()` trong constructor
- [x] `_loadCachedEmail()` set `emailController.text`
- [x] `_loadCachedEmail()` set `_isRememberMe = true`
- [x] `toggleRememberMe()` xóa cache khi uncheck
- [x] `login()` cache email khi Remember Me checked
- [x] LoginScreen có CheckboxListTile
- [x] Checkbox bind với `provider.isRememberMe`
- [x] Checkbox onChanged gọi `provider.toggleRememberMe()`

---

## 📝 TÓM TẮT

### Luồng đơn giản:

```
1. LoginProvider khởi tạo
   → _loadCachedEmail()
   → Lấy email từ SharedPreferences
   → Điền vào TextField + check Checkbox

2. User login với Remember Me
   → Login thành công
   → Cache email vào SharedPreferences

3. User bỏ chọn Remember Me
   → Xóa email khỏi SharedPreferences NGAY

4. Lần sau mở app
   → Quay lại bước 1
```

### Key Points:

1. **Load cached email trong constructor** của LoginProvider
2. **Tự động điền** `emailController.text = cachedEmail`
3. **Tự động check** `_isRememberMe = true`
4. **Xóa ngay** khi user uncheck Remember Me
5. **Cache sau** khi login thành công
6. **CHỈ lưu email**, KHÔNG lưu password

---

✅ **Implementation hoàn thành! Email sẽ tự động gợi ý ở lần đăng nhập sau.**

