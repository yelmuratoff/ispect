import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_parts.dart';

class ISpectLogException extends ISpectLogData {
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
