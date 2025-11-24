class ValidationHelper {
  ValidationHelper._();

  /// Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number (basic validation)
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Validate password strength
  static bool isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  /// Check if string is empty or null
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Validate minimum length
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  /// Validate maximum length
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }
}

