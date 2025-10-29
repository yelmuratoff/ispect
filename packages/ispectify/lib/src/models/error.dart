import 'package:ispectify/ispectify.dart';

class ISpectifyError extends ISpectifyData {
  ISpectifyError(
    Error error, {
    String? message,
    super.stackTrace,
    super.title,
  }) : super(
          message,
          error: error,
          key: ISpectifyLogType.error.key,
          logLevel: LogLevel.error,
        );

  @override
  String get textMessage => '$messageText$errorText$stackTraceText';

  @override
  void notifyObserver(ISpectObserver observer) {
    observer.onError(this);
  }
}
