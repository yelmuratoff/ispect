import 'package:ispectify/src/models/log_level.dart';

/// Determines whether a log message should be recorded
/// based on its content and log level.
abstract class ILoggerFilter {
  const ILoggerFilter();

  /// Returns `true` if the log should be recorded.
  bool shouldLog(Object? msg, LogLevel level);
}

/// Filters logs by a [LogLevel] range (inclusive).
///
/// Only logs with `minLevel.index <= level.index <= maxLevel.index` pass.
/// See [LogLevel] for the severity ordering.
class LogLevelRangeFilter extends ILoggerFilter {
  /// Throws [ArgumentError] if `minLevel.index > maxLevel.index`.
  factory LogLevelRangeFilter({
    LogLevel minLevel = LogLevel.critical,
    LogLevel maxLevel = LogLevel.verbose,
  }) {
    if (minLevel.index > maxLevel.index) {
      throw ArgumentError(
        'minLevel ($minLevel) must have lower or equal index than maxLevel ($maxLevel). '
        'Lower index means higher severity.',
      );
    }
    return LogLevelRangeFilter._(minLevel: minLevel, maxLevel: maxLevel);
  }

  const LogLevelRangeFilter._({
    required this.minLevel,
    required this.maxLevel,
  });

  final LogLevel minLevel;
  final LogLevel maxLevel;

  @override
  bool shouldLog(Object? msg, LogLevel level) =>
      level.index >= minLevel.index && level.index <= maxLevel.index;
}
