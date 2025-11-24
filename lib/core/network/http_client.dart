import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:demo_login/core/core.dart';

final kAuthInfoKey = "${Flavor.current.toString()}auth_info";
const kBaseUrl = 'https://api.openweathermap.org/data/2.5';
const kBaseUrlDev = 'https://api.openweathermap.org/data/2.5';

String get baseUrlHandler => switch (Flavor.current) {
  Flavor.prod => kBaseUrl,
  Flavor.dev => kBaseUrlDev,
  _ => kBaseUrlDev,
};

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
    dio.options.headers['X-VSM-LANG'] = localeStr;
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
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
          'X-VSM-PLATFORM': platform,
          'X-VSM-LANG': localeStr,
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
