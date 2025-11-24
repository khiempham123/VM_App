import 'package:demo_login/data/dto/auth_dto.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_service.g.dart';

@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio, {String? baseUrl}) = _AuthService;

  @POST('/fw-api/login')
  Future<AuthResponseDto> login(@Body() LoginDto request);

  @POST('/fw-api/register')
  Future<AuthResponseDto> register(@Body() RegisterDto request);
}

