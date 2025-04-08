import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/error.dart';
import 'package:ispectify/src/models/exception.dart';

/// An abstract observer class for monitoring ISpectify events.
///
/// Implementations of this class can listen to errors, exceptions, and log events.
abstract class ISpectifyObserver {
  /// Creates an instance of `ISpectifyObserver`.
  const ISpectifyObserver();

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
