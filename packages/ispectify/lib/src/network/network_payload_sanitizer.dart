import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/utils/bounded_json_decoder.dart';

/// Provides reusable sanitization helpers for network payloads.
///
/// Handles string-key normalization, optional redaction, and conversion of
/// arbitrary values into map representations consumable by log models.
final class NetworkPayloadSanitizer {
  NetworkPayloadSanitizer(
    this._redactor, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) : _resourceLimits = resourceLimits {
    resourceLimits.validate();
  }

  final RedactionService _redactor;
  final DiagnosticResourceLimits _resourceLimits;

  /// Returns a string-keyed map of headers, applying redaction when enabled.
  Map<String, dynamic> headersMap(
    Map<dynamic, dynamic>? headers, {
    required bool enableRedaction,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      headersMapWithProvenance(
        headers,
        enableRedaction: enableRedaction,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      ).headers;

  /// Like [headersMap], and also reports which header keys redaction changed.
  ///
  /// A key is reported when its value differs from the bounded input, or when
  /// redaction introduced it. A failed redaction yields an empty map and no
  /// reported keys.
  ({Map<String, dynamic> headers, List<String> redactedKeys})
      headersMapWithProvenance(
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
      resourceLimits: _resourceLimits,
    );
    final typed = prepared is Map<String, Object?>
        ? Map<String, dynamic>.from(prepared)
        : <String, dynamic>{};
    final limited = _limitStringMap(typed, _resourceLimits.maxNetworkHeaders);
    if (!redactionActive) return (headers: limited, redactedKeys: const []);
    try {
      final redacted = _redactor.redactHeaders(
        limited,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        resourceLimits: _resourceLimits,
      );
      final normalized = _boundedSnapshot(
        redacted,
        redactionActive: true,
        preserveTypes: true,
        resourceLimits: _resourceLimits,
      );
      if (normalized is! Map<String, Object?>) {
        return (headers: <String, dynamic>{}, redactedKeys: const []);
      }
      final result = _limitStringMap(
        Map<String, dynamic>.from(normalized),
        _resourceLimits.maxNetworkHeaders,
      );
      final redactedKeys = <String>[
        for (final key in result.keys)
          if (!limited.containsKey(key) ||
              !jsonEquals(limited[key], result[key], _resourceLimits))
            key,
      ];
      return (headers: result, redactedKeys: redactedKeys);
    } on Object {
      return (headers: <String, dynamic>{}, redactedKeys: const []);
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
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.strict,
  }) =>
      bodyWithProvenance(
        data,
        enableRedaction: enableRedaction,
        normalizer: normalizer,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        captureMode: captureMode,
      ).body;

  /// Like [body], and also reports whether redaction changed the bounded
  /// input.
  ({Object? body, bool redacted}) bodyWithProvenance(
    Object? data, {
    required bool enableRedaction,
    Object? Function(Object? value)? normalizer,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.strict,
  }) {
    final redactionActive = enableRedaction && ISpectRedaction.enabled;
    final prepared = _boundedSnapshot(
      data,
      redactionActive: redactionActive,
      preserveTypes: redactionActive,
      captureMode: captureMode,
      resourceLimits: _resourceLimits,
    );
    final normalized = normalizer != null ? normalizer(prepared) : prepared;
    final bounded = normalizer == null
        ? prepared
        : _boundedSnapshot(
            normalized,
            redactionActive: redactionActive,
            preserveTypes: redactionActive,
            resourceLimits: _resourceLimits,
          );
    if (!redactionActive) return (body: bounded, redacted: false);
    final redacted = _redactBody(
      bounded,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    return (
      body: redacted,
      redacted: !jsonEquals(bounded, redacted, _resourceLimits),
    );
  }

  /// Structural equality over JSON-shaped values, bounded by
  /// [DiagnosticResourceLimits.maxTraversalNodes].
  static bool jsonEquals(
    Object? left,
    Object? right,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final pending = <(Object?, Object?)>[(left, right)];
    var inspected = 0;
    while (pending.isNotEmpty && inspected < resourceLimits.maxTraversalNodes) {
      final (currentLeft, currentRight) = pending.removeLast();
      inspected++;
      if (identical(currentLeft, currentRight)) continue;
      if (currentLeft == null ||
          currentRight == null ||
          currentLeft.runtimeType != currentRight.runtimeType) {
        return false;
      }
      if (currentLeft is String || currentLeft is num || currentLeft is bool) {
        if (currentLeft != currentRight) return false;
      } else if (currentLeft is Map<String, Object?> &&
          currentRight is Map<String, Object?>) {
        if (currentLeft.length != currentRight.length) return false;
        for (final entry in currentLeft.entries) {
          if (!currentRight.containsKey(entry.key)) return false;
          pending.add((entry.value, currentRight[entry.key]));
        }
      } else if (currentLeft is List<Object?> &&
          currentRight is List<Object?>) {
        if (currentLeft.length != currentRight.length) return false;
        for (var index = 0; index < currentLeft.length; index++) {
          pending.add((currentLeft[index], currentRight[index]));
        }
      } else {
        return false;
      }
    }
    return pending.isEmpty;
  }

  /// Ensures the value is represented as a string-keyed map. Non-map values are
  /// wrapped in `{ 'data': value }`.
  Map<String, dynamic> ensureMap(Object? value) {
    final bounded = _boundedSnapshot(
      value,
      redactionActive: false,
      preserveTypes: true,
      resourceLimits: _resourceLimits,
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
      toStringKeyMap(input, resourceLimits: _resourceLimits);

  /// Converts a map with arbitrary key types into a `Map<String, dynamic>`.
  ///
  /// The result is always bounded. Strict capture replaces caller-defined
  /// objects with stable markers; balanced capture may use guarded `toJson()`
  /// or `toString()` before applying the same output limits.
  static Map<String, dynamic> toStringKeyMap(
    Map<dynamic, dynamic>? input, {
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.strict,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
    int? maxEntries,
  }) {
    resourceLimits.validate();
    if (input == null) return <String, dynamic>{};
    final bounded = _boundedSnapshot(
      input,
      redactionActive: false,
      preserveTypes: true,
      captureMode: captureMode,
      resourceLimits: resourceLimits,
    );
    final result = bounded is Map<String, Object?>
        ? Map<String, dynamic>.from(bounded)
        : <String, dynamic>{};
    return maxEntries == null ? result : _limitStringMap(result, maxEntries);
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
  static Object? decodeJsonGracefully(
    Object? value, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    final bounded = _boundedSnapshot(
      value,
      redactionActive: false,
      resourceLimits: resourceLimits,
    );
    if (bounded is! String) return bounded;
    if (bounded.isEmpty) return null;
    if (!BoundedJsonDecoder.looksLikeJson(bounded)) return bounded;
    try {
      return BoundedJsonDecoder.decode(
        bounded,
        maxCharacters: resourceLimits.maxCapturedValueBytes,
        maxEncodedBytes: resourceLimits.maxCapturedValueBytes,
        maxDepth: resourceLimits.maxTraversalDepth,
        maxNodes: resourceLimits.maxTraversalNodes,
        maxCollectionItems: resourceLimits.maxCollectionItems,
      );
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
        final decoded = BoundedJsonDecoder.decode(
          value,
          maxCharacters: _resourceLimits.maxCapturedValueBytes,
          maxEncodedBytes: _resourceLimits.maxCapturedValueBytes,
          maxDepth: _resourceLimits.maxTraversalDepth,
          maxNodes: _resourceLimits.maxTraversalNodes,
          maxCollectionItems: _resourceLimits.maxCollectionItems,
        );
        if (decoded is Map || decoded is List) {
          final redacted = _redactor.redactForExport(
            decoded,
            ignoredValues: ignoredValues,
            ignoredKeys: ignoredKeys,
            resourceLimits: _resourceLimits,
          );
          if (redacted == null) return redactionFailedPlaceholder;
          final bounded = _boundedSnapshot(
            redacted,
            redactionActive: true,
            resourceLimits: _resourceLimits,
          );
          if (bounded is! Map && bounded is! List) return bounded;
          final encoded = jsonEncode(bounded);
          final boundedEncoded = _boundedSnapshot(
            encoded,
            redactionActive: true,
            resourceLimits: _resourceLimits,
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
        resourceLimits: _resourceLimits,
      );
      if (redacted == null) return redactionFailedPlaceholder;
      return _boundedSnapshot(
        redacted,
        redactionActive: true,
        resourceLimits: _resourceLimits,
      );
    } on Object {
      return redactionFailedPlaceholder;
    }
  }

  /// Creates a bounded payload snapshot using the selected capture policy.
  ///
  /// Pure JSON values retain their shape. Typed binary values remain atomic so
  /// an active redactor can apply its binary policy; oversized binary values
  /// are replaced before they can cross the capture boundary.
  static Object? encodeJsonGracefully(
    Object? value, {
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.strict,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      _boundedSnapshot(
        value,
        redactionActive: false,
        preserveTypes: true,
        captureMode: captureMode,
        resourceLimits: resourceLimits,
      );

  static Object? _boundedSnapshot(
    Object? value, {
    required bool redactionActive,
    bool preserveTypes = false,
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.strict,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    final bounded = LogExportOutput.boundJsonValue(
      value,
      resourceLimits: resourceLimits,
      preserveTypes: preserveTypes,
      replaceOversizedStrings: redactionActive,
      allowCustomSerialization: captureMode == DiagnosticCaptureMode.balanced,
      allowCustomStringification: captureMode == DiagnosticCaptureMode.balanced,
    );
    final binaryBounded = preserveTypes
        ? _PreservedBinaryBudget(
            resourceLimits.maxCapturedValueBytes,
            resourceLimits.maxTraversalDepth,
          ).convert(bounded)
        : bounded;
    return redactionActive
        ? LogExportOutput.replaceTruncatedPrefixes(
            binaryBounded,
            resourceLimits: resourceLimits,
          )
        : binaryBounded;
  }

  static Map<String, dynamic> _limitStringMap(
    Map<String, dynamic> source,
    int maxEntries,
  ) {
    if (maxEntries < 1) {
      throw RangeError.range(maxEntries, 1, null, 'maxEntries');
    }
    if (source.length <= maxEntries) return source;
    return <String, dynamic>{
      for (final entry in source.entries.take(maxEntries))
        entry.key: entry.value,
    };
  }
}

final class _PreservedBinaryBudget {
  _PreservedBinaryBudget(this._remainingBytes, this._maxDepth);

  int _remainingBytes;
  final int _maxDepth;

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
    if (depth >= _maxDepth) return JsonValueNormalizer.maxDepthReached;
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
