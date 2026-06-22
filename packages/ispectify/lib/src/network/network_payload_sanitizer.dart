import 'dart:convert';
import 'dart:typed_data';

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

  /// Renders typed bodies via their `toJson()`, recursing into maps and
  /// iterables; values that fail to encode are returned as-is.
  ///
  /// Covers DTOs nested inside a `toJson()` map generated without
  /// `explicitToJson` (freezed/json_serializable), which would otherwise log
  /// as `toString()`. Pure JSON structures pass through unchanged without
  /// copying; the original input is never mutated.
  static Object? encodeJsonGracefully(Object? value) {
    if (!_containsEncodableObject(value, 0)) return value;
    return _deepEncode(value, Set<Object>.identity(), 0);
  }

  /// Guards against stack overflow on pathological nesting or cycles.
  static const int _maxEncodeDepth = 64;

  static bool _containsEncodableObject(Object? value, int depth) {
    if (value == null || value is String || value is num || value is bool) {
      return false;
    }
    if (depth >= _maxEncodeDepth) return false;
    if (value is Map) {
      return value.values.any((v) => _containsEncodableObject(v, depth + 1));
    }
    if (value is Iterable) {
      if (_isPrimitiveCollection(value)) return false;
      return value.any((v) => _containsEncodableObject(v, depth + 1));
    }
    return value is! TypedData;
  }

  static bool _isPrimitiveCollection(Iterable<dynamic> value) =>
      value is Iterable<num> ||
      value is Iterable<String> ||
      value is Iterable<bool>;

  static Object? _deepEncode(Object? value, Set<Object> visiting, int depth) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (depth >= _maxEncodeDepth) return value;
    if (value is Map) {
      if (!visiting.add(value)) return value;
      try {
        final result = <String, dynamic>{};
        value.forEach((key, entry) {
          result[key.toString()] =
              _deepEncode(entry as Object?, visiting, depth + 1);
        });
        return result;
      } finally {
        visiting.remove(value);
      }
    }
    if (value is Iterable) {
      if (_isPrimitiveCollection(value)) return value;
      if (!visiting.add(value)) return value;
      try {
        return value
            .map((entry) => _deepEncode(entry as Object?, visiting, depth + 1))
            .toList();
      } finally {
        visiting.remove(value);
      }
    }
    if (value is TypedData) return value;
    if (!visiting.add(value)) return value;
    try {
      final encoded = (value as dynamic).toJson();
      if (identical(encoded, value)) return value;
      return _deepEncode(encoded as Object?, visiting, depth + 1);
    } on Object {
      return value;
    } finally {
      visiting.remove(value);
    }
  }
}
