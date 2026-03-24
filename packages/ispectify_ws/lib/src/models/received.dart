import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/src/models/ws_log_fields.dart';
import 'package:ispectify_ws/src/settings.dart';

class WSReceivedLog extends NetworkResponseLog with WSLogFields {
  WSReceivedLog(
    super.message, {
    required this.type,
    required String url,
    required String path,
    required Object? payload,
    required ISpectWSInterceptorSettings settings,
    Map<String, dynamic>? metrics,
  })  : _settings = settings,
        _metrics = metrics,
        super(
          method: type,
          url: url,
          path: path,
          statusCode: null,
          statusMessage: settings.printReceivedMessage ? type : null,
          settings: settings,
          responseBody: payload,
          logKey: getKey,
          textMessage:
              'URL: $url\nData: ${message?.toString() ?? ''}'.truncate() ?? '',
          metadata: WSLogFields.buildMetadata(
            type: type,
            url: url,
            path: path,
            body: payload,
            metrics: metrics,
          ),
        );

  @override
  final String type;
  final ISpectWSInterceptorSettings _settings;
  final Map<String, dynamic>? _metrics;

  static const getKey = 'ws-received';

  @override
  ISpectWSInterceptorSettings get wsSettings => _settings;

  @override
  Map<String, dynamic>? get metrics =>
      _metrics == null ? null : Map<String, dynamic>.from(_metrics);
}
