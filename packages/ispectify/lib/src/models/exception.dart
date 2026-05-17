import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_parts.dart';

/// Log entry produced when a Dart [Exception] is captured by the logger.
///
/// Serialized with `key: ISpectLogType.exception.key` and [LogLevel.error].
/// The original [Exception] is stored on [ISpectLogData.exception] and the
/// optional stack trace on [ISpectLogData.stackTrace].
base class ISpectLogException extends ISpectLogData {
  /// Creates an exception log entry wrapping [exception] with an optional
  /// human-readable [message] and [stackTrace].
  ISpectLogException(
    Exception exception, {
    String? message,
    super.stackTrace,
  }) : super(
          message,
          exception: exception,
          key: ISpectLogType.exception.key,
          logLevel: LogLevel.error,
        );

  @override
  String get textMessage => joinLogParts([
        messageText,
        exceptionText,
        stackTraceText,
      ]);

  @override
  void notifyObserver(ISpectObserver observer) {
    observer.onException(this);
  }
}
