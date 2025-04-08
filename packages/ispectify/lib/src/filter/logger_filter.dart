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
class LoggerFilter extends ILoggerFilter {
  /// Creates a `LoggerFilter` with a minimum and maximum log level range.
  ///
  /// Logs outside of this range will be ignored.
  ///
  /// - `minLevel`: The lowest log level that should be recorded (default: `LogLevel.debug`).
  /// - `maxLevel`: The highest log level that should be recorded (default: `LogLevel.critical`).
  const LoggerFilter({
    this.minLevel = LogLevel.debug,
    this.maxLevel = LogLevel.critical,
  });

  /// The minimum log level that should be recorded.
  final LogLevel minLevel;

  /// The maximum log level that should be recorded.
  final LogLevel maxLevel;

  @override
  bool shouldLog(Object? msg, LogLevel level) =>
      level.index >= minLevel.index && level.index <= maxLevel.index;
}
