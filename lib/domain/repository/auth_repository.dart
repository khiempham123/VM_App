import 'package:demo_login/domain/entities/auth_entity.dart';
import 'package:demo_login/domain/entities/auth_request.dart';

abstract class AuthRepository {
  Future<void> setAuthInfo(AuthInfo? authInfo);
  Future<AuthInfo?> getAuthInfo();
  Future<AuthInfo> login(LoginRequest request);
  Future<AuthInfo> register(RegisterRequest request);
}
