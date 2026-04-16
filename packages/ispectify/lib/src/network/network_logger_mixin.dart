import 'package:ispectify/src/ispectify.dart';

/// Mixin providing core logging utilities for network interceptors.
///
/// Implementing classes must provide [logger].
mixin NetworkLoggerMixin {
  /// The logger instance for network logging.
  ///
  /// Implementing classes must override this to return their logger.
  ISpectLogger get logger;

  /// Normalises a raw map value to `Map<String, dynamic>`, or returns `null`.
  ///
  /// Accepts both `Map<String, dynamic>` and wider `Map` types (e.g. from Dio
  /// response headers). Returns `null` when [value] is not a map at all.
  static Map<String, dynamic>? asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  /// Returns `true` when the interceptor is [enabled] and the optional
  /// [filter] either is `null` or returns `true` for [value].
  ///
  /// Consolidates the `settings.enabled && (filter?.call(x) ?? true)` pattern
  /// used across all network interceptors.
  bool shouldProcess<T>({
    required bool enabled,
    required bool Function(T)? filter,
    required T value,
  }) =>
      enabled && (filter?.call(value) ?? true);
}
