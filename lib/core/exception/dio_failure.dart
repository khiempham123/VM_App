import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:vm_first_app/core/core.dart';

class DioFailure extends Failure implements DioException {
  final DioException actualException;
  DioFailure._({
    required super.code,
    required super.error,
    required this.actualException,
    super.message,
    super.info,
  });

  factory DioFailure(DioException dioException) {
    final info = {
      'requestOptions': dioException.requestOptions,
      'response': dioException.response,
      'type': dioException.type,
      'error': dioException.error,
      'stackTrace': dioException.stackTrace,
    };

    if (dioException.response?.data == null) {
      return DioFailure._(
        code: ErrorCodes.notFound,
        error: ErrorCodes.notFound,
        actualException: dioException,
        info: info,
        message:
            (dioException.response?.data
                as Map<String, dynamic>?)?['message'] ??
            ErrorCodes.notFound,
      );
    }

    // is no connection?
    if (dioException.isNoConnection) {
      return DioFailure._(
        code: ErrorCodes.noConnection,
        error: ErrorCodes.noConnection,
        actualException: dioException,
        info: info,
        message: ErrorCodes.noConnection,
      );
    }

    if (dioException.isTimeout) {
      return DioFailure._(
        code: ErrorCodes.timeout,
        error: ErrorCodes.timeout,
        actualException: dioException,
        message: ErrorCodes.timeout,
        info: info,
      );
    }

    if (dioException.isServerError) {
      return DioFailure._(
        code: ErrorCodes.server,
        error: ErrorCodes.server,
        actualException: dioException,
        message: ErrorCodes.server,
        info: info,
      );
    }
    //ToDo: After refactor the AuthDTO must refactor the parse method to make it fit with the new format
    // PARSE BUSINESS ERROR từ ResponseValidatorInterceptor
    // Backend format: { "code": "MSG_ERROR_...", "message": "...", "data": null }
    final respData = dioException.response?.data;

    if (respData is Map<String, dynamic>) {
      final code = respData['code'] as String?;
      final message = respData['message'] as String?;

      // Check nếu là business error (code có giá trị)
      if (code != null && code.isNotEmpty) {
        // Map error code sang user-friendly message
        final userMessage = message;

        return DioFailure._(
          code: code,
          error: code,
          actualException: dioException,
          message: userMessage,
          info: info,
        );
      }
    }

    // parse api error from response (old format)
    if (respData case {
      'code': String code,
      'error': String error,
      'message': String message,
    }) {
      info['data'] = respData['data'];

      return DioFailure._(
        code: code,
        error: error,
        actualException: dioException,
        message: message,
        info: info,
      );
    } else if (respData case {'code': String code, 'message': List messages}) {
      return DioFailure._(
        code: code,
        error: 'err_$code',
        actualException: dioException,
        message: messages.join('\n'),
        info: info,
      );
    } else if (jsonDecode(respData) case {
      'code': String code,
      'error': String error,
      'message': String message,
    }) {
      final res = jsonDecode(respData);
      info['data'] = (res as Map<String, dynamic>)['data'];

      return DioFailure._(
        code: code,
        error: error,
        actualException: dioException,
        message: message,
        info: info,
      );
    }

    return DioFailure._(
      code: ErrorCodes.unknown,
      error: ErrorCodes.unknown,
      actualException: dioException,
      info: info,
    );
  }

  @override
  DioFailure copyWith({
    RequestOptions? requestOptions,
    Response? response,
    DioExceptionType? type,
    Object? error,
    StackTrace? stackTrace,
    String? message,
  }) {
    return DioFailure(
      actualException.copyWith(
        requestOptions: requestOptions,
        response: response,
        type: type,
        error: error,
        stackTrace: stackTrace,
        message: message,
      ),
    );
  }

  // @override
  // Object? get error => actualException.error;

  @override
  RequestOptions get requestOptions => actualException.requestOptions;

  @override
  Response? get response => actualException.response;

  @override
  StackTrace get stackTrace => actualException.stackTrace;

  @override
  DioExceptionType get type => actualException.type;

  @override
  DioExceptionReadableStringBuilder? stringBuilder;
}

extension DioExceptionEx on DioException {
  bool get isNoConnection =>
      type == DioExceptionType.connectionError ||
      error is SocketException ||
      error is HandshakeException;

  bool get isTimeout =>
      type == DioExceptionType.receiveTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.connectionTimeout;

  bool get isServerError =>
      type == DioExceptionType.unknown && response?.statusCode == 503;
}
