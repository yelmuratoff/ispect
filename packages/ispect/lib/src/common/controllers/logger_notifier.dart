import 'package:flutter/foundation.dart';
import 'package:ispectify/ispectify.dart';

/// A [ValueNotifier] for [ISpectLogger] that exposes [notify] publicly,
/// allowing callers to signal that the logger's mutable state has changed
/// without requiring access to the protected [ChangeNotifier.notifyListeners].
class ISpectLoggerNotifier extends ValueNotifier<ISpectLogger> {
  // ignore: use_super_parameters
  ISpectLoggerNotifier(ISpectLogger value) : super(value);

  /// Notifies listeners that the logger's state has changed.
  void notify() => notifyListeners();
}
