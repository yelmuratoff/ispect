import 'package:ispectify/src/models/data.dart';

/// An abstract observer class for monitoring ISpectify events.
///
/// Implementations of this class can listen to errors, exceptions, and log events.
abstract interface class ISpectObserver {
  /// Creates an instance of `ISpectObserver`.
  const ISpectObserver();

  /// Called when an `ISpectifyError` is reported.
  ///
  /// Override this method to handle errors.
  void onError(ISpectifyData err) {}

  /// Called when an `ISpectifyException` is reported.
  ///
  /// Override this method to handle exceptions.
  void onException(ISpectifyData err) {}

  /// Called when an `ISpectifyData` log entry is recorded.
  ///
  /// Override this method to handle logs.
  void onLog(ISpectifyData log) {}
}
