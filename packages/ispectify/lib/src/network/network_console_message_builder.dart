import 'package:ispectify/src/utils/json_truncator.dart';

/// Builds a rich console message for network logs, respecting
/// [BaseNetworkInterceptorSettings] print flags.
///
/// Default layout puts the method + URL together on their own line so they
/// are easy to spot at a glance — no need to scan past a long header:
///
/// ```
/// FAILED
/// → GET https://example.com/api/users/42
/// Status: 500
/// ```
///
/// The first body line carries only short status flags (`FAILED` and, when
/// [printDurationInBody] is enabled, `${ms}ms`). When no flag applies, the
/// `→ METHOD URL` line becomes the first line of the body — no leading
/// blank line is emitted, which keeps UI renderers and JSON inspectors
/// from showing an empty paragraph.
///
/// `source` and `duration` are accepted for callers who want to embed them
/// in the body; by default they are omitted because the entry formatter
/// already renders source in the header (`[source]`) and duration in
/// metadata (`dur=…ms`). Set [printSourceInBody] / [printDurationInBody] to
/// `true` to re-introduce them — useful when copying a single line out of
/// context.
///
/// Set [wrapTargetOnNewLine] to `false` to keep the legacy single-line
/// layout (`METHOD → URL`) for grep-style consumers.
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
  final firstLine = <String>[];
  if (printSourceInBody && source != null && source.isNotEmpty) {
    firstLine.add('[$source]');
  }
  if (!success) firstLine.add('FAILED');
  if (printDurationInBody && duration != null) {
    firstLine.add('${duration.inMilliseconds}ms');
  }

  final buf = StringBuffer(firstLine.join(' '));

  if (wrapTargetOnNewLine) {
    if (buf.isNotEmpty) buf.write('\n');
    buf.write('→ $operation $target');
  } else {
    if (buf.isNotEmpty) buf.write(' ');
    buf.write('$operation → $target');
  }

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
