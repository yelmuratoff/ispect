import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;

/// Mixin providing common functionality for network interceptors.
///
/// Implementing classes must provide [logger], [enableRedaction], and [redactor].
mixin BaseNetworkInterceptor {
  /// Shared trace config that disables Layer 2 (trace pipeline) redaction.
  ///
  /// Used when the interceptor's [enableRedaction] flag is `false` so that
  /// metadata stored in the trace is not additionally redacted by the pipeline.
  static const noRedactConfig = ISpectTraceConfig(redact: false);

  /// Normalises a raw map value to `Map<String, dynamic>`, or returns `null`.
  ///
  /// Accepts both `Map<String, dynamic>` and wider `Map` types (e.g. from Dio
  /// response headers). Returns `null` when [value] is not a map at all.
  static Map<String, dynamic>? asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  /// The logger instance for network logging.
  ///
  /// Implementing classes must override this to return their logger.
  ISpectLogger get logger;

  /// Whether redaction is enabled for this interceptor.
  ///
  /// Implementations should return their specific settings' redaction flag.
  bool get enableRedaction;

  /// The redaction service for this interceptor.
  ///
  /// Implementing classes must override this to return their redactor instance.
  RedactionService get redactor;

  late final NetworkPayloadSanitizer _payloadSanitizer =
      NetworkPayloadSanitizer(redactor);

  NetworkPayloadSanitizer get _payload => _payloadSanitizer;

  /// Redacts query parameter values and userInfo credentials in a URL.
  ///
  /// Returns the original URL string if redaction is disabled or
  /// the URL has nothing to redact. Delegates to [RedactionService.redactUrl].
  String redactUrl(String url, {required bool useRedaction}) {
    if (!useRedaction) return url;
    return redactor.redactUrl(url);
  }

  /// Redacts both URL and path from a [Uri] in one call.
  ///
  /// Returns a record with `url` (full URI string) and `path` (URI path only),
  /// both redacted if [useRedaction] is `true`.
  ({String url, String path}) redactUrlAndPath(
    Uri uri, {
    required bool useRedaction,
  }) =>
      (
        url: redactUrl(uri.toString(), useRedaction: useRedaction),
        path: redactUrl(uri.path, useRedaction: useRedaction),
      );

  /// Applies redaction with error handling: logs a warning and returns
  /// a placeholder on failure instead of propagating the exception.
  Object safeRedact(Object data, {required bool useRedaction}) {
    try {
      return _payload.body(data, enableRedaction: useRedaction) ?? data;
    } catch (e, s) {
      logger.logData(
        ISpectLogData(
          'Redaction failed, data omitted: $e',
          logLevel: LogLevel.warning,
          stackTrace: s,
        ),
      );
      return ph.redactionFailedPlaceholder;
    }
  }

  /// Returns `true` when the interceptor is [enabled] and the optional
  /// [filter] either is `null` or returns `true` for [value].
  ///
  /// Consolidates the `settings.enabled && (filter?.call(x) ?? true)` pattern
  /// used across all network interceptors.
  bool shouldProcess<T>({
    required bool enabled,
    required bool Function(T)? filter,
    required T value,
  }) =>
      enabled && (filter?.call(value) ?? true);

  // ---------------------------------------------------------------------------
  // Runtime reconfiguration (opt-in)
  // ---------------------------------------------------------------------------

  /// The current settings exposed for runtime reconfiguration.
  ///
  /// Returns `null` by default — override in interceptors that support
  /// [configure] (e.g. Dio, HTTP). WS and other read-only interceptors
  /// do not need to override this.
  BaseNetworkInterceptorSettings? get configurableSettings => null;

  /// Applies [updated] settings. Override alongside [configurableSettings].
  ///
  /// The default implementation is a no-op.
  // ignore: use_setters_to_change_properties
  void applyConfigurableSettings(BaseNetworkInterceptorSettings updated) {}

  /// Reconfigures logging options at runtime without replacing the interceptor.
  ///
  /// Only fields provided (non-null) are updated; omitted fields retain their
  /// current values. Has no effect when [configurableSettings] returns `null`.
  void configure({
    bool? printResponseData,
    bool? printResponseHeaders,
    bool? printResponseMessage,
    bool? printErrorData,
    bool? printErrorHeaders,
    bool? printErrorMessage,
    bool? printRequestData,
    bool? printRequestHeaders,
    bool? enableRedaction,
    AnsiPen? requestPen,
    AnsiPen? responsePen,
    AnsiPen? errorPen,
  }) {
    final current = configurableSettings;
    if (current == null) return;
    applyConfigurableSettings(
      current.copyWith(
        printResponseData: printResponseData,
        printResponseHeaders: printResponseHeaders,
        printResponseMessage: printResponseMessage,
        printErrorData: printErrorData,
        printErrorHeaders: printErrorHeaders,
        printErrorMessage: printErrorMessage,
        printRequestData: printRequestData,
        printRequestHeaders: printRequestHeaders,
        enableRedaction: enableRedaction,
        requestPen: requestPen,
        responsePen: responsePen,
        errorPen: errorPen,
      ),
    );
  }

  /// Processes and redacts a map, ensuring string keys.
  ///
  /// Applies redaction if enabled, then converts to Map<String, dynamic>.
  Map<String, dynamic> processMapData(
    Map<dynamic, dynamic> data, {
    required bool useRedaction,
  }) {
    try {
      final redacted =
          _payload.body(data, enableRedaction: useRedaction) ?? data;

      if (redacted is Map<String, dynamic>) return redacted;

      final mapToConvert = redacted is Map ? redacted : data;
      return mapToConvert.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {
      try {
        return _payload.stringKeyMap(data);
      } catch (_) {
        return <String, dynamic>{'raw': ph.conversionFailedPlaceholder};
      }
    }
  }
}
