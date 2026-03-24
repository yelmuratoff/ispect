import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart'
    as ph;

/// Mixin providing common functionality for network interceptors.
///
/// Implementing classes must provide [logger] and [enableRedaction].
/// Optionally set [redactor] in the constructor for custom redaction behavior.
mixin BaseNetworkInterceptor {
  /// The logger instance for network logging.
  ///
  /// Implementing classes must override this to return their logger.
  ISpectLogger get logger;

  /// Whether redaction is enabled for this interceptor.
  ///
  /// Implementations should return their specific settings' redaction flag.
  bool get enableRedaction;

  RedactionService _redactor = RedactionService();
  late NetworkPayloadSanitizer _payloadSanitizer =
      NetworkPayloadSanitizer(_redactor);

  /// Gets the current redaction service.
  RedactionService get redactor => _redactor;

  /// Updates the redaction service instance.
  ///
  /// Allows runtime reconfiguration of redaction behavior without
  /// recreating the interceptor.
  set redactor(RedactionService newRedactor) {
    _redactor = newRedactor;
    _payloadSanitizer = NetworkPayloadSanitizer(newRedactor);
  }

  /// Provides helper functions for sanitizing headers and bodies.
  NetworkPayloadSanitizer get payload => _payloadSanitizer;

  /// Redacts HTTP headers according to redaction rules.
  ///
  /// Returns redacted headers as Map<String, dynamic> for maximum compatibility.
  Map<String, dynamic> redactHeaders(
    Map<String, dynamic> headers, {
    required bool useRedaction,
  }) =>
      payload.headersMap(headers, enableRedaction: useRedaction);

  /// Redacts request/response body data.
  ///
  /// Returns redacted data or original if redaction is disabled.
  Object? redactBody(Object? data, {required bool useRedaction}) =>
      payload.body(data, enableRedaction: useRedaction);

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

  /// Redacts URLs embedded in a message string (e.g. error messages).
  ///
  /// Returns the original [message] if `null` or redaction is disabled.
  /// Delegates to [RedactionService.redactUrlsInText].
  String? redactErrorMessage(
    String? message, {
    required bool useRedaction,
  }) {
    if (message == null || !useRedaction) return message;
    return redactor.redactUrlsInText(message);
  }

  /// Sanitizes body data and returns it as a non-empty map, or `null`.
  ///
  /// Applies optional [normalizer] before redaction, then wraps the result
  /// in a string-keyed map. Returns `null` when the data is `null` or the
  /// resulting map is empty.
  Map<String, dynamic>? bodyAsMap(
    Object? data, {
    required bool useRedaction,
    Object? Function(Object?)? normalizer,
  }) {
    if (data == null) return null;
    final sanitized = payload.body(
      data,
      enableRedaction: useRedaction,
      normalizer: normalizer,
    );
    if (sanitized == null) return null;
    final map = payload.ensureMap(sanitized);
    return map.isEmpty ? null : map;
  }

  /// Applies [redactBody] with error handling: logs a warning and returns
  /// a placeholder on failure instead of propagating the exception.
  Object safeRedact(Object data, {required bool useRedaction}) {
    try {
      return redactBody(data, useRedaction: useRedaction) ?? data;
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

  /// Wraps a log-building callback in try-catch, logging a warning on failure
  /// instead of propagating the exception.
  ///
  /// Use this in interceptor hooks (`onRequest`, `onResponse`, `onError`)
  /// to prevent log-building failures from breaking the HTTP pipeline.
  void safeLog(ISpectLogData Function() builder) {
    try {
      logger.logData(builder());
    } catch (e, st) {
      logger.log('Failed to build log: $e', stackTrace: st);
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

  /// Processes and redacts a map, ensuring string keys.
  ///
  /// Applies redaction if enabled, then converts to Map<String, dynamic>.
  Map<String, dynamic> processMapData(
    Map<dynamic, dynamic> data, {
    required bool useRedaction,
  }) {
    try {
      final redacted =
          payload.body(data, enableRedaction: useRedaction) ?? data;

      if (redacted is Map<String, dynamic>) return redacted;

      final mapToConvert = redacted is Map ? redacted : data;
      return mapToConvert.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {
      try {
        return payload.stringKeyMap(data);
      } catch (_) {
        return <String, dynamic>{'raw': ph.conversionFailedPlaceholder};
      }
    }
  }
}
