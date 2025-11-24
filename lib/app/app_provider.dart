import 'dart:async';

import 'package:demo_login/core/core.dart';
import 'package:demo_login/data/data.dart';
import 'package:demo_login/domain/domain.dart';
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
    isLoggedIn.add(false);
    authInfo.add(null);
    await _authRepo.setAuthInfo(null);
    locator<HttpClient>().clearSession();
    await _storage.clear();
  }

  Future<void> forceLogout(_) async {
    isLoggedIn.add(false);
    authInfo.add(null);
    await _authRepo.setAuthInfo(null);
    locator<HttpClient>().clearSession();
    _storage.clear();
  }

  Future<void> login(LoginRequest request) async {
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
  }

  Future<void> register(RegisterRequest request) async {
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
  }

  Future<void> restore() async {
    final savedAuthInfo = await _authRepo.getAuthInfo();
    if (savedAuthInfo != null) {
      locator<HttpClient>().setSession(
        accessToken: savedAuthInfo.accessToken,
        refreshToken: savedAuthInfo.refreshToken,
        expiresIn: savedAuthInfo.expiresIn,
      );
      authInfo.add(savedAuthInfo);
      isLoggedIn.add(true);
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
