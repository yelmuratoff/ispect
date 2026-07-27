import 'package:ispectify/src/history/serialization.dart';
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

/// Combines domain-specific trace fields with caller metadata behind the
/// non-executing export snapshot boundary.
///
/// Caller metadata retains its existing override precedence without exposing
/// domain helpers to hostile map iteration, formatters, or unbounded values.
Map<String, Object?> boundedTraceMeta({
  Map<String, Object?> fields = const <String, Object?>{},
  Map<String, Object?>? overrides,
}) {
  final bounded = LogExportOutput.boundJsonValue(
    <String, Object?>{
      'fields': fields,
      if (overrides != null) 'overrides': overrides,
    },
    preserveTypes: true,
    replaceOversizedStrings: true,
  );
  if (bounded is! Map) return const <String, Object?>{};

  final result = <String, Object?>{};
  void addMap(Object? value) {
    if (value is Map<String, Object?>) {
      result.addAll(value);
    } else if (value is Map) {
      result.addAll(Map<String, Object?>.from(value));
    }
  }

  addMap(bounded['fields']);
  addMap(bounded['overrides']);
  return result;
}

/// Safely builds and logs trace data. If the builder throws, logs a warning
/// instead of crashing the application.
void safeTrace(
  ISpectLogger logger,
  ISpectLogData Function() builder, {
  bool redact = true,
}) {
  try {
    final data = builder();
    logger.logData(data, redact: redact);
  } catch (_) {
    try {
      logger.warning('Trace builder failed safely.');
    } catch (_) {}
  }
}
