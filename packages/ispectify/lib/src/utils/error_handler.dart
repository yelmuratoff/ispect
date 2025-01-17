import 'package:ispectify/ispectify.dart';

class ISpectifyErrorHandler {
  const ISpectifyErrorHandler(this.settings);

  final ISpectifyOptions settings;

  ISpectiyData handle(
    Object exception, [
    StackTrace? stackTrace,
    String? msg,
  ]) {
    if (exception is ISpectifyError) {
      return exception;
    } else if (exception is ISpectifyException) {
      return exception;
    } else if (exception is Error) {
      return ISpectifyError(
        exception,
        title: settings.titleByKey(
          ISpectifyLogType.error.key,
        ),
        message: msg,
        stackTrace: stackTrace,
      );
    } else if (exception is Exception) {
      return ISpectifyException(
        exception,
        title: settings.titleByKey(
          ISpectifyLogType.exception.key,
        ),
        message: msg,
        stackTrace: stackTrace,
      );
    } else {
      return ISpectifyLog(
        exception.toString(),
        key: ISpectifyLogType.error.key,
        title: settings.titleByKey(
          ISpectifyLogType.error.key,
        ),
        logLevel: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }
}
