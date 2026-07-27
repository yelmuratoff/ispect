import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/network/network_json_keys.dart';
import 'package:ispectify/src/network/network_payload_sanitizer.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:ispectify/src/redaction/redaction_toggle.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Standard redaction pipeline for network `toJson()` maps.
///
/// Each method mutates [map] in place, matching the existing pattern across
/// all interceptor data classes. This keeps the consumer code minimal:
///
/// ```dart
/// if (redactor == null) return map;
/// NetworkMapRedactor.redactUrl(map, redactor);
/// NetworkMapRedactor.redactHeaders(map, redactor, ...);
/// NetworkMapRedactor.redactData(map, redactor, ...);
/// ```
abstract final class NetworkMapRedactor {
  /// Redacts a URL field by applying [RedactionService.redactUrl].
  ///
  /// No-op if the field is absent or not a [String].
  static void redactUrl(
    Map<String, dynamic> map,
    RedactionService redactor, {
    String key = NetworkJsonKeys.url,
  }) {
    final value = map[key];
    if (value is String) {
      final redacted = _redactUrlValue(value, redactor);
      map[key] = redacted;
      if (ISpectRedaction.enabled && redacted != value) {
        _markRedaction(map, NetworkJsonKeys.urlRedacted, true);
      }
    }
  }

  /// Redacts a headers field using [RedactionService.redactHeaders].
  ///
  /// Returns the redacted headers map so callers can apply additional
  /// transformations (e.g. stringifying values for `http` package).
  static Map<String, dynamic>? redactHeaders(
    Map<String, dynamic> map,
    RedactionService redactor, {
    String key = NetworkJsonKeys.headers,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final raw = map[key];
    if (raw == null) return null;
    if (raw is! Map) return null;

    final sanitizer = NetworkPayloadSanitizer(redactor);
    final prepared = sanitizer.headersMap(
      raw,
      enableRedaction: false,
    );
    final redacted = sanitizer.headersMap(
      raw,
      enableRedaction: true,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    map[key] = redacted;
    if (ISpectRedaction.enabled) {
      final changedKeys = redacted.keys.where(
        (header) =>
            !prepared.containsKey(header) ||
            !_safeJsonEquals(prepared[header], redacted[header]),
      );
      if (changedKeys.isNotEmpty) {
        _markRedaction(
          map,
          NetworkJsonKeys.redactedHeaderKeys,
          changedKeys.toList(growable: false),
        );
      }
    }
    return redacted;
  }

  /// Redacts a data/body field via [RedactionService.redact].
  ///
  /// Preserves `null` — if the field is absent or `null`, nothing changes.
  static void redactData(
    Map<String, dynamic> map,
    RedactionService redactor, {
    String key = NetworkJsonKeys.data,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    if (!map.containsKey(key)) return;
    final raw = map[key];
    final sanitizer = NetworkPayloadSanitizer(redactor);
    final prepared = sanitizer.body(
      raw,
      enableRedaction: false,
    );
    final redacted = sanitizer.body(
      raw,
      enableRedaction: true,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    map[key] = redacted;
    if (ISpectRedaction.enabled && !_safeJsonEquals(prepared, redacted)) {
      _markRedaction(map, NetworkJsonKeys.bodyRedacted, true);
    }
  }

  /// Redacts an arbitrary map field (e.g. `extra`, `query-parameters`).
  ///
  /// Keys listed in [preserveKeys] are restored after redaction — useful for
  /// internal metadata like [NetworkJsonKeys.ispectRequestId]. A redactor that
  /// throws, returns `null`, or returns a non-map value produces an empty map;
  /// the raw field is never used as a fallback.
  static void redactMapField(
    Map<String, dynamic> map,
    RedactionService redactor, {
    required String key,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    Set<String> preserveKeys = const {},
  }) {
    final raw = map[key];
    if (raw == null) return;
    final redactionActive = ISpectRedaction.enabled;
    final prepared = _boundValue(
      raw,
      redactionActive: redactionActive,
      preserveTypes: redactionActive,
    );

    final preserved =
        prepared is Map<String, Object?> && preserveKeys.isNotEmpty
            ? _extractPreservedValues(prepared, preserveKeys)
            : const <String, Object?>{};

    var redacted = <String, dynamic>{};
    try {
      final result = redactionActive
          ? redactor.redactForExport(
              prepared,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            )
          : prepared;
      final normalized = _boundValue(
        result,
        redactionActive: redactionActive,
      );
      if (normalized is Map<String, Object?>) {
        redacted = Map<String, dynamic>.from(normalized);
      }
    } on Object {
      // Redaction failures intentionally leave the outbound field empty.
    }

    redacted.addAll(preserved);

    final bounded = _boundValue(
      redacted,
      redactionActive: redactionActive,
    );
    map[key] = bounded is Map<String, Object?>
        ? Map<String, dynamic>.from(bounded)
        : <String, dynamic>{};
    if (redactionActive &&
        key == NetworkJsonKeys.queryParameters &&
        !_safeJsonEquals(prepared, map[key])) {
      _markRedaction(map, NetworkJsonKeys.queryRedacted, true);
    }
  }

  static void _markRedaction(
    Map<String, dynamic> map,
    String key,
    Object value,
  ) {
    final existing = map[NetworkJsonKeys.redactionProvenance];
    final provenance = existing is Map<String, dynamic>
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};
    if (key == NetworkJsonKeys.redactedHeaderKeys &&
        provenance[key] is List<Object?> &&
        value is List<Object?>) {
      provenance[key] = <Object?>{
        ...provenance[key]! as List<Object?>,
        ...value,
      }.toList(growable: false);
    } else {
      provenance[key] = value;
    }
    map[NetworkJsonKeys.redactionProvenance] = provenance;
  }

  static bool _safeJsonEquals(Object? left, Object? right) {
    final pending = <(Object?, Object?)>[(left, right)];
    var inspected = 0;
    while (
        pending.isNotEmpty && inspected < JsonValueNormalizer.defaultMaxNodes) {
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

  static Map<String, Object?> _extractPreservedValues(
    Map<String, Object?> raw,
    Set<String> preserveKeys,
  ) =>
      <String, Object?>{
        for (final key in preserveKeys)
          if (raw.containsKey(key)) key: raw[key],
      };

  /// Redacts `path` and `base-url` fields.
  ///
  /// Both fields are passed through [RedactionService.redactUrl] so query
  /// values and user-info credentials cannot leak through duplicate URL data.
  static void redactPathFields(
    Map<String, dynamic> map,
    RedactionService redactor,
  ) {
    final rawPath = map[NetworkJsonKeys.path];
    if (rawPath is String) {
      map[NetworkJsonKeys.path] = _redactUrlValue(rawPath, redactor);
    }

    final rawBaseUrl = map[NetworkJsonKeys.baseUrl];
    if (rawBaseUrl is String) {
      map[NetworkJsonKeys.baseUrl] = _redactUrlValue(rawBaseUrl, redactor);
    }
  }

  /// Redacts a diagnostic text field and normalizes it to a safe string.
  ///
  /// Unknown objects are replaced with non-executing descriptors before
  /// redaction. If the configured redactor fails, the raw value is omitted
  /// instead of crossing the logging boundary.
  static void redactFreeText(
    Map<String, dynamic> map,
    RedactionService redactor, {
    required String key,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final value = map[key];
    if (value is! Object) return;
    map[key] = redactFreeTextValue(
      value,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
  }

  /// Returns a fail-closed, redacted string for arbitrary diagnostic text.
  static String redactFreeTextValue(
    Object value,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final redactionActive = ISpectRedaction.enabled;
    try {
      final prepared = _boundValue(
        value,
        redactionActive: redactionActive,
        preserveTypes: redactionActive,
      );
      final exported = redactionActive
          ? redactor.redactForExport(
              prepared,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            )
          : prepared;
      if (exported == null) return redactionFailedPlaceholder;
      final bounded = _boundValue(
        exported,
        redactionActive: redactionActive,
      );
      final text = _safeText(bounded);
      final redacted = redactionActive ? redactor.redactUrlsInText(text) : text;
      final output = _boundValue(
        redacted,
        redactionActive: redactionActive,
      );
      return output is String ? output : redactionFailedPlaceholder;
    } on Object {
      return redactionFailedPlaceholder;
    }
  }

  /// Redacts the HTTP method field as caller-controlled diagnostic text.
  static void redactMethod(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    redactFreeText(
      map,
      redactor,
      key: NetworkJsonKeys.method,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
  }

  /// Removes payload fields that a caller did not opt into retaining.
  ///
  /// When [recursive] is `true`, the same policy is applied to nested request
  /// and response maps used by error records.
  static void applyCapturePolicy(
    Map<String, dynamic> map, {
    required bool includeData,
    required bool includeHeaders,
    required bool includeMessage,
    bool recursive = false,
  }) {
    final pending = <(Map<String, dynamic>, int)>[(map, 0)];
    final visited = HashSet<Map<String, dynamic>>.identity();
    var inspected = 0;

    while (pending.isNotEmpty) {
      final (current, depth) = pending.removeLast();
      if (!visited.add(current)) continue;
      inspected++;
      _applyCapturePolicyFields(
        current,
        includeData: includeData,
        includeHeaders: includeHeaders,
        includeMessage: includeMessage,
      );
      if (!recursive) continue;

      for (final key in const [
        NetworkJsonKeys.request,
        NetworkJsonKeys.response,
      ]) {
        final nested = current[key];
        if (nested is! Map<String, dynamic>) continue;
        if (visited.contains(nested) ||
            depth >= _capturePolicyMaxDepth ||
            inspected >= JsonValueNormalizer.defaultMaxNodes) {
          current.remove(key);
        } else {
          pending.add((nested, depth + 1));
        }
      }
    }
  }

  static void _applyCapturePolicyFields(
    Map<String, dynamic> map, {
    required bool includeData,
    required bool includeHeaders,
    required bool includeMessage,
  }) {
    if (!includeData) {
      map
        ..remove(NetworkJsonKeys.data)
        ..remove(NetworkJsonKeys.body)
        ..remove(NetworkJsonKeys.multipartRequest);
    }
    if (!includeHeaders) map.remove(NetworkJsonKeys.headers);
    if (!includeMessage) {
      map
        ..remove(NetworkJsonKeys.statusMessage)
        ..remove(NetworkJsonKeys.message)
        ..remove(NetworkJsonKeys.error)
        ..remove(NetworkJsonKeys.stackTrace);
    }
  }

  static const int _capturePolicyMaxDepth = 64;

  /// Redacts caller-controlled URL and method fields in redirect entries.
  ///
  /// Replaces each entry with a bounded snapshot without invoking
  /// caller-defined conversion methods.
  static void redactRedirects(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final raw = map[NetworkJsonKeys.redirects];
    if (raw is! List) return;
    final redactionActive = ISpectRedaction.enabled;
    final bounded = _boundValue(
      raw,
      redactionActive: redactionActive,
    );
    if (bounded is! List<Object?>) {
      map[NetworkJsonKeys.redirects] = <Object?>[];
      return;
    }

    final redirects = <Object?>[];
    for (final item in bounded) {
      if (item is! Map<String, Object?>) continue;
      final redirect = Map<String, dynamic>.from(item);
      final location = redirect[NetworkJsonKeys.location];
      if (location is String) {
        redirect[NetworkJsonKeys.location] =
            _redactUrlValue(location, redactor);
      } else if (location != null) {
        redirect[NetworkJsonKeys.location] = redactionActive
            ? redactionFailedPlaceholder
            : JsonValueNormalizer.unprintableValue;
      }
      redactMethod(
        redirect,
        redactor,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      redirects.add(redirect);
    }
    map[NetworkJsonKeys.redirects] = _boundValue(
      redirects,
      redactionActive: redactionActive,
    );
  }

  /// Redacts multipart request fields and file metadata.
  static void redactMultipart(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final raw = map[NetworkJsonKeys.multipartRequest];
    if (raw is! Map) return;
    final redactionActive = ISpectRedaction.enabled;
    final prepared = _boundValue(
      raw,
      redactionActive: redactionActive,
      preserveTypes: redactionActive,
    );
    if (prepared is! Map<String, Object?>) {
      map[NetworkJsonKeys.multipartRequest] = <String, Object?>{
        NetworkJsonKeys.fields: <String, Object?>{},
        NetworkJsonKeys.files: <Object?>[],
      };
      return;
    }

    final mp = <String, dynamic>{
      NetworkJsonKeys.fields: <String, Object?>{},
      NetworkJsonKeys.files: <Object?>[],
    };
    final rawFields = prepared[NetworkJsonKeys.fields];
    if (rawFields is Map<String, Object?>) {
      try {
        final redacted = redactionActive
            ? redactor.redactForExport(
                rawFields,
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              )
            : rawFields;
        final normalized = _boundValue(
          redacted,
          redactionActive: redactionActive,
        );
        if (normalized is Map<String, Object?>) {
          mp[NetworkJsonKeys.fields] = normalized;
        }
      } on Object {
        // Redaction failures intentionally leave multipart fields empty.
      }
    }

    final rawFiles = prepared[NetworkJsonKeys.files];
    if (rawFiles is List<Object?>) {
      try {
        final redacted = redactionActive
            ? redactor.redactForExport(
                rawFiles,
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              )
            : rawFiles;
        final normalized = _boundValue(
          redacted,
          redactionActive: redactionActive,
        );
        if (normalized is List<Object?>) {
          mp[NetworkJsonKeys.files] =
              normalized.whereType<Map<String, Object?>>().toList();
        }
      } on Object {
        // Redaction failures intentionally leave multipart files empty.
      }
    }

    final boundedMultipart = _boundValue(
      mp,
      redactionActive: redactionActive,
    );
    map[NetworkJsonKeys.multipartRequest] =
        boundedMultipart is Map<String, Object?>
            ? Map<String, dynamic>.from(boundedMultipart)
            : <String, dynamic>{
                NetworkJsonKeys.fields: <String, Object?>{},
                NetworkJsonKeys.files: <Object?>[],
              };
  }

  static String _redactUrlValue(
    String value,
    RedactionService redactor,
  ) {
    final redactionActive = ISpectRedaction.enabled;
    try {
      final prepared = _boundValue(
        value,
        redactionActive: redactionActive,
      );
      if (prepared is! String) return redactionFailedPlaceholder;
      final redacted =
          redactionActive ? redactor.redactUrl(prepared) : prepared;
      final bounded = _boundValue(
        redacted,
        redactionActive: redactionActive,
      );
      return bounded is String ? bounded : redactionFailedPlaceholder;
    } on Object {
      return redactionFailedPlaceholder;
    }
  }

  static String _safeText(Object? value) {
    if (value is String) return value;
    if (value == null) return 'null';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return value.toString();
    if (value is Map<String, Object?> || value is List<Object?>) {
      return jsonEncode(value);
    }
    return JsonValueNormalizer.unprintableValue;
  }

  static Object? _boundValue(
    Object? value, {
    required bool redactionActive,
    bool preserveTypes = false,
  }) {
    final prepared = NetworkPayloadSanitizer.encodeJsonGracefully(value);
    final bounded = LogExportOutput.boundJsonValue(
      prepared,
      preserveTypes: preserveTypes,
      replaceOversizedStrings: redactionActive,
    );
    return redactionActive ? _replaceTruncatedPrefixes(bounded) : bounded;
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
