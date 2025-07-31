import 'package:ispectify/ispectify.dart';

class WSRequestLog extends ISpectifyData {
  WSRequestLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.body,
  }) : super(
          title: getKey,
          key: getKey,
          pen: (AnsiPen()..xterm(207)),
          additionalData: {
            'method': method,
            'url': url,
            'path': path,
            'body': body,
          },
        );

  final String method;
  final String url;
  final String path;
  final Object? body;

  static const getKey = 'ws-request';

  @override
  String get textMessage {
    final buffer = StringBuffer()
      ..writeln('URL: $url')
      ..writeln('Data: $message');

    return buffer.toString().truncate()!;
  }
}
