class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String password;
  final String email;
  final String? phone;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.email,
    this.phone,
  });
}

