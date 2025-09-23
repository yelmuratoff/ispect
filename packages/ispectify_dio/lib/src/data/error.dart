import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
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

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      {
        'type': exception?.type,
        'error': exception?.error,
        'stack-trace': exception?.stackTrace,
        'message': exception?.message,
        'request-options': redactor == null
            ? requestData.toJson()
            : requestData.toJson(
                redactor: redactor,
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              ),
        'response': redactor == null
            ? responseData.toJson()
            : responseData.toJson(
                redactor: redactor,
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              ),
      };
}
