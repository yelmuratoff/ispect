import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/network/network_json_keys.dart';
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
    final code = _traceMeta(response)?[NetworkJsonKeys.statusCode] ??
        _traceMeta(error)?[NetworkJsonKeys.statusCode];
    if (code is int) return code;
    // v4 fallback: flat additionalData
    return response?.additionalData?['statusCode'] as int? ??
        error?.additionalData?['statusCode'] as int?;
  }

  /// HTTP status reason phrase (e.g. `No Content`), if reported.
  String? get statusMessage =>
      _nonEmptyString(_responseField(NetworkJsonKeys.statusMessage)) ??
      _nonEmptyString(_errorResponse?[NetworkJsonKeys.statusMessage]);

  /// Media type of the request body (e.g. `application/json`), if reported.
  String? get requestContentType =>
      _nonEmptyString(_requestField(NetworkJsonKeys.contentType));

  /// Request body size in bytes, if reported.
  int? get requestContentLength =>
      _positiveInt(_requestField(NetworkJsonKeys.contentLength));

  /// Response body size in bytes, if reported.
  int? get responseContentLength =>
      _positiveInt(_responseField(NetworkJsonKeys.contentLength));

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

  /// The error log's embedded response sub-map, if present.
  Map<String, dynamic>? get _errorResponse {
    final resp =
        _dataMap(error, NetworkJsonKeys.errorData)?[NetworkJsonKeys.response];
    return resp is Map<String, dynamic> ? resp : null;
  }

  /// Extract trace meta map from a log entry.
  static Map<String, dynamic>? _traceMeta(ISpectLogData? log) {
    final meta = log?.additionalData?[TraceKeys.meta];
    return meta is Map<String, dynamic> ? meta : null;
  }

  /// A data sub-map nested inside a log's trace [meta] envelope, keyed by
  /// [NetworkJsonKeys.requestData] / [NetworkJsonKeys.responseData] / etc.
  static Map<String, dynamic>? _dataMap(ISpectLogData? log, String key) {
    final v = _traceMeta(log)?[key];
    return v is Map<String, dynamic> ? v : null;
  }

  Object? _requestField(String key) =>
      _dataMap(request, NetworkJsonKeys.requestData)?[key];

  Object? _responseField(String key) =>
      _dataMap(response, NetworkJsonKeys.responseData)?[key];

  /// Extract int from trace envelope.
  static int? _metaInt(ISpectLogData? log, String key) {
    final v = log?.additionalData?[key];
    return v is int ? v : null;
  }

  static String? _nonEmptyString(Object? v) =>
      v is String && v.isNotEmpty ? v : null;

  static int? _positiveInt(Object? v) {
    final n = v is int ? v : (v is String ? int.tryParse(v) : null);
    return n != null && n > 0 ? n : null;
  }
}
