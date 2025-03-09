import 'package:ispectify/ispectify.dart';

class HttpRequestLog extends ISpectifyData {
  HttpRequestLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.headers,
    required this.body,
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
  final Map<String, dynamic> headers;
  final Object? body;

  static const getKey = 'http-request';

  @override
  String get textMessage {
    var msg = '[$method] $message';

    try {
      if (headers.isNotEmpty) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      return msg;
    }
    return msg;
  }
}
