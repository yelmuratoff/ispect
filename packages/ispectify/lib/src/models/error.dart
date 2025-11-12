import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/utils/log_message_formatter.dart';

class ISpectLogError extends ISpectLogData {
  ISpectLogError(
    Error error, {
    String? message,
    super.stackTrace,
    super.title,
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
