import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/utils/bounded_json_decoder.dart';

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
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final redactionActive = enableRedaction && ISpectRedaction.enabled;
    final prepared = _boundedSnapshot(
      headers,
      redactionActive: redactionActive,
      preserveTypes: redactionActive,
    );
    final typed = prepared is Map<String, Object?>
        ? Map<String, dynamic>.from(prepared)
        : <String, dynamic>{};
    if (!redactionActive) return typed;
    try {
      final redacted = _redactor.redactHeaders(
        typed,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      final normalized = _boundedSnapshot(
        redacted,
        redactionActive: true,
        preserveTypes: true,
      );
      if (normalized is! Map<String, Object?>) {
        return <String, dynamic>{};
      }
      return Map<String, dynamic>.from(normalized);
    } on Object {
      return <String, dynamic>{};
    }
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
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final redactionActive = enableRedaction && ISpectRedaction.enabled;
    final prepared = _boundedSnapshot(
      data,
      redactionActive: redactionActive,
      preserveTypes: redactionActive,
    );
    final normalized = normalizer != null ? normalizer(prepared) : prepared;
    final bounded = _boundedSnapshot(
      normalized,
      redactionActive: redactionActive,
      preserveTypes: redactionActive,
    );
    if (!redactionActive) return bounded;
    return _redactBody(
      bounded,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
  }

  /// Ensures the value is represented as a string-keyed map. Non-map values are
  /// wrapped in `{ 'data': value }`.
  Map<String, dynamic> ensureMap(Object? value) {
    final bounded = _boundedSnapshot(
      value,
      redactionActive: false,
      preserveTypes: true,
    );
    if (bounded == null) return <String, dynamic>{};
    if (bounded is Map<String, Object?>) {
      return Map<String, dynamic>.from(bounded);
    }
    return <String, dynamic>{'data': bounded};
  }

  /// Converts a map with arbitrary key types into a string-keyed map.
  ///
  /// Also available as [toStringKeyMap] for call sites without a sanitizer
  /// instance (e.g. data serialization classes).
  Map<String, dynamic> stringKeyMap(Map<dynamic, dynamic>? input) =>
      toStringKeyMap(input);

  /// Converts a map with arbitrary key types into a `Map<String, dynamic>`.
  ///
  /// The result is a bounded, non-executing snapshot. Non-string keys and
  /// caller-defined objects are replaced with stable diagnostic markers;
  /// their `toString` or `toJson` implementations are never invoked.
  static Map<String, dynamic> toStringKeyMap(Map<dynamic, dynamic>? input) {
    if (input == null) return <String, dynamic>{};
    final bounded = _boundedSnapshot(
      input,
      redactionActive: false,
      preserveTypes: true,
    );
    return bounded is Map<String, Object?>
        ? Map<String, dynamic>.from(bounded)
        : <String, dynamic>{};
  }

  /// Returns null when the provided map is null or empty; otherwise returns the map.
  Map<K, V>? nullIfEmpty<K, V>(Map<K, V>? map) =>
      map == null || map.isEmpty ? null : map;

  /// Attempts to decode [value] as bounded JSON.
  ///
  /// Returns `null` for empty strings. Every other value is snapshotted before
  /// inspection, so ordinary non-JSON text and malformed or over-budget JSON
  /// retain a bounded prefix without executing caller-defined methods.
  /// Useful for HTTP string responses that may contain remote JSON.
  static Object? decodeJsonGracefully(Object? value) {
    final bounded = _boundedSnapshot(
      value,
      redactionActive: false,
    );
    if (bounded is! String) return bounded;
    if (bounded.isEmpty) return null;
    if (!BoundedJsonDecoder.looksLikeJson(bounded)) return bounded;
    try {
      return BoundedJsonDecoder.decode(bounded);
    } on BoundedJsonException {
      return bounded;
    }
  }

  Object? _redactBody(
    Object? value, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    if (value == null) return null;

    try {
      if (value is String && BoundedJsonDecoder.looksLikeJson(value)) {
        final decoded = BoundedJsonDecoder.decode(value);
        if (decoded is Map || decoded is List) {
          final redacted = _redactor.redactForExport(
            decoded,
            ignoredValues: ignoredValues,
            ignoredKeys: ignoredKeys,
          );
          if (redacted == null) return redactionFailedPlaceholder;
          final bounded = _boundedSnapshot(
            redacted,
            redactionActive: true,
          );
          if (bounded is! Map && bounded is! List) return bounded;
          final encoded = jsonEncode(bounded);
          final boundedEncoded = _boundedSnapshot(
            encoded,
            redactionActive: true,
          );
          return boundedEncoded is String
              ? boundedEncoded
              : redactionFailedPlaceholder;
        }
      }

      final redacted = _redactor.redactForExport(
        value,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      if (redacted == null) return redactionFailedPlaceholder;
      return _boundedSnapshot(
        redacted,
        redactionActive: true,
      );
    } on Object {
      return redactionFailedPlaceholder;
    }
  }

  /// Creates a bounded snapshot without invoking caller-supplied `toJson` or
  /// `toString` implementations.
  ///
  /// Pure JSON values retain their shape. Typed binary values remain atomic so
  /// an active redactor can apply its binary policy; oversized binary values
  /// are replaced before they can cross the capture boundary.
  static Object? encodeJsonGracefully(Object? value) => _boundedSnapshot(
        value,
        redactionActive: false,
        preserveTypes: true,
      );

  static Object? _boundedSnapshot(
    Object? value, {
    required bool redactionActive,
    bool preserveTypes = false,
  }) {
    final bounded = LogExportOutput.boundJsonValue(
      value,
      preserveTypes: preserveTypes,
      replaceOversizedStrings: redactionActive,
    );
    final binaryBounded = preserveTypes
        ? _PreservedBinaryBudget(
            LogExportOutput.maxPreparedValueBytes,
          ).convert(bounded)
        : bounded;
    return redactionActive
        ? _replaceTruncatedPrefixes(binaryBounded)
        : binaryBounded;
  }

  static Object? _replaceTruncatedPrefixes(Object? value, {int depth = 0}) {
    if (value is String) {
      return value.contains(LogExportOutput.truncatedMarker)
          ? LogExportOutput.truncatedMarker
          : value;
    }
    if (value is TypedData || value is ByteBuffer) return value;
    if (depth >= 64) return JsonValueNormalizer.maxDepthReached;
    if (value is Map<String, Object?>) {
      return <String, Object?>{
        for (final entry in value.entries)
          (entry.key.contains(LogExportOutput.truncatedMarker)
              ? LogExportOutput.truncatedMarker
              : entry.key): _replaceTruncatedPrefixes(
            entry.value,
            depth: depth + 1,
          ),
      };
    }
    if (value is List<Object?>) {
      return <Object?>[
        for (final item in value)
          _replaceTruncatedPrefixes(item, depth: depth + 1),
      ];
    }
    return value;
  }
}

final class _PreservedBinaryBudget {
  _PreservedBinaryBudget(this._remainingBytes);

  int _remainingBytes;

  Object? convert(Object? value, {int depth = 0}) {
    if (value is TypedData) {
      if (value.lengthInBytes > _remainingBytes) {
        return LogExportOutput.truncatedMarker;
      }
      _remainingBytes -= value.lengthInBytes;
      return value;
    }
    if (value is ByteBuffer) {
      if (value.lengthInBytes > _remainingBytes) {
        return LogExportOutput.truncatedMarker;
      }
      _remainingBytes -= value.lengthInBytes;
      return value;
    }
    if (depth >= 64) return JsonValueNormalizer.maxDepthReached;
    if (value is Map<String, Object?>) {
      return <String, Object?>{
        for (final entry in value.entries)
          entry.key: convert(entry.value, depth: depth + 1),
      };
    }
    if (value is List<Object?>) {
      return <Object?>[
        for (final item in value) convert(item, depth: depth + 1),
      ];
    }
    return value;
  }
}
