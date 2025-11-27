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

/// DTO (Data Transfer Object) cho Auth API Response
///
/// **Mapping với Backend JSON:**
/// ```json
/// {
///   "accessToken": "eyJhbG...",
///   "refreshToken": "refresh...",
///   "expiresIn": 3600,
///   "user": {                    ← Nested object
///     "id": "user123",
///     "firstName": "Khiem",
///     "lastName": "Pham",
///     "email": "khiempg@vietmap.vn",
///     "phone": "0123456789"
///   },
///   "success": true,
///   "message": "Login successful"
/// }
/// ```
///
/// **Tại sao có UserDto?**
/// - Backend trả nested object "user" bên trong response
/// - UserDto parse nested object này
/// - Sau đó convert UserDto → UserEntity (Domain)
class AuthResponseDto {
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final UserDto? user;  // ← Nested object từ Backend
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

  /// Parse JSON từ Backend → DTO Object
  /// Retrofit tự động gọi method này khi nhận response
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      // Parse primitive fields
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,

      // Nếu json['user'] không null → gọi UserDto.fromJson()
      // Đây là cách Data Layer "biết" đâu là User info
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,

      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }
}

/// DTO cho User information từ Backend
/// **Được parse từ nested object trong AuthResponseDto:**
/// ```json
/// "user": {
///   "id": "user123",
///   "firstName": "Khiem",
///   "lastName": "Pham",
///   "email": "khiempg@vietmap.vn",
///   "phone": "0123456789"
/// }
/// ```
/// **Tách riêng UserDto**
/// - User info là nested object trong nhiều API response (login, register, getProfile)
/// - Reusable: Dùng chung cho nhiều endpoint
/// - Single Responsibility: Chỉ parse user data
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

  /// Parse JSON "user" object → UserDto
  /// Called by: AuthResponseDto.fromJson() khi parse nested "user"
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

/// Extension method: Convert AuthResponseDto (Data Layer) → AuthInfo (Domain Layer)
///
/// - DTO: can nullable fields
/// - Entity: Business logic structure, can be non-nullable
class ChangePasswordDto {
  final String oldPassword;
  final String newPassword;

  ChangePasswordDto({
    required this.oldPassword,
    required this.newPassword,
  });

  factory ChangePasswordDto.fromJson(Map<String, dynamic> json) {
    return ChangePasswordDto(
      oldPassword: json['oldPassword'] as String,
      newPassword: json['newPassword'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }
}

extension AuthResponseDtoX on AuthResponseDto {
  /// Convert DTO → Entity
  /// Called by: Repository sau khi nhận response từ API
  AuthInfo toEntity() {
    return AuthInfo(
      // Map primitive fields với default values
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
      expiresIn: expiresIn ?? 0,

      // Convert nested UserDto → UserEntity
      // Gọi user?.toEntity() (UserDtoX extension)
      // Data Layer hieu & convert User info
      user: user?.toEntity() ?? UserEntity(id: '', firstName: '', lastName: '', email: ''),
    );
  }
}

/// Extension method: Convert UserDto (Data Layer) → UserEntity (Domain Layer)
///
/// **Tại sao tách riêng?**
/// - UserDto có thể được dùng ở nhiều DTO khác (ProfileResponseDto, etc.)
/// - Reusable conversion logic
/// - Single Responsibility
extension UserDtoX on UserDto {
  /// Convert UserDto → UserEntity
  /// Called by: AuthResponseDto.toEntity() hoặc các DTO khác
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

