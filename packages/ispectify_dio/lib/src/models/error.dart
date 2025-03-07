import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioErrorLog extends ISpectifyData {
  DioErrorLog(
    super.message, {
    required this.method,
    required this.errorData,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.body,
    required this.settings,
  }) : super(
          key: getKey,
          title: getKey,
          pen: settings.errorPen ?? (AnsiPen()..red()),
          additionalData: errorData.toJson,
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? body;
  final ISpectifyDioLoggerSettings settings;
  final DioErrorData errorData;

  static const getKey = 'http-error';

  @override
  String get textMessage {
    var msg = '[$method] $message';

    final responseMessage = statusMessage;

    final data = body;
    final headers = this.headers ?? {};

    if (statusCode != null) {
      msg += '\nStatus: $statusCode';
    }

    if (settings.printErrorMessage && responseMessage != null) {
      msg += '\nMessage: $responseMessage';
    }

    if (settings.printErrorData && data != null) {
      msg += '\nData: $data';
    }
    if (settings.printErrorHeaders && (headers.isNotEmpty)) {
      msg += '\nHeaders: $headers';
    }
    return msg;
  }
}
