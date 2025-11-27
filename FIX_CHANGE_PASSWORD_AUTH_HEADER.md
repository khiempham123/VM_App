# Hướng Dẫn Sửa Lỗi: Change Password API Không Gửi Access Token

## 🔍 Vấn Đề Hiện Tại

Khi gọi API `changePassword`, bạn gặp lỗi:
```
[log] ⚠️ CURL:
[log] unable to create a CURL representation of the requestOptions
```

API này yêu cầu **authentication header** với access token, nhưng request không có token → Server reject request.

---

## 🎯 Nguyên Nhân Gốc Rễ

### **1. AuthRequestInterceptor KHÔNG tự động thêm token**

Trong file `auth_request_interceptor.dart`, line 52-61:

```dart
@override
void onRequest(
  RequestOptions options,
  RequestInterceptorHandler handler,
) async {
  if (accessToken?.isNotEmpty == true &&
      !options.headers.containsKey("Authorization")) {
    options.headers.addAll(authHeader);
  }
  return handler.next(options);
}
```

**Logic hiện tại**:
- CHỈ thêm header nếu `accessToken` có giá trị
- Nhưng `accessToken` trong interceptor **chưa được set**!

### **2. Flow Login/Register KHÔNG áp dụng cho ChangePassword**

Xem file `app_provider.dart`, line 72-86:

```dart
Future<void> login(LoginRequest request) async {
  try {
    final authResponse = await _authRepo.login(request);
    await _authRepo.setAuthInfo(authResponse);
    
    // ✅ SET SESSION cho HttpClient
    locator<HttpClient>().setSession(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      expiresIn: authResponse.expiresIn,
    );
    
    authInfo.add(authResponse);
    isLoggedIn.add(true);
  } catch (e) {
    rethrow;
  }
}
```

**Nhưng** trong `changePassword()`, line 127-132:

```dart
Future<void> changePassword(ChangePasswordRequest request) async {
  try {
    await _authRepo.changePassword(request);
    // ❌ KHÔNG có setSession()
    // ❌ Token không được update vào interceptor
  } catch (e) {
    rethrow;
  }
}
```

### **3. Token đã lưu nhưng chưa load vào Interceptor**

Sau khi login thành công:
- ✅ Token được lưu vào `FlutterSecureStorage` (qua `setAuthInfo`)
- ✅ Token được set vào `HttpClient.authRequestInterceptor` (qua `setSession`)
- ✅ Mọi request sau đó có Authorization header

**NHƯNG** khi app restart hoặc user quay lại sau:
- ❌ Token vẫn còn trong storage
- ❌ NHƯNG `authRequestInterceptor.accessToken` = `null`
- ❌ → Request không có Authorization header

---

## ✅ Giải Pháp Theo Clean Architecture

### **Phân Tích Luồng Đúng**

```
┌─────────────────────────────────────────────────────────────┐
│                   APP KHỞI ĐỘNG                              │
├─────────────────────────────────────────────────────────────┤
│ 1. AppProvider.restore() được gọi trong main.dart           │
│ 2. Đọc AuthInfo từ FlutterSecureStorage                     │
│ 3. NẾU có AuthInfo (user đã login):                         │
│    → Gọi setSession() để restore token vào interceptor      │
│ 4. NẾU KHÔNG có AuthInfo:                                   │
│    → User chưa login, không cần token                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              USER LOGIN/REGISTER                             │
├─────────────────────────────────────────────────────────────┤
│ 1. User submit form                                          │
│ 2. AppProvider.login() hoặc register()                      │
│ 3. AuthRepository gọi AuthService (Retrofit)                │
│ 4. Nhận AuthInfo (accessToken, refreshToken, user...)       │
│ 5. Lưu AuthInfo vào Storage                                 │
│ 6. ✅ Gọi setSession() để set token vào interceptor         │
│ 7. Update isLoggedIn = true                                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│          USER GỌI PROTECTED API (Change Password)           │
├─────────────────────────────────────────────────────────────┤
│ 1. ChangePasswordProvider.changePassword()                  │
│ 2. AppProvider.changePassword(request)                      │
│ 3. AuthRepository.changePassword(request)                   │
│ 4. AuthService.changePassword(dto)                          │
│ 5. ⚡ AuthRequestInterceptor.onRequest() TỰ ĐỘNG:          │
│    → Check: accessToken có giá trị?                         │
│    → NẾU có: Thêm header "Authorization: Bearer {token}"   │
│    → NẾU không: Skip (sẽ lỗi 401)                          │
│ 6. Gửi request đến server                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Các Bước Sửa Lỗi

### **Bước 1: Sửa AppProvider.restore() - Load token khi app start**

**File**: `lib/app/app_provider.dart`

**Vị trí**: Method `restore()` (thường ở đầu class)

**Vấn đề hiện tại**:
```dart
Future<void> restore() async {
  try {
    final savedAuthInfo = await _authRepo.getAuthInfo();
    
    if (savedAuthInfo != null) {
      authInfo.add(savedAuthInfo);
      isLoggedIn.add(true);
      // ❌ THIẾU: Không set token vào interceptor
    } else {
      isLoggedIn.add(false);
    }
  } catch (e) {
    isLoggedIn.add(false);
  }
}
```

**Sửa thành**:
```dart
Future<void> restore() async {
  try {
    final savedAuthInfo = await _authRepo.getAuthInfo();
    
    if (savedAuthInfo != null) {
      authInfo.add(savedAuthInfo);
      isLoggedIn.add(true);
      
      // ✅ THÊM: Restore token vào interceptor để protected APIs hoạt động
      locator<HttpClient>().setSession(
        accessToken: savedAuthInfo.accessToken,
        refreshToken: savedAuthInfo.refreshToken,
        expiresIn: savedAuthInfo.expiresIn,
      );
    } else {
      isLoggedIn.add(false);
    }
  } catch (e) {
    isLoggedIn.add(false);
  }
}
```

**Giải thích**:
- Khi app khởi động, `restore()` đọc token từ storage
- **BẮT BUỘC** phải gọi `setSession()` để load token vào `AuthRequestInterceptor`
- Sau đó, mọi protected API (changePassword, getUserProfile...) tự động có Authorization header

---

### **Bước 2: Sửa AppProvider.logout() - Clear token đúng cách**

**File**: `lib/app/app_provider.dart`

**Vị trí**: Method `logout()`

**Vấn đề hiện tại** (nếu có):
```dart
Future<void> logout() async {
  try {
    await _authRepo.logout();  // Gọi API logout
    
    isLoggedIn.add(false);
    authInfo.add(null);
    await _authRepo.setAuthInfo(null);
    
    // ✅ ĐÃ CÓ: Clear session (line 69 trong app_provider)
    locator<HttpClient>().clearSession();
    _storage.clear();
  } catch (e) {
    // Handle error
  }
}
```

**Nếu chưa có `clearSession()`, cần thêm**:
- Đảm bảo sau khi logout, `AuthRequestInterceptor.accessToken = null`
- Các request sau logout sẽ KHÔNG có Authorization header

---

### **Bước 3: Verify AuthRequestInterceptor Logic**

**File**: `lib/core/network/auth_request_interceptor.dart`

**Vị trí**: Method `onRequest()`, line 52-61

**Code hiện tại** (GIỮ NGUYÊN - đã đúng):
```dart
@override
void onRequest(
  RequestOptions options,
  RequestInterceptorHandler handler,
) async {
  if (accessToken?.isNotEmpty == true &&
      !options.headers.containsKey("Authorization")) {
    options.headers.addAll(authHeader);
  }
  return handler.next(options);
}
```

**Logic**:
- NẾU `accessToken` có giá trị VÀ header chưa có "Authorization"
- → Tự động thêm `Authorization: Bearer {token}`
- Điều kiện `!options.headers.containsKey("Authorization")` cho phép override token nếu cần

**KHÔNG CẦN SỬA** - Logic này đã đúng theo Clean Architecture.

---

### **Bước 4: Verify HttpClient.setSession()**

**File**: `lib/core/network/http_client.dart`

**Vị trí**: Method `setSession()`, line 65-70

**Code hiện tại** (GIỮ NGUYÊN):
```dart
void setSession({String? accessToken, String? refreshToken, int? expiresIn}) {
  authRequestInterceptor.accessToken = accessToken;
  authRequestInterceptor.refreshToken = refreshToken;
  authRequestInterceptor.expiresIn = expiresIn;
  authRequestInterceptor.scheduleRefreshToken();
}
```

**KHÔNG CẦN SỬA** - Logic này đã đúng.

---

### **Bước 5: Verify CurlInterceptor (Optional)**

**File**: `lib/core/network/curl_interceptor.dart`

**Lỗi**: `unable to create a CURL representation of the requestOptions`

**Nguyên nhân**: 
- Request options có thể bị malformed
- Hoặc CurlInterceptor không handle được format nào đó

**Giải pháp tạm thời**:
```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) {
  try {
    _renderCurlRepresentation(err.requestOptions);
  } catch (e) {
    // ✅ THÊM: Ignore curl generation error
    debugPrint('⚠️ Cannot generate CURL: $e');
  }
  return handler.next(err);
}
```

**Lưu ý**: 
- Lỗi này KHÔNG ảnh hưởng đến việc gọi API
- Chỉ ảnh hưởng đến việc log CURL command để debug
- Có thể tạm thời comment dòng `CurlInterceptor` trong `http_client.dart` nếu gây phiền

---

## 🏗️ Tuân Thủ Clean Architecture Rules

### **1. Layer Responsibilities** ✅

```
┌─────────────────────────────────────────────────────────┐
│ PRESENTATION (modules/)                                  │
│ ChangePasswordProvider                                   │
│  → Gọi AppProvider.changePassword()                     │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ APPLICATION (app/)                                       │
│ AppProvider                                              │
│  → Orchestrate: Gọi Repository, Update State            │
│  → KHÔNG trực tiếp xử lý HTTP/Token                     │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ DOMAIN (domain/)                                         │
│ AuthRepository Interface + Entities                      │
│  → Định nghĩa contract: changePassword(request)         │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ DATA (data/)                                             │
│ AuthRepositoryImpl + AuthService + DTOs                  │
│  → Implement: Convert Request → DTO → API Call          │
│  → KHÔNG biết về token/header (do Interceptor xử lý)    │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ CORE (core/network/)                                     │
│ AuthRequestInterceptor                                   │
│  → TỰ ĐỘNG inject Authorization header vào mọi request  │
│  → Data layer KHÔNG cần biết về authentication logic    │
└─────────────────────────────────────────────────────────┘
```

**Nguyên tắc**:
- ❌ **KHÔNG** thêm logic token vào `AuthRepositoryImpl`
- ❌ **KHÔNG** thêm header thủ công trong `AuthService`
- ✅ **NÊN** để `AuthRequestInterceptor` tự động xử lý
- ✅ **NÊN** gọi `setSession()` trong `AppProvider` sau login/register/restore

---

### **2. Import Rules** ✅

**Tuân thủ**:
- `app/app_provider.dart` → import `domain/` (Repository interface) ✅
- `app/app_provider.dart` → import `core/` (HttpClient) ✅
- `data/repository/` → import `data/services/`, `data/dto/`, `domain/` ✅
- `core/network/` → KHÔNG import `domain/` hay `data/` ✅

---

### **3. Dependency Injection** ✅

**HttpClient và AuthRequestInterceptor được inject qua GetIt**:

```dart
// lib/core/dependencies/app_dependencies.dart

void registerCore() {
  // 1. Register FlutterSecureStorage
  locator.registerLazySingleton(() => const FlutterSecureStorage());
  
  // 2. Register AuthRequestInterceptor (cần HttpClient + Storage)
  locator.registerLazySingleton(
    () => AuthRequestInterceptor(
      httpClient: locator(),
      storage: locator(),
    ),
  );
  
  // 3. Register HttpClient (cần Dio + Storage)
  locator.registerLazySingleton(
    () => HttpClient(
      dio: HttpClient.createDio(localeStr: 'en'),
      storage: locator(),
      onForceLogout: (_) => locator<AppProvider>().forceLogout(_),
    ),
  );
}
```

**Trong AppProvider**:
```dart
// Sử dụng locator để get HttpClient
locator<HttpClient>().setSession(
  accessToken: authResponse.accessToken,
  refreshToken: authResponse.refreshToken,
  expiresIn: authResponse.expiresIn,
);
```

---

## 🔄 So Sánh: Login vs ChangePassword

### **Login Flow** (ĐÚNG - có setSession)

```dart
// app/app_provider.dart
Future<void> login(LoginRequest request) async {
  // 1. Call Repository (Data Layer)
  final authResponse = await _authRepo.login(request);
  
  // 2. Save to Storage
  await _authRepo.setAuthInfo(authResponse);
  
  // 3. ✅ UPDATE INTERCEPTOR
  locator<HttpClient>().setSession(
    accessToken: authResponse.accessToken,
    refreshToken: authResponse.refreshToken,
    expiresIn: authResponse.expiresIn,
  );
  
  // 4. Update UI State
  authInfo.add(authResponse);
  isLoggedIn.add(true);
}
```

**Kết quả**: 
- Token được lưu vào storage ✅
- Token được set vào interceptor ✅
- Các protected API sau đó có Authorization header ✅

---

### **ChangePassword Flow** (SAI - thiếu token)

**Code hiện tại**:
```dart
// app/app_provider.dart
Future<void> changePassword(ChangePasswordRequest request) async {
  // 1. Call Repository (Data Layer)
  await _authRepo.changePassword(request);
  
  // ❌ KHÔNG có setSession()
  // ❌ Token không được update (nhưng cũng không cần update vì không đổi)
}
```

**Vấn đề**:
- `changePassword()` KHÔNG trả về AuthInfo mới
- Nhưng cần token để gọi API
- Nếu `AuthRequestInterceptor.accessToken = null` → Request thất bại

**Giải pháp**:
- KHÔNG cần sửa `changePassword()` trong `AppProvider`
- CHỈ cần đảm bảo `restore()` đã gọi `setSession()` khi app start
- Interceptor sẽ tự động thêm token vào request

---

## ⚠️ Lưu Ý Quan Trọng

### **1. Token Lifecycle**

```
┌──────────────────────────────────────────────────────┐
│ 1. APP START                                          │
│    → restore() gọi getAuthInfo() từ storage          │
│    → NẾU có token: gọi setSession() để load         │
├──────────────────────────────────────────────────────┤
│ 2. LOGIN/REGISTER                                     │
│    → API trả về token mới                            │
│    → Lưu vào storage + gọi setSession()             │
├──────────────────────────────────────────────────────┤
│ 3. PROTECTED API CALLS (Change Password, Profile...) │
│    → Interceptor tự động inject token                │
│    → KHÔNG cần xử lý thủ công                        │
├──────────────────────────────────────────────────────┤
│ 4. LOGOUT                                             │
│    → Xóa token khỏi storage                          │
│    → Gọi clearSession() để xóa khỏi interceptor     │
└──────────────────────────────────────────────────────┘
```

---

### **2. Khi Nào Cần Gọi setSession()?**

| Tình Huống | Có Cần Gọi? | Lý Do |
|-----------|------------|-------|
| App khởi động (restore) | ✅ CÓ | Load token từ storage vào interceptor |
| User login thành công | ✅ CÓ | Set token mới vào interceptor |
| User register thành công | ✅ CÓ | Set token mới vào interceptor |
| User change password | ❌ KHÔNG | Token không đổi, interceptor đã có token |
| User logout | ✅ CÓ (clearSession) | Xóa token khỏi interceptor |
| Refresh token | ✅ CÓ | Update token mới (nếu có refresh logic) |

---

### **3. Debug Tips**

**Kiểm tra xem token có được inject không**:

```dart
// Trong AuthRequestInterceptor.onRequest()
@override
void onRequest(
  RequestOptions options,
  RequestInterceptorHandler handler,
) async {
  debugPrint('🔐 [AUTH_INTERCEPTOR] AccessToken: ${accessToken ?? "NULL"}');
  debugPrint('🔐 [AUTH_INTERCEPTOR] Request: ${options.method} ${options.path}');
  
  if (accessToken?.isNotEmpty == true &&
      !options.headers.containsKey("Authorization")) {
    options.headers.addAll(authHeader);
    debugPrint('✅ [AUTH_INTERCEPTOR] Added Authorization header');
  } else {
    debugPrint('⚠️ [AUTH_INTERCEPTOR] No token to add');
  }
  
  return handler.next(options);
}
```

**Kiểm tra xem setSession() có được gọi không**:

```dart
// Trong AppProvider.restore()
Future<void> restore() async {
  debugPrint('🔄 [APP_PROVIDER] Starting restore...');
  
  final savedAuthInfo = await _authRepo.getAuthInfo();
  
  if (savedAuthInfo != null) {
    debugPrint('✅ [APP_PROVIDER] Found saved auth: ${savedAuthInfo.accessToken}');
    
    locator<HttpClient>().setSession(
      accessToken: savedAuthInfo.accessToken,
      refreshToken: savedAuthInfo.refreshToken,
      expiresIn: savedAuthInfo.expiresIn,
    );
    
    debugPrint('✅ [APP_PROVIDER] Session restored to interceptor');
  } else {
    debugPrint('⚠️ [APP_PROVIDER] No saved auth found');
  }
}
```

---

## 🎯 Checklist Triển Khai

- [ ] **Sửa AppProvider.restore()**
  - [ ] Thêm `setSession()` sau khi load token từ storage
  - [ ] Thêm debug log để verify
  
- [ ] **Verify AppProvider.login()**
  - [ ] Đảm bảo có gọi `setSession()` sau khi login thành công
  
- [ ] **Verify AppProvider.register()**
  - [ ] Đảm bảo có gọi `setSession()` sau khi register thành công
  
- [ ] **Verify AppProvider.logout()**
  - [ ] Đảm bảo có gọi `clearSession()`
  
- [ ] **Test changePassword()**
  - [ ] Login → ChangePassword → Verify có Authorization header
  - [ ] Restart app → ChangePassword → Verify có Authorization header
  
- [ ] **Fix CurlInterceptor (Optional)**
  - [ ] Thêm try-catch trong `onError()` để tránh crash log

---

## 📝 Kết Luận

**Nguyên nhân chính**: 
- Token không được load vào `AuthRequestInterceptor` khi app khởi động
- → Protected APIs (changePassword, getUserProfile...) không có Authorization header
- → Server reject request với 401 Unauthorized

**Giải pháp**: 
- Thêm `setSession()` trong `AppProvider.restore()` để load token khi app start
- Đảm bảo `login()` và `register()` cũng gọi `setSession()`
- Interceptor sẽ tự động xử lý phần còn lại

**Tuân thủ Clean Architecture**:
- ✅ Data layer KHÔNG biết về authentication logic
- ✅ Interceptor (Core layer) tự động xử lý
- ✅ App layer orchestrate việc set/clear session
- ✅ Không vi phạm Import Rules

---

## 📚 Tài Liệu Liên Quan

- `Rules.md` - Coding standards
- `REMEMBER_ME_IMPLEMENTATION.md` - Token caching logic
- `LOGOUT_FLOW.md` - Logout và clear session
- `FIX_AUTH_REPOSITORY_ERROR.md` - Auth setup issues

