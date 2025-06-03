import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/settings.dart';

class HttpResponseLog extends ISpectifyData {
  HttpResponseLog(
    super.message, {
    required this.responseData,
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.requestBody,
    required this.responseBody,
    required this.settings,
  }) : super(
          key: getKey,
          title: getKey,
          pen: AnsiPen()..xterm(46),
          additionalData: responseData?.toJson,
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, String>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? requestBody;
  final Object? responseBody;
  final ISpectifyHttpLoggerSettings settings;
  final HttpResponseData? responseData;

  static const getKey = 'http-response';

  @override
  String get textMessage {
    final buffer = StringBuffer('[$method] $message')
      ..write('\nStatus: $statusCode');

    if (settings.printResponseMessage && statusMessage != null) {
      buffer.write('\nMessage: $statusMessage');
    }

    if (settings.printResponseData && requestBody != null) {
      final prettyData = JsonTruncatorService.pretty(
        requestBody,
      );
      buffer.write('\nData: $prettyData');
    }

    if (settings.printResponseHeaders &&
        headers != null &&
        headers!.isNotEmpty) {
      final prettyHeaders = JsonTruncatorService.pretty(
        headers,
      );
      buffer.write('\nHeaders: $prettyHeaders');
    }

    return buffer.toString().truncated!;
  }
}
