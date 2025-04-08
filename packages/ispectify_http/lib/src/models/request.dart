import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/settings.dart';

class HttpRequestLog extends ISpectifyData {
  HttpRequestLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.headers,
    required this.body,
    required this.settings,
  }) : super(
          title: getKey,
          key: getKey,
          pen: AnsiPen()..xterm(219),
          additionalData: {
            'method': method,
            'url': url,
            'path': path,
            'headers': headers,
            'body': body,
          },
        );

  final String method;
  final String url;
  final String path;
  final Map<String, String>? headers;
  final Object? body;
  final ISpectifyHttpLoggerSettings settings;

  static const getKey = 'http-request';

  @override
  String get textMessage {
    final buffer = StringBuffer('[$method] $message');

    if (settings.printRequestHeaders &&
        headers != null &&
        headers!.isNotEmpty) {
      final prettyHeaders = JsonTruncatorService.pretty(
        headers,
      );
      buffer.writeln('Headers: $prettyHeaders');
    }

    return buffer.toString().truncated!;
  }
}
