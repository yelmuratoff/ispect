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

  bool get isError => error != null;
}
