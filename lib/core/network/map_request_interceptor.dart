import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vm_first_app/core/core.dart';

class MapRequestInterceptor extends Interceptor {
  final MapClient mapClient;
  final FlutterSecureStorage storage;

  MapRequestInterceptor({
    required this.mapClient,
    required this.storage,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters['apikey'] = kVietmapApiKey;
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);
  }
}
