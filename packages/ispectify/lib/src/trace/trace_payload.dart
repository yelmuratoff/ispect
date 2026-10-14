import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/diagnostic_capture_mode.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';

/// Bounds [value], then redacts and re-bounds it when [redactor] is non-null.
///
/// Fails closed: any failure yields [redactionFailedPlaceholder].
Object? prepareTracePayload(
  Object? value, {
  required RedactionService? redactor,
  required DiagnosticCaptureMode captureMode,
  required DiagnosticResourceLimits resourceLimits,
  int? maxBytes,
}) {
  final balanced = captureMode == DiagnosticCaptureMode.balanced;
  try {
    final prepared = LogExportOutput.boundJsonValue(
      value,
      maxBytes: maxBytes,
      resourceLimits: resourceLimits,
      preserveTypes: redactor != null,
      replaceOversizedStrings: redactor != null,
      allowCustomSerialization: balanced,
      allowCustomStringification: balanced,
    );
    if (redactor == null) return prepared;
    final redacted = redactor.redactForExport(
      LogExportOutput.replaceTruncatedPrefixes(
        prepared,
        resourceLimits: resourceLimits,
      ),
      resourceLimits: resourceLimits,
    );
    return LogExportOutput.boundJsonValue(
      redacted,
      maxBytes: maxBytes,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: true,
    );
  } catch (_) {
    return redactionFailedPlaceholder;
  }
}
