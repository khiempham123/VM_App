class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'VM First App';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = 'https://api.example.com';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Pagination
  static const int pageSize = 20;
}

