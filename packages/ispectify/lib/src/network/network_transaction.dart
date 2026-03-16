import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/network/network_logs.dart';

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
    final resp = response;
    if (resp is NetworkResponseLog) return resp.statusCode;
    final err = error;
    if (err is NetworkErrorLog) return err.statusCode;
    // Fallback for imported logs (deserialized as plain ISpectLogData).
    return response?.additionalData?['statusCode'] as int? ??
        error?.additionalData?['statusCode'] as int?;
  }

  /// HTTP method from the request.
  String? get method {
    final req = request;
    if (req is NetworkRequestLog) return req.method;
    return request.additionalData?['method'] as String?;
  }

  /// Request URL.
  String? get url {
    final req = request;
    if (req is NetworkRequestLog) return req.url;
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
}
