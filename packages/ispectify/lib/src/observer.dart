import 'package:ispectify/src/models/models.dart';

/// Base observer class for
/// to create your own observers
abstract class ISpectifyObserver {
  const ISpectifyObserver();

  /// Called when [ISpectiy] handle an [TalkerError]
  void onError(TalkerError err) {}

  /// Called when [ISpectiy] handle an [TalkerException]
  void onException(TalkerException err) {}

  /// Called when [ISpectiy] handle an [ISpectiyData] log
  void onLog(ISpectiyData log) {}
}
