import 'package:ispectify/ispectify.dart';

class ISpectifyException extends ISpectiyData {
  ISpectifyException(
    Exception exception, {
    String? message,
    super.stackTrace,
    String? key,
    super.title,
    LogLevel? logLevel,
  }) : super(
          message,
          exception: exception,
          key: ISpectifyLogType.exception.key,
          logLevel: LogLevel.error,
        );

  @override
  String get textMessage {
    return '$messageText$exceptionText$stackTraceText';
  }
}
