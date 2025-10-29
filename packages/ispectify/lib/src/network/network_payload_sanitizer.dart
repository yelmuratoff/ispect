import 'package:ispectify/ispectify.dart';

/// Provides reusable sanitization helpers for network payloads.
///
/// Handles string-key normalization, optional redaction, and conversion of
/// arbitrary values into map representations consumable by log models.
class NetworkPayloadSanitizer {
  NetworkPayloadSanitizer(this._redactor);

  final RedactionService _redactor;

  /// Returns a string-keyed map of headers, applying redaction when enabled.
  Map<String, dynamic> headersMap(
    Map<dynamic, dynamic>? headers, {
    required bool enableRedaction,
  }) {
    final typed = stringKeyMap(headers);
    if (!enableRedaction) return typed;
    final redacted = _redactor.redactHeaders(typed);
    return Map<String, dynamic>.from(redacted);
  }

  /// Returns null if the headers map is empty after sanitization.
  Map<String, dynamic>? headersOrNull(
    Map<dynamic, dynamic>? headers, {
    required bool enableRedaction,
  }) {
    final sanitized = headersMap(headers, enableRedaction: enableRedaction);
    return sanitized.isEmpty ? null : sanitized;
  }

  /// Redacts (if enabled) and returns the provided body, optionally applying
  /// a [normalizer] before redaction.
  Object? body(
    Object? data, {
    required bool enableRedaction,
    Object? Function(Object? value)? normalizer,
  }) {
    final normalized = normalizer != null ? normalizer(data) : data;
    if (!enableRedaction) return normalized;
    return _redactor.redact(normalized) ?? normalized;
  }

  /// Ensures the value is represented as a string-keyed map. Non-map values are
  /// wrapped in `{ 'data': value }`.
  Map<String, dynamic> ensureMap(Object? value) {
    if (value == null) return <String, dynamic>{};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return stringKeyMap(value);
    return <String, dynamic>{'data': value};
  }

  /// Converts a map with arbitrary key types into a string-keyed map.
  Map<String, dynamic> stringKeyMap(Map<dynamic, dynamic>? input) {
    if (input == null || input.isEmpty) return <String, dynamic>{};
    return input.map((key, value) => MapEntry(key.toString(), value));
  }

  /// Returns null when the provided map is null or empty; otherwise returns the map.
  Map<K, V>? nullIfEmpty<K, V>(Map<K, V>? map) =>
      map == null || map.isEmpty ? null : map;
}
