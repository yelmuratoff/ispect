import 'package:ispectify/ispectify.dart';

class ISpectifyError extends ISpectiyData {
  ISpectifyError(
    Error error, {
    String? message,
    super.stackTrace,
    String? key,
    super.title,
    LogLevel? logLevel,
  }) : super(
          message,
          error: error,
          key: ISpectifyLogType.error.key,
          logLevel: LogLevel.error,
        );

  @override
  String get textMessage {
    return '$messageText$errorText$stackTraceText';
  }
}
