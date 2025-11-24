import 'package:vm_first_app/domain/entities/auth_entity.dart';

class LoginDto {
  final String email;
  final String password;

  LoginDto({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterDto {
  final String firstName;
  final String lastName;
  final String password;
  final String email;
  final String? phone;

  RegisterDto({
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.email,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
      'email': email,
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
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;

  UserDto({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
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
      user: user?.toEntity() ?? UserEntity(id: '', firstName: '', lastName: '', email: ''),
    );
  }
}

extension UserDtoX on UserDto {
  UserEntity toEntity() {
    return UserEntity(
      id: id ?? '',
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      email: email ?? '',
      phone: phone,
    );
  }
}

