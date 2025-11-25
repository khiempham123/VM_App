# GỢI Ý EMAIL SAU KHI LOGOUT - IMPLEMENTATION

## 🎯 YÊU CẦU

**Mục tiêu:** Khi user logout và vào lại app, TextField email vẫn hiển thị email đã cached để gợi ý login nhanh.

---

## 🔄 LUỒNG HOẠT ĐỘNG

### Luồng hiện tại (ĐÃ HOÀN THÀNH):

```
1. User login với "Remember Me" checked
   ↓
   Email được lưu vào SharedPreferences
   ↓
2. User sử dụng app...
   ↓
3. User logout
   ↓
   ✅ Backup cached email
   ↓
   Clear all storage (xóa token, session, etc.)
   ↓
   ✅ Restore cached email
   ↓
4. User mở app lại
   ↓
   LoginProvider khởi tạo
   ↓
   _loadCachedEmail() được gọi
   ↓
   ✅ TextField tự động điền email
   ✅ Checkbox "Remember Me" tự động checked
   ↓
5. User chỉ cần nhập password và login lại!
```

---

## 💻 IMPLEMENTATION

### 1. **AppProvider.logout() - Backup và Restore Email**

```dart
// File: app/app_provider.dart

Future logout() async {
  try {
    await _authRepo.logout(); // Call API logout
  } catch(e) {
    debugPrint('$e');
  }
  
  // ✅ STEP 1: Backup cached email TRƯỚC khi clear
  final cachedEmail = await _storage.getString('email');
  
  // Update streams
  isLoggedIn.add(false);
  authInfo.add(null);
  
  // Delete token
  await _authRepo.setAuthInfo(null);
  
  // Clear HTTP session
  locator<HttpClient>().clearSession();
  
  // ✅ STEP 2: Clear tất cả storage
  await _storage.clear();
  
  // ✅ STEP 3: Restore cached email SAU khi clear
  // User vẫn thấy email gợi ý khi login lại
  if (cachedEmail != null && cachedEmail.isNotEmpty) {
    await _storage.setString('email', cachedEmail);
  }
}
```

**Tại sao cần backup và restore?**
- `_storage.clear()` xóa TẤT CẢ data trong SharedPreferences
- Bao gồm cả token, session, settings, VÀ cached email
- Muốn giữ lại cached email → phải backup trước khi clear → restore sau

---

### 2. **LoginProvider._loadCachedEmail() - Load Email Khi Khởi Tạo**

```dart
// File: modules/auth/login/login_provider.dart

class LoginProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  final emailController = TextEditingController();
  bool _isRememberMe = false;

  LoginProvider(this._appProvider) {
    // ✅ Load cached email khi LoginProvider được tạo
    _loadCachedEmail();
  }

  /// Load cached email từ SharedPreferences
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
}
```

**Key Points:**
1. `_loadCachedEmail()` được gọi trong constructor
2. Mỗi lần LoginScreen được tạo → LoginProvider mới → `_loadCachedEmail()` chạy
3. Tự động điền email vào `emailController.text`
4. Tự động set `_isRememberMe = true`

---

### 3. **LoginScreen - UI Hiển Thị Email Cached**

```dart
// File: modules/auth/login/login_screen.dart

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // ✅ Tạo LoginProvider mới mỗi lần mở screen
      create: (context) => LoginProvider(locator<AppProvider>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoginProvider>();
    
    return Form(
      child: Column(
        children: [
          // Email TextField - Tự động điền nếu có cached
          TextFormField(
            controller: provider.emailController,
            // ✅ Controller đã có email từ _loadCachedEmail()
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
            enabled: !provider.isLoading,
          ),
          
          // Remember Me Checkbox
          CheckboxListTile(
            title: const Text('Remember me'),
            value: provider.isRememberMe,
            // ✅ Auto-checked nếu có cached email
            onChanged: provider.toggleRememberMe,
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

## 📊 LUỒNG DỮ LIỆU CHI TIẾT

### Scenario: User logout và vào lại

```
TRƯỚC KHI LOGOUT:
SharedPreferences = {
  "accessToken": "eyJhbG...",
  "refreshToken": "refresh...",
  "email": "khiempg@vietmap.vn",     ← Cached email
  "remember_me": true,
  "other_settings": "..."
}

LOGOUT - STEP 1: Backup
cachedEmail = "khiempg@vietmap.vn"   ← Lưu vào biến tạm

LOGOUT - STEP 2: Clear
SharedPreferences = {}                ← Xóa hết

LOGOUT - STEP 3: Restore
SharedPreferences = {
  "email": "khiempg@vietmap.vn"      ← Chỉ restore email
}

MỞ APP LẠI:
LoginProvider khởi tạo
    ↓
_loadCachedEmail()
    ↓
getCachedEmail() → "khiempg@vietmap.vn"
    ↓
emailController.text = "khiempg@vietmap.vn"  ✅
_isRememberMe = true                          ✅
    ↓
UI UPDATE:
- TextField email: "khiempg@vietmap.vn"       ✅ Tự động điền
- Checkbox Remember Me: Checked               ✅ Tự động checked
- TextField password: Empty                   ← User cần nhập
```

---

## 🎨 UX FLOW

### Trải nghiệm người dùng:

```
┌─────────────────────────────────────────────┐
│  Lần đầu: User chưa từng login              │
├─────────────────────────────────────────────┤
│  TextField Email: [              ]          │
│  TextField Password: [           ]          │
│  ☐ Remember me                              │
│  [Sign In]                                  │
└─────────────────────────────────────────────┘
                    ↓
         User nhập email + password
         Check "Remember Me"
         Login
                    ↓
┌─────────────────────────────────────────────┐
│  User sử dụng app...                        │
│  User logout                                │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Lần 2: User mở app lại                     │
├─────────────────────────────────────────────┤
│  TextField Email: [khiempg@vietmap.vn] ✅   │
│  TextField Password: [           ]          │
│  ☑ Remember me                         ✅   │
│  [Sign In]                                  │
│                                              │
│  → User chỉ cần nhập password!              │
└─────────────────────────────────────────────┘
```

---

## ⚡ PERFORMANCE & EDGE CASES

### 1. **Multiple Logins/Logouts**

```dart
Login as "user1@email.com" → Logout
  → Email cached: "user1@email.com"

Open app → TextField shows "user1@email.com" ✅

Login as "user2@email.com" → Logout
  → Email cached: "user2@email.com" (overwrite)

Open app → TextField shows "user2@email.com" ✅
```

### 2. **User Bỏ Chọn Remember Me**

```dart
User uncheck "Remember Me" checkbox
  → toggleRememberMe(false)
  → clearCachedEmail() được gọi NGAY
  → SharedPreferences["email"] = null

Logout
  → Backup email = null
  → Clear storage
  → Restore null → không restore

Open app → TextField EMPTY ✅
```

### 3. **User Thay Đổi Email**

```dart
TextField có cached: "old@email.com"
User xóa và nhập: "new@email.com"
Login với Remember Me checked
  → Cache "new@email.com"

Logout → Open app
  → TextField shows "new@email.com" ✅
```

---

## 🔒 BẢO MẬT

### ✅ An toàn:
- Chỉ lưu email (public info)
- KHÔNG lưu password
- Token bị xóa hoàn toàn khi logout
- User phải nhập password mỗi lần login

### Data sau khi logout:

```json
// SharedPreferences after logout
{
  "email": "khiempg@vietmap.vn"
}

// ✅ Token đã bị xóa
// ✅ Session đã bị clear
// ✅ User data đã bị xóa
// ✅ CHỈ còn email để gợi ý
```

---

## 🐛 TROUBLESHOOTING

### Problem 1: Email không hiển thị sau logout

**Nguyên nhân:** Quên restore email sau khi clear

**Kiểm tra:**
```dart
// Đảm bảo có đoạn code này trong logout()
if (cachedEmail != null && cachedEmail.isNotEmpty) {
  await _storage.setString('email', cachedEmail);
}
```

### Problem 2: TextField empty dù đã cache email

**Nguyên nhân:** `_loadCachedEmail()` không được gọi

**Kiểm tra:**
```dart
LoginProvider(this._appProvider) {
  _loadCachedEmail(); // ← Phải có dòng này
}
```

### Problem 3: Checkbox không checked dù có email

**Nguyên nhân:** Quên set `_isRememberMe = true`

**Kiểm tra:**
```dart
if (cachedEmail != null && cachedEmail.isNotEmpty) {
  emailController.text = cachedEmail;
  _isRememberMe = true; // ← Phải có dòng này
  notifyListeners();
}
```

---

## ✅ TESTING

### Test Case 1: Login → Logout → Mở app lại

```
1. Login với email: "test@email.com"
2. Check "Remember me"
3. Login thành công
4. Logout
5. Mở app lại
6. Kiểm tra:
   ✅ TextField email: "test@email.com"
   ✅ Checkbox: Checked
   ✅ TextField password: Empty
```

### Test Case 2: Login → Uncheck Remember Me → Logout

```
1. Login với Remember me checked
2. Sau khi login, vào lại LoginScreen
3. Uncheck "Remember me"
4. Logout
5. Mở app lại
6. Kiểm tra:
   ✅ TextField email: Empty
   ✅ Checkbox: Unchecked
```

### Test Case 3: Đổi email → Login → Logout

```
1. Có cached email: "old@email.com"
2. Xóa và nhập: "new@email.com"
3. Login với Remember me checked
4. Logout
5. Mở app lại
6. Kiểm tra:
   ✅ TextField email: "new@email.com" (đã update)
```

---

## 📝 TÓM TẮT

### Flow đơn giản:

```
Login + Remember Me
    ↓
Cache email → SharedPreferences["email"]
    ↓
Logout
    ↓
Backup email → variable
    ↓
Clear all storage
    ↓
Restore email → SharedPreferences["email"]
    ↓
Mở app lại
    ↓
LoginProvider._loadCachedEmail()
    ↓
TextField tự động điền email ✅
Checkbox tự động checked ✅
```

### Key Points:

1. **Logout:** Backup → Clear → Restore email
2. **LoginProvider constructor:** Load cached email
3. **TextField:** Auto-fill từ controller
4. **Checkbox:** Auto-check nếu có cached email
5. **Security:** Chỉ cache email, KHÔNG cache password

---

✅ **Hoàn thành! Email sẽ gợi ý sau khi logout và mở app lại.**

