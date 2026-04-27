/// Unified trace summary for all categories.
///
/// Default layout puts `operation` on the first line and `→ target` on the
/// next so the target stays easy to scan even after a long log header:
///
/// ```
/// GET FAILED
/// → https://example.com/api/users/42
/// ```
///
/// Pass [printSourceInBody] / [printDurationInBody] = `true` to embed the
/// source tag and duration into the body; by default they are omitted because
/// the entry formatter already renders them in the header and metadata.
///
/// Pass [wrapTargetOnNewLine] = `false` to keep the legacy single-line form
/// (e.g. for grep-friendly export).
String buildTraceMessage({
  required String operation,
  required bool success,
  String? source,
  String? target,
  String? key,
  Duration? duration,
  bool printSourceInBody = false,
  bool printDurationInBody = false,
  bool wrapTargetOnNewLine = true,
}) {
  final buffer = StringBuffer();

  if (printSourceInBody && source != null && source.isNotEmpty) {
    buffer.write('[$source] ');
  }
  buffer.write(operation);

  if (key != null) buffer.write(' ($key)');
  if (printDurationInBody && duration != null) {
    buffer.write(' ${duration.inMilliseconds}ms');
  }
  if (!success) buffer.write(' FAILED');

  if (target != null) {
    buffer.write(wrapTargetOnNewLine ? '\n→ $target' : ' → $target');
  }

  return buffer.toString();
}
