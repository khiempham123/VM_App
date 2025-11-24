import 'package:demo_login/domain/entities/auth_entity.dart';

class LoginDto {
  final String username;
  final String password;

  LoginDto({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class RegisterDto {
  final String username;
  final String password;
  final String email;
  final String? fullName;
  final String? phone;

  RegisterDto({
    required this.username,
    required this.password,
    required this.email,
    this.fullName,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
    };
  }
}

class AuthResponseDto {
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final UserDto? user;
  final bool? success;
  final String? message;

  AuthResponseDto({
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.user,
    this.success,
    this.message,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
      user: json['user'] != null ? UserDto.fromJson(json['user'] as Map<String, dynamic>) : null,
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }
}

class UserDto {
  final String? id;
  final String? username;
  final String? email;
  final String? fullName;
  final String? phone;

  UserDto({
    this.id,
    this.username,
    this.email,
    this.fullName,
    this.phone,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

extension AuthResponseDtoX on AuthResponseDto {
  AuthInfo toEntity() {
    return AuthInfo(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
      expiresIn: expiresIn ?? 0,
      user: user?.toEntity() ?? UserEntity(id: '', username: '', email: ''),
    );
  }
}

extension UserDtoX on UserDto {
  UserEntity toEntity() {
    return UserEntity(
      id: id ?? '',
      username: username ?? '',
      email: email ?? '',
      fullName: fullName,
      phone: phone,
    );
  }
}

