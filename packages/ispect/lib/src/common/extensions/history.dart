import 'package:ispect/ispect.dart';

/// Extension on `List<ISpectLogData>` to format history text output.
///
/// This extension provides a formatted string representation of the list,
/// where each message is followed by a separator line.
extension HistoryListFlutterText on List<ISpectLogData> {
  /// Returns a formatted string representation of the history list.
  ///
  /// Each message in the list is separated by a horizontal line of length 30.
  /// Ensures proper spacing for readability.
  ///
  /// ### Example:
  /// ```dart
  /// print(history.formattedText);
  /// ```
  ///
  /// **Output:**
  /// ```
  /// First log
  /// ──────────────────────────────
  /// Second log
  /// ──────────────────────────────
  /// ```
  String get formattedText {
    if (isEmpty) return ''; // Handle empty list case.

    final sb = StringBuffer();
    for (final data in this) {
      sb
        ..writeln(
          '\n${JsonTruncatorService.pretty(
            data.toJson(truncated: true),
          ).truncate()}',
        ) // Ensures newline after text.
        ..writeln('\n${ConsoleUtils.bottomLine(100)}'); // Separator line.
    }
    return sb.toString().trim(); // Trim trailing newline for cleaner output.
  }
}
