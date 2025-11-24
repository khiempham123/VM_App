import 'dart:convert';
import 'package:demo_login/core/network/http_client.dart';
import 'package:demo_login/data/dto/auth_dto.dart';
import 'package:demo_login/data/services/auth_service.dart';
import 'package:demo_login/domain/entities/auth_entity.dart';
import 'package:demo_login/domain/entities/auth_request.dart';
import 'package:demo_login/domain/repository/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FlutterSecureStorage storage;
  final AuthService authService;

  AuthRepositoryImpl(this.storage, this.authService);

  @override
  Future<void> setAuthInfo(AuthInfo? authInfo) {
    if (authInfo == null) {
      return storage.delete(key: kAuthInfoKey);
    }
    return storage.write(key: kAuthInfoKey, value: jsonEncode(authInfo.toJson()));
  }

  @override
  Future<AuthInfo?> getAuthInfo() {
    return storage.read(key: kAuthInfoKey).then((value) {
      if (value != null) {
        return AuthInfo.fromJson(jsonDecode(value));
      }
      return null;
    });
  }

  @override
  Future<AuthInfo> login(LoginRequest request) async {
    final dto = LoginDto(
      username: request.username,
      password: request.password,
    );
    final response = await authService.login(dto);
    return response.toEntity();
  }

  @override
  Future<AuthInfo> register(RegisterRequest request) async {
    final dto = RegisterDto(
      username: request.username,
      password: request.password,
      email: request.email,
      fullName: request.fullName,
      phone: request.phone,
    );
    final response = await authService.register(dto);
    return response.toEntity();
  }
}
