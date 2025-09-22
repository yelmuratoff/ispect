import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/src/settings.dart';

class WSErrorLog extends ISpectifyData {
  WSErrorLog(
    super.message, {
    required this.type,
    required this.url,
    required this.path,
    required this.body,
    super.exception,
    super.stackTrace,
    this.settings = const ISpectWSInterceptorSettings(),
  }) : super(
          title: getKey,
          key: getKey,
          logLevel: LogLevel.error,
          pen: (settings.errorPen ?? AnsiPen()
            ..red()),
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

  static const getKey = 'ws-error';

  @override
  String get textMessage {
    final buffer = StringBuffer()
      ..writeln('URL: $url')
      ..write('Data: $message');

    return buffer.toString().truncate()!;
  }
}
