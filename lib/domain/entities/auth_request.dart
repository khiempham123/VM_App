class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });
}

class RegisterRequest {
  final String username;
  final String password;
  final String email;
  final String? fullName;
  final String? phone;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.email,
    this.fullName,
    this.phone,
  });
}

