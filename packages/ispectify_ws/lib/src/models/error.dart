import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/src/models/ws_log_fields.dart';
import 'package:ispectify_ws/src/settings.dart';

class WSErrorLog extends NetworkErrorLog with WSLogFields {
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
  }) : super(
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

  static const getKey = 'ws-error';
}
