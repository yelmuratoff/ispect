import 'package:ispect/ispect.dart';

/// Formats log history for human-readable diagnostic handoff.
extension HistoryListFlutterText on List<ISpectLogData> {
  /// Uses the initialized logger policy, or the first entry's capture policy.
  String get formattedText => formattedTextWith();

  /// Formats history with an optional local resource-policy override.
  String formattedTextWith({DiagnosticResourceLimits? resourceLimits}) {
    if (isEmpty) return '';
    final limits =
        (resourceLimits ??
              ISpect.loggerIfInitialized?.options.resourceLimits ??
              captureISpectLogDataForEgress(first).resourceLimits)
          ..validate();
    final sb = StringBuffer();
    for (final data in this) {
      final pretty = JsonTruncator.pretty(
        data.toJson(truncated: true),
        maxDepth: limits.maxTraversalDepth,
        maxIterableSize: limits.maxCollectionItems,
        maxStringLength: limits.maxUiDiagnosticBytes,
      );
      sb
        ..writeln(
          '\n${LogExportOutput.truncateUtf8(pretty, maxBytes: limits.maxUiDiagnosticBytes)}',
        )
        ..writeln('\n${ConsoleUtils.bottomLine(100)}');
    }
    return LogExportOutput.truncateUtf8(
      sb.toString().trim(),
      maxBytes: limits.maxExportDocumentBytes,
    );
  }
}
