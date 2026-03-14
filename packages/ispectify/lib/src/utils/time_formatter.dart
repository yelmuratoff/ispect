/// A utility class for formatting `DateTime` objects into readable strings.
///
/// Provides various time formatting styles, including full timestamps
/// and time with milliseconds.
class ISpectDateTimeFormatter {
  /// Creates an instance of `ISpectDateTimeFormatter` with the given [date].
  const ISpectDateTimeFormatter(this.date);

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

  /// Returns the default formatted time representation.
  ///
  /// Uses `timeAndSeconds` as the standard compact format.
  String get format => date == null ? '' : timeAndSeconds;

  /// Returns a human-readable relative time string (e.g. "2s ago", "5m ago").
  ///
  /// Falls back to absolute format for durations > 24h.
  String get relativeFormat {
    if (date == null) return '';
    final diff = DateTime.now().difference(date!);
    if (diff.isNegative) return 'just now';
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return format;
  }

  /// Pads single-digit values with a leading zero.
  ///
  /// Ensures that time and date components have a consistent two-digit format.
  String _pad(int value) => value.toString().padLeft(2, '0');
}
