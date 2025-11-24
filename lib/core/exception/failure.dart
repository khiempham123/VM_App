class Failure implements Exception {
  final String code;
  final String error;
  final String? message;
  final Map<String, dynamic>? info;

  const Failure({required this.code, this.error = '', this.message, this.info});

  factory Failure.wrap(Object object) {
    if (object is Failure) {
      return object;
    }

    return Failure(
      code: object.runtimeType.toString(),
      error: object.toString(),
      message: object.toString(),
    );
  }

  factory Failure.code(
    String code, {
    String? error,
    String? message,
    Map<String, dynamic>? info,
  }) {
    return Failure(
      code: code,
      error: error ?? '',
      message: message,
      info: info,
    );
  }

  @override
  String toString() {
    return '[$code] $message';
  }

  factory Failure.fromJson(Map<String, dynamic> json) {
    return Failure(
      code: json['code'],
      error: json['error'],
      message: json['message'],
      info: json['info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'error': error,
      if (message != null) 'message': message,
      if (info != null) 'info': info,
    };
  }
}

// class VException<T> implements Exception {
//   static const String kUnknownError = "unknown_error";
//   static const int kUnknownErrorCode = -1;
//   static const int kItemContFound = 404;
//   static const kErrorNoConnection = -1001;
//   static const kErrorTimeout = -1004;
//   static const kVinCodeInvalid = 'vincode_invalid';
//   static const kVinCodeExist = 'vincode_exist';
//   static const kUploadFileError = 'upload_file_error';
//   static const kCompressImageError = 'compress_image_error';

//   final int code;
//   final String message;
//   final T? data;
//   VException({this.code = -1, this.message = kUnknownError, this.data});

//   VException.code(int code, [String? message, T? data])
//     : this(code: code, message: message ?? kUnknownError, data: data);

//   VException.unknown([String? message, T? data])
//     : this(
//         code: kUnknownErrorCode,
//         message: message ?? kUnknownError,
//         data: data,
//       );

//   VException.noConnection()
//     : this(code: kErrorNoConnection, message: "no_connection");

//   VException.timeout()
//     : this(code: kErrorTimeout, message: "connection_timeout");

//   VException.message(String message)
//     : this(code: message.hashCode, message: message);

//   factory VException.wrap(dynamic error, [T? data]) {
//     if (error is VException) {
//       if (data != null) {
//         return VException.code(error.code, error.message, data);
//       }
//       return error as VException<T>;
//     }

//     if (_isFileNotFoundError(error)) {
//       FileSystemException err = error;
//       return VException(
//         code: kItemContFound,
//         message: err.osError?.message ?? kUnknownError,
//         data: data,
//       );
//     }

//     return VException<T>.unknown(error.toString(), data);
//   }

//   @override
//   String toString() {
//     return "[$code][$message]";
//   }

//   bool isError(int code) => this.code == code;
//   static bool isCode(error, int code) {
//     return error is VException && error.code == code;
//   }

//   static bool isCodes(error, List<int> codes) {
//     return error is VException && codes.contains(error.code);
//   }
// }

// bool _isFileNotFoundError(error) =>
//     error is FileSystemException && error.osError?.errorCode == 2;
