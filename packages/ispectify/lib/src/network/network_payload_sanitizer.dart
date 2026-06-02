import 'dart:convert';

import 'package:ispectify/ispectify.dart';

/// Provides reusable sanitization helpers for network payloads.
///
/// Handles string-key normalization, optional redaction, and conversion of
/// arbitrary values into map representations consumable by log models.
final class NetworkPayloadSanitizer {
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
  ///
  /// Also available as [toStringKeyMap] for call sites without a sanitizer
  /// instance (e.g. data serialization classes).
  Map<String, dynamic> stringKeyMap(Map<dynamic, dynamic>? input) =>
      toStringKeyMap(input);

  /// Converts a map with arbitrary key types into a `Map<String, dynamic>`.
  ///
  /// Static version of [stringKeyMap] for use without a sanitizer instance.
  static Map<String, dynamic> toStringKeyMap(Map<dynamic, dynamic>? input) {
    if (input == null || input.isEmpty) return <String, dynamic>{};
    return input.map((key, value) => MapEntry(key.toString(), value));
  }

  /// Returns null when the provided map is null or empty; otherwise returns the map.
  Map<K, V>? nullIfEmpty<K, V>(Map<K, V>? map) =>
      map == null || map.isEmpty ? null : map;

  /// Attempts to decode [value] as JSON; returns the original on failure.
  ///
  /// Returns `null` for empty strings. Non-string values pass through unchanged.
  /// Useful as a [body] normalizer for HTTP string responses that may be JSON.
  static Object? decodeJsonGracefully(Object? value) {
    if (value is! String) return value;
    if (value.isEmpty) return null;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  /// Renders a typed body via its `toJson()`; returns the original on failure.
  ///
  /// Values already representable as JSON (null, maps, collections, strings,
  /// numbers, booleans) pass through unchanged. Useful as a [body] normalizer
  /// for clients that pass DTOs (freezed/json_serializable) to the request as-is
  /// and serialize them only later, so logs would otherwise show `toString()`.
  static Object? encodeJsonGracefully(Object? value) {
    if (value == null ||
        value is Map ||
        value is Iterable ||
        value is String ||
        value is num ||
        value is bool) {
      return value;
    }
    try {
      return (value as dynamic).toJson();
    } on Object {
      return value;
    }
  }
}
