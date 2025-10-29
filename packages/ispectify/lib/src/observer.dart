import 'package:ispectify/src/models/data.dart';

/// An abstract observer class for monitoring ISpectLogger events.
///
/// Implementations of this class can listen to errors, exceptions, and log events.
abstract interface class ISpectObserver {
  /// Creates an instance of `ISpectObserver`.
  const ISpectObserver();

  /// Called when an `ISpectLogError` is reported.
  ///
  /// Override this method to handle errors.
  void onError(ISpectLogData err) {}

  /// Called when an `ISpectLogException` is reported.
  ///
  /// Override this method to handle exceptions.
  void onException(ISpectLogData err) {}

  /// Called when an `ISpectLogData` log entry is recorded.
  ///
  /// Override this method to handle logs.
  void onLog(ISpectLogData log) {}
}
