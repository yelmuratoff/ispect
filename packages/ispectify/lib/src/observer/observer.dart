import 'package:ispectify/src/models/data.dart';

/// Observer for monitoring ISpectLogger events.
///
/// Subclass and override only the methods you need.
abstract class ISpectObserver {
  const ISpectObserver();

  /// Called when an error-level log is reported.
  void onError(ISpectLogData data) {}

  /// Called when an exception-level log is reported.
  void onException(ISpectLogData data) {}

  /// Called when a general log entry is recorded.
  void onLog(ISpectLogData data) {}
}
