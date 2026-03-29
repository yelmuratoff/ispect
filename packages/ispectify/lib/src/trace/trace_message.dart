/// Unified format for all trace categories.
///
/// Details are in the JSON viewer. Message is only a summary for the list.
String buildTraceMessage({
  required String source,
  required String operation,
  required bool success,
  String? target,
  String? key,
  Duration? duration,
}) {
  final buffer = StringBuffer()
    ..write('[$source] ')
    ..write(operation);

  if (target != null) buffer.write(' → $target');
  if (key != null) buffer.write(' ($key)');
  if (duration != null) buffer.write(' ${duration.inMilliseconds}ms');
  if (!success) buffer.write(' FAILED');

  return buffer.toString();
}
