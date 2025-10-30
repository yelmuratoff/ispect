import 'package:ispectify/ispectify.dart';

/// Factory class for creating log entries with consistent configuration.
///
/// This factory centralizes log creation logic and ensures all logs are
/// created with proper settings from ISpectLoggerOptions.
class LogFactory {
  const LogFactory._();

  /// Creates a log entry using an explicit [ISpectLogType].
  ///
  /// The [level] parameter allows overriding the default level derived from
  /// the provided [type].
  static ISpectLogData fromType({
    required ISpectLogType type,
    required Object? message,
    LogLevel? level,
    Object? exception,
    StackTrace? stackTrace,
    AnsiPen? pen,
    ISpectLoggerOptions? options,
  }) {
    final resolvedLevel = level ?? type.level;
    return ISpectLogData(
      message?.toString() ?? '',
      key: type.key,
      title: options?.titleByKey(type.key),
      exception: exception,
      stackTrace: stackTrace,
      pen: pen ?? options?.penByKey(type.key),
      logLevel: resolvedLevel,
    );
  }

  /// Creates a standardized log entry from the given parameters.
  ///
  /// - `level`: The severity level of the log
  /// - `message`: The log message content
  /// - `exception`: Optional exception associated with the log
  /// - `stackTrace`: Optional stack trace for debugging
  /// - `pen`: Optional custom styling for console output
  /// - `options`: Configuration options for title and pen defaults
  ///
  /// Returns an `ISpectLogData` instance configured according to the log level.
  static ISpectLogData createLog({
    required LogLevel level,
    required Object? message,
    Object? exception,
    StackTrace? stackTrace,
    AnsiPen? pen,
    ISpectLoggerOptions? options,
  }) {
    final type = ISpectLogType.fromLogLevel(level);
    return fromType(
      type: type,
      level: level,
      message: message,
      exception: exception,
      stackTrace: stackTrace,
      pen: pen,
      options: options,
    );
  }
}
