import 'package:ispectify/ispectify.dart';
import 'package:meta/meta.dart';

/// Log entry produced when a Dart [Exception] is captured by the logger.
///
/// Serialized with `key: ISpectLogType.exception.key` and [LogLevel.error].
/// The original [Exception] is stored on [ISpectLogData.exception] and the
/// optional stack trace on [ISpectLogData.stackTrace].
base class ISpectLogException extends ISpectLogData {
  /// Creates an exception log entry wrapping [exception] with an optional
  /// human-readable [message] and [stackTrace].
  ISpectLogException(
    Exception exception, {
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
    @internal DiagnosticMasker? maskAdditionalData,
  }) : super(
          message,
          exception: exception,
          stackTrace: stackTrace,
          time: time,
          logLevel: logLevel ?? LogLevel.error,
          pen: pen,
          key: key ?? ISpectLogType.exception.key,
          additionalData: additionalData,
          id: id,
          captureMode: captureMode,
          resourceLimits: resourceLimits,
          maskAdditionalData: maskAdditionalData,
        );

  @override
  void notifyObserver(ISpectObserver observer) {
    observer.onException(this);
  }
}
