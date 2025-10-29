import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioErrorLog extends NetworkErrorLog {
  DioErrorLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required super.statusCode,
    required String? statusMessage,
    required ISpectDioInterceptorSettings settings,
    required DioErrorData errorData,
    super.requestHeaders,
    Map<String, String>? headers,
    super.body,
    RedactionService? redactor,
  })  : _settings = settings,
        _errorData = errorData,
        super(
          statusMessage: statusMessage ?? errorData.exception?.message,
          settings: settings,
          headers: headers?.map(MapEntry.new),
          capturedException: errorData.exception,
          capturedStackTrace: errorData.exception?.stackTrace,
          metadata: errorData.toJson(
            redactor: redactor,
          ),
        );

  final ISpectDioInterceptorSettings _settings;
  final DioErrorData _errorData;

  @override
  ISpectDioInterceptorSettings get settings => _settings;

  DioErrorData get errorData => _errorData;
}
