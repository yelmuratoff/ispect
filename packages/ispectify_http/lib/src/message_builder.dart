import 'package:ispectify/ispectify.dart';

/// Builds a rich console message for HTTP network logs, respecting
/// [BaseNetworkInterceptorSettings] print flags.
String buildHttpConsoleMessage({
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
  final buf = StringBuffer('[$source] $operation → $target');
  if (duration != null) buf.write(' ${duration.inMilliseconds}ms');
  if (!success) buf.write(' FAILED');

  if (printStatusCode && statusCode != null) {
    buf.write('\nStatus: $statusCode');
  }
  if (printStatusMessage && statusMessage != null && statusMessage.isNotEmpty) {
    buf.write('\nMessage: $statusMessage');
  }
  if (printErrorMessage && errorMessage != null && errorMessage.isNotEmpty) {
    buf.write('\nError: $errorMessage');
  }
  if (printBody && body != null) {
    buf.write('\nData: ${JsonTruncator.pretty(body)}');
  }
  if (printHeaders && headers != null && headers.isNotEmpty) {
    buf.write('\nHeaders: ${JsonTruncator.pretty(headers)}');
  }

  return buf.toString();
}
