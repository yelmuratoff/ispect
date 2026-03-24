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
    super.requestId,
    super.requestHeaders,
    Map<String, String>? headers,
    super.body,
    RedactionService? redactor,
  })  : _errorData = errorData,
        super(
          statusMessage: statusMessage ??
              _redactExceptionMessage(
                errorData.exception?.message,
                redactor: redactor,
              ),
          settings: settings,
          headers: headers?.map(MapEntry.new),
          capturedException: errorData.exception,
          capturedStackTrace: errorData.exception?.stackTrace,
          metadata: errorData.toJson(
            redactor: redactor,
          ),
        );

  /// Redacts URLs embedded in the DioException message when a redactor is
  /// provided. This prevents sensitive query parameters and userInfo from
  /// leaking through the fallback status message.
  static String? _redactExceptionMessage(
    String? message, {
    RedactionService? redactor,
  }) {
    if (message == null || redactor == null) return message;
    return redactor.redactUrlsInText(message);
  }

  final DioErrorData _errorData;

  DioErrorData get errorData => _errorData;
}
