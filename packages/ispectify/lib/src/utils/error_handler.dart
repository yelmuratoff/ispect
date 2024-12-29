import 'package:ispectify/ispectify.dart';

class ISpectifyErrorHandler {
  ISpectifyErrorHandler(this.settings);

  final ISpectifyOptions settings;

  ISpectiyData handle(
    Object exception, [
    StackTrace? stackTrace,
    String? msg,
  ]) {
    if (exception is ISpectifyError) {
      return exception;
    }
    if (exception is ISpectifyException) {
      return exception;
    }
    if (exception is Error) {
      final errType = ISpectifyLogType.error;
      return ISpectifyError(
        exception,
        key: errType.key,
        title: settings.getTitleByLogKey(errType.key),
        message: msg,
        stackTrace: stackTrace,
      );
    }
    if (exception is Exception) {
      final exceptionType = ISpectifyLogType.exception;
      return ISpectifyException(
        exception,
        key: exceptionType.key,
        title: settings.getTitleByLogKey(exceptionType.key),
        message: msg,
        stackTrace: stackTrace,
      );
    }
    final errType = ISpectifyLogType.error;
    return ISpectifyLog(
      exception.toString(),
      key: errType.key,
      title: settings.getTitleByLogKey(errType.key),
      logLevel: LogLevel.error,
      stackTrace: stackTrace,
    );
  }
}
