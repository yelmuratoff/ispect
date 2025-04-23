import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/settings.dart';

class HttpErrorLog extends ISpectifyData {
  HttpErrorLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.body,
    required this.responseData,
    required this.settings,
  }) : super(
          key: getKey,
          pen: AnsiPen()..red(),
          additionalData: responseData?.toJson,
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, String>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? body;
  final HttpResponseData? responseData;
  final ISpectifyHttpLoggerSettings settings;

  static const getKey = 'http-error';

  @override
  String get textMessage {
    final buffer = StringBuffer('[$method] $message')
      ..writeln('\nStatus: $statusCode');

    if (settings.printErrorMessage && statusMessage != null) {
      buffer.writeln('Message: $statusMessage');
    }

    if (settings.printErrorData && body != null && body!.isNotEmpty) {
      final prettyBody = JsonTruncatorService.pretty(body);
      buffer.writeln('Data: $prettyBody');
    }

    if (settings.printErrorHeaders && headers != null && headers!.isNotEmpty) {
      final prettyHeaders = JsonTruncatorService.pretty(headers);
      buffer.writeln('\nHeaders: $prettyHeaders');
    }

    return buffer.toString().truncated!;
  }
}
