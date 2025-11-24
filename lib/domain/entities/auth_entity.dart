class AuthInfo {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserEntity user;

  AuthInfo({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthInfo.fromJson(Map<String, dynamic> json) {
    return AuthInfo(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: UserEntity.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'user': user.toJson(),
    };
  }
}

class UserEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    };
  }
}

