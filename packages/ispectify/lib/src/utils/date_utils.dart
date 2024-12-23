/// A utility class for working with date and time formatting.
///
/// The [DateUtils] class provides a static method to format a [DateTime]
/// object into a human-readable string. This class is non-instantiable
/// and only provides static functionality.
final class DateUtils {
  /// Prevents instantiation of [DateUtils].
  /// This is a utility class and should not be instantiated.
  const DateUtils._();

  /// Formats a [DateTime] object into a string in the `DD.MM.YYYY HH:mm:ss` format.
  ///
  /// The method takes a [DateTime] object and converts it to a string where:
  /// - `DD`: Day of the month (2 digits, zero-padded)
  /// - `MM`: Month of the year (2 digits, zero-padded)
  /// - `YYYY`: Full year
  /// - `HH`: Hour of the day (24-hour format, 2 digits, zero-padded)
  /// - `mm`: Minute of the hour (2 digits, zero-padded)
  /// - `ss`: Second of the minute (2 digits, zero-padded)
  ///
  /// ### Example:
  /// ```dart
  /// final now = DateTime.now();
  /// print(DateUtils.format(now)); // Output: 23.12.2024 14:05:09
  /// ```
  ///
  /// - [date]: The [DateTime] object to format.
  ///
  /// Returns:
  /// A string representation of the date and time in `DD.MM.YYYY HH:mm:ss` format.
  static String format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute:$second';
  }
}
