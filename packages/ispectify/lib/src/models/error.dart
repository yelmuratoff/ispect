import 'package:ispectify/ispectify.dart';

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
  String get textMessage => '$messageText$errorText$stackTraceText';

  @override
  void notifyObserver(ISpectObserver observer) {
    observer.onError(this);
  }
}
