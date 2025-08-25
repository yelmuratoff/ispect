import 'package:ispectify/ispectify.dart';

class WSReceivedLog extends ISpectifyData {
  WSReceivedLog(
    super.message, {
    required this.type,
    required this.url,
    required this.path,
    required this.body,
  }) : super(
          title: getKey,
          key: getKey,
          pen: (AnsiPen()..xterm(35)),
          additionalData: {
            'type': type,
            'url': url,
            'path': path,
            'body': body,
          },
        );

  final String type;
  final String url;
  final String path;
  final Object? body;

  static const getKey = 'ws-received';

  @override
  String get textMessage {
    final buffer = StringBuffer()
      ..writeln('URL: $url')
      ..write('Data: $message');

    return buffer.toString().truncate()!;
  }
}
