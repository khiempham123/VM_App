import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  final AppProvider _appProvider;

  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmNewPassword = TextEditingController();
  bool _isLoading = false;
  bool _obsurePassword = true;
  bool get isLoading => _isLoading;

  ProfileProvider(this._appProvider);

  // Lấy thông tin user từ AppProvider
  UserEntity? get currentUser => _appProvider.authInfo.value?.user;
  bool get obscurePassword => _obsurePassword;
  // Future<UserEntity> getProfile () async {
  //
  // }
  void togglePasswordVisibility() {
    _obsurePassword = !_obsurePassword;
    notifyListeners();
  }
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _appProvider.logout();
    } catch (e) {
      // Có thể show error dialog
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}