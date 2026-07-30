import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/diagnostic_capture_mode.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/models/models.dart';
import 'package:ispectify/src/network/network_payload_sanitizer.dart';
import 'package:ispectify/src/network/network_uri_snapshot.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Mixin providing redaction utilities for network interceptors.
///
/// Implementing classes must provide [logger], [enableRedaction], and
/// [redactor].
mixin NetworkRedactionMixin {
  /// Disables trace-pipeline redaction after the caller resolves Layer 1.
  ///
  /// Every caller-controlled trace field must already be bounded and processed
  /// with the selected adapter policy before this config crosses the boundary.
  static const noRedactConfig = ISpectTraceConfig(redact: false);

  /// The logger instance — needed for error reporting in [safeRedact].
  ISpectLogger get logger;

  /// Whether redaction is enabled for this interceptor.
  ///
  /// Implementations should return their specific settings' redaction flag.
  bool get enableRedaction;

  /// Capture policy for values crossing this interceptor boundary.
  DiagnosticCaptureMode get captureMode => DiagnosticCaptureMode.balanced;

  /// Resource budgets resolved by the adapter or inherited from [logger].
  DiagnosticResourceLimits get resourceLimits => logger.options.resourceLimits;

  /// The redaction service for this interceptor.
  ///
  /// Implementing classes must override this to return their redactor instance.
  RedactionService get redactor;

  NetworkPayloadSanitizer get _payload => NetworkPayloadSanitizer(
        redactor,
        resourceLimits: resourceLimits,
      );

  /// Redacts query parameter values and userInfo credentials in a URL.
  ///
  /// Returns the original URL string if redaction is disabled or
  /// the URL has nothing to redact. Delegates to [RedactionService.redactUrl].
  String redactUrl(String url, {required bool useRedaction}) {
    final prepared = LogExportOutput.truncateUtf8(
      url,
      maxBytes: resourceLimits.maxCapturedValueBytes,
    );
    if (!useRedaction) return prepared;
    try {
      return LogExportOutput.truncateUtf8(
        redactor.redactUrl(prepared),
        maxBytes: resourceLimits.maxCapturedValueBytes,
      );
    } on Object {
      _logRedactionFailure();
      return ph.redactionFailedPlaceholder;
    }
  }

  /// Returns a bounded URL and path using the selected capture policy.
  ({String url, String path}) redactUrlAndPath(
    Uri uri, {
    required bool useRedaction,
  }) =>
      redactUrlSnapshot(
        NetworkUriSnapshot.fromUri(
          uri,
          captureMode: captureMode,
          resourceLimits: resourceLimits,
        ),
        useRedaction: useRedaction,
      );

  /// Redacts a URL snapshot whose provenance was established by its creator.
  ({String url, String path}) redactUrlSnapshot(
    NetworkUriSnapshot snapshot, {
    required bool useRedaction,
  }) {
    if (!snapshot.isTrusted) {
      return (url: snapshot.url, path: snapshot.path);
    }
    return (
      url: redactUrl(snapshot.url, useRedaction: useRedaction),
      path: redactUrl(snapshot.path, useRedaction: useRedaction),
    );
  }

  /// Applies redaction with error handling: logs a warning and returns
  /// a placeholder on failure instead of propagating the exception.
  Object safeRedact(Object data, {required bool useRedaction}) {
    try {
      final redacted = _payload.body(
        data,
        enableRedaction: useRedaction,
        captureMode: captureMode,
      );
      if (useRedaction && redacted == ph.redactionFailedPlaceholder) {
        _logRedactionFailure();
      }
      if (redacted != null) return redacted;
      return useRedaction
          ? ph.redactionFailedPlaceholder
          : JsonValueNormalizer.unprintableValue;
    } on Object {
      _logRedactionFailure();
      return ph.redactionFailedPlaceholder;
    }
  }

  /// Returns bounded diagnostic text, failing closed when redaction fails.
  String redactDiagnosticText(
    String value, {
    required bool useRedaction,
  }) {
    final prepared = safeRedact(value, useRedaction: useRedaction);
    return prepared is String ? prepared : ph.redactionFailedPlaceholder;
  }

  /// Processes and redacts a map, ensuring string keys.
  ///
  /// Applies redaction if enabled, then converts to Map<String, dynamic>.
  ///
  /// Fails closed: if processing throws, returns a placeholder map instead of
  /// the original (unredacted) data, mirroring [safeRedact].
  Map<String, dynamic> processMapData(
    Map<dynamic, dynamic> data, {
    required bool useRedaction,
  }) {
    try {
      final redacted = _payload.body(
        data,
        enableRedaction: useRedaction,
        captureMode: captureMode,
      );
      if (redacted == null) {
        return useRedaction
            ? <String, dynamic>{'raw': ph.redactionFailedPlaceholder}
            : NetworkPayloadSanitizer.toStringKeyMap(
                data,
                resourceLimits: resourceLimits,
              );
      }

      if (redacted is Map<String, dynamic>) return redacted;
      if (redacted is Map) {
        return redacted.map((k, v) => MapEntry(k.toString(), v));
      }

      // Redaction collapsed the whole map to a scalar placeholder (a
      // fail-closed strategy throw or a depth limit). Never fall back to the
      // raw input — wrap the placeholder instead.
      if (useRedaction && redacted == ph.redactionFailedPlaceholder) {
        _logRedactionFailure();
      }
      return <String, dynamic>{'raw': redacted};
    } on Object {
      _logRedactionFailure();
      return <String, dynamic>{'raw': ph.redactionFailedPlaceholder};
    }
  }

  void _logRedactionFailure() {
    logger.logData(
      ISpectLogData(
        'Redaction failed; diagnostic data omitted.',
        logLevel: LogLevel.warning,
        resourceLimits: resourceLimits,
      ),
    );
  }
}
