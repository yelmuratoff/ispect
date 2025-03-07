import 'package:ispectify/ispectify.dart';

/// Extension on [List<ISpectifyData>] to format history text output.
///
/// This extension provides a formatted string representation of the list,
/// where each message is followed by a separator line.
extension HistoryListFlutterText on List<ISpectifyData> {
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
        ..writeln(data.textMessage) // Ensures newline after text.
        ..writeln(ConsoleUtils.bottomLine(30)); // Separator line.
    }
    return sb.toString().trim(); // Trim trailing newline for cleaner output.
  }
}
