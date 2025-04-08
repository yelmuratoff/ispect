/// A utility class for formatting `DateTime` objects into readable strings.
///
/// Provides various time formatting styles, including full timestamps
/// and time with milliseconds.
class ISpectifyDateTimeFormatter {
  /// Creates an instance of `ISpectifyDateTimeFormatter` with the given [date].
  const ISpectifyDateTimeFormatter(this.date);

  /// The `DateTime` instance to be formatted.
  final DateTime? date;

  /// Returns the formatted time with hours, minutes, seconds, and milliseconds.
  ///
  /// Format: `HH:MM:SS | Xms`
  String get timeAndSeconds {
    if (date == null) return '';

    return '${_pad(date!.hour)}:${_pad(date!.minute)}:${_pad(date!.second)} | ${date!.millisecond}ms';
  }

  /// Returns the full formatted date and time.
  ///
  /// Format: `DD.MM.YYYY | HH:MM:SS | Xms`
  String get fullTime {
    if (date == null) return '';

    return '${_pad(date!.day)}.${_pad(date!.month)}.${date!.year} | $timeAndSeconds';
  }

  /// Returns the default formatted date-time representation.
  ///
  /// Uses `fullTime` as the standard format.
  String get format => date == null ? '' : fullTime;

  /// Pads single-digit values with a leading zero.
  ///
  /// Ensures that time and date components have a consistent two-digit format.
  String _pad(int value) => value.toString().padLeft(2, '0');
}
