import 'package:vm_first_app/data/dto/auth_dto.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_service.g.dart';

@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio, {String? baseUrl}) = _AuthService;

  @POST('/fw-api/settings/login')
  Future<AuthResponseDto> login(@Body() LoginDto request);

  @POST('/fw-api/settings/register')
  Future<AuthResponseDto> register(@Body() RegisterDto request);

  @PUT('/fw-api/settings/password')
  Future<void> changePassword(@Body() ChangePasswordDto request);

  @POST('/fw-api/settings/logout')
  Future<void> logout();
}

