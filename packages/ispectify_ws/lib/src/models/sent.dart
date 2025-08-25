import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/src/settings.dart';

class WSSentLog extends ISpectifyData {
  WSSentLog(
    super.message, {
    required this.type,
    required this.url,
    required this.path,
    required this.body,
    this.settings = const ISpectWSInterceptorSettings(),
  }) : super(
          title: getKey,
          key: getKey,
          pen: (settings.sentPen ?? AnsiPen()
            ..xterm(207)),
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
  final ISpectWSInterceptorSettings settings;

  static const getKey = 'ws-sent';

  @override
  String get textMessage {
    final buffer = StringBuffer()
      ..writeln('URL: $url')
      ..write('Data: $message');

    return buffer.toString().truncate()!;
  }
}
