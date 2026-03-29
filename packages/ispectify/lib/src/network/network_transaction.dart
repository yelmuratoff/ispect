import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/trace/trace_keys.dart';

/// Groups a correlated HTTP request with its response or error.
///
/// Used by the UI layer to display network logs as unified transactions
/// instead of separate entries.
class NetworkTransaction {
  const NetworkTransaction({
    required this.requestId,
    required this.request,
    this.response,
    this.error,
  });

  /// The shared correlation ID linking these logs.
  final String requestId;

  /// The originating request log.
  final ISpectLogData request;

  /// The response log, if the request completed successfully.
  final ISpectLogData? response;

  /// The error log, if the request failed.
  final ISpectLogData? error;

  /// Duration from request to response/error, or `null` if still pending.
  Duration? get duration {
    // v5: check trace durationMs first
    final respDurationMs =
        _metaInt(response, 'durationMs') ?? _metaInt(error, 'durationMs');
    if (respDurationMs != null) {
      return Duration(milliseconds: respDurationMs);
    }
    // Fallback: time difference
    final end = response?.time ?? error?.time;
    if (end == null) return null;
    return end.difference(request.time);
  }

  /// Whether no response or error has been received yet.
  bool get isPending => response == null && error == null;

  /// Whether the request completed with a response (no error).
  bool get isSuccess => response != null && error == null;

  /// Whether the request resulted in an error.
  bool get isError => error != null;

  /// HTTP status code from response or error, if available.
  int? get statusCode {
    // v5: trace meta
    final code =
        _traceMeta(response)?['statusCode'] ?? _traceMeta(error)?['statusCode'];
    if (code is int) return code;
    // v4 fallback: flat additionalData
    return response?.additionalData?['statusCode'] as int? ??
        error?.additionalData?['statusCode'] as int?;
  }

  /// HTTP method from the request.
  String? get method {
    // v5: trace operation field
    final op = request.additionalData?[TraceKeys.operation];
    if (op is String) return op;
    // v4 fallback
    return request.additionalData?['method'] as String?;
  }

  /// Request URL.
  String? get url {
    // v5: trace target field
    final target = request.additionalData?[TraceKeys.target];
    if (target is String) return target;
    // v4 fallback
    return request.additionalData?['url'] as String?;
  }

  /// Returns a copy with updated response or error.
  NetworkTransaction copyWith({
    ISpectLogData? response,
    ISpectLogData? error,
  }) =>
      NetworkTransaction(
        requestId: requestId,
        request: request,
        response: response ?? this.response,
        error: error ?? this.error,
      );

  /// Extract trace meta map from a log entry.
  static Map<String, dynamic>? _traceMeta(ISpectLogData? log) {
    final meta = log?.additionalData?[TraceKeys.meta];
    return meta is Map<String, dynamic> ? meta : null;
  }

  /// Extract int from trace envelope.
  static int? _metaInt(ISpectLogData? log, String key) {
    final v = log?.additionalData?[key];
    return v is int ? v : null;
  }
}
