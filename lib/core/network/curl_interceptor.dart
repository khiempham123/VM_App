import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CurlInterceptor extends Interceptor {
  final bool? printOnSuccess;
  final bool convertFormData;

  CurlInterceptor({this.printOnSuccess, this.convertFormData = true});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _renderCurlRepresentation(err.requestOptions);
    return handler.next(err); //continue
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (printOnSuccess != null && printOnSuccess == true) {
      _renderCurlRepresentation(response.requestOptions);
    }
    final data = response.data;
    if(data is Map<String, dynamic>) {
      final code = data['code'] as String? ?? '';
      final message = data['message'] as String? ?? '';
      final realData = data['data'];
      //ToDo: try refactor AuthDto because the format data respone is difference.
      // My format like { "code": "", "message": "", "userId": ""}
      // But the format from api like { "code": "", "message": "", "data": {"userId": ""}}

      // Check if code exists and is NOT a success code
      if(code != '' && code.toUpperCase() != 'OK') {
        debugPrint('Message from api: $message');
        debugPrint('Code from api: $code');
        final error = DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: message,
          message: message,
        );
        handler.reject(error);
        return;
      }

      // If code is OK or empty, check if there's a 'data' field to unwrap
      if(realData != null && code != '' && code.toUpperCase() == 'OK') {
        // Unwrap the data field for OK responses that have nested data
        response.data = realData;
        debugPrint('Exactly data - unwrapped from OK response');
      } else if(code == '' && realData != null) {
        // Original behavior for responses without code field
        response.data = realData;
        debugPrint('Exactly data');
      } else {
        // Keep response as-is for OK responses without nested data (like Vietmap Route API)
        debugPrint('Response with code: $code - keeping original structure');
      }

    }
    return handler.next(response); //continue
  }

  void _renderCurlRepresentation(RequestOptions requestOptions) {
    // add a breakpoint here so all errors can break
    try {
      log("⚠️ CURL:");
      log(_cURLRepresentation(requestOptions));
    } catch (err) {
      log('unable to create a CURL representation of the requestOptions');
    }
  }

  String _cURLRepresentation(RequestOptions options) {
    List<String> components = ['curl -i'];
    components.add('-X ${options.method}');

    options.headers.forEach((k, v) {
      if (k != 'Cookie') {
        components.add('-H "$k: $v"');
      }
    });

    if (options.data != null) {
      // FormData can't be JSON-serialized, so keep only their fields attributes
      if (options.data is FormData && convertFormData == true) {
        options.data = Map.fromEntries((options.data as FormData).fields);
      }

      final data = json.encode(options.data).replaceAll('"', '\\"');
      components.add('-d "$data"');
    }

    components.add('"${options.uri.toString()}"');

    return components.join(' \\\n\t');
  }
}
