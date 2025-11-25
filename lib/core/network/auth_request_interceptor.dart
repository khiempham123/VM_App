import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:vm_first_app/core/core.dart';

class AuthRequestInterceptor extends Interceptor {
  String? accessToken;
  String? refreshToken;
  int? expiresIn;

  final HttpClient httpClient;
  final FlutterSecureStorage storage;

  AuthRequestInterceptor({required this.httpClient, required this.storage});

  final _controller = StreamController<Failure>.broadcast();
  Stream<Failure> get errorStream => _controller.stream;
  Completer<bool>? _refreshTokenCompleter;
  Timer? _refreshTokenTimer;

  /// Last time refresh token
  DateTime _lastRefreshTokenDate = DateTime.now();
  static const kMinRefreshTokenDuration = Duration(minutes: 10);

  // Future initAccessToken() async {
  //   final str = await storage.getString(kAuthInfoKey);
  //   if (str != null) {
  //     final session = SessionDto.fromJson(jsonDecode(str));
  //     accessToken = session.accessToken;
  //   }
  // }

  void dispose() {
    _controller.close();
    _refreshTokenCompleter?.complete(false);
    _refreshTokenCompleter = null;
    _refreshTokenTimer?.cancel();
    _refreshTokenTimer = null;
  }

  Map<String, String> get authHeader {
    return {'Authorization': 'Bearer $accessToken'};
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (accessToken?.isNotEmpty == true &&
        !options.headers.containsKey("Authorization")) {
      options.headers.addAll(authHeader);
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      _controller.add(
        const Failure(code: "401", error: ErrorCodes.unauthorized),
      );

      final str = await storage.read(key: kAuthInfoKey);
      if (str != null) {
        // final session = SessionDto.fromJson(jsonDecode(str));
        // refreshToken = session.refreshToken;
      }

      if (refreshToken?.isNotEmpty != true) {
        _forceLogout();
      } else {
        return handleInvalidAccessToken(err, handler);
      }
    }
    super.onError(err, handler);
  }

  void handleInvalidAccessToken(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final rf = await _refreshAccessToken(force: true);

      /// Refresh token
      if (!rf) {
        throw ErrorCodes.unauthorized;
      }

      /// Update session and request options
      final reqOpts = err.requestOptions;
      reqOpts.headers['Authorization'] = 'Bearer $accessToken';

      /// Retry request
      final resp = await httpClient.dio.fetch(reqOpts);
      handler.resolve(resp);
    } on DioException catch (dioException, st) {
      debugPrint("$dioException\n$st");
      handler.next(err);
    } catch (e, st) {
      debugPrint("$e\n$st");
      final f = Failure.wrap(e);

      /// Notify un-authorized if refresh token failed
      if (f.error == ErrorCodes.unauthorized) {
        _forceLogout();
      }
      handler.next(err);
    }
  }

  void _forceLogout() {
    httpClient.onForceLogout();
    httpClient.clearSession();
  }

  void scheduleRefreshToken() {
    _refreshTokenTimer?.cancel();
    _refreshTokenTimer = null;

    if ((expiresIn ?? 0) <= 10) {
      // cancel
      return;
    }

    _refreshTokenTimer = Timer(Duration(seconds: expiresIn! - 10), () async {
      _refreshTokenTimer?.cancel();
      _refreshTokenTimer = null;
      _refreshAccessToken();
    });
  }

  Future<bool> _refreshAccessToken({bool force = false}) async {
    if (_refreshTokenCompleter != null) {
      return _refreshTokenCompleter!.future;
    }

    if (refreshToken == null) {
      return false;
    }

    if (!force &&
        DateTime.now().difference(_lastRefreshTokenDate) <
            kMinRefreshTokenDuration) {
      return false;
    }

    Future<Map<String, dynamic>?> request() async {
      try {
        final baseUrl = baseUrlHandler;
        final Dio dio = Dio();
        final headers = httpClient.dio.options.headers;
        if (headers.containsKey('Authorization')) {
          headers.remove('Authorization');
        }
        dio.options.headers = headers;
        dio.interceptors.add(
          PrettyDioLogger(
            requestHeader: true,
            requestBody: true,
            responseHeader: false,
            responseBody: true,
          ),
        );
        //TODO: doi lai dung api refresh token
        final url = "$baseUrl/fw-api/settings/refresh-token";
        final request = <String, dynamic>{'refreshToken': refreshToken};
        final response = await dio.post(url, data: request);
        final responseJson = response.data;
        debugPrint(responseJson);
        _lastRefreshTokenDate = DateTime.now();
        // final newSession = tokenResponse.session;
        // if (newSession.refreshToken.isEmpty) {
        //   return newSession.copyWith(refreshToken: refreshToken);
        // }

        return responseJson;
      } catch (e, st) {
        debugPrint("$e\n$st");
        return null;
      }
    }

    _refreshTokenCompleter = Completer<bool>();
    request().then((value) {
      if (value != null) {
        accessToken = value['access_token'];
        refreshToken = value['refresh_token'] ?? value['refreshToken'];
        expiresIn = value['expires_in'];
        storage.write(key: kAuthInfoKey, value: jsonEncode(value));
      }

      _refreshTokenCompleter!.complete(value != null);
      _refreshTokenCompleter = null;
    });
    return _refreshTokenCompleter!.future;
  }
}
