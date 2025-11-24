import 'dart:convert';
import 'package:vm_first_app/core/network/http_client.dart';
import 'package:vm_first_app/data/dto/auth_dto.dart';
import 'package:vm_first_app/data/services/auth_service.dart';
import 'package:vm_first_app/domain/entities/auth_entity.dart';
import 'package:vm_first_app/domain/entities/auth_request.dart';
import 'package:vm_first_app/domain/repository/auth_repository.dart';
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
      email: request.email,
      password: request.password,
    );
    final response = await authService.login(dto);
    return response.toEntity();
  }

  @override
  Future<AuthInfo> register(RegisterRequest request) async {
    final dto = RegisterDto(
      firstName: request.firstName,
      lastName: request.lastName,
      password: request.password,
      email: request.email,
      phone: request.phone,
    );
    final response = await authService.register(dto);
    return response.toEntity();
  }

  @override
  Future<void> logout() async {
    await authService.logout();
    await storage.delete(key: kAuthInfoKey);
  }
}
