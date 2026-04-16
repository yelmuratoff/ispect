import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_parts.dart';

base class ISpectLogError extends ISpectLogData {
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
