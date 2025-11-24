import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/domain.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginProvider extends ChangeNotifier {
  final AppProvider _appProvider;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;

  LoginProvider(this._appProvider);

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> login() async {
    debugPrint('🔑 [LOGIN_PROVIDER] Bắt đầu validate form...');
    if (!formKey.currentState!.validate()) {
      debugPrint('❌ [LOGIN_PROVIDER] Form validation thất bại');
      return;
    }

    debugPrint('✅ [LOGIN_PROVIDER] Form validation thành công');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      debugPrint('🔑 [LOGIN_PROVIDER] Gọi AppProvider.login() với email: ${request.email}');
      await _appProvider.login(request);

      debugPrint('✅ [LOGIN_PROVIDER] Đăng nhập thành công!');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [LOGIN_PROVIDER] Đăng nhập thất bại: $e');
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

