/// Unified trace summary for all categories.
///
/// When a `target` is present, the default layout puts `operation` and
/// `→ target` together on their own line so the request/key is easy to spot
/// without scanning past the log header:
///
/// ```
/// FAILED
/// → GET /api/users/42
/// ```
///
/// The first body line carries only short flags (`FAILED`, optional
/// `${ms}ms`, optional `(key)`). When nothing applies, the line is
/// intentionally empty — the visual break makes the `→ operation target`
/// line stand out. Without a `target`, the body falls back to a compact
/// single-line form (`operation (key)`).
///
/// Pass [printSourceInBody] / [printDurationInBody] = `true` to embed the
/// source tag and duration into the body; by default they are omitted
/// because the entry formatter already renders them in the header and
/// metadata.
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
  final hasTarget = target != null;
  final wrap = wrapTargetOnNewLine && hasTarget;

  final firstLine = <String>[];
  if (printSourceInBody && source != null && source.isNotEmpty) {
    firstLine.add('[$source]');
  }
  if (!wrap) firstLine.add(operation);
  if (key != null) firstLine.add('($key)');
  if (printDurationInBody && duration != null) {
    firstLine.add('${duration.inMilliseconds}ms');
  }
  if (!success) firstLine.add('FAILED');

  final buf = StringBuffer(firstLine.join(' '));

  if (hasTarget) {
    if (wrap) {
      buf.write('\n→ $operation $target');
    } else {
      if (buf.isNotEmpty) buf.write(' ');
      buf.write('→ $target');
    }
  }

  return buf.toString();
}
