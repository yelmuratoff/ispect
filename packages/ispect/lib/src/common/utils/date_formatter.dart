/// Utility class for consistent date and time formatting across the application.
///
/// Provides standardized formatting methods for timestamps, file names,
/// and date-based operations. This ensures consistency and eliminates
/// duplicate formatting logic throughout the codebase.
abstract final class DateFormatter {
  /// Prevents instantiation of this utility class.
  const DateFormatter._();

  /// Formats a [DateTime] as a timestamp suitable for file naming.
  ///
  /// Returns a string in the format: `YYYY-MM-DD_HH-mm-ss`
  ///
  /// Example:
  /// ```dart
  /// final timestamp = DateFormatter.toFileTimestamp(DateTime(2025, 10, 29, 14, 30, 45));
  /// print(timestamp); // Output: 2025-10-29_14-30-45
  /// ```
  ///
  /// This format is:
  /// - Sortable (lexicographic order = chronological order)
  /// - Cross-platform compatible (no special characters)
  /// - Human-readable
  /// - Suitable for file system naming
  static String toFileTimestamp(DateTime dateTime) =>
      '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')}_'
      '${dateTime.hour.toString().padLeft(2, '0')}-'
      '${dateTime.minute.toString().padLeft(2, '0')}-'
      '${dateTime.second.toString().padLeft(2, '0')}';

  /// Formats the current date and time as a file timestamp.
  ///
  /// Convenience method equivalent to `toFileTimestamp(DateTime.now())`.
  ///
  /// Example:
  /// ```dart
  /// final timestamp = DateFormatter.nowAsFileTimestamp();
  /// // Returns current time in format: 2025-10-29_14-30-45
  /// ```
  static String nowAsFileTimestamp() => toFileTimestamp(DateTime.now());
}
