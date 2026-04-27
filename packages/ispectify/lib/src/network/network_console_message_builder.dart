import 'package:ispectify/src/utils/json_truncator.dart';

/// Builds a rich console message for network logs, respecting
/// [BaseNetworkInterceptorSettings] print flags.
///
/// Default layout splits `operation` and `target` across two lines so the URL
/// is always easy to spot in the console:
///
/// ```
/// GET FAILED
/// → https://example.com/api/users/42
/// ```
///
/// `source` and `duration` are accepted for callers who want to embed them in
/// the body; by default they are omitted because the entry formatter already
/// renders source in the header (`[source]`) and duration in metadata
/// (`dur=…ms`). Set [printSourceInBody] / [printDurationInBody] to `true` to
/// re-introduce them — useful when copying a single line out of context.
///
/// Set [wrapTargetOnNewLine] to `false` to keep the legacy single-line layout.
String buildNetworkConsoleMessage({
  required String operation,
  required String target,
  String? source,
  Duration? duration,
  bool success = true,
  int? statusCode,
  String? statusMessage,
  Object? body,
  Map<String, dynamic>? headers,
  String? errorMessage,
  bool printSourceInBody = false,
  bool printDurationInBody = false,
  bool wrapTargetOnNewLine = true,
  bool printStatusCode = true,
  bool printStatusMessage = false,
  bool printBody = false,
  bool printHeaders = false,
  bool printErrorMessage = false,
}) {
  final buf = StringBuffer();

  if (printSourceInBody && source != null && source.isNotEmpty) {
    buf.write('[$source] ');
  }
  buf.write(operation);
  if (!success) buf.write(' FAILED');
  if (printDurationInBody && duration != null) {
    buf.write(' ${duration.inMilliseconds}ms');
  }

  buf.write(wrapTargetOnNewLine ? '\n→ $target' : ' → $target');

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
