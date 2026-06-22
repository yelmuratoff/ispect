/// Canonical JSON key names used across BLoC observer events.
///
/// Centralizes string literals so every lifecycle event produces structurally
/// consistent metadata, mirroring `NetworkJsonKeys` in the network packages.
///
/// Usage:
/// ```dart
/// final map = <String, dynamic>{
///   BlocJsonKeys.blocType: 'AuthBloc',
///   BlocJsonKeys.eventType: 'SignIn',
/// };
/// ```
abstract final class BlocJsonKeys {
  // ---------------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------------

  static const String blocType = 'bloc-type';
  static const String eventType = 'event-type';

  // ---------------------------------------------------------------------------
  // Payload
  // ---------------------------------------------------------------------------

  static const String event = 'event';

  // ---------------------------------------------------------------------------
  // State transition
  // ---------------------------------------------------------------------------

  static const String currentState = 'current-state';
  static const String nextState = 'next-state';

  // ---------------------------------------------------------------------------
  // Completion
  // ---------------------------------------------------------------------------

  static const String hasError = 'has-error';
}
