/// Global kill-switch for all ISpect redaction — the single source of truth.
///
/// Every redaction path routes through this gate: network interceptors
/// (Dio/HTTP/WS), database tracing, BLoC/Riverpod observers, the trace
/// pipeline, navigation route arguments, and every export path (JSON, text,
/// Markdown, file share, clipboard, cURL).
///
/// Setting [enabled] to `false` disables redaction everywhere at once,
/// overriding the per-interceptor `enableRedaction` flags. Restoring it to
/// `true` re-applies each path's own flag (all of which default to redacting).
///
/// Defaults to `true`. Because captured diagnostics can contain sensitive data,
/// disabling redaction is a deliberate opt-out — leave it on unless a build
/// genuinely needs raw payloads.
///
/// ```dart
/// // Pure Dart, or any ispectify_* adapter used standalone:
/// ISpectRedaction.enabled = false;
///
/// // Flutter apps can use the ISpect.run convenience, which sets this gate:
/// ISpect.run(() => runApp(MyApp()), redactionEnabled: false);
/// ```
abstract final class ISpectRedaction {
  /// Whether redaction is active across all ISpect diagnostics.
  ///
  /// `true` by default. When `false`, [RedactionService] instance and static
  /// methods pass data through unchanged and the navigation observer logs full
  /// route arguments.
  static bool enabled = true;
}
