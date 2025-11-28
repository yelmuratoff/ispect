import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/src/settings.dart';

class WSErrorLog extends NetworkErrorLog {
  WSErrorLog(
    super.message, {
    required this.type,
    required String url,
    required String path,
    required Map<String, dynamic>? payload,
    required Object? exception,
    required StackTrace stackTrace,
    required ISpectWSInterceptorSettings settings,
    Map<String, dynamic>? metrics,
  })  : _settings = settings,
        _metrics = metrics,
        super(
          method: type,
          url: url,
          path: path,
          statusCode: null,
          statusMessage: settings.printErrorMessage ? type : null,
          settings: settings,
          requestHeaders: null,
          headers: null,
          body: payload,
          capturedException: exception,
          capturedStackTrace: stackTrace,
          logKey: getKey,
          metadata: {
            'type': type,
            'url': url,
            'path': path,
            'body': payload,
            if (metrics != null) 'metrics': metrics,
          },
        );

  final String type;
  final ISpectWSInterceptorSettings _settings;
  final Map<String, dynamic>? _metrics;

  static const getKey = 'ws-error';

  ISpectWSInterceptorSettings get wsSettings => _settings;

  Map<String, dynamic>? get metrics =>
      _metrics == null ? null : Map<String, dynamic>.from(_metrics);

  @override
  ISpectWSInterceptorSettings get settings => _settings;

  @override
  String get textMessage {
    final buffer = StringBuffer()
      ..writeln('URL: ${url ?? ''}')
      ..write('Data: ${message ?? ''}');

    return buffer.toString().truncate() ?? '';
  }
}
