import 'package:ispectify/ispectify.dart';

/// Log entry produced when a Dart [Error] is captured by the logger.
///
/// Serialized with `key: ISpectLogType.error.key` and [LogLevel.error]. The
/// original [Error] is stored on [ISpectLogData.error] and the optional
/// stack trace on [ISpectLogData.stackTrace].
base class ISpectLogError extends ISpectLogData {
  /// Creates an error log entry wrapping [error] with an optional
  /// human-readable [message] and [stackTrace].
  ISpectLogError(
    Error error, {
    Object? message,
    StackTrace? stackTrace,
    DateTime? time,
    LogLevel? logLevel,
    AnsiPen? pen,
    String? key,
    Map<String, dynamic>? additionalData,
    String? id,
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) : super(
          message,
          error: error,
          stackTrace: stackTrace,
          time: time,
          logLevel: logLevel ?? LogLevel.error,
          pen: pen,
          key: key ?? ISpectLogType.error.key,
          additionalData: additionalData,
          id: id,
          captureMode: captureMode,
          resourceLimits: resourceLimits,
        );

  @override
  void notifyObserver(ISpectObserver observer) {
    observer.onError(this);
  }
}
