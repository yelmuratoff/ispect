import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:ispectify/src/redaction/redaction_toggle.dart';
import 'package:meta/meta.dart';

/// Outcome of sending a [NetworkReplayRequest] through a [NetworkRequestSender].
///
/// The same request is also captured by the client's existing ISpect
/// interceptor and appears in the network logs; this lightweight result lets the
/// composer show an inline summary without duplicating the full log rendering.
@immutable
final class NetworkReplayResult {
  const NetworkReplayResult({
    this.statusCode,
    this.headers = const {},
    this.body,
    this.durationMs,
    this.error,
  });

  /// HTTP status code, or `null` when the send failed before a response.
  final int? statusCode;

  final Map<String, String> headers;

  /// Decoded response body (structure or text), when available.
  final Object? body;

  /// Round-trip duration in milliseconds, when measured.
  final int? durationMs;

  /// Non-null when the send failed (transport error or non-2xx surfaced as an
  /// exception by the underlying client).
  final Object? error;

  bool get isError => !identical(error, null);

  /// Creates a detached, bounded snapshot suitable for controller and UI state.
  ///
  /// Caller-owned maps, iterables, errors, and unknown objects never cross the
  /// boundary by identity. The global redaction switch remains authoritative;
  /// when active, the supplied [redactor] or the safe default redactor masks
  /// sensitive response content before the final bounded snapshot is retained.
  NetworkReplayResult safeSnapshot({
    RedactionService? redactor,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    final redactionActive = ISpectRedaction.enabled;
    final prepared = LogExportOutput.boundJsonValue(
      <String, Object?>{
        'body': body,
        'error': error,
        'headers': headers,
      },
      resourceLimits: resourceLimits,
      preserveTypes: redactionActive,
      replaceOversizedStrings: redactionActive,
    );
    final Object? sanitized;
    if (redactionActive) {
      try {
        sanitized =
            ISpectRedaction.resolveService(service: redactor).redactForExport(
          prepared,
          resourceLimits: resourceLimits,
        );
      } catch (_) {
        return _redactionFailureSnapshot();
      }
    } else {
      sanitized = prepared;
    }
    final bounded = LogExportOutput.boundJsonValue(
      sanitized,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactionActive,
    );
    if (bounded is! Map<String, Object?>) {
      return _redactionFailureSnapshot();
    }

    return NetworkReplayResult(
      statusCode: statusCode,
      headers: _safeHeaders(bounded['headers']),
      body: bounded['body'],
      durationMs: durationMs,
      error: bounded['error'],
    );
  }

  NetworkReplayResult _redactionFailureSnapshot() => NetworkReplayResult(
        statusCode: statusCode,
        body: identical(body, null) ? null : redactionFailedPlaceholder,
        durationMs: durationMs,
        error: identical(error, null) ? null : redactionFailedPlaceholder,
      );

  static Map<String, String> _safeHeaders(Object? value) {
    if (value is! Map<String, Object?>) return const <String, String>{};
    final result = <String, String>{};
    for (final entry in value.entries) {
      if (entry.value case final String headerValue) {
        result[entry.key] = headerValue;
      }
    }
    return Map<String, String>.unmodifiable(result);
  }
}
