/// Canonical JSON key names used across Riverpod observer events.
///
/// Centralizes string literals so every lifecycle event produces structurally
/// consistent metadata, mirroring `NetworkJsonKeys` in the network packages.
///
/// Usage:
/// ```dart
/// final map = <String, dynamic>{
///   RiverpodJsonKeys.providerName: 'counter',
///   RiverpodJsonKeys.providerType: 'StateProvider<int>',
/// };
/// ```
abstract final class RiverpodJsonKeys {
  // ---------------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------------

  static const String providerName = 'provider-name';
  static const String providerType = 'provider-type';
  static const String argument = 'argument';

  // ---------------------------------------------------------------------------
  // Value payload
  // ---------------------------------------------------------------------------

  static const String value = 'value';
  static const String valueType = 'value-type';

  static const String previousValue = 'previous-value';
  static const String previousValueType = 'previous-value-type';

  static const String newValue = 'new-value';
  static const String newValueType = 'new-value-type';

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  static const String errorType = 'error-type';
}
