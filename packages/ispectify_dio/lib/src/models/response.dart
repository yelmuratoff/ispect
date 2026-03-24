import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioResponseLog extends NetworkResponseLog {
  DioResponseLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required super.statusCode,
    required super.statusMessage,
    required ISpectDioInterceptorSettings settings,
    required DioResponseData responseData,
    super.requestId,
    super.requestHeaders,
    super.headers,
    super.requestBody,
    super.responseBody,
    RedactionService? redactor,
  })  : _responseData = responseData,
        super(
          settings: settings,
          metadata: responseData.toJson(
            redactor: redactor,
          ),
        );

  final DioResponseData _responseData;

  DioResponseData get responseData => _responseData;
}
