import 'package:ispectify/ispectify.dart';

/// Builds a rich console message for Dio network logs, respecting
/// [BaseNetworkInterceptorSettings] print flags.
///
/// The first line is the standard trace header (`[dio] {method} → {url} {ms}`).
/// Additional sections (status, body, headers) are appended on separate lines
/// when the corresponding setting flag is `true`.
String buildDioConsoleMessage({
  required String source,
  required String operation,
  required String target,
  Duration? duration,
  bool success = true,
  int? statusCode,
  String? statusMessage,
  Object? body,
  Map<String, dynamic>? headers,
  String? errorMessage,
  bool printStatusCode = true,
  bool printStatusMessage = false,
  bool printBody = false,
  bool printHeaders = false,
  bool printErrorMessage = false,
}) {
  final header = _buildHeader(
    source: source,
    operation: operation,
    target: target,
    duration: duration,
    success: success,
  );

  final buffer = StringBuffer(header);

  if (printStatusCode && statusCode != null) {
    buffer.write('\nStatus: $statusCode');
  }
  if (printStatusMessage && statusMessage != null && statusMessage.isNotEmpty) {
    buffer.write('\nMessage: $statusMessage');
  }
  if (printErrorMessage && errorMessage != null && errorMessage.isNotEmpty) {
    buffer.write('\nError: $errorMessage');
  }
  if (printBody && body != null) {
    buffer.write('\nData: ${JsonTruncator.pretty(body)}');
  }
  if (printHeaders && headers != null && headers.isNotEmpty) {
    buffer.write('\nHeaders: ${JsonTruncator.pretty(headers)}');
  }

  return buffer.toString();
}

String _buildHeader({
  required String source,
  required String operation,
  required bool success,
  required String target,
  Duration? duration,
}) {
  final buf = StringBuffer('[$source] $operation → $target');
  if (duration != null) buf.write(' ${duration.inMilliseconds}ms');
  if (!success) buf.write(' FAILED');
  return buf.toString();
}
