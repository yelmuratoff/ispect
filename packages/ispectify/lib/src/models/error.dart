import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_parts.dart';

/// Log entry produced when a Dart [Error] is captured by the logger.
///
/// Serialized with `key: ISpectLogType.error.key` and [LogLevel.error]. The
/// original [Error] is stored on [ISpectLogData.error] and the optional
/// stack trace on [ISpectLogData.stackTrace].
base class ISpectLogError extends ISpectLogData {
  /// Creates an error log entry wrapping [error] with an optional
  /// human-readable [message] and [stackTrace].
  ISpectLogError(
    Error error, {
    String? message,
    super.stackTrace,
  }) : super(
          message,
          error: error,
          key: ISpectLogType.error.key,
          logLevel: LogLevel.error,
        );

  @override
  String get textMessage => joinLogParts([
        messageText,
        errorText,
        stackTraceText,
      ]);

  @override
  void notifyObserver(ISpectObserver observer) {
    observer.onError(this);
  }
}
