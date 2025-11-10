import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/observer_registry.dart';

/// Manages lifecycle and notification of `ISpectObserver`s for a logger.
///
/// Encapsulates the registry and delegates error logging to the provided
/// console logger getter to avoid tight coupling with the logger internals.
class ObserverManager {
  ObserverManager(ISpectBaseLogger Function() consoleLogger)
      : _getConsoleLogger = consoleLogger;

  final ISpectBaseLogger Function() _getConsoleLogger;
  final ObserverRegistry _registry = ObserverRegistry();

  bool get hasObservers => _registry.hasObservers;

  void clear() => _registry.clear();

  void add(ISpectObserver observer) => _registry.add(observer);

  void remove(ISpectObserver observer) => _registry.remove(observer);

  /// Replaces all observers with a single [observer]. If null, clears all.
  void replace(ISpectObserver? observer) => _registry.replaceWith(observer);

  /// Registers an observer and returns a disposer to remove it later.
  ISpectObserverDisposer observe(ISpectObserver observer) =>
      _registry.observe(observer);

  /// Notifies all observers safely using the current console logger.
  void notify(void Function(ISpectObserver) notify) =>
      _registry.notify(notify, _getConsoleLogger());
}
