import 'package:ispectify/src/models/models.dart';

/// Base observer class for
/// to create your own observers
abstract class ISpectifyObserver {
  const ISpectifyObserver();

  /// Called when [ISpectiy] handle an [ISpectifyError]
  void onError(ISpectifyError err) {}

  /// Called when [ISpectiy] handle an [ISpectifyException]
  void onException(ISpectifyException err) {}

  /// Called when [ISpectiy] handle an [ISpectiyData] log
  void onLog(ISpectiyData log) {}
}
