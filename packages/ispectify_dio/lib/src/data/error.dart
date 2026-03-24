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
        // --- Error summary: what went wrong ---
        'type': exception?.type,
        'message': redactor != null
            ? redactor.redact(
                exception?.message,
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              )
            : exception?.message,
        'error': redactor != null
            ? redactor.redact(
                exception?.error?.toString(),
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              )
            : exception?.error,
        'stack-trace': exception?.stackTrace,

        // --- Response (if any) ---
        'response': redactor == null
            ? responseData.toJson()
            : responseData.toJson(
                redactor: redactor,
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              ),

        // --- Original request (reference) ---
        'request': redactor == null
            ? requestData.toJson()
            : requestData.toJson(
                redactor: redactor,
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              ),
      };
}
