import 'package:dio/dio.dart';

import 'package:demo_login/core/exception/dio_failure.dart';

///
/// Chuyển tất cả các DioException thành DioFailure để có thể dễ dàng xử lý trên UI
class ErrorHandlerInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final newError = DioFailure(err);
    super.onError(newError, handler);
  }
}
