import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/utils/log_message_formatter.dart';

class ISpectLogException extends ISpectLogData {
  ISpectLogException(
    Exception exception, {
    String? message,
    super.stackTrace,
    super.title,
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
