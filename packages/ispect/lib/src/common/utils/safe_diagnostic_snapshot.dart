import 'dart:convert';

import 'package:ispectify/ispectify.dart';

/// Produces bounded UI-safe diagnostics without executing caller formatters.
abstract final class ISpectSafeDiagnosticSnapshot {
  static String text(
    Object? value, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    if (value == null) return '';
    resourceLimits.validate();
    final maxBytes = resourceLimits.maxUiDiagnosticBytes;
    final redactor = ISpectRedaction.enabled ? ISpectRedaction.service : null;
    try {
      final prepared = LogExportOutput.boundJsonValue(
        value,
        maxBytes: maxBytes,
        resourceLimits: resourceLimits,
        preserveTypes: redactor != null,
        replaceOversizedStrings: redactor != null,
      );
      final scrubbed = redactor == null
          ? prepared
          : redactor.redactForExport(
              prepared,
              resourceLimits: resourceLimits,
            );
      final bounded = LogExportOutput.boundJsonValue(
        scrubbed,
        maxBytes: maxBytes,
        resourceLimits: resourceLimits,
        replaceOversizedStrings: redactor != null,
      );
      final rendered = switch (bounded) {
        null => '',
        final String text => text,
        final bool primitive => primitive.toString(),
        final num primitive => primitive.toString(),
        _ => jsonEncode(bounded),
      };
      return LogExportOutput.truncateUtf8(
        rendered,
        maxBytes: maxBytes,
      );
    } on Object {
      return defaultPlaceholder;
    }
  }

  static String summary(
    Object? value, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      text(value, resourceLimits: resourceLimits)
          .replaceAll(RegExp(r'[\r\n\u2028\u2029]+'), ' ')
          .trim();
}
