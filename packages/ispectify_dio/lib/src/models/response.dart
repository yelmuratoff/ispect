import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioResponseLog extends ISpectifyData {
  DioResponseLog(
    super.message, {
    required this.responseData,
    required this.settings,
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.requestBody,
    required this.responseBody,
  }) : super(
          key: getKey,
          title: getKey,
          pen: settings.responsePen ?? (AnsiPen()..xterm(46)),
          additionalData: responseData.toJson,
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? requestBody;
  final Object? responseBody;
  final ISpectifyDioLoggerSettings settings;
  final DioResponseData responseData;

  static const getKey = 'http-response';

  @override
  String get textMessage {
    var msg = '[$method] $message';

    final responseMessage = statusMessage;
    final data = responseBody;
    final headers = this.headers ?? {};

    msg += '\nStatus: $statusCode';

    if (settings.printResponseMessage && responseMessage != null) {
      msg += '\nMessage: $responseMessage';
    }

    try {
      if (settings.printResponseData && data != null) {
        final prettyData = encoder.convert(data);
        msg += '\nData: $prettyData';
      }
      if (settings.printResponseHeaders && headers.isNotEmpty) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      return msg;
    }
    return msg;
  }
}
