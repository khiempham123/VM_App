import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/domain.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginProvider extends ChangeNotifier {
  final AppProvider _appProvider;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isRememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isRememberMe => _isRememberMe;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;

  LoginProvider(this._appProvider) {
    _loadCachedEmail();
  }

  /// Load cached email từ SharedPreferences khi mở màn login
  /// Nếu user đã chọn Remember Me ở lần trước, email sẽ tự động điền vào TextField
  Future<void> _loadCachedEmail() async {
    try {
      final cachedEmail = await _appProvider.getCachedEmail();
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        emailController.text = cachedEmail;
        _isRememberMe = true; // Tự động check Remember Me nếu có cached email
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load cached email error: $e');
    }
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Toggle Remember Me checkbox
  /// - Nếu user CHECK: Email sẽ được lưu khi login thành công
  /// - Nếu user UNCHECK: Xóa cached email ngay lập tức
  void toggleRememberMe(bool? newState) {
    _isRememberMe = newState ?? false;

    // Nếu user bỏ chọn Remember Me, xóa cached email ngay
    if (!_isRememberMe) {
      _appProvider.clearCachedEmail();
    }

    notifyListeners();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await _appProvider.login(request);

      if (_isRememberMe) {
        await _appProvider.cachedEmail(emailController.text.trim());
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

