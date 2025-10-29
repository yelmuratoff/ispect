import 'package:ispectify/ispectify.dart';

/// Mixin providing common functionality for network interceptors.
///
/// This mixin encapsulates shared patterns across HTTP, Dio, and WebSocket
/// interceptors including:
/// - Logger instance management
/// - Redaction service configuration
/// - Header redaction
/// - Body redaction
/// - Settings management
///
/// Implementing classes should use this mixin and call [initializeInterceptor]
/// in their constructor to set up the logger and redactor.
mixin BaseNetworkInterceptor {
  late final ISpectLogger _logger;
  late RedactionService _redactor;
  late NetworkPayloadSanitizer _payloadSanitizer;

  /// Initializes the interceptor with logger and redaction service.
  ///
  /// Must be called in the implementing class's constructor.
  ///
  /// - [logger]: The ISpectLogger instance to use for logging. Defaults to new instance.
  /// - [redactor]: The RedactionService for sensitive data masking. Defaults to new instance.
  void initializeInterceptor({
    ISpectLogger? logger,
    RedactionService? redactor,
  }) {
    _logger = logger ?? ISpectLogger();
    _redactor = redactor ?? RedactionService();
    _payloadSanitizer = NetworkPayloadSanitizer(_redactor);
  }

  /// Gets the current logger instance.
  ISpectLogger get logger => _logger;

  /// Gets the current redaction service.
  RedactionService get redactor => _redactor;

  /// Provides helper functions for sanitizing headers and bodies.
  NetworkPayloadSanitizer get payload => _payloadSanitizer;

  /// Indicates whether redaction is enabled for this interceptor.
  ///
  /// Implementations should override this to return their specific
  /// settings' redaction flag.
  bool get enableRedaction;

  /// Updates the redaction service instance.
  ///
  /// This allows runtime reconfiguration of redaction behavior without
  /// recreating the interceptor.
  set redactor(RedactionService newRedactor) {
    _redactor = newRedactor;
    _payloadSanitizer = NetworkPayloadSanitizer(_redactor);
  }

  /// Redacts HTTP headers according to redaction rules.
  ///
  /// - [headers]: The headers map to redact.
  /// - [useRedaction]: Whether to apply redaction (typically from settings).
  ///
  /// Returns redacted headers as Map<String, dynamic> for maximum compatibility.
  Map<String, dynamic> redactHeaders(
    Map<String, dynamic> headers, {
    required bool useRedaction,
  }) =>
      payload.headersMap(
        headers,
        enableRedaction: useRedaction,
      );

  /// Redacts request/response body data.
  ///
  /// - [data]: The body data to redact (can be any type: Map, List, String, etc).
  /// - [useRedaction]: Whether to apply redaction.
  ///
  /// Returns redacted data or original if redaction is disabled.
  Object? redactBody(Object? data, {required bool useRedaction}) =>
      payload.body(
        data,
        enableRedaction: useRedaction,
        normalizer: (value) => value,
      );

  /// Conditionally redacts data based on redaction setting.
  ///
  /// Convenience method for inline redaction checks.
  ///
  /// - [data]: Data to potentially redact.
  /// - [useRedaction]: Whether redaction is enabled.
  Object? maybeRedact(Object? data, {required bool useRedaction}) =>
      payload.body(
        data,
        enableRedaction: useRedaction,
        normalizer: (value) => value,
      );

  /// Converts an untyped Map<dynamic, dynamic> to Map<String, dynamic>.
  ///
  /// Useful when processing JSON or form data that may have dynamic keys.
  /// Falls back to stringified raw data if conversion fails.
  ///
  /// - [map]: The untyped map to convert.
  Map<String, dynamic> convertToTypedMap(Map<dynamic, dynamic> map) {
    try {
      return payload.stringKeyMap(map);
    } catch (_) {
      return <String, dynamic>{'raw': map.toString()};
    }
  }

  /// Processes and redacts a map, ensuring correct type.
  ///
  /// Applies redaction if enabled, then ensures the result is properly typed
  /// as Map<String, dynamic>.
  ///
  /// - [data]: The map to process.
  /// - [useRedaction]: Whether to apply redaction.
  Map<String, dynamic> processMapData(
    Map<dynamic, dynamic> data, {
    required bool useRedaction,
  }) {
    try {
      final redacted = payload.body(
            data,
            enableRedaction: useRedaction,
            normalizer: (value) => value,
          ) ??
          data;

      // Guard clause: if already correct type, return early
      if (redacted is Map<String, dynamic>) {
        return redacted;
      }

      // Convert to correct type
      final mapToConvert = redacted is Map ? redacted : data;
      return mapToConvert.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {
      // Fallback: convert original data
      return payload.stringKeyMap(data);
    }
  }
}
