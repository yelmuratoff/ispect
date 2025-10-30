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
  ]) =>
      switch (exception) {
        final ISpectLogError logError => logError,
        final ISpectLogException logException => logException,
        final Error err => ISpectLogError(
            err,
            title: settings.titleByKey(ISpectLogType.error.key),
            message: msg,
            stackTrace: stackTrace,
          ),
        final Exception ex => ISpectLogException(
            ex,
            title: settings.titleByKey(ISpectLogType.exception.key),
            message: msg,
            stackTrace: stackTrace,
          ),
        _ => ISpectLogData(
            exception.toString(),
            key: ISpectLogType.error.key,
            title: settings.titleByKey(ISpectLogType.error.key),
            logLevel: LogLevel.error,
            stackTrace: stackTrace,
          ),
      };
}
