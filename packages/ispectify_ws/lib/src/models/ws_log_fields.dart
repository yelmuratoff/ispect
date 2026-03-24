import 'package:ispectify_ws/src/settings.dart';

/// Shared fields and accessors for all WS log types
/// ([WSSentLog], [WSReceivedLog], [WSErrorLog]).
///
/// Avoids repeating the same `type`, `settings`, and `metrics` boilerplate
/// across every log subclass.
mixin WSLogFields {
  /// The WebSocket message type (e.g. `wsTypeRequest`, `wsTypeResponse`).
  String get type;

  /// The interceptor settings snapshot captured at log time.
  ISpectWSInterceptorSettings get wsSettings;

  /// Optional connection metrics, defensively copied.
  Map<String, dynamic>? get metrics;

  /// Builds the standard metadata map used by all WS log types.
  static Map<String, dynamic> buildMetadata({
    required String type,
    required String url,
    required String path,
    required Object? body,
    Map<String, dynamic>? metrics,
  }) =>
      {
        'type': type,
        'url': url,
        'path': path,
        'body': body,
        if (metrics != null) 'metrics': metrics,
      };
}
