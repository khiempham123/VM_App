import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:vm_first_app/core/core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


const String kBaseMapUrl="https://maps.vietmap.vn/";
String get baseMapUrlHandler => kBaseMapUrl;
final String kVietmapApiKey = '${dotenv.env['VM_API_KEY']}';

class MapClient {
  final Dio dio;
  final FlutterSecureStorage storage;

  late final String baseUrl;
  late final MapRequestInterceptor mapRequestInterceptor;

  MapClient({
    required this.dio,
    required this.storage,
    List<Interceptor>? interceptors,
  }) {
    baseUrl = baseMapUrlHandler;
    initInterceptors(interceptors);
  }

  void initInterceptors(List<Interceptor>? interceptors) {
    mapRequestInterceptor = MapRequestInterceptor(
      mapClient: this,
      storage: storage,
    );
    dio.interceptors.addAll([
      if (interceptors != null) ...interceptors,
      mapRequestInterceptor,
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

  static Dio createDio() {
    return Dio(
      BaseOptions(
        baseUrl: kBaseMapUrl,
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
      ),
    );
  }
}



