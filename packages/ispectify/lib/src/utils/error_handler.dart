import 'package:ispectify/ispectify.dart';

/// A utility class for handling errors and exceptions in ISpectLogger.
class ISpectErrorHandler {
  /// Creates an instance of `ISpectErrorHandler` with the given settings.
  const ISpectErrorHandler(this.settings);

  /// Configuration settings for ISpectLogger.
  final ISpectLoggerOptions settings;

  /// Handles various types of exceptions and errors, converting them into
  /// `ISpectLogData` objects for consistent error reporting.
  ///
  /// - `exception`: The exception or error to handle.
  /// - `stackTrace`: Optional stack trace for debugging purposes.
  /// - `msg`: Optional custom message to include in the error data.
  ISpectLogData handle(
    Object exception, [
    StackTrace? stackTrace,
    String? msg,
  ]) {
    // If the exception is already an ISpectLogError, return it as is.
    if (exception is ISpectLogError) {
      return exception;
    }
    // If the exception is already an ISpectLogException, return it as is.
    else if (exception is ISpectLogException) {
      return exception;
    }
    // Handle Dart [Error] objects.
    else if (exception is Error) {
      return ISpectLogError(
        exception,
        title: settings.titleByKey(ISpectLogType.error.key),
        message: msg,
        stackTrace: stackTrace,
      );
    }
    // Handle Dart [Exception] objects.
    else if (exception is Exception) {
      return ISpectLogException(
        exception,
        title: settings.titleByKey(ISpectLogType.exception.key),
        message: msg,
        stackTrace: stackTrace,
      );
    }
    // Handle any other type of object as a generic error.
    else {
      return ISpectLogData(
        exception.toString(),
        key: ISpectLogType.error.key,
        title: settings.titleByKey(ISpectLogType.error.key),
        logLevel: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }
}
