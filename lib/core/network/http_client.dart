import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:vm_first_app/core/core.dart';

final kAuthInfoKey = "auth_info";
final kRoutePlcaeKey = "route_place";
const kBaseUrl = 'https://dricon.fastmap.vn';

String get baseUrlHandler => kBaseUrl;

class HttpClient {
  final Dio dio;
  final VoidCallback onForceLogout;
  final FlutterSecureStorage storage;

  late final String baseUrl;
  late final AuthRequestInterceptor authRequestInterceptor;

  HttpClient({
    required this.dio,
    required this.onForceLogout,
    required this.storage,
    List<Interceptor>? interceptors,
  }) {
    baseUrl = baseUrlHandler;
    initInterceptors(interceptors);
  }

  Future initAuthRequest() async {
    // return authRequestInterceptor.initAccessToken();
  }

  void initInterceptors(List<Interceptor>? interceptors) {
    authRequestInterceptor = AuthRequestInterceptor(
      httpClient: this,
      storage: storage,
    );
    dio.interceptors.addAll([
      if (interceptors != null) ...interceptors,
      authRequestInterceptor,
      if (!kReleaseMode) ...[
        CurlInterceptor(convertFormData: true, printOnSuccess: false),
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
        ),
      ],

      ErrorHandlerInterceptor(),
    ]);
  }

  void updateLocale(String localeStr) {
    dio.options.headers['X-VM-LANG'] = localeStr;
  }

  void setSession({String? accessToken, String? refreshToken, int? expiresIn}) {
    authRequestInterceptor.accessToken = accessToken;
    authRequestInterceptor.refreshToken = refreshToken;
    authRequestInterceptor.expiresIn = expiresIn;
    authRequestInterceptor.scheduleRefreshToken();
  }

  void clearSession() {
    authRequestInterceptor.accessToken = null;
    authRequestInterceptor.refreshToken = null;
    authRequestInterceptor.expiresIn = null;
  }

  static Dio createDio({required String localeStr}) {
    final platform = Platform.isAndroid ? "android" : "ios";
    final dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
          'X-VM-PLATFORM': platform,
          'X-VM-LANG': localeStr,
        },
      ),
    );

    return dio;
  }
}

extension HttpStringExt on String {
  Uint8List? base64Decode() {
    try {
      return base64.decode(this);
    } catch (_) {
      return null;
    }
  }
}

class FileDownloader {
  const FileDownloader();

  Future download(Uri uri, String path) {
    final dio = Dio();
    return dio.downloadUri(uri, path);
  }
}
