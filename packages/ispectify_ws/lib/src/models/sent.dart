import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/src/models/ws_log_fields.dart';
import 'package:ispectify_ws/src/settings.dart';

class WSSentLog extends NetworkRequestLog with WSLogFields {
  WSSentLog(
    super.message, {
    required this.type,
    required String url,
    required String path,
    required Object? payload,
    required ISpectWSInterceptorSettings settings,
    Map<String, dynamic>? metrics,
  }) : super(
          method: type,
          url: url,
          path: path,
          settings: settings,
          body: payload,
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
        ) {
    initWSLogFields(settings: settings, metrics: metrics);
  }

  @override
  final String type;

  static const getKey = 'ws-sent';
}
