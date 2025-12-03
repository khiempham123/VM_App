# XỬ LÝ API TRẢ VỀ 200 OK NHƯNG CÓ ERROR CODE

## ❌ VẤN ĐỀ

**API Response khi login sai:**
```json
Status: 200 OK
Body: {
  "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG",
  "message": "Invalid username/password",
  "data": null
}
```

**Vấn đề:** 
- ✅ HTTP Status: `200 OK` 
- ❌ Business Logic Error: `code: "MSG_USER_PASSWORD_OR_USERNAME_WRONG"`
- ❌ App nghĩ là thành công vì status 200
- ❌ Không throw exception → UI không hiển thị lỗi

---

## 🔍 PHÂN TÍCH

### Luồng hiện tại (SAI):

```
User login với email/password sai
    ↓
POST /fw-api/settings/login
    ↓
Backend trả về:
    Status: 200 OK
    Body: { "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG", ... }
    ↓
Retrofit parse thành công (vì status 200)
    ↓
AuthResponseDto được tạo
    ↓
❌ App nghĩ login thành công
    ↓
❌ Lỗi: accessToken = null → Crash hoặc lỗi khác
```

### Luồng đúng (CẦN SỬA):

```
User login với email/password sai
    ↓
POST /fw-api/settings/login
    ↓
Backend trả về:
    Status: 200 OK
    Body: { "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG", ... }
    ↓
✅ Interceptor/Repository kiểm tra response.code
    ↓
✅ Nếu code != success → Throw exception
    ↓
✅ LoginProvider catch exception
    ↓
✅ UI hiển thị: "Invalid username/password"
```

---

## 💡 GIẢI PHÁP

Có **3 cách** để xử lý, theo thứ tự ưu tiên:

### **Cách 1: Xử lý trong Dio Interceptor** ⭐⭐⭐ (KHUYẾN NGHỊ)
- Tự động check mọi response
- Centralized: Áp dụng cho TẤT CẢ API
- Không cần sửa từng Repository

### **Cách 2: Xử lý trong Repository**
- Check từng API response
- Phải sửa nhiều chỗ (login, register, etc.)
- Dễ quên check

### **Cách 3: Xử lý trong DTO**
- Validate khi parse JSON
- Phức tạp, khó maintain

---

## 📝 PSEUDO CODE - LUỒNG XỬ LÝ

### Pseudo Code 1: ResponseValidatorInterceptor

```
FUNCTION onResponse(response):
    // Chỉ check response thành công (200-299)
    IF response.statusCode IN [200..299]:
        data = response.body
        
        // Check nếu là JSON object
        IF data is Map:
            errorCode = data["code"]
            errorMessage = data["message"]
            
            // Danh sách error codes từ backend
            errorCodeList = [
                "MSG_USER_PASSWORD_OR_USERNAME_WRONG",
                "MSG_USER_NOT_FOUND",
                "MSG_TOKEN_EXPIRED",
                ...
            ]
            
            // Check nếu có error code
            IF errorCode EXISTS AND errorCode IN errorCodeList:
                // Đây là business error dù status 200
                THROW DioException(
                    type: badResponse,
                    message: errorMessage,
                    response: response
                )
            END IF
        END IF
    END IF
    
    // Response OK, tiếp tục
    CONTINUE to next interceptor
END FUNCTION
```

### Pseudo Code 2: DioFailure Parser

```
FUNCTION parseDioException(dioException):
    response = dioException.response
    
    // Check business error (status 200 nhưng có error code)
    IF response EXISTS:
        data = response.body
        
        IF data is Map:
            errorCode = data["code"]
            errorMessage = data["message"]
            
            IF errorCode EXISTS AND errorMessage EXISTS:
                // Map error code sang tiếng Việt
                userFriendlyMessage = mapErrorMessage(errorCode, errorMessage)
                
                RETURN DioFailure(
                    code: errorCode,
                    message: userFriendlyMessage
                )
            END IF
        END IF
    END IF
    
    // Check network errors (no connection, timeout, etc.)
    IF dioException.type == connectionTimeout:
        RETURN DioFailure(message: "Kết nối quá chậm")
    ELSE IF dioException.type == receiveTimeout:
        RETURN DioFailure(message: "Không nhận được phản hồi từ server")
    ELSE IF dioException.type == connectionError:
        RETURN DioFailure(message: "Không có kết nối internet")
    ...
    
    // Unknown error
    RETURN DioFailure(message: "Đã xảy ra lỗi không xác định")
END FUNCTION

FUNCTION mapErrorMessage(errorCode, defaultMessage):
    errorMap = {
        "MSG_USER_PASSWORD_OR_USERNAME_WRONG": "Email hoặc mật khẩu không đúng",
        "MSG_USER_NOT_FOUND": "Tài khoản không tồn tại",
        "MSG_TOKEN_EXPIRED": "Phiên đăng nhập đã hết hạn",
        ...
    }
    
    IF errorCode IN errorMap:
        RETURN errorMap[errorCode]
    ELSE:
        RETURN defaultMessage  // Dùng message từ backend
    END IF
END FUNCTION
```

### Pseudo Code 3: LoginProvider

```
CLASS LoginProvider:
    FIELD emailController
    FIELD passwordController
    FIELD isLoading = false
    FIELD errorMessage = null
    
    FUNCTION login():
        // Reset state
        isLoading = true
        errorMessage = null
        UPDATE_UI()
        
        TRY:
            // Tạo request
            request = LoginRequest(
                email: emailController.text,
                password: passwordController.text
            )
            
            // Gọi API qua AppProvider
            AWAIT appProvider.login(request)
            
            // Nếu đến đây = thành công
            isLoading = false
            UPDATE_UI()
            NAVIGATE_TO(HomeScreen)
            
        CATCH exception:
            // Nếu vào đây = có lỗi
            // Exception có thể là:
            // - Business error: "Email hoặc mật khẩu không đúng"
            // - Network error: "Không có kết nối internet"
            // - Unknown error: "Đã xảy ra lỗi không xác định"
            
            isLoading = false
            errorMessage = exception.message
            UPDATE_UI()  // UI sẽ hiển thị error màu đỏ
        END TRY
    END FUNCTION
END CLASS
```

### Pseudo Code 4: Luồng đầy đủ khi login SAI

```
// USER ACTION
User nhập:
    email = "wrong@email.com"
    password = "wrongpass"
User click "Sign In"

// STEP 1: LoginProvider.login()
LoginProvider:
    isLoading = true
    errorMessage = null
    UI shows loading spinner
    
    request = LoginRequest(email: "wrong@email.com", password: "wrongpass")
    CALL appProvider.login(request)

// STEP 2: AppProvider.login()
AppProvider:
    CALL authRepository.login(request)

// STEP 3: AuthRepository.login()
AuthRepository:
    dto = LoginDto(email: "wrong@email.com", password: "wrongpass")
    CALL authService.login(dto)  // Retrofit

// STEP 4: Retrofit HTTP Call
Retrofit:
    POST https://dricon.fastmap.vn/fw-api/settings/login
    Body: { "email": "wrong@email.com", "password": "wrongpass" }

// STEP 5: Backend Response
Backend:
    Status: 200 OK
    Body: {
        "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG",
        "message": "Invalid username/password",
        "data": null
    }

// STEP 6: ResponseValidatorInterceptor (QUAN TRỌNG!)
ResponseValidatorInterceptor:
    response.statusCode = 200
    response.body = { "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG", ... }
    
    CHECK: "MSG_USER_PASSWORD_OR_USERNAME_WRONG" IN errorCodeList?
    → YES! Đây là business error
    
    THROW DioException(
        type: badResponse,
        message: "Invalid username/password",
        response: response
    )

// STEP 7: DioFailure Parser
DioFailure:
    dioException received
    response.data = { "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG", ... }
    
    errorCode = "MSG_USER_PASSWORD_OR_USERNAME_WRONG"
    userMessage = mapErrorMessage(errorCode)
    → "Email hoặc mật khẩu không đúng"
    
    THROW Exception("Email hoặc mật khẩu không đúng")

// STEP 8: Exception bubbles up
AuthRepository → AppProvider → LoginProvider

// STEP 9: LoginProvider.login() CATCH block
LoginProvider:
    CATCH exception:
        isLoading = false
        errorMessage = "Email hoặc mật khẩu không đúng"
        UPDATE_UI()

// STEP 10: UI Update
LoginScreen:
    Show error message container (màu đỏ)
    Text: "Email hoặc mật khẩu không đúng"
    TextField vẫn giữ nguyên email
    User có thể sửa và thử lại
```

### Pseudo Code 5: Luồng đầy đủ khi login ĐÚNG

```
// USER ACTION
User nhập:
    email = "khiempg@vietmap.vn"
    password = "correctpass"
User click "Sign In"

// STEP 1-4: Giống như login sai
...

// STEP 5: Backend Response
Backend:
    Status: 200 OK
    Body: {
        "accessToken": "eyJhbGci...",
        "refreshToken": "refresh...",
        "expiresIn": 3600,
        "user": {
            "id": "user123",
            "email": "khiempg@vietmap.vn",
            "firstName": "Khiem",
            "lastName": "Pham"
        },
        "success": true
    }

// STEP 6: ResponseValidatorInterceptor
ResponseValidatorInterceptor:
    response.statusCode = 200
    response.body = { "accessToken": "...", "user": {...} }
    
    CHECK: body có "code" field?
    → NO! Không có error code
    
    CONTINUE to next interceptor (không throw exception)

// STEP 7: Retrofit Parse
Retrofit:
    Parse JSON → AuthResponseDto
    AuthResponseDto {
        accessToken: "eyJhbGci...",
        refreshToken: "refresh...",
        user: UserDto { ... }
    }

// STEP 8: Repository Convert
AuthRepository:
    authInfo = response.toEntity()
    // AuthResponseDto → AuthInfo (Entity)
    RETURN authInfo

// STEP 9: AppProvider Update State
AppProvider:
    Save token to storage
    Update HttpClient session
    authInfo.add(authInfo)
    isLoggedIn.add(true)

// STEP 10: LoginProvider Success
LoginProvider:
    // Không vào CATCH block
    isLoading = false
    UPDATE_UI()

// STEP 11: Auto Navigate
RootPage:
    Listen to isLoggedIn stream
    isLoggedIn = true
    → NAVIGATE_TO(HomeScreen)

// STEP 12: User sees HomeScreen
User thấy HomeScreen ✅
```

### Decision Tree: ResponseValidatorInterceptor

```
                    ┌─────────────────────────┐
                    │   Response received     │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼────────────┐
                    │ Status code 200-299?   │
                    └───┬─────────────────┬──┘
                       YES               NO
                        │                 │
                        │                 └──► Continue (let DioFailure handle)
                        │
            ┌───────────▼────────────┐
            │  Response is JSON Map? │
            └───┬─────────────────┬──┘
               YES               NO
                │                 │
                │                 └──► Continue (not JSON error format)
                │
    ┌───────────▼────────────────┐
    │  Has "code" field?         │
    └───┬─────────────────────┬──┘
       YES                   NO
        │                     │
        │                     └──► Continue (normal success response)
        │
┌───────▼──────────────────────┐
│ Code in errorCodeList?       │
│ - MSG_USER_PASSWORD_...      │
│ - MSG_USER_NOT_FOUND         │
│ - MSG_TOKEN_EXPIRED          │
│ - etc.                        │
└───┬──────────────────────┬───┘
   YES                    NO
    │                      │
    │                      └──► Continue (unknown code, let it pass)
    │
┌───▼──────────────────────┐
│ REJECT with DioException │
│ - type: badResponse      │
│ - message: from response │
└──────────────────────────┘
```

### Decision Tree: DioFailure Parser

```
                    ┌─────────────────────────┐
                    │  DioException received  │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼────────────┐
                    │  Has response object?  │
                    └───┬─────────────────┬──┘
                       YES               NO
                        │                 │
                        │                 └──► Check exception type
                        │                      (timeout, connection error, etc.)
                        │
            ┌───────────▼────────────┐
            │  Response.data is Map? │
            └───┬─────────────────┬──┘
               YES               NO
                │                 │
                │                 └──► Parse as generic error
                │
    ┌───────────▼────────────────┐
    │  Has "code" AND "message"? │
    └───┬─────────────────────┬──┘
       YES                   NO
        │                     │
        │                     └──► Parse status code (404, 500, etc.)
        │
┌───────▼──────────────────────────┐
│ Map error code to Vietnamese     │
│                                   │
│ "MSG_USER_PASSWORD_..." →        │
│ "Email hoặc mật khẩu không đúng" │
└───────┬──────────────────────────┘
        │
┌───────▼──────────────────────┐
│ Return DioFailure            │
│ - code: from response        │
│ - message: user-friendly     │
└──────────────────────────────┘
```

### Comparison: With vs Without Interceptor

```
╔════════════════════════════════════════════════════════════════════╗
║                    WITHOUT INTERCEPTOR                             ║
╚════════════════════════════════════════════════════════════════════╝

Backend: 200 OK + { "code": "MSG_...", "message": "..." }
    ↓
Retrofit: Parse success (vì status 200)
    ↓
AuthResponseDto created
    ↓
❌ accessToken = null
    ↓
❌ response.toEntity() → Error hoặc crash
    ↓
❌ User confused


╔════════════════════════════════════════════════════════════════════╗
║                    WITH INTERCEPTOR                                ║
╚════════════════════════════════════════════════════════════════════╝

Backend: 200 OK + { "code": "MSG_...", "message": "..." }
    ↓
✅ Interceptor: Check code → Is error? YES!
    ↓
✅ Reject with DioException
    ↓
✅ DioFailure: Parse error → "Email hoặc mật khẩu không đúng"
    ↓
✅ LoginProvider: Catch exception
    ↓
✅ UI: Show error message màu đỏ
    ↓
✅ User sees clear error message
```

---

## ✅ CÁCH 1: XỬ LÝ TRONG DIO INTERCEPTOR (KHUYẾN NGHỊ)

### Step 1: Tạo Response Interceptor

**File mới:** `lib/core/network/response_validator_interceptor.dart`

```dart
import 'package:dio/dio.dart';
import 'package:vm_first_app/core/exception/dio_failure.dart';

/// Interceptor kiểm tra response body có error code không
/// Dùng cho API trả về 200 OK nhưng có error code trong body
class ResponseValidatorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Chỉ check với status 200-299
    if (response.statusCode != null && 
        response.statusCode! >= 200 && 
        response.statusCode! < 300) {
      
      final data = response.data;
      
      // Check nếu response có error code
      if (data is Map<String, dynamic>) {
        final code = data['code'] as String?;
        final message = data['message'] as String?;
        
        // ✅ Danh sách error codes từ backend
        // Thêm các error code khác vào đây
        final errorCodes = [
          'MSG_USER_PASSWORD_OR_USERNAME_WRONG',
          'MSG_USER_NOT_FOUND',
          'MSG_TOKEN_EXPIRED',
          'MSG_INVALID_TOKEN',
          // ... thêm các error code khác
        ];
        
        if (code != null && errorCodes.contains(code)) {
          // ✅ Convert thành DioException để DioFailure xử lý
          final error = DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: message ?? code,
          );
          
          // Reject với DioException
          handler.reject(error);
          return;
        }
      }
    }
    
    // Response OK, tiếp tục
    handler.next(response);
  }
}
```

### Step 2: Đăng ký Interceptor trong HttpClient

**File:** `lib/core/network/http_client.dart`

Tìm đoạn code khởi tạo Dio:

```dart
class HttpClient {
  static Dio createDio({
    required String localeStr,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://dricon.fastmap.vn',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 1),
    ));

    // Add interceptors
    dio.interceptors.addAll([
      // ... existing interceptors
      
      // ✅ THÊM ResponseValidatorInterceptor
      ResponseValidatorInterceptor(),
      
      // Pretty dio logger phải ở cuối
      PrettyDioLogger(/* ... */),
    ]);

    return dio;
  }
}
```

### Step 3: Update DioFailure để xử lý business error

**File:** `lib/core/exception/dio_failure.dart`

Thêm vào factory constructor (sau phần parse api error):

```dart
factory DioFailure(DioException dioException) {
  final info = {
    'requestOptions': dioException.requestOptions,
    'response': dioException.response,
    'type': dioException.type,
    'error': dioException.error,
    'stackTrace': dioException.stackTrace,
  };

  // ... existing checks (404, no connection, timeout, etc.)

  // ✅ THÊM: Parse business error từ response (status 200 nhưng có error code)
  final respData = dioException.response?.data;
  
  if (respData is Map<String, dynamic>) {
    final code = respData['code'] as String?;
    final message = respData['message'] as String?;
    
    // Check nếu là business error
    if (code != null && message != null) {
      // Map error code sang user-friendly message (optional)
      final userMessage = _getErrorMessage(code, message);
      
      return DioFailure._(
        code: code,
        error: code,
        actualException: dioException,
        message: userMessage,
        info: info,
      );
    }
  }

  // ... existing code for parsing other errors
  
  return DioFailure._(
    code: ErrorCodes.unknown,
    error: ErrorCodes.unknown,
    actualException: dioException,
    info: info,
  );
}

/// Map backend error code sang user-friendly message
static String _getErrorMessage(String code, String defaultMessage) {
  switch (code) {
    case 'MSG_USER_PASSWORD_OR_USERNAME_WRONG':
      return 'Email hoặc mật khẩu không đúng';
    case 'MSG_USER_NOT_FOUND':
      return 'Tài khoản không tồn tại';
    case 'MSG_TOKEN_EXPIRED':
      return 'Phiên đăng nhập đã hết hạn';
    case 'MSG_INVALID_TOKEN':
      return 'Phiên đăng nhập không hợp lệ';
    default:
      return defaultMessage; // Dùng message từ backend
  }
}
```

### Step 4: LoginProvider đã tự động catch lỗi

**File:** `lib/modules/auth/login/login_provider.dart`

Code hiện tại đã đúng:

```dart
Future<void> login() async {
  try {
    final request = LoginRequest(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    await _appProvider.login(request, rememberMe: _isRememberMe);

    // ✅ Nếu đến đây = login thành công
  } catch (e) {
    // ✅ Nếu vào đây = có lỗi (bao gồm business error)
    _errorMessage = e.toString();
    notifyListeners();
  }
}
```

### Step 5: UI hiển thị lỗi

**File:** `lib/modules/auth/login/login_screen.dart`

Code hiện tại đã có:

```dart
// Error Message
if (provider.errorMessage != null) ...[
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            provider.errorMessage!,  // ✅ Hiển thị "Email hoặc mật khẩu không đúng"
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    ),
  ),
],
```

---

## 🎯 CÁCH 2: XỬ LÝ TRONG REPOSITORY (BACKUP)

Nếu không muốn dùng Interceptor, có thể check trong Repository:

**File:** `lib/data/repository/auth_repository.dart`

```dart
@override
Future<AuthInfo> login(LoginRequest request) async {
  final dto = LoginDto(
    email: request.email,
    password: request.password,
  );

  final response = await authService.login(dto);
  
  // ✅ Check response có error code không
  // Lưu ý: Cần sửa AuthService để return Response thay vì AuthResponseDto
  // Hoặc AuthResponseDto phải có field code/message
  
  // Option 1: Nếu AuthService return Response<dynamic>
  if (response.data is Map<String, dynamic>) {
    final data = response.data as Map<String, dynamic>;
    final code = data['code'] as String?;
    final message = data['message'] as String?;
    
    if (code != null && code.startsWith('MSG_')) {
      // Đây là business error
      throw Exception(message ?? 'Login failed');
    }
  }
  
  return response.toEntity();
}
```

**Vấn đề của cách này:**
- ❌ Phải check ở MỌI method (login, register, getProfile, etc.)
- ❌ Dễ quên check
- ❌ Duplicate code

---

## 📊 SO SÁNH CÁC CÁCH

| Cách | Ưu điểm | Nhược điểm | Khuyến nghị |
|------|---------|------------|-------------|
| **Interceptor** | ✅ Centralized<br>✅ Auto áp dụng cho tất cả API<br>✅ Không sửa Repository | ❌ Cần tạo thêm file | ⭐⭐⭐ |
| **Repository** | ✅ Control từng API<br>✅ Flexible | ❌ Phải check mọi method<br>❌ Duplicate code | ⭐ |
| **DTO** | ✅ Validate khi parse | ❌ Phức tạp<br>❌ DTO không nên có logic | ❌ |

---

## 🔑 ERROR CODES CẦN XỬ LÝ

Dựa vào backend API, thêm các error codes vào danh sách:

```dart
final errorCodes = [
  // Authentication
  'MSG_USER_PASSWORD_OR_USERNAME_WRONG',
  'MSG_USER_NOT_FOUND',
  'MSG_USER_ALREADY_EXISTS',
  'MSG_TOKEN_EXPIRED',
  'MSG_INVALID_TOKEN',
  'MSG_TOKEN_NOT_FOUND',
  
  // Validation
  'MSG_INVALID_EMAIL',
  'MSG_INVALID_PASSWORD',
  'MSG_INVALID_PHONE',
  
  // Permission
  'MSG_PERMISSION_DENIED',
  'MSG_ACCESS_DENIED',
  
  // Business Logic
  'MSG_INSUFFICIENT_BALANCE',
  'MSG_ITEM_NOT_FOUND',
  'MSG_ORDER_CANCELLED',
  
  // Rate Limiting
  'MSG_TOO_MANY_REQUESTS',
  'MSG_RATE_LIMIT_EXCEEDED',
];
```

---

## 🎨 USER-FRIENDLY ERROR MESSAGES

Thay vì hiển thị raw message từ backend, map sang tiếng Việt:

```dart
static String _getErrorMessage(String code, String defaultMessage) {
  final errorMessages = {
    // Authentication
    'MSG_USER_PASSWORD_OR_USERNAME_WRONG': 'Email hoặc mật khẩu không đúng',
    'MSG_USER_NOT_FOUND': 'Tài khoản không tồn tại',
    'MSG_USER_ALREADY_EXISTS': 'Email đã được sử dụng',
    'MSG_TOKEN_EXPIRED': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại',
    'MSG_INVALID_TOKEN': 'Phiên đăng nhập không hợp lệ',
    
    // Validation
    'MSG_INVALID_EMAIL': 'Email không hợp lệ',
    'MSG_INVALID_PASSWORD': 'Mật khẩu phải có ít nhất 6 ký tự',
    'MSG_INVALID_PHONE': 'Số điện thoại không hợp lệ',
    
    // Permission
    'MSG_PERMISSION_DENIED': 'Bạn không có quyền thực hiện hành động này',
    'MSG_ACCESS_DENIED': 'Truy cập bị từ chối',
    
    // Rate Limiting
    'MSG_TOO_MANY_REQUESTS': 'Bạn đã thực hiện quá nhiều lần. Vui lòng thử lại sau',
  };
  
  return errorMessages[code] ?? defaultMessage;
}
```

---

## 🐛 TESTING

### Test Case 1: Login sai email/password

```dart
Input:
  email: "wrong@email.com"
  password: "wrongpassword"

Expected:
  ✅ UI hiển thị: "Email hoặc mật khẩu không đúng"
  ✅ TextField không bị clear
  ✅ Không navigate
```

### Test Case 2: Login đúng

```dart
Input:
  email: "khiempg@vietmap.vn"
  password: "correctpassword"

Expected:
  ✅ Login thành công
  ✅ Navigate to HomeScreen
  ✅ Không có error message
```

### Test Case 3: Network error

```dart
Input:
  Không có internet

Expected:
  ✅ UI hiển thị: "Không có kết nối internet"
  ✅ Khác với business error
```

---

## 📝 CHECKLIST IMPLEMENTATION

### Cách 1: Interceptor (Khuyến nghị)

- [ ] Tạo file `response_validator_interceptor.dart`
- [ ] Implement ResponseValidatorInterceptor
- [ ] Thêm danh sách error codes
- [ ] Đăng ký interceptor trong HttpClient
- [ ] Update DioFailure._getErrorMessage() với tiếng Việt
- [ ] Test với login sai
- [ ] Test với login đúng
- [ ] Test với network error
- [ ] Thêm error codes khác từ backend

### Cách 2: Repository (Backup)

- [ ] Sửa AuthRepositoryImpl.login()
- [ ] Check response.code
- [ ] Throw exception nếu có error
- [ ] Lặp lại cho register(), updateProfile(), etc.
- [ ] Test từng method

---

## 🔄 LUỒNG SAU KHI FIX

### Login sai:

```
User nhập email/password sai
    ↓
POST /fw-api/settings/login
    ↓
Backend: 200 OK + { "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG" }
    ↓
✅ ResponseValidatorInterceptor intercept
    ↓
✅ Check code trong errorCodes list
    ↓
✅ Reject với DioException
    ↓
✅ DioFailure parse error
    ↓
✅ Map sang "Email hoặc mật khẩu không đúng"
    ↓
✅ LoginProvider catch exception
    ↓
✅ Set _errorMessage
    ↓
✅ UI hiển thị error message màu đỏ
    ↓
User thấy: "Email hoặc mật khẩu không đúng" ✅
```

### Login đúng:

```
User nhập email/password đúng
    ↓
POST /fw-api/settings/login
    ↓
Backend: 200 OK + { "accessToken": "...", "user": {...} }
    ↓
✅ ResponseValidatorInterceptor check
    ↓
✅ Không có error code → next()
    ↓
✅ Retrofit parse AuthResponseDto
    ↓
✅ Repository convert DTO → Entity
    ↓
✅ Login thành công
    ↓
✅ Navigate to HomeScreen ✅
```

---

## 💡 BEST PRACTICES

### 1. Centralized Error Handling

```dart
// ✅ ĐÚNG: Tất cả error handling ở 1 chỗ
class ResponseValidatorInterceptor extends Interceptor {
  // Check mọi response
}

// ❌ SAI: Error handling rải rác
class AuthRepositoryImpl {
  login() { /* check error */ }
  register() { /* check error */ }
  // ... phải lặp lại logic check
}
```

### 2. User-Friendly Messages

```dart
// ✅ ĐÚNG: Dễ hiểu cho user
"Email hoặc mật khẩu không đúng"

// ❌ SAI: Technical message
"MSG_USER_PASSWORD_OR_USERNAME_WRONG"
```

### 3. Consistent Error Format

```dart
// Backend nên trả về format nhất quán:
{
  "code": "ERROR_CODE",     // Machine-readable
  "message": "...",         // Human-readable
  "data": null
}
```

---

## ✅ TÓM TẮT

### Vấn đề:
- API trả về 200 OK nhưng có error code trong body
- App nghĩ là thành công → không hiển thị lỗi

### Giải pháp:
1. **Tạo ResponseValidatorInterceptor** - Check response body
2. **Reject nếu có error code** - Convert thành DioException
3. **DioFailure parse error** - Map sang user-friendly message
4. **UI tự động hiển thị** - LoginProvider đã catch exception

### Khuyến nghị:
⭐⭐⭐ **Dùng Interceptor** - Centralized, auto áp dụng cho tất cả API

### Files cần tạo/sửa:
1. Tạo: `lib/core/network/response_validator_interceptor.dart`
2. Sửa: `lib/core/network/http_client.dart` - Đăng ký interceptor
3. Sửa: `lib/core/exception/dio_failure.dart` - Thêm _getErrorMessage()

---

✅ **Sau khi implement, login sai sẽ hiển thị: "Email hoặc mật khẩu không đúng"**

