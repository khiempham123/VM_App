# CUSTOM ERROR HANDLER - HIỂN THỊ MESSAGE TỪ SERVER LÊN UI

## 🎯 MỤC TIÊU

Customize error handling để:
1. ✅ Hiển thị chính xác message từ server
2. ✅ Phân biệt các loại error (network, business, validation)
3. ✅ User-friendly messages
4. ✅ Dễ maintain và extend

---

## 📋 CẤU TRÚC ERROR HANDLING HIỆN TẠI

### Luồng Error:

```
API Error Response
    ↓
Dio throws DioException
    ↓
ErrorHandlerInterceptor.onError()
    ↓
Convert DioException → DioFailure
    ↓
LoginProvider.catch(e)
    ↓
errorMessage = e.toString()
    ↓
UI hiển thị error
```

### Files liên quan:

```
lib/core/exception/
├── failure.dart                      ← Base Failure class
├── dio_failure.dart                  ← Parse DioException → Failure
├── error_handler_interceptor.dart    ← Intercept error
├── error_codes.dart                  ← Error code constants
└── exception_extension.dart          ← Extensions
```

---

## 🔧 CÁCH 1: SỬ DỤNG `message` TRỰC TIẾP TỪ SERVER (ĐƠN GIẢN)

### Backend Response Format:

```json
// Error response
{
  "code": "MSG_USER_PASSWORD_OR_USERNAME_WRONG",
  "message": "Email hoặc mật khẩu không đúng",
  "data": null
}
```

### Đã có sẵn trong DioFailure:

```dart
// File: lib/core/exception/dio_failure.dart (dòng 74-89)

if (respData is Map<String, dynamic>) {
  final code = respData['code'] as String?;
  final message = respData['message'] as String?;

  if (code != null && code.isNotEmpty) {
    // ✅ Lấy message trực tiếp từ server
    final userMessage = message;  // ← Dùng message từ server

    return DioFailure._(
      code: code,
      error: code,
      actualException: dioException,
      message: userMessage,  // ← Message này sẽ hiển thị trên UI
      info: info,
    );
  }
}
```

### Hiển thị trên UI:

```dart
// File: lib/modules/auth/login/login_provider.dart

Future<void> login() async {
  try {
    await _appProvider.login(request, rememberMe: _isRememberMe);
  } catch (e) {
    // ✅ e.toString() sẽ gọi Failure.toString()
    // → "[code] message"
    _errorMessage = e.toString();
    
    // Hoặc extract message cụ thể:
    if (e is DioFailure) {
      _errorMessage = e.message ?? 'Đã xảy ra lỗi';
    } else {
      _errorMessage = e.toString();
    }
    
    notifyListeners();
  }
}
```

### Vấn đề với cách này:

- ✅ Đơn giản, dùng message từ server
- ❌ Backend phải trả về message bằng tiếng Việt
- ❌ Không control được message format
- ❌ Message có thể không consistent

---

## 🎨 CÁCH 2: MAP ERROR CODE → CUSTOM MESSAGE (LINH HOẠT)

### Tạo Error Message Mapper:

**File mới:** `lib/core/exception/error_message_mapper.dart`

```dart
/// Map error code từ backend sang user-friendly message
class ErrorMessageMapper {
  /// Map error code → Message tiếng Việt
  static String getMessage(String code, String? defaultMessage) {
    final messages = _errorMessages[code];
    
    if (messages != null) {
      return messages;
    }
    
    // Fallback: Dùng message từ server nếu không có mapping
    return defaultMessage ?? _getGenericMessage(code);
  }
  
  /// Danh sách error messages
  static const Map<String, String> _errorMessages = {
    // ==================== AUTHENTICATION ====================
    'MSG_USER_PASSWORD_OR_USERNAME_WRONG': 
        'Email hoặc mật khẩu không đúng. Vui lòng thử lại.',
    
    'MSG_USER_NOT_FOUND': 
        'Tài khoản không tồn tại. Vui lòng kiểm tra lại email.',
    
    'MSG_USER_ALREADY_EXISTS': 
        'Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng email khác.',
    
    'MSG_TOKEN_EXPIRED': 
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    
    'MSG_INVALID_TOKEN': 
        'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
    
    'MSG_TOKEN_NOT_FOUND': 
        'Bạn chưa đăng nhập. Vui lòng đăng nhập để tiếp tục.',
    
    'MSG_SESSION_EXPIRED':
        'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.',
    
    // ==================== VALIDATION ====================
    'MSG_INVALID_EMAIL': 
        'Địa chỉ email không hợp lệ.',
    
    'MSG_INVALID_PASSWORD': 
        'Mật khẩu phải có ít nhất 6 ký tự, bao gồm chữ và số.',
    
    'MSG_INVALID_PHONE': 
        'Số điện thoại không hợp lệ.',
    
    'MSG_REQUIRED_FIELD': 
        'Vui lòng điền đầy đủ thông tin bắt buộc.',
    
    'MSG_INVALID_FORMAT':
        'Định dạng dữ liệu không đúng. Vui lòng kiểm tra lại.',
    
    // ==================== PERMISSION ====================
    'MSG_PERMISSION_DENIED': 
        'Bạn không có quyền thực hiện thao tác này.',
    
    'MSG_ACCESS_DENIED': 
        'Truy cập bị từ chối.',
    
    'MSG_FORBIDDEN':
        'Bạn không được phép truy cập tài nguyên này.',
    
    // ==================== BUSINESS LOGIC ====================
    'MSG_INSUFFICIENT_BALANCE': 
        'Số dư tài khoản không đủ.',
    
    'MSG_ITEM_NOT_FOUND': 
        'Không tìm thấy dữ liệu yêu cầu.',
    
    'MSG_ORDER_CANCELLED': 
        'Đơn hàng đã bị hủy.',
    
    'MSG_DUPLICATE_ENTRY':
        'Dữ liệu đã tồn tại trong hệ thống.',
    
    // ==================== RATE LIMITING ====================
    'MSG_TOO_MANY_REQUESTS': 
        'Bạn đã thực hiện quá nhiều lần. Vui lòng thử lại sau 5 phút.',
    
    'MSG_RATE_LIMIT_EXCEEDED': 
        'Vượt quá giới hạn cho phép. Vui lòng thử lại sau.',
    
    // ==================== SERVER ERRORS ====================
    'MSG_INTERNAL_SERVER_ERROR':
        'Lỗi hệ thống. Vui lòng thử lại sau.',
    
    'MSG_SERVICE_UNAVAILABLE':
        'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.',
    
    'MSG_MAINTENANCE':
        'Hệ thống đang bảo trì. Vui lòng quay lại sau.',
  };
  
  /// Generate generic message nếu không có mapping
  static String _getGenericMessage(String code) {
    if (code.startsWith('MSG_')) {
      // Convert MSG_USER_NOT_FOUND → "User Not Found"
      final readable = code
          .replaceAll('MSG_', '')
          .replaceAll('_', ' ')
          .toLowerCase();
      
      return 'Lỗi: ${_capitalize(readable)}';
    }
    
    return 'Đã xảy ra lỗi không xác định ($code)';
  }
  
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  /// Get short message (cho toast/snackbar)
  static String getShortMessage(String code) {
    final shortMessages = {
      'MSG_USER_PASSWORD_OR_USERNAME_WRONG': 'Đăng nhập thất bại',
      'MSG_TOKEN_EXPIRED': 'Phiên hết hạn',
      'MSG_NETWORK_ERROR': 'Lỗi kết nối',
      'MSG_TIMEOUT': 'Hết thời gian chờ',
    };
    
    return shortMessages[code] ?? getMessage(code, null);
  }
}
```

### Cập nhật DioFailure để dùng Mapper:

```dart
// File: lib/core/exception/dio_failure.dart

import 'package:vm_first_app/core/exception/error_message_mapper.dart';

factory DioFailure(DioException dioException) {
  // ... existing code ...
  
  if (respData is Map<String, dynamic>) {
    final code = respData['code'] as String?;
    final serverMessage = respData['message'] as String?;

    if (code != null && code.isNotEmpty) {
      // ✅ Dùng ErrorMessageMapper thay vì message từ server
      final userMessage = ErrorMessageMapper.getMessage(code, serverMessage);
      
      return DioFailure._(
        code: code,
        error: code,
        actualException: dioException,
        message: userMessage,  // ← Custom message
        info: info,
      );
    }
  }
  
  // ... rest of code ...
}
```

---

## 🎯 CÁCH 3: CUSTOM ERROR DISPLAY WIDGET (BEST UX)

### Tạo Custom Error Widget:

**File mới:** `lib/core/widgets/error_message_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:vm_first_app/core/exception/dio_failure.dart';
import 'package:vm_first_app/core/exception/error_message_mapper.dart';
import 'package:vm_first_app/core/theme/app_colors.dart';
import 'package:vm_first_app/core/theme/app_text_styles.dart';

/// Widget hiển thị error message với icon và style
class ErrorMessageWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final bool showIcon;
  final bool showCode;

  const ErrorMessageWidget({
    Key? key,
    required this.error,
    this.onRetry,
    this.showIcon = true,
    this.showCode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorInfo = _parseError(error);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(errorInfo.type),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(errorInfo.type),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              _getIcon(errorInfo.type),
              color: _getIconColor(errorInfo.type),
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorInfo.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (showCode && errorInfo.code != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Mã lỗi: ${errorInfo.code}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }

  ErrorInfo _parseError(Object error) {
    if (error is DioFailure) {
      return ErrorInfo(
        message: error.message ?? 'Đã xảy ra lỗi',
        code: error.code,
        type: _getErrorType(error.code),
      );
    }
    
    return ErrorInfo(
      message: error.toString(),
      type: ErrorType.unknown,
    );
  }

  ErrorType _getErrorType(String code) {
    if (code.contains('PASSWORD') || code.contains('USERNAME')) {
      return ErrorType.authentication;
    }
    if (code.contains('PERMISSION') || code.contains('ACCESS')) {
      return ErrorType.permission;
    }
    if (code.contains('NETWORK') || code.contains('CONNECTION')) {
      return ErrorType.network;
    }
    if (code.contains('TIMEOUT')) {
      return ErrorType.timeout;
    }
    if (code.contains('VALIDATION') || code.contains('INVALID')) {
      return ErrorType.validation;
    }
    return ErrorType.unknown;
  }

  Color _getBackgroundColor(ErrorType type) {
    switch (type) {
      case ErrorType.authentication:
      case ErrorType.validation:
        return AppColors.error.withOpacity(0.1);
      case ErrorType.network:
      case ErrorType.timeout:
        return AppColors.warning.withOpacity(0.1);
      case ErrorType.permission:
        return AppColors.error.withOpacity(0.15);
      default:
        return AppColors.error.withOpacity(0.1);
    }
  }

  Color _getBorderColor(ErrorType type) {
    switch (type) {
      case ErrorType.authentication:
      case ErrorType.validation:
        return AppColors.error.withOpacity(0.3);
      case ErrorType.network:
      case ErrorType.timeout:
        return AppColors.warning.withOpacity(0.3);
      default:
        return AppColors.error.withOpacity(0.3);
    }
  }

  IconData _getIcon(ErrorType type) {
    switch (type) {
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_amber_outlined;
      case ErrorType.network:
      case ErrorType.timeout:
        return Icons.wifi_off_outlined;
      case ErrorType.permission:
        return Icons.block;
      default:
        return Icons.error_outline;
    }
  }

  Color _getIconColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }
}

class ErrorInfo {
  final String message;
  final String? code;
  final ErrorType type;

  ErrorInfo({
    required this.message,
    this.code,
    required this.type,
  });
}

enum ErrorType {
  authentication,
  validation,
  permission,
  network,
  timeout,
  unknown,
}
```

### Sử dụng trong LoginScreen:

```dart
// File: lib/modules/auth/login/login_screen.dart

// Thay thế error message container hiện tại
if (provider.errorMessage != null) ...[
  const SizedBox(height: 16),
  
  // ✅ Dùng ErrorMessageWidget thay vì Container thô
  ErrorMessageWidget(
    error: provider.errorObject ?? provider.errorMessage!,
    onRetry: () {
      // Clear error và cho phép user thử lại
      provider.clearError();
    },
    showIcon: true,
    showCode: false,  // Chỉ show code khi debug
  ),
],
```

### Cập nhật LoginProvider để lưu error object:

```dart
// File: lib/modules/auth/login/login_provider.dart

class LoginProvider extends ChangeNotifier {
  String? _errorMessage;
  Object? _errorObject;  // ← Thêm field này
  
  String? get errorMessage => _errorMessage;
  Object? get errorObject => _errorObject;
  
  Future<void> login() async {
    try {
      await _appProvider.login(request, rememberMe: _isRememberMe);
    } catch (e) {
      _errorObject = e;  // ← Lưu error object
      
      // Extract message
      if (e is DioFailure) {
        _errorMessage = e.message ?? 'Đã xảy ra lỗi';
      } else {
        _errorMessage = e.toString();
      }
      
      notifyListeners();
    }
  }
  
  void clearError() {
    _errorMessage = null;
    _errorObject = null;
    notifyListeners();
  }
}
```

---

## 📊 SO SÁNH CÁC CÁCH

| Khía cạnh | Cách 1: Server Message | Cách 2: Error Mapper | Cách 3: Custom Widget |
|-----------|----------------------|---------------------|----------------------|
| **Đơn giản** | ⭐⭐⭐ | ⭐⭐ | ⭐ |
| **Control** | ⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **UX** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Maintain** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Flexible** | ⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Khuyến nghị** | Prototype | ⭐⭐⭐ Production | ⭐⭐⭐ Best UX |

---

## 🎯 KHUYẾN NGHỊ: KẾT HỢP CẢ 3 CÁCH

### Setup tối ưu:

```
1. ErrorMessageMapper (Cách 2)
   → Map error code → message tiếng Việt
   → Control message format
   → Fallback to server message

2. ErrorMessageWidget (Cách 3)
   → Beautiful UI
   → Icon theo loại error
   → Retry button
   → Consistent design

3. Fallback to Server Message (Cách 1)
   → Nếu không có mapping, dùng server message
   → Đảm bảo luôn có message hiển thị
```

---

## 📝 IMPLEMENTATION STEPS

### Step 1: Tạo ErrorMessageMapper

- [ ] Tạo file `error_message_mapper.dart`
- [ ] Thêm danh sách error codes
- [ ] Implement `getMessage()` method
- [ ] Export trong `core.dart`

### Step 2: Update DioFailure

- [ ] Import ErrorMessageMapper
- [ ] Sửa logic parse error
- [ ] Dùng `ErrorMessageMapper.getMessage()`

### Step 3: Tạo ErrorMessageWidget

- [ ] Tạo file `error_message_widget.dart`
- [ ] Implement UI với icon, color
- [ ] Parse error type
- [ ] Add retry functionality

### Step 4: Update Providers

- [ ] Thêm `errorObject` field
- [ ] Update catch block
- [ ] Add `clearError()` method

### Step 5: Update UI

- [ ] Replace error Container với ErrorMessageWidget
- [ ] Test với các loại error
- [ ] Adjust styling

---

## 🧪 TESTING

### Test Cases:

```dart
// 1. Login sai password
Error: MSG_USER_PASSWORD_OR_USERNAME_WRONG
→ UI hiển thị: "Email hoặc mật khẩu không đúng. Vui lòng thử lại."
→ Icon: lock_outline
→ Color: error red

// 2. Không có internet
Error: No connection
→ UI hiển thị: "Không có kết nối internet. Vui lòng kiểm tra lại."
→ Icon: wifi_off_outlined
→ Color: warning orange

// 3. Token expired
Error: MSG_TOKEN_EXPIRED
→ UI hiển thị: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
→ Auto navigate to login

// 4. Unknown error
Error: Unknown
→ UI hiển thị: Message từ server (fallback)
→ Icon: error_outline
→ Show error code
```

---

## ✅ CHECKLIST

- [ ] ErrorMessageMapper created
- [ ] 20+ error codes mapped
- [ ] DioFailure updated
- [ ] ErrorMessageWidget created
- [ ] Provider updated với errorObject
- [ ] UI updated với ErrorMessageWidget
- [ ] Tested login error
- [ ] Tested network error
- [ ] Tested unknown error
- [ ] Documented

---

## 📄 FILES CẦN TẠO/SỬA

### Tạo mới:
1. `lib/core/exception/error_message_mapper.dart`
2. `lib/core/widgets/error_message_widget.dart`

### Sửa:
1. `lib/core/exception/dio_failure.dart` - Dùng ErrorMessageMapper
2. `lib/modules/auth/login/login_provider.dart` - Thêm errorObject
3. `lib/modules/auth/login/login_screen.dart` - Dùng ErrorMessageWidget
4. `lib/core/core.dart` - Export mapper và widget

---

## 🎨 UI EXAMPLES

### Login Error:
```
┌─────────────────────────────────────┐
│ 🔒 Email hoặc mật khẩu không đúng.  │
│     Vui lòng thử lại.               │
│                        [Thử lại]    │
└─────────────────────────────────────┘
```

### Network Error:
```
┌─────────────────────────────────────┐
│ 📶 Không có kết nối internet.       │
│     Vui lòng kiểm tra lại.          │
│                        [Thử lại]    │
└─────────────────────────────────────┘
```

### Permission Error:
```
┌─────────────────────────────────────┐
│ 🚫 Bạn không có quyền thực hiện     │
│     thao tác này.                    │
└─────────────────────────────────────┘
```

---

✅ **Hướng dẫn hoàn chỉnh! Kết hợp cả 3 cách để có trải nghiệm tốt nhất.**

