import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/models.dart';
import 'package:ispectify/src/network/network_payload_sanitizer.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:ispectify/src/trace/trace_config.dart';

/// Mixin providing redaction utilities for network interceptors.
///
/// Implementing classes must provide [logger], [enableRedaction], and
/// [redactor].
mixin NetworkRedactionMixin {
  /// Shared trace config that disables Layer 2 (trace pipeline) redaction.
  ///
  /// Used when the interceptor's [enableRedaction] flag is `false` so that
  /// metadata stored in the trace is not additionally redacted by the pipeline.
  static const noRedactConfig = ISpectTraceConfig(redact: false);

  /// The logger instance — needed for error reporting in [safeRedact].
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
      return _payload.body(
            data,
            enableRedaction: useRedaction,
            normalizer: NetworkPayloadSanitizer.encodeJsonGracefully,
          ) ??
          data;
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
