import 'package:dio/dio.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioErrorData {
  DioErrorData({
    required this.exception,
    required this.requestData,
    required this.responseData,
  });

  final DioException? exception;
  final DioRequestData requestData;
  final DioResponseData responseData;

  Map<String, dynamic> get toJson => {
        'type': exception?.type,
        'error': exception?.error,
        'stack-trace': exception?.stackTrace,
        'message': exception?.message,
        'request-options': requestData.toJson,
        'response': responseData.toJson,
      };
}
