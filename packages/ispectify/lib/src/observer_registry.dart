import 'dart:collection';

import 'package:ispectify/ispectify.dart';

/// Internal utility to manage `ISpectObserver` lifecycle and notifications.
///
/// Keeps insertion order, prevents duplicates, and isolates notification
/// error handling from the main logger.
class ObserverRegistry {
  final LinkedHashSet<ISpectObserver> _observers =
      LinkedHashSet<ISpectObserver>();

  bool get hasObservers => _observers.isNotEmpty;

  void clear() => _observers.clear();

  void add(ISpectObserver observer) {
    _observers.add(observer);
  }

  void remove(ISpectObserver observer) {
    _observers.remove(observer);
  }

  /// Replaces all observers with a single [observer]. If [observer] is null,
  /// clears the registry.
  void replaceWith(ISpectObserver? observer) {
    _observers.clear();
    if (observer != null) {
      _observers.add(observer);
    }
  }

  /// Registers an observer and returns a disposer to remove it later.
  ISpectObserverDisposer observe(ISpectObserver observer) {
    add(observer);
    return () => remove(observer);
  }

  /// Notifies all observers using [notify]. Any exceptions thrown by an
  /// observer callback are caught and logged via [consoleLogger].
  void notify(
    void Function(ISpectObserver) notify,
    ISpectBaseLogger consoleLogger,
  ) {
    if (_observers.isEmpty) return;
    for (final observer in _observers) {
      try {
        notify(observer);
      } catch (e, st) {
        consoleLogger.log(
          'Observer error: $e\n$st',
          level: LogLevel.error,
        );
      }
    }
  }
}
 
