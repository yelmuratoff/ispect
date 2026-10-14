import 'dart:collection';

import 'package:ispectify/ispectify.dart';

/// Internal utility to manage `ISpectObserver` lifecycle and notifications.
///
/// Keeps insertion order, prevents duplicates, and isolates notification
/// error handling from the main logger.
final class ObserverRegistry {
  final LinkedHashSet<ISpectObserver> _observers =
      LinkedHashSet<ISpectObserver>();

  List<ISpectObserver> _snapshot = const <ISpectObserver>[];

  bool get hasObservers => _observers.isNotEmpty;

  void clear() {
    _observers.clear();
    _refreshSnapshot();
  }

  void add(ISpectObserver observer) {
    if (_observers.add(observer)) _refreshSnapshot();
  }

  void remove(ISpectObserver observer) {
    if (_observers.remove(observer)) _refreshSnapshot();
  }

  /// Replaces all observers with a single [observer]. If [observer] is null,
  /// clears the registry.
  void replace(ISpectObserver? observer) {
    _observers.clear();
    if (observer != null) {
      _observers.add(observer);
    }
    _refreshSnapshot();
  }

  void _refreshSnapshot() {
    _snapshot = List<ISpectObserver>.unmodifiable(_observers);
  }

  /// Registers an observer and returns a disposer to remove it later.
  ISpectObserverDisposer observe(ISpectObserver observer) {
    add(observer);
    return () => remove(observer);
  }

  /// Notifies all observers using [notify]. Any exception thrown by an
  /// observer callback is caught and reported by its runtime type via
  /// [consoleLogger] when [options] enable console logs.
  void notify(
    void Function(ISpectObserver) notify, {
    required ISpectBaseLogger consoleLogger,
    required ISpectLoggerOptions options,
  }) {
    if (_observers.isEmpty) return;
    for (final observer in _snapshot) {
      try {
        notify(observer);
      } catch (error) {
        if (!options.useConsoleLogs) continue;
        try {
          final type = describeRuntimeType(
            error,
            captureMode: options.captureMode,
            fallback: 'unknown error',
          );
          consoleLogger.log(
            'Observer callback failed safely: $type',
            level: LogLevel.error,
          );
        } catch (_) {
          // Prevent cascading failures if console logging also fails.
        }
      }
    }
  }
}
