import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  final AppProvider _appProvider;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProfileProvider(this._appProvider);

  // Lấy thông tin user từ AppProvider
  UserEntity? get currentUser => _appProvider.authInfo.value?.user;

  Future<void> logout() async {
    debugPrint('🚪 [PROFILE_PROVIDER] Bắt đầu logout...');
    _isLoading = true;
    notifyListeners();

    try {
      await _appProvider.logout();
      debugPrint('✅ [PROFILE_PROVIDER] Logout thành công');
    } catch (e) {
      debugPrint('❌ [PROFILE_PROVIDER] Logout thất bại: $e');
      // Có thể show error dialog
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}