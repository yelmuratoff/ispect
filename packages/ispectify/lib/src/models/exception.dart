import 'package:ispectify/ispectify.dart';

class ISpectifyException extends ISpectiyData {
  ISpectifyException(
    Exception exception, {
    String? message,
    super.stackTrace,
    super.title,
  }) : super(
          message,
          exception: exception,
          key: ISpectifyLogType.exception.key,
          logLevel: LogLevel.error,
        );

  @override
  String get textMessage => '$messageText$exceptionText$stackTraceText';
}
