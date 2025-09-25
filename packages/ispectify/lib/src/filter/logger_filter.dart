import 'package:ispectify/src/models/log_level.dart';

/// An abstract class defining a logger filter interface.
///
/// Implementations determine whether a log message should be recorded
/// based on its content and log level.
abstract class ILoggerFilter {
  /// Default constructor for the logger filter.
  const ILoggerFilter();

  /// Determines if a log entry should be recorded.
  ///
  /// - `msg`: The log message to evaluate.
  /// - `level`: The log level associated with the message.
  ///
  /// Returns `true` if the log should be recorded, otherwise `false`.
  bool shouldLog(Object? msg, LogLevel level);
}

/// A concrete implementation of `ILoggerFilter` that filters logs
/// based on a specified log level range.
///
/// Log levels are ordered by severity where lower index = higher severity:
/// - `LogLevel.critical` (0) - Most severe
/// - `LogLevel.error` (1)
/// - `LogLevel.warning` (2)
/// - `LogLevel.info` (3)
/// - `LogLevel.debug` (4)
/// - `LogLevel.verbose` (5) - Least severe
///
/// The filter includes levels where: `minLevel.index <= level.index <= maxLevel.index`
class LoggerFilter extends ILoggerFilter {
  /// Creates a `LoggerFilter` with a minimum and maximum log level range.
  ///
  /// Logs outside of this range will be ignored.
  ///
  /// - `minLevel`: The lowest log level that should be recorded (default: `LogLevel.critical`).
  /// - `maxLevel`: The highest log level that should be recorded (default: `LogLevel.verbose`).
  ///
  /// Throws [ArgumentError] if `minLevel.index > maxLevel.index`.
  factory LoggerFilter({
    LogLevel minLevel = LogLevel.critical,
    LogLevel maxLevel = LogLevel.verbose,
  }) {
    if (minLevel.index > maxLevel.index) {
      throw ArgumentError(
        'minLevel ($minLevel) must have lower or equal index than maxLevel ($maxLevel). '
        'Lower index means higher severity.',
      );
    }
    return LoggerFilter._(minLevel: minLevel, maxLevel: maxLevel);
  }

  const LoggerFilter._({
    required this.minLevel,
    required this.maxLevel,
  });

  /// The minimum log level that should be recorded.
  final LogLevel minLevel;

  /// The maximum log level that should be recorded.
  final LogLevel maxLevel;

  @override
  bool shouldLog(Object? msg, LogLevel level) =>
      level.index >= minLevel.index && level.index <= maxLevel.index;
}
