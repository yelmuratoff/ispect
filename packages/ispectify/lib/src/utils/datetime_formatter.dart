/// A utility class for formatting `DateTime` objects into readable strings.
///
/// Provides various time formatting styles, including full timestamps
/// and time with milliseconds.
class ISpectDateTimeFormatter {
  /// Creates an instance of [ISpectDateTimeFormatter] with the given [date].
  const ISpectDateTimeFormatter(this.date);

  /// The `DateTime` instance to be formatted.
  final DateTime? date;

  /// Returns the formatted time with hours, minutes, seconds, and milliseconds.
  ///
  /// Format: `HH:MM:SS.mmm`
  ///
  /// Milliseconds are appended as a decimal part of the timestamp — they
  /// represent the fractional second, not a duration. Real durations (e.g.
  /// elapsed time of a traced operation) are rendered separately by the
  /// trace helpers.
  String get timeAndSeconds {
    final d = date;
    if (d == null) return '';

    return '${_pad(d.hour)}:${_pad(d.minute)}:${_pad(d.second)}.${_pad3(d.millisecond)}';
  }

  /// Returns the full formatted date and time.
  ///
  /// Format: `DD.MM.YYYY | HH:MM:SS | Xms`
  String get fullTime {
    final d = date;
    if (d == null) return '';

    return '${_pad(d.day)}.${_pad(d.month)}.${d.year} | $timeAndSeconds';
  }

  /// Returns the default compact time representation.
  ///
  /// Uses [timeAndSeconds] as the standard format.
  String get defaultFormat => date == null ? '' : timeAndSeconds;

  /// Returns a localized human-readable relative time string.
  ///
  /// Uses [now] for computing the difference (defaults to [DateTime.now]).
  /// Falls back to [defaultFormat] for durations > 24h.
  String relativeFormat({
    required String justNow,
    required String Function(int count) secondsAgo,
    required String Function(int count) minutesAgo,
    required String Function(int count) hoursAgo,
    DateTime? now,
  }) {
    if (date == null) return '';
    final diff = (now ?? DateTime.now()).difference(date!);
    if (diff.isNegative || diff.inSeconds < 5) return justNow;
    if (diff.inSeconds < 60) return secondsAgo(diff.inSeconds);
    if (diff.inMinutes < 60) return minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return hoursAgo(diff.inHours);
    return defaultFormat;
  }

  /// Pads single-digit values with a leading zero.
  String _pad(int value) => value.toString().padLeft(2, '0');

  /// Pads millisecond values to three digits.
  String _pad3(int value) => value.toString().padLeft(3, '0');
}
