import 'dart:async';

import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/data/data.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// Business logic quản lý phần login / logout,
/// Các tác vụ cần thực thi khi login / logout để ở class này
class AppProvider extends ChangeNotifier {
  static const kCheckSessionDuration = Duration(seconds: 3);
  late final _interceptor = locator<AuthRequestInterceptor>();
  late final _authRepo = locator<AuthRepository>();
  final KeyValueStorage _storage;

  final authInfo = BehaviorSubject<AuthInfo?>.seeded(null);
  final isLoggedIn = BehaviorSubject<bool>.seeded(false);
  final List<StreamSubscription> _subscriptions = [];

  AppProvider(this._storage) {
    _subscriptions.addAll([
      // khi có lỗi kErrorNotAuthorized force log out
      _interceptor.errorStream
          .where((event) => event.code == ErrorCodes.unauthorized)
          .listen(forceLogout),
    ]);
  }

  @override
  void dispose() async {
    super.dispose();
    for (var s in _subscriptions) {
      await s.cancel();
    }
    isLoggedIn.close();
    authInfo.close();
  }

  Future logout() async {
    try {
      await _authRepo.logout(); // call api logout
    } catch(e) {
      debugPrint('$e');
    }

    // Backup cached email trước khi clear
    final cachedEmail = await _storage.getString('email');

    isLoggedIn.add(false); // update stream -> rebuild rootpage
    authInfo.add(null); // noti UI now -> navigate to login
    await _authRepo.setAuthInfo(null); // delete token in local storage
    locator<HttpClient>().clearSession();

    // Clear all storage
    await _storage.clear();

    // Restore cached email sau khi clear (nếu có)
    // User vẫn thấy email gợi ý khi login lại
    if (cachedEmail != null && cachedEmail.isNotEmpty) {
      await _storage.setString('email', cachedEmail);
    }
  }

  Future<void> forceLogout(_) async {
    isLoggedIn.add(false);
    authInfo.add(null);
    await _authRepo.setAuthInfo(null);
    locator<HttpClient>().clearSession();
    _storage.clear();
  }

  Future<void> login(LoginRequest request) async {
    try {
      final authResponse = await _authRepo.login(request);

      await _authRepo.setAuthInfo(authResponse);
      // Update session in HttpClient
      locator<HttpClient>().setSession(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        expiresIn: authResponse.expiresIn,
      );

      authInfo.add(authResponse);
      isLoggedIn.add(true);
      notifyListeners();
    } catch (e) {
      // Re-throw để LoginProvider có thể handle
      rethrow;
    }
  }

  Future<void> cachedEmail(String email) async {
    await _storage.setString('email', email);
  }

  Future<String?> getCachedEmail() async {
    return await _storage.getString('email');
  }

  Future<void> clearCachedEmail() async {
    await _storage.removeKey('email');
  }

  Future<void> register(RegisterRequest request) async {
    try {
      final authResponse = await _authRepo.register(request);

      await _authRepo.setAuthInfo(authResponse);

      // Update session in HttpClient
      locator<HttpClient>().setSession(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        expiresIn: authResponse.expiresIn,
      );

      authInfo.add(authResponse);
      isLoggedIn.add(true);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      await _authRepo.changePassword(request);
      isLoggedIn.add(false);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  Future<void> restore() async {
    try {
      final savedAuthInfo = await _authRepo.getAuthInfo();

      if (savedAuthInfo != null) {
        debugPrint('session is setted');
        locator<HttpClient>().setSession(
          accessToken: savedAuthInfo.accessToken,
          refreshToken: savedAuthInfo.refreshToken,
          expiresIn: savedAuthInfo.expiresIn,
        );
        authInfo.add(savedAuthInfo);
        isLoggedIn.add(true);
      } else {
        isLoggedIn.add(false);
      }
      notifyListeners();
    } catch (e) {
      isLoggedIn.add(false);
      notifyListeners();
    }
  }

  Future<bool> get hasSession async {
    final savedAuthInfo = await _authRepo.getAuthInfo();
    return savedAuthInfo != null;
  }

  Future<void> updateSession() async {
    final savedAuthInfo = await _authRepo.getAuthInfo();
    if (savedAuthInfo != null) {
      authInfo.add(savedAuthInfo);
    }
  }


}
