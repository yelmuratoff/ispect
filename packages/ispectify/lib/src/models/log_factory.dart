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
    Map<String, dynamic>? additionalData,
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
      additionalData: additionalData,
    );
  }
}
