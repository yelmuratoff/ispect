import 'package:ispectify/ispectify.dart';

/// Creates [ISpectLogData] entries with consistent configuration
/// from [ISpectLoggerOptions].
abstract class LogFactory {
  /// Creates a log entry for [type], optionally overriding the default [level].
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
