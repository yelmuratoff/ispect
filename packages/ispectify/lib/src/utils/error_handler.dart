import 'package:ispectify/ispectify.dart';

/// A utility class for handling errors and exceptions in ISpectify.
class ISpectifyErrorHandler {
  /// Creates an instance of `ISpectifyErrorHandler` with the given settings.
  const ISpectifyErrorHandler(this.settings);

  /// Configuration settings for ISpectify.
  final ISpectifyOptions settings;

  /// Handles various types of exceptions and errors, converting them into
  /// `ISpectifyData` objects for consistent error reporting.
  ///
  /// - `exception`: The exception or error to handle.
  /// - `stackTrace`: Optional stack trace for debugging purposes.
  /// - `msg`: Optional custom message to include in the error data.
  ISpectifyData handle(
    Object exception, [
    StackTrace? stackTrace,
    String? msg,
  ]) {
    // If the exception is already an ISpectifyError, return it as is.
    if (exception is ISpectifyError) {
      return exception;
    }
    // If the exception is already an ISpectifyException, return it as is.
    else if (exception is ISpectifyException) {
      return exception;
    }
    // Handle Dart [Error] objects.
    else if (exception is Error) {
      return ISpectifyError(
        exception,
        title: settings.titleByKey(ISpectifyLogType.error.key),
        message: msg,
        stackTrace: stackTrace,
      );
    }
    // Handle Dart [Exception] objects.
    else if (exception is Exception) {
      return ISpectifyException(
        exception,
        title: settings.titleByKey(ISpectifyLogType.exception.key),
        message: msg,
        stackTrace: stackTrace,
      );
    }
    // Handle any other type of object as a generic error.
    else {
      return ISpectifyData(
        exception.toString(),
        key: ISpectifyLogType.error.key,
        title: settings.titleByKey(ISpectifyLogType.error.key),
        logLevel: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }
}
