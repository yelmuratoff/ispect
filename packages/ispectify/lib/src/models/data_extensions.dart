import 'package:ispectify/ispectify.dart';

/// Utility extensions on [ISpectLogData]: copy, formatting, cURL generation.
extension ISpectDataX on ISpectLogData {
  /// Returns a copy with the given fields replaced.
  ///
  /// Preserves [ISpectLogData.id] by default so the copy stays equal to the
  /// original under the id-based `==`/`hashCode`; pass [id] to mint a new
  /// identity. Always returns a base [ISpectLogData] — subtypes such as
  /// [ISpectLogException]/[ISpectLogError] are not reconstructed, since this is
  /// an extension method and cannot dispatch on the runtime type.
  ISpectLogData copyWith({
    Object? message,
    LogLevel? logLevel,
    Object? exception,
    Error? error,
    StackTrace? stackTrace,
    DateTime? time,
    AnsiPen? pen,
    String? key,
    Map<String, dynamic>? additionalData,
    String? id,
  }) {
    final captured = captureISpectLogDataForEgress(this);
    return ISpectLogData(
      message ?? captured.message,
      logLevel: logLevel ?? captured.logLevel,
      exception: exception ?? captured.exception,
      error: error ?? captured.error,
      stackTrace: stackTrace ?? captured.stackTrace,
      time: time ?? captured.time,
      pen: pen ?? captured.pen,
      key: key ?? captured.key,
      additionalData: additionalData ?? captured.additionalData,
      id: id ?? captured.id,
    );
  }

  /// Identity-preserving copy: equal to the original under `==`.
  ISpectLogData copy() => copyWith();

  /// Truncated summary for debugging/display.
  String generateText() {
    final captured = captureISpectLogDataForEgress(this);
    String truncate(String? value, int maxLength) {
      if (value == null) return '';
      return value.length > maxLength
          ? '${value.substring(0, maxLength)}...'
          : value;
    }

    final formattedKey = truncate(captured.key, 100);
    final formattedMessage = truncate(
      _safeDiagnosticText(captured.message),
      100,
    );
    final exceptionText = truncate(captured.exceptionText, 500);
    final errorText = truncate(captured.errorText, 500);
    final stackTraceText = truncate(captured.stackTraceText, 500);

    return '''[Item with hashcode: ${captured.id.hashCode}
Time: ${ISpectDateTimeFormatter(captured.time).defaultFormat}
Key: $formattedKey
Message: $formattedMessage
Exception: $exceptionText
Error: $errorText
StackTrace: $stackTraceText]''';
  }

  /// Stack trace text for log display. Returns `null` if unavailable.
  String? get stackTraceLogText {
    final captured = captureISpectLogDataForEgress(this);
    final isError = captured.logLevel == LogLevel.error ||
        captured.logLevel == LogLevel.critical ||
        ISpectLogType.isErrorKey(captured.key) ||
        captured.additionalData?[TraceKeys.success] == false;
    final stackTraceText = captured.stackTraceText;
    return isError && stackTraceText != null && stackTraceText.isNotEmpty
        ? 'StackTrace:\n$stackTraceText'.truncate()
        : null;
  }

  /// Error/exception message with special handling for HTTP and Flutter errors.
  String? get httpLogText {
    final captured = captureISpectLogDataForEgress(this);
    var txt = captured.exceptionText;

    if ((txt?.isNotEmpty ?? false) && txt!.contains('Source stack:')) {
      txt = 'Data: ${txt.split('Source stack:').first.replaceAll('\n', ' ')}';
    }

    final text = _isHttpKey(captured.key) ? toExportMessageText() : txt;

    return text.truncate();
  }

  bool get isHttpLog => _isHttpKey(captureISpectLogDataForEgress(this).key);

  bool get isRouteLog =>
      captureISpectLogDataForEgress(this).key == ISpectLogType.route.key;

  /// Generates a cURL command for HTTP logs, or `null` for non-HTTP entries.
  ///
  /// Headers, URL credentials/query secrets, and bodies are redacted by
  /// default.
  String? get curlCommand => curlCommandWith();

  /// Like [curlCommand], with an optional custom [redactor].
  ///
  /// Set [enableRedaction] to `false` only for controlled local debugging.
  String? curlCommandWith({
    RedactionService? redactor,
    bool enableRedaction = true,
  }) {
    final captured = captureISpectLogDataForEgress(this);
    if (captured.key == ISpectLogType.httpRequest.key) {
      return CurlUtils.generateCurl(
        captured.additionalData,
        redactor: redactor,
        enableRedaction: enableRedaction,
      );
    } else if (captured.key == ISpectLogType.httpResponse.key ||
        captured.key == ISpectLogType.httpError.key) {
      final requestOptionsValue = captured.additionalData?['request-options'];
      final requestOptions = requestOptionsValue is Map<String, dynamic>
          ? requestOptionsValue
          : null;
      return requestOptions != null
          ? CurlUtils.generateCurl(
              requestOptions,
              redactor: redactor,
              enableRedaction: enableRedaction,
            )
          : null;
    }
    return null;
  }

  /// Exception/error runtime type label, or `null` for non-error logs.
  String? get typeText {
    if (this is ISpectLogException) return 'Type: Exception';
    if (this is ISpectLogError) return 'Type: Error';
    return null;
  }
}

bool _isHttpKey(String? key) =>
    key == ISpectLogType.httpRequest.key ||
    key == ISpectLogType.httpResponse.key ||
    key == ISpectLogType.httpError.key;

String? _safeDiagnosticText(Object? value) {
  if (value == null) return null;
  final bounded = LogExportOutput.boundJsonValue(value);
  return switch (bounded) {
    final String text => text,
    final bool primitive => primitive.toString(),
    final num primitive => primitive.toString(),
    _ => JsonValueNormalizer.unprintableValue,
  };
}
