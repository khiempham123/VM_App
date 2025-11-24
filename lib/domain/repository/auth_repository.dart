import 'package:vm_first_app/domain/entities/auth_entity.dart';
import 'package:vm_first_app/domain/entities/auth_request.dart';

abstract class AuthRepository {
  Future<void> setAuthInfo(AuthInfo? authInfo);
  Future<AuthInfo?> getAuthInfo();
  Future<AuthInfo> login(LoginRequest request);
  Future<AuthInfo> register(RegisterRequest request);
  Future<void> logout();
}
