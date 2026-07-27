import 'dart:convert';

import 'package:ispectify/ispectify.dart';

/// Produces bounded UI-safe diagnostics without executing caller formatters.
abstract final class ISpectSafeDiagnosticSnapshot {
  static const int maxUiDiagnosticBytes = 8 * 1024;

  static String text(Object? value) {
    if (value == null) return '';
    final redactor = ISpectRedaction.enabled ? ISpectRedaction.service : null;
    try {
      final prepared = LogExportOutput.boundJsonValue(
        value,
        maxBytes: maxUiDiagnosticBytes,
        preserveTypes: redactor != null,
        replaceOversizedStrings: redactor != null,
      );
      final scrubbed =
          redactor == null ? prepared : redactor.redactForExport(prepared);
      final bounded = LogExportOutput.boundJsonValue(
        scrubbed,
        maxBytes: maxUiDiagnosticBytes,
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
        maxBytes: maxUiDiagnosticBytes,
      );
    } on Object {
      return defaultPlaceholder;
    }
  }

  static String summary(Object? value) =>
      text(value).replaceAll(RegExp(r'[\r\n\u2028\u2029]+'), ' ').trim();
}
