import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RegisterProvider extends ChangeNotifier {
  final AppProvider _appProvider;

  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  String? get errorMessage => _errorMessage;

  RegisterProvider(this._appProvider);

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  Future<void> register() async {
    debugPrint('📝 [REGISTER_PROVIDER] Bắt đầu validate form...');
    if (!formKey.currentState!.validate()) {
      debugPrint('❌ [REGISTER_PROVIDER] Form validation thất bại');
      return;
    }

    debugPrint('✅ [REGISTER_PROVIDER] Form validation thành công');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        password: passwordController.text,
        email: emailController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
      );

      debugPrint('📝 [REGISTER_PROVIDER] Gọi AppProvider.register() với email: ${request.email}');
      await _appProvider.register(request);

      debugPrint('✅ [REGISTER_PROVIDER] Đăng ký thành công!');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [REGISTER_PROVIDER] Đăng ký thất bại: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}

