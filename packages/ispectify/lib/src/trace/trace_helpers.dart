import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/utils/string_extension.dart';

/// Truncates [value] to [maxLen] characters if it is a [String].
///
/// Map and List values are returned as-is. For large payloads, use
/// `projectResult` in traceAsync/traceSync to project only needed fields
/// before writing to the log.
Object? truncateValue(Object? value, int maxLen) {
  if (value == null) return null;
  if (value is String) return truncateString(value, maxLength: maxLen);
  return value;
}

/// Safely builds and logs trace data. If the builder throws, logs a warning
/// instead of crashing the application.
void safeTrace(ISpectLogger logger, ISpectLogData Function() builder) {
  try {
    final data = builder();
    logger.logData(data);
  } catch (e, st) {
    try {
      logger.warning('Trace builder threw: ${e.runtimeType}\n$st');
    } catch (_) {}
  }
}
