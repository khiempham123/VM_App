import 'package:vm_first_app/domain/entities/auth_entity.dart';
import 'package:vm_first_app/domain/entities/auth_request.dart';

//abstract class de lam hop dong su dung cho data repository => co the implement logic trong repository cua data
//repository data se thong qua viec dang ky services de goi toi API voi cac tham so dau vao theo dung nhu hop dong ma repository cua domain cung cap
//exp: LoginRequest request => repository  trong data se dua cac thong tin trong LoginRequest vao dto va goi toi api thong qua services va tra ve Entity tuong ung

abstract class AuthRepository {
  Future<void> setAuthInfo(AuthInfo? authInfo);
  Future<AuthInfo?> getAuthInfo();
  Future<AuthInfo> login(LoginRequest request);
  Future<AuthInfo> register(RegisterRequest request);
  Future<void> changePassword(ChangePasswordRequest request);
  Future<void> logout();
}
