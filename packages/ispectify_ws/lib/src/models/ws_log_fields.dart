import 'package:ispectify_ws/src/settings.dart';

/// Shared fields and accessors for all WS log types
/// ([WSSentLog], [WSReceivedLog], [WSErrorLog]).
///
/// Stores the interceptor settings snapshot and optional connection metrics,
/// avoiding repetition across every log subclass.
mixin WSLogFields {
  /// The WebSocket message type (e.g. `wsTypeRequest`, `wsTypeResponse`).
  String get type;

  /// Backing field for [wsSettings]. Set by concrete constructors via
  /// [initWSLogFields].
  late final ISpectWSInterceptorSettings _wsSettings;

  /// Backing field for [metrics].
  late final Map<String, dynamic>? _wsMetrics;

  /// Initializes the shared WS log fields.
  ///
  /// Must be called from the concrete class constructor's initializer list
  /// or body.
  void initWSLogFields({
    required ISpectWSInterceptorSettings settings,
    Map<String, dynamic>? metrics,
  }) {
    _wsSettings = settings;
    _wsMetrics = metrics;
  }

  /// The interceptor settings snapshot captured at log time.
  ISpectWSInterceptorSettings get wsSettings => _wsSettings;

  /// Optional connection metrics, defensively copied.
  Map<String, dynamic>? get metrics =>
      _wsMetrics == null ? null : Map<String, dynamic>.from(_wsMetrics);

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
