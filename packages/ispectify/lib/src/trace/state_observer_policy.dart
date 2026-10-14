import 'package:ispectify/ispectify.dart';

/// Capture gates and filter matching shared by the BLoC and Riverpod
/// observers.
abstract final class StateObserverPolicy {
  /// Whether an observer may log.
  ///
  /// Requires the compile-time [kISpectEnabled] gate, an enabled [logger], and
  /// [settingsEnabled]. [debugEnabledOverride] can only narrow the
  /// compile-time gate.
  static bool loggingEnabled({
    required ISpectLogger logger,
    required bool settingsEnabled,
    bool? debugEnabledOverride,
  }) =>
      kISpectEnabled &&
      (debugEnabledOverride ?? true) &&
      logger.isEnabled &&
      settingsEnabled;

  /// Whether [loggingEnabled] holds and [logger] has an active consumer.
  static bool captureEnabled({
    required ISpectLogger logger,
    required bool settingsEnabled,
    bool? debugEnabledOverride,
  }) =>
      loggingEnabled(
        logger: logger,
        settingsEnabled: settingsEnabled,
        debugEnabledOverride: debugEnabledOverride,
      ) &&
      logger.hasActiveConsumers;

  /// Whether [candidate] contains any of [patterns].
  ///
  /// A pattern that throws does not match. [isEnabled] is re-checked after
  /// every pattern because a [Pattern] runs caller code; once it returns
  /// `false` the candidate counts as matched, so the event is dropped.
  static bool matchesAnyPattern(
    String candidate,
    Iterable<Pattern> patterns, {
    required bool Function() isEnabled,
  }) {
    for (final pattern in patterns) {
      var matches = false;
      try {
        matches = candidate.contains(pattern);
      } catch (_) {}
      if (!isEnabled()) return true;
      if (matches) return true;
    }
    return false;
  }
}
