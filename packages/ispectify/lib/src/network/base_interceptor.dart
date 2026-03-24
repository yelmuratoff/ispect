import 'package:ispectify/ispectify.dart';

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
  /// the URL has nothing to redact.
  String redactUrl(String url, {required bool useRedaction}) {
    if (!useRedaction) return url;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final hasParams = uri.queryParameters.isNotEmpty;
    final hasUserInfo = uri.userInfo.isNotEmpty;
    if (!hasParams && !hasUserInfo) return url;

    final redactedParams = hasParams
        ? uri.queryParameters.map(
            (key, value) => MapEntry(key, redactor.redact(value, keyName: key)),
          )
        : null;

    return uri
        .replace(
          userInfo: hasUserInfo ? '[REDACTED]' : null,
          queryParameters:
              redactedParams?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        )
        .toString();
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
          payload.body(data, enableRedaction: useRedaction) ?? data;

      if (redacted is Map<String, dynamic>) return redacted;

      final mapToConvert = redacted is Map ? redacted : data;
      return mapToConvert.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {
      try {
        return payload.stringKeyMap(data);
      } catch (_) {
        return <String, dynamic>{'raw': '[conversion failed]'};
      }
    }
  }
}
