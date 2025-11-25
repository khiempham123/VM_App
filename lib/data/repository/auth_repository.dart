import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vm_first_app/core/network/http_client.dart';
import 'package:vm_first_app/data/dto/auth_dto.dart';
import 'package:vm_first_app/data/services/auth_service.dart';
import 'package:vm_first_app/domain/entities/auth_entity.dart';
import 'package:vm_first_app/domain/entities/auth_request.dart';
import 'package:vm_first_app/domain/repository/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vm_first_app/data/database/key_value_store.dart';
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
    // B1: Convert Domain Request → DTO (Data Transfer Object)
    // LoginRequest (Domain) chứa data từ UI/UseCase
    // LoginDto (Data) match với API request body format
    final dto = LoginDto(
      email: request.email,
      password: request.password,
    );

    // B2: Gọi API qua Service
    // authService.login() → POST /fw-api/settings/login
    // Retrofit auto-parse JSON response → AuthResponseDto
    // AuthResponseDto chứa: accessToken, refreshToken, expiresIn, UserDto
    final response = await authService.login(dto);
    //keyValueStore.write(key: kAuthInfoKey, value: jsonEncode())
    // B3: Convert DTO → Entity
    // response.toEntity() gọi extension method AuthResponseDtoX
    // Convert: AuthResponseDto → AuthInfo (Domain Entity)
    // Bên trong sẽ convert: UserDto → UserEntity
    // Return AuthInfo chứa thông tin auth + user để dùng trong Domain/Presentation
    return response.toEntity();
  }

  @override
  Future<AuthInfo> register(RegisterRequest request) async {
    // B1: Convert Domain Request → DTO
    // RegisterRequest có nhiều fields hơn LoginRequest
    // DTO mapping với API body format
    final dto = RegisterDto(
      firstName: request.firstName,
      lastName: request.lastName,
      password: request.password,
      email: request.email,
      phone: request.phone,
    );

    // B2: Call API
    // POST /fw-api/settings/register
    // Response tương tự login: AuthResponseDto (accessToken + UserDto)
    final response = await authService.register(dto);

    // B3: Convert DTO → Entity
    // Giống login: AuthResponseDto → AuthInfo (chứa UserEntity)
    return response.toEntity();
  }

  @override
  Future<void> logout() async {
    await authService.logout();
    await storage.delete(key: kAuthInfoKey);
  }


}
