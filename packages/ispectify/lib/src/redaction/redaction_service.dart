import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;
import 'package:ispectify/src/redaction/redaction_config.dart';
import 'package:ispectify/src/redaction/redaction_request.dart';
import 'package:ispectify/src/redaction/redaction_walker.dart';

export 'package:ispectify/src/redaction/constants/key_defaults.dart';

const String _unprintableMapKey = '<unprintable-key>';

({String value, bool isSafe}) _safeMapKey(Object? key) => switch (key) {
      String() => (value: key, isSafe: true),
      null => (value: 'null', isSafe: true),
      bool() => (value: key ? 'true' : 'false', isSafe: true),
      num() => (value: key.toString(), isSafe: true),
      Enum() => (value: key.name, isSafe: true),
      _ => (value: _unprintableMapKey, isSafe: false),
    };

/// A configurable service that redacts sensitive values in headers and payloads.
///
/// Leaf-level redaction is handled entirely by [RedactionStrategy] instances
/// (by default [KeyBasedRedaction] + [PatternBasedRedaction] via
/// [CompositeRedactionStrategy]). The internal walker only handles structural
/// traversal of Maps and Lists with depth limiting.
///
/// Example:
/// ```dart
/// final redactor = RedactionService(
///   sensitiveKeys: {'authorization', 'password', 'token'},
/// );
///
/// final headers = redactor.redactHeaders({
///   'authorization': 'Bearer abc123',
///   'content-type': 'application/json',
/// });
/// // {authorization: [REDACTED], content-type: application/json}
///
/// final body = redactor.redact({
///   'user': 'alice',
///   'password': 'p@ss',
/// });
/// // {user: alice, password: [REDACTED]}
/// ```
class RedactionService {
  RedactionService({
    Set<String>? sensitiveKeys,
    Set<String>? additionalSensitiveKeys,
    List<RegExp>? sensitiveKeyPatterns,
    List<RegExp>? additionalSensitiveKeyPatterns,
    int? visibleEdgeLength,
    String? placeholder,
    bool? redactBinary,
    bool? redactBase64,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    Set<String>? fullyMaskedKeys,
    int? maxDepth,
    RedactionStrategy? strategy,
  })  : _strategy = strategy ??
            const CompositeRedactionStrategy([
              KeyBasedRedaction(),
              PatternBasedRedaction(),
            ]),
        _config = RedactionConfig(
          sensitiveKeysLower: {
            ...sensitiveKeys == null
                ? defaultSensitiveKeysLower
                : sensitiveKeys.map((key) => key.toLowerCase()),
            ...?additionalSensitiveKeys?.map((key) => key.toLowerCase()),
          },
          sensitiveKeyPatterns: [
            ...sensitiveKeyPatterns ?? defaultSensitiveKeyPatterns,
            ...?additionalSensitiveKeyPatterns,
          ],
          maxDepth: maxDepth ?? 100,
          visibleEdgeLength: visibleEdgeLength ?? 2,
          placeholder: placeholder ?? ph.defaultPlaceholder,
          redactBinary: redactBinary ?? true,
          redactBase64: redactBase64 ?? true,
          ignoredValues: {...?ignoredValues},
          ignoredKeyNamesLower: {
            ...?(ignoredKeys?.map((e) => e.toLowerCase())),
          },
          fullyMaskedKeyNamesLower: {
            ...defaultFullyMaskedKeysLower,
            ...?fullyMaskedKeys?.map((e) => e.toLowerCase()),
          },
        ) {
    if (_config.maxDepth <= 0) {
      throw ArgumentError(
        'maxDepth must be positive, got: ${_config.maxDepth}',
      );
    }
    if (_config.visibleEdgeLength < 0) {
      throw ArgumentError(
        'visibleEdgeLength must be non-negative, '
        'got: ${_config.visibleEdgeLength}',
      );
    }
    if (_config.placeholder.isEmpty) {
      throw ArgumentError('placeholder must not be empty');
    }
  }

  RedactionConfig _config;
  final RedactionStrategy _strategy;
  late final _ExportKeyPatterns? _exportKeyPatterns =
      _exportPatternsFor(_config.sensitiveKeysLower);

  /// Redacts header names and values, respecting optional per-call overrides.
  ///
  /// Header-aware masking runs before and after export-string scrubbing. The
  /// second pass preserves structured Authorization and Cookie behavior after
  /// secrets embedded in arbitrary values or cookie names have been removed.
  /// Name collisions retain unchanged names first, then the first redacted
  /// name in input order.
  ///
  /// Returns [headers] unchanged when redaction is globally disabled via
  /// [ISpectRedaction.enabled].
  Map<String, Object?> redactHeaders(
    Map<String, Object?> headers, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    if (!ISpectRedaction.enabled) return headers;
    final request = RedactionRequest.fromOverrides(ignoredValues, ignoredKeys);
    final headerAware = _createWalker(request).redactHeaders(headers);
    return _hardenRedactedHeaders(
      originalHeaders: headers,
      headerAware: headerAware,
      request: request,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
  }

  Map<String, Object?> _hardenRedactedHeaders({
    required Map<String, Object?> originalHeaders,
    required Map<String, Object?> headerAware,
    required RedactionRequest request,
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
    RedactionStats? stats,
  }) {
    final entries = <({
      String originalName,
      String safeName,
      Object? value,
    })>[];

    for (final entry in headerAware.entries) {
      final ignoredHeader = _isIgnoredHeaderName(entry.key, request);
      final String safeName;
      final Object? restoredValue;
      if (ignoredHeader) {
        safeName = entry.key;
        restoredValue = originalHeaders[entry.key];
      } else {
        safeName = _scrubHeaderName(
          entry.key,
          request: request,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        );
        final scrubbedValue = _scrubHeaderValue(
          entry.value,
          request: request,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        );
        restoredValue = _restoreHeaderAwareValue(
          scrubbedValue,
          headerName: entry.key,
          request: request,
        );
      }
      if (!ignoredHeader &&
          stats != null &&
          (safeName != entry.key ||
              _headerComponentChanged(entry.value, restoredValue))) {
        stats.incrementPatternBased();
      }
      entries.add(
        (
          originalName: entry.key,
          safeName: safeName,
          value: restoredValue,
        ),
      );
    }

    final result = <String, Object?>{};
    for (final retainUnchangedNames in const [true, false]) {
      for (final entry in entries) {
        if ((entry.safeName == entry.originalName) != retainUnchangedNames) {
          continue;
        }
        result.putIfAbsent(entry.safeName, () => entry.value);
      }
    }
    return result;
  }

  Object? _restoreHeaderAwareValue(
    Object? value, {
    required String headerName,
    required RedactionRequest request,
  }) {
    try {
      final restored = _createWalker(request).redact(
        value,
        keyName: headerName,
      );
      return value != null && restored == null ? _config.placeholder : restored;
    } on Object {
      return _config.placeholder;
    }
  }

  String _scrubHeaderName(
    String name, {
    required RedactionRequest request,
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
  }) {
    if (_isIgnoredHeaderValue(name, request)) return name;
    try {
      final scrubbed = redactForExport(
        name,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      if (scrubbed is! String || scrubbed.isEmpty) return _config.placeholder;
      return scrubbed == name ? name : _config.placeholder;
    } on Object {
      return _config.placeholder;
    }
  }

  Object? _scrubHeaderValue(
    Object? value, {
    required RedactionRequest request,
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
  }) {
    if (value is String && _isIgnoredHeaderValue(value, request)) {
      return value;
    }
    if (value is TypedData || value is ByteBuffer || value is Type) {
      return _safeHeaderExport(
        value,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }
    if (value is List<Object?>) {
      return <Object?>[
        for (final item in value)
          _scrubHeaderValue(
            item,
            request: request,
            ignoredValues: ignoredValues,
            ignoredKeys: ignoredKeys,
          ),
      ];
    }
    if (value is Map<String, Object?>) {
      final entries = <({
        String originalName,
        String safeName,
        Object? value,
      })>[];
      for (final entry in value.entries) {
        entries.add(
          (
            originalName: entry.key,
            safeName: _scrubHeaderName(
              entry.key,
              request: request,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            ),
            value: _scrubHeaderValue(
              entry.value,
              request: request,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            ),
          ),
        );
      }
      final result = <String, Object?>{};
      for (final retainUnchangedNames in const [true, false]) {
        for (final entry in entries) {
          if ((entry.safeName == entry.originalName) != retainUnchangedNames) {
            continue;
          }
          result.putIfAbsent(entry.safeName, () => entry.value);
        }
      }
      return result;
    }
    return _safeHeaderExport(
      value,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
  }

  Object? _safeHeaderExport(
    Object? value, {
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
  }) {
    try {
      final scrubbed = redactForExport(
        value,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      return value != null && scrubbed == null ? _config.placeholder : scrubbed;
    } on Object {
      return _config.placeholder;
    }
  }

  bool _isIgnoredHeaderName(String name, RedactionRequest request) {
    final lower = name.trim().toLowerCase();
    return _config.ignoredKeyNamesLower.contains(lower) ||
        (request.ignoredKeysLower?.contains(lower) ?? false);
  }

  bool _isIgnoredHeaderValue(String value, RedactionRequest request) =>
      _config.ignoredValues.contains(value) ||
      (request.ignoredValues?.contains(value) ?? false);

  static bool _headerComponentChanged(Object? before, Object? after) {
    if (identical(before, after)) return false;
    if (before == null ||
        after == null ||
        before.runtimeType != after.runtimeType) {
      return true;
    }
    if (before is String || before is num || before is bool) {
      return before != after;
    }
    return true;
  }

  /// Redacts any JSON-like payload (Map/List/scalars).
  ///
  /// Disabling global redaction changes masking only. Outbound values remain
  /// bounded and are snapshotted without executing caller formatters.
  Object? redact(
    Object? data, {
    String? keyName,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    if (!ISpectRedaction.enabled) return data;
    return _createWalker(
      RedactionRequest.fromOverrides(ignoredValues, ignoredKeys),
    ).redact(data, keyName: keyName);
  }

  /// Prepares arbitrary diagnostic data for an outbound boundary.
  ///
  /// Structural key- and pattern-based redaction runs first. Every remaining
  /// string is then scanned for embedded credentials, tokens, query
  /// parameters, and JSON-shaped secrets. Exceptions, errors, and other
  /// unknown values are converted to scrubbed strings so raw diagnostic
  /// objects cannot cross an export or persistence boundary. Type tokens are
  /// retained for structured metadata.
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      _redactForExport(
        data,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );

  /// Prepares a schema envelope while treating [rootValueKeys] as values.
  ///
  /// This is for discriminator fields such as a diagnostic log's root `key`:
  /// their values are still scrubbed as free text, but their schema-level key
  /// name does not cause the whole value to be structurally masked. Nested
  /// fields with the same name continue to receive normal key redaction.
  Object? redactEnvelopeForExport(
    Object? data, {
    required Set<String> rootValueKeys,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      _redactForExport(
        data,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        rootValueKeys: rootValueKeys,
      );

  Object? _redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    Set<String>? rootValueKeys,
  }) {
    try {
      final redactionActive = ISpectRedaction.enabled;
      final normalized = LogExportOutput.boundJsonValue(
        data,
        preserveTypes: true,
        replaceOversizedStrings: redactionActive,
      );
      if (!redactionActive) return normalized;
      final structurallyRedacted = _redactNormalizedForExport(
        normalized,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        rootValueKeys: rootValueKeys,
      );
      final safeRedacted = LogExportOutput.boundJsonValue(
        structurallyRedacted,
        preserveTypes: true,
        replaceOversizedStrings: true,
      );
      final scrubbed = _scrubExportValue(
        safeRedacted,
        _exportKeyPatterns,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      return LogExportOutput.boundJsonValue(
        scrubbed,
        preserveTypes: true,
        replaceOversizedStrings: true,
      );
    } catch (_) {
      return _config.placeholder;
    }
  }

  Object? _redactNormalizedForExport(
    Object? normalized, {
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
    required Set<String>? rootValueKeys,
  }) {
    if (normalized is! Map<String, Object?> ||
        rootValueKeys == null ||
        rootValueKeys.isEmpty) {
      return redact(
        normalized,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }

    final structuralInput = Map<String, Object?>.from(normalized)
      ..removeWhere((key, _) => rootValueKeys.contains(key));
    final structuralResult = redact(
      structuralInput,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    if (structuralResult is! Map<String, Object?>) {
      return _config.placeholder;
    }

    return <String, Object?>{
      for (final entry in normalized.entries)
        entry.key: rootValueKeys.contains(entry.key)
            ? redact(
                entry.value,
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              )
            : structuralResult[entry.key],
    };
  }

  Object? _scrubExportValue(
    Object? value,
    _ExportKeyPatterns? patterns, {
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
  }) {
    if (value == null || value is bool || value is num) return value;
    if (value is Type) return value;
    // Keep typed binary atomic when binary masking is disabled. Outbound
    // callers apply their byte/node budget after redaction; iterating a typed
    // list here would eagerly materialize the complete buffer first.
    if (value is TypedData || value is ByteBuffer) return value;
    if (value is String) {
      final assignmentRedacted = _redactClassifiedAssignments(
        redactUrlsInText(value),
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      final queryRedacted = _maskQueryParameters(
        assignmentRedacted,
        (key) => _isConfiguredSensitiveKey(
          key,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        ),
        _config.placeholder,
      );
      final redacted = _redactExportString(
        queryRedacted,
        patterns,
        mask: _config.placeholder,
      );
      return redacted;
    }
    if (value is Map<Object?, Object?>) {
      return <String, Object?>{
        for (final entry in value.entries)
          _scrubExportValue(
                entry.key,
                patterns,
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              )?.toString() ??
              JsonValueNormalizer.unprintableValue: _scrubExportValue(
            entry.value,
            patterns,
            ignoredValues: ignoredValues,
            ignoredKeys: ignoredKeys,
          ),
      };
    }
    if (value is Iterable<Object?>) {
      return value
          .map(
            (entry) => _scrubExportValue(
              entry,
              patterns,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            ),
          )
          .toList(growable: false);
    }
    final assignmentRedacted = _redactClassifiedAssignments(
      redactUrlsInText(value.toString()),
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    final queryRedacted = _maskQueryParameters(
      assignmentRedacted,
      (key) => _isConfiguredSensitiveKey(
        key,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      ),
      _config.placeholder,
    );
    final redacted = _redactExportString(
      queryRedacted,
      patterns,
      mask: _config.placeholder,
    );
    return redacted;
  }

  String _redactClassifiedAssignments(
    String value, {
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
  }) =>
      _maskSensitiveAssignments(
        value,
        (key) => _isConfiguredSensitiveKey(
          key,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        ),
        _config.placeholder,
      );

  bool _isConfiguredSensitiveKey(
    String key, {
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
  }) {
    try {
      const probe = 8675309;
      final keyless = redact(
        probe,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      final keyed = redact(
        probe,
        keyName: key,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      return keyed != keyless;
    } on Object {
      return true;
    }
  }

  static String _maskSensitiveAssignments(
    String value,
    bool Function(String key) isSensitive,
    String placeholder,
  ) {
    final output = StringBuffer();
    var copiedThrough = 0;
    var index = 0;
    while (index < value.length) {
      final assignment = _assignmentAt(value, index);
      if (assignment == null) {
        index++;
        continue;
      }

      var valueStart = assignment.separator + 1;
      while (valueStart < value.length &&
          (assignment.quotedKey
              ? _isJsonWhitespace(value.codeUnitAt(valueStart))
              : _isInlineWhitespace(value.codeUnitAt(valueStart)))) {
        valueStart++;
      }
      final key = assignment.key;
      if (key != null && !isSensitive(key)) {
        index = assignment.keyEnd;
        continue;
      }

      final valueEnd = _assignmentValueEnd(
        value,
        valueStart,
        quotedKey: assignment.quotedKey,
      );
      final replacement =
          assignment.quotedKey ? jsonEncode(placeholder) : placeholder;
      output
        ..write(value.substring(copiedThrough, valueStart))
        ..write(replacement);
      copiedThrough = valueEnd;
      index = valueEnd > valueStart ? valueEnd : valueStart + 1;
    }
    output.write(value.substring(copiedThrough));
    return output.toString();
  }

  static ({
    String? key,
    int keyEnd,
    int separator,
    bool quotedKey,
  })? _assignmentAt(String value, int start) {
    final codeUnit = value.codeUnitAt(start);
    if (!_isAssignmentBoundary(value, start)) return null;

    if (codeUnit == _doubleQuoteCodeUnit || codeUnit == _singleQuoteCodeUnit) {
      final keyEnd = _quotedAssignmentKeyEnd(value, start, codeUnit);
      if (keyEnd == null) return null;
      var separator = keyEnd;
      while (separator < value.length &&
          _isJsonWhitespace(value.codeUnitAt(separator))) {
        separator++;
      }
      if (separator >= value.length ||
          value.codeUnitAt(separator) != _colonCodeUnit) {
        return null;
      }

      return (
        key: _decodeQuotedAssignmentKey(value, start, keyEnd, codeUnit),
        keyEnd: keyEnd,
        separator: separator,
        quotedKey: true,
      );
    }

    if (!_isAssignmentKeyStart(codeUnit)) return null;
    var keyEnd = start + 1;
    while (keyEnd < value.length &&
        _isAssignmentKeyCharacter(value.codeUnitAt(keyEnd))) {
      keyEnd++;
    }
    var separator = keyEnd;
    while (separator < value.length &&
        _isInlineWhitespace(value.codeUnitAt(separator))) {
      separator++;
    }
    if (separator >= value.length ||
        (value.codeUnitAt(separator) != _equalsCodeUnit &&
            value.codeUnitAt(separator) != _colonCodeUnit)) {
      return null;
    }
    final encodedKey = value.substring(start, keyEnd);
    return (
      key: _decodeUrlKey(encodedKey),
      keyEnd: keyEnd,
      separator: separator,
      quotedKey: false,
    );
  }

  static bool _isAssignmentBoundary(String value, int start) {
    if (start == 0) return true;
    final previous = value.codeUnitAt(start - 1);
    return _isJsonWhitespace(previous) ||
        previous == _questionMarkCodeUnit ||
        previous == _ampersandCodeUnit ||
        previous == _commaCodeUnit ||
        previous == _semicolonCodeUnit ||
        previous == _openParenthesisCodeUnit ||
        previous == _openBracketCodeUnit ||
        previous == _openBraceCodeUnit;
  }

  static int? _quotedAssignmentKeyEnd(
    String value,
    int start,
    int quote,
  ) {
    var escaped = false;
    for (var index = start + 1; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (escaped) {
        escaped = false;
        continue;
      }
      if (codeUnit == _backslashCodeUnit) {
        escaped = true;
        continue;
      }
      if (codeUnit == quote) return index + 1;
      if (codeUnit == _lineFeedCodeUnit ||
          codeUnit == _carriageReturnCodeUnit) {
        return null;
      }
    }
    return null;
  }

  static String? _decodeQuotedAssignmentKey(
    String value,
    int start,
    int end,
    int quote,
  ) {
    if (quote == _doubleQuoteCodeUnit) {
      try {
        final decoded = jsonDecode(value.substring(start, end));
        return decoded is String ? decoded : null;
      } on FormatException {
        return null;
      }
    }

    final output = StringBuffer();
    for (var index = start + 1; index < end - 1; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit != _backslashCodeUnit) {
        output.writeCharCode(codeUnit);
        continue;
      }
      index++;
      if (index >= end - 1) return null;
      final escaped = value.codeUnitAt(index);
      if (escaped == _lowercaseUCodeUnit && index + 4 < end - 1) {
        final decoded = int.tryParse(
          value.substring(index + 1, index + 5),
          radix: 16,
        );
        if (decoded == null) return null;
        output.writeCharCode(decoded);
        index += 4;
      } else {
        output.writeCharCode(escaped);
      }
    }
    return output.toString();
  }

  static int _assignmentValueEnd(
    String value,
    int start, {
    required bool quotedKey,
  }) {
    if (start >= value.length) return start;
    final openingQuote = value.codeUnitAt(start);
    if (openingQuote == _openBraceCodeUnit ||
        openingQuote == _openBracketCodeUnit) {
      return _balancedJsonValueEnd(value, start);
    }
    if (openingQuote == _singleQuoteCodeUnit ||
        openingQuote == _doubleQuoteCodeUnit) {
      var escaped = false;
      for (var index = start + 1; index < value.length; index++) {
        final codeUnit = value.codeUnitAt(index);
        if (escaped) {
          escaped = false;
          continue;
        }
        if (codeUnit == _backslashCodeUnit) {
          escaped = true;
          continue;
        }
        if (codeUnit == openingQuote) return index + 1;
      }
      return value.length;
    }

    if (quotedKey) {
      for (var index = start; index < value.length; index++) {
        final codeUnit = value.codeUnitAt(index);
        if (codeUnit == _commaCodeUnit ||
            codeUnit == _closeBraceCodeUnit ||
            codeUnit == _closeBracketCodeUnit) {
          return index;
        }
      }
      return value.length;
    }

    for (var index = start; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (_isHardAssignmentBoundary(codeUnit)) {
        var next = index + 1;
        while (next < value.length &&
            _isInlineWhitespace(value.codeUnitAt(next))) {
          next++;
        }
        if (_startsAssignmentAt(value, next)) return index;
        continue;
      }
      if (!_isInlineWhitespace(codeUnit)) continue;

      var next = index;
      while (
          next < value.length && _isInlineWhitespace(value.codeUnitAt(next))) {
        next++;
      }
      if (_startsAssignmentAt(value, next)) return index;
    }
    return value.length;
  }

  static int _balancedJsonValueEnd(String value, int start) {
    final expectedClosings = <int>[
      if (value.codeUnitAt(start) == _openBraceCodeUnit)
        _closeBraceCodeUnit
      else
        _closeBracketCodeUnit,
    ];
    int? stringQuote;
    var escaped = false;
    for (var index = start + 1; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (stringQuote != null) {
        if (escaped) {
          escaped = false;
        } else if (codeUnit == _backslashCodeUnit) {
          escaped = true;
        } else if (codeUnit == stringQuote) {
          stringQuote = null;
        }
        continue;
      }
      if (codeUnit == _doubleQuoteCodeUnit ||
          codeUnit == _singleQuoteCodeUnit) {
        stringQuote = codeUnit;
        continue;
      }
      if (codeUnit == _openBraceCodeUnit) {
        expectedClosings.add(_closeBraceCodeUnit);
        continue;
      }
      if (codeUnit == _openBracketCodeUnit) {
        expectedClosings.add(_closeBracketCodeUnit);
        continue;
      }
      if (codeUnit == _closeBraceCodeUnit ||
          codeUnit == _closeBracketCodeUnit) {
        if (codeUnit != expectedClosings.last) return value.length;
        expectedClosings.removeLast();
        if (expectedClosings.isEmpty) return index + 1;
      }
    }
    return value.length;
  }

  static bool _startsAssignmentAt(String value, int start) =>
      start < value.length && _assignmentAt(value, start) != null;

  static String _maskQueryParameters(
    String value,
    bool Function(String key) isSensitive,
    String placeholder,
  ) =>
      value.replaceAllMapped(_queryParameterPattern, (match) {
        final separator = match.group(1)!;
        final encodedKey = match.group(2)!;
        final decodedKey = _decodeUrlKey(encodedKey);
        if (decodedKey == null || isSensitive(decodedKey)) {
          return '$separator$encodedKey=$placeholder';
        }
        return match.group(0)!;
      });

  static bool _isAssignmentKeyStart(int codeUnit) =>
      (codeUnit >= _uppercaseACodeUnit && codeUnit <= _uppercaseZCodeUnit) ||
      (codeUnit >= _lowercaseACodeUnit && codeUnit <= _lowercaseZCodeUnit) ||
      (codeUnit >= _zeroCodeUnit && codeUnit <= _nineCodeUnit) ||
      codeUnit == _underscoreCodeUnit ||
      codeUnit == _percentCodeUnit;

  static bool _isAssignmentKeyCharacter(int codeUnit) =>
      _isAssignmentKeyStart(codeUnit) ||
      (codeUnit >= _zeroCodeUnit && codeUnit <= _nineCodeUnit) ||
      codeUnit == _underscoreCodeUnit ||
      codeUnit == _dotCodeUnit ||
      codeUnit == _hyphenCodeUnit ||
      codeUnit == _percentCodeUnit ||
      codeUnit == _openBracketCodeUnit ||
      codeUnit == _closeBracketCodeUnit;

  static bool _isInlineWhitespace(int codeUnit) =>
      codeUnit == _spaceCodeUnit || codeUnit == _tabCodeUnit;

  static bool _isJsonWhitespace(int codeUnit) =>
      _isInlineWhitespace(codeUnit) ||
      codeUnit == _lineFeedCodeUnit ||
      codeUnit == _carriageReturnCodeUnit;

  static bool _isHardAssignmentBoundary(int codeUnit) =>
      codeUnit == _commaCodeUnit ||
      codeUnit == _semicolonCodeUnit ||
      codeUnit == _ampersandCodeUnit ||
      codeUnit == _closeParenthesisCodeUnit ||
      codeUnit == _closeBracketCodeUnit ||
      codeUnit == _closeBraceCodeUnit ||
      codeUnit == _carriageReturnCodeUnit ||
      codeUnit == _lineFeedCodeUnit;

  static final RegExp _queryParameterPattern = RegExp(
    r'(^|[?&#])([^?&#=\s]+)=([^?&#\s]*)',
    multiLine: true,
  );

  static const int _uppercaseACodeUnit = 65;
  static const int _uppercaseZCodeUnit = 90;
  static const int _lowercaseACodeUnit = 97;
  static const int _lowercaseZCodeUnit = 122;
  static const int _zeroCodeUnit = 48;
  static const int _nineCodeUnit = 57;
  static const int _tabCodeUnit = 9;
  static const int _lineFeedCodeUnit = 10;
  static const int _carriageReturnCodeUnit = 13;
  static const int _spaceCodeUnit = 32;
  static const int _exclamationCodeUnit = 33;
  static const int _doubleQuoteCodeUnit = 34;
  static const int _percentCodeUnit = 37;
  static const int _singleQuoteCodeUnit = 39;
  static const int _openParenthesisCodeUnit = 40;
  static const int _closeParenthesisCodeUnit = 41;
  static const int _commaCodeUnit = 44;
  static const int _hyphenCodeUnit = 45;
  static const int _dotCodeUnit = 46;
  static const int _colonCodeUnit = 58;
  static const int _semicolonCodeUnit = 59;
  static const int _questionMarkCodeUnit = 63;
  static const int _equalsCodeUnit = 61;
  static const int _openBracketCodeUnit = 91;
  static const int _closeBracketCodeUnit = 93;
  static const int _underscoreCodeUnit = 95;
  static const int _backslashCodeUnit = 92;
  static const int _openBraceCodeUnit = 123;
  static const int _closeBraceCodeUnit = 125;
  static const int _ampersandCodeUnit = 38;
  static const int _lowercaseUCodeUnit = 117;

  /// Like [redactHeaders], but also returns [RedactionStats] describing
  /// what was redacted and why.
  HeaderRedactionResult redactHeadersWithStats(
    Map<String, Object?> headers, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    if (!ISpectRedaction.enabled) {
      return HeaderRedactionResult(headers: headers, stats: RedactionStats());
    }
    final request = RedactionRequest.fromOverrides(ignoredValues, ignoredKeys);
    final walker = _createWalker(request);
    final headerAware = walker.redactHeaders(headers);
    final result = _hardenRedactedHeaders(
      originalHeaders: headers,
      headerAware: headerAware,
      request: request,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      stats: walker.stats,
    );
    return HeaderRedactionResult(headers: result, stats: walker.stats);
  }

  /// Like [redact], but also returns [RedactionStats] describing
  /// what was redacted and why.
  RedactionResult redactWithStats(
    Object? data, {
    String? keyName,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    if (!ISpectRedaction.enabled) {
      return RedactionResult(data: data, stats: RedactionStats());
    }
    final walker = _createWalker(
      RedactionRequest.fromOverrides(ignoredValues, ignoredKeys),
    );
    final result = walker.redact(data, keyName: keyName);
    return RedactionResult(data: result, stats: walker.stats);
  }

  RedactionWalker _createWalker(RedactionRequest request) =>
      RedactionWalker(_config, request, _strategy);

  // Mutation API — ignored values

  /// Add a string value to the ignore list (exact match).
  void ignoreValue(String value) {
    _config = _config.copyWithIgnoredValues({..._config.ignoredValues, value});
  }

  /// Add multiple string values to the ignore list (exact matches).
  void ignoreValues(Iterable<String> values) {
    _config = _config.copyWithIgnoredValues(
      {..._config.ignoredValues, ...values},
    );
  }

  /// Remove a string value from the ignore list.
  void unignoreValue(String value) {
    _config = _config.copyWithIgnoredValues(
      {..._config.ignoredValues}..remove(value),
    );
  }

  /// Clear all ignored string values.
  void clearIgnoredValues() {
    _config = _config.copyWithIgnoredValues({});
  }

  // Mutation API — ignored keys

  /// Add a key name to the ignore list (case-insensitive).
  void ignoreKey(String keyName) {
    _config = _config.copyWithIgnoredKeys(
      {..._config.ignoredKeyNamesLower, keyName.toLowerCase()},
    );
  }

  /// Add multiple key names to the ignore list (case-insensitive).
  void ignoreKeys(Iterable<String> keyNames) {
    _config = _config.copyWithIgnoredKeys(
      {
        ..._config.ignoredKeyNamesLower,
        ...keyNames.map((e) => e.toLowerCase()),
      },
    );
  }

  /// Remove a key name from the ignore list.
  void unignoreKey(String keyName) {
    _config = _config.copyWithIgnoredKeys(
      {..._config.ignoredKeyNamesLower}..remove(keyName.toLowerCase()),
    );
  }

  /// Clear all ignored key names.
  void clearIgnoredKeys() {
    _config = _config.copyWithIgnoredKeys({});
  }

  // URL redaction

  /// Redacts query-parameter values and userInfo credentials in a URL string.
  ///
  /// Returns the original [url] unchanged when there is nothing to redact
  /// (no query parameters and no userInfo). When the URL cannot be parsed,
  /// falls back to regex-based sanitization of credentials and sensitive
  /// query parameters rather than returning it verbatim.
  String redactUrl(String url) {
    if (!ISpectRedaction.enabled) return url;
    return _redactUrl(
      url,
      remainingOperations: _maxNestedUrlOperations,
      maxOutputLength: _redactedUrlOutputLimit(url.length),
    );
  }

  String _redactUrl(
    String url, {
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      // Malformed URL — Uri APIs are unavailable. Best-effort regex sanitize
      // so credentials and sensitive query params don't survive verbatim.
      final queryRedacted = _maskQueryParameters(
        url,
        (key) => _isConfiguredSensitiveKey(
          key,
          ignoredValues: null,
          ignoredKeys: null,
        ),
        _config.placeholder,
      );
      final redacted = _redactClassifiedAssignments(
        _redactExportString(
          queryRedacted,
          _exportKeyPatterns,
          mask: _config.placeholder,
        ),
        ignoredValues: null,
        ignoredKeys: null,
      );
      return redacted.length <= maxOutputLength
          ? redacted
          : _config.placeholder;
    }

    final hasQuery = uri.hasQuery;
    final hasUserInfo = uri.userInfo.isNotEmpty;
    final redactedQuery = hasQuery
        ? _redactQuery(
            uri.query,
            remainingOperations: remainingOperations,
            maxOutputLength: maxOutputLength,
          )
        : null;
    final queryChanged = redactedQuery != null && redactedQuery != uri.query;
    final redactedFragment = uri.fragment.isNotEmpty
        ? _redactFragment(
            uri.fragment,
            remainingOperations: remainingOperations,
            maxOutputLength: maxOutputLength,
          )
        : null;
    final fragmentChanged =
        redactedFragment != null && redactedFragment != uri.fragment;
    if (!queryChanged && !hasUserInfo && !fragmentChanged) return url;

    final redacted = uri
        .replace(
          userInfo: hasUserInfo ? ph.userInfoRedactedPlaceholder : null,
          query: queryChanged ? redactedQuery : null,
          fragment: fragmentChanged ? redactedFragment : null,
        )
        .toString();
    return redacted.length <= maxOutputLength ? redacted : _config.placeholder;
  }

  String _redactQuery(
    String query, {
    required int remainingOperations,
    required int maxOutputLength,
  }) =>
      _mapParameterSegments(query, (pair) {
        final separator = pair.indexOf('=');
        if (separator < 0) return pair;

        final encodedKey = pair.substring(0, separator);
        final encodedValue = pair.substring(separator + 1);
        final decodedKey = _decodeUrlKey(encodedKey);
        if (decodedKey == null) {
          return '$encodedKey=${Uri.encodeQueryComponent(_config.placeholder)}';
        }

        final redacted = _redactUrlComponentValue(
          encodedValue,
          keyName: decodedKey,
          remainingOperations: remainingOperations,
          maxOutputLength: maxOutputLength,
        );
        if (redacted == encodedValue) return pair;
        return '$encodedKey=${Uri.encodeQueryComponent(redacted)}';
      });

  /// Redacts sensitive values in a URL fragment that carries `key=value` pairs
  /// (e.g. the OAuth implicit-grant `#access_token=…&id_token=…` redirect).
  ///
  /// Returns [fragment] unchanged when it is not a `key=value` list.
  String _redactFragment(
    String fragment, {
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final direct = _redactDecodedFragment(
      fragment,
      remainingOperations: remainingOperations,
      maxOutputLength: maxOutputLength,
    );
    if (direct != fragment) return direct;

    var decoded = fragment;
    var operationsLeft = remainingOperations;
    for (var depth = 0; depth < _maxNestedUrlDecodePasses; depth++) {
      final candidate = _tryDecodeUrlComponent(decoded);
      if (candidate == null) return _config.placeholder;
      if (candidate == decoded) return fragment;
      if (operationsLeft <= 0) return _config.placeholder;
      operationsLeft--;
      decoded = candidate;
      final redacted = _redactDecodedFragment(
        decoded,
        remainingOperations: operationsLeft,
        maxOutputLength: maxOutputLength,
      );
      if (redacted != decoded) return redacted;
    }

    final remaining = _tryDecodeUrlComponent(decoded);
    if (remaining == null || remaining != decoded) {
      return _config.placeholder;
    }
    return fragment;
  }

  String _redactDecodedFragment(
    String fragment, {
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final queryIndex = fragment.indexOf('?');
    if (queryIndex >= 0) {
      final query = fragment.substring(queryIndex + 1);
      final redactedQuery = _redactQuery(
        query,
        remainingOperations: remainingOperations,
        maxOutputLength: maxOutputLength,
      );
      return '${fragment.substring(0, queryIndex + 1)}$redactedQuery';
    }
    if (!fragment.contains('=')) return fragment;
    return _mapParameterSegments(fragment, (pair) {
      final idx = pair.indexOf('=');
      if (idx < 0) return pair;
      final key = pair.substring(0, idx);
      final value = pair.substring(idx + 1);
      final decodedKey = _decodeUrlKey(key);
      if (decodedKey == null) {
        return '$key=${_config.placeholder}';
      }
      final redacted = _redactUrlComponentValue(
        value,
        keyName: decodedKey,
        remainingOperations: remainingOperations,
        maxOutputLength: maxOutputLength,
      );
      return '$key=$redacted';
    });
  }

  String _redactUrlComponentValue(
    String value, {
    required String keyName,
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final redactedValue = redact(value, keyName: keyName);
    final keyRedacted = switch (redactedValue) {
      null => '',
      final String text => text,
      final bool primitive => primitive.toString(),
      final num primitive when primitive is! double || primitive.isFinite =>
        primitive.toString(),
      _ => _config.placeholder,
    };
    if (LogExportOutput.utf8Length(
          keyRedacted,
          limit: maxOutputLength,
        ) >
        maxOutputLength) {
      return _config.placeholder;
    }
    if (keyRedacted != value) return keyRedacted;

    var decoded = value;
    if (_malformedPercentEncodingPattern.hasMatch(decoded)) {
      return _config.placeholder;
    }
    var operationsLeft = remainingOperations;
    final initialUrlRedaction = _redactNestedUrlValue(
      decoded,
      remainingOperations: operationsLeft,
      maxOutputLength: maxOutputLength,
    );
    if (initialUrlRedaction != null) return initialUrlRedaction;
    final initialAssignmentRedaction = _redactNestedAssignments(decoded);
    if (initialAssignmentRedaction != null) {
      return initialAssignmentRedaction;
    }
    for (var depth = 0; depth < _maxNestedUrlDecodePasses; depth++) {
      final candidate = _tryDecodeUrlComponent(decoded);
      if (candidate == null) {
        return decoded == value ? _config.placeholder : value;
      }
      if (candidate == decoded) return value;
      if (operationsLeft <= 0) return _config.placeholder;
      operationsLeft--;
      decoded = candidate;
      final nestedUrlRedaction = _redactNestedUrlValue(
        decoded,
        remainingOperations: operationsLeft,
        maxOutputLength: maxOutputLength,
      );
      if (nestedUrlRedaction != null) return nestedUrlRedaction;
      final assignmentRedaction = _redactNestedAssignments(decoded);
      if (assignmentRedaction != null) return assignmentRedaction;
    }

    final remaining = _tryDecodeUrlComponent(decoded);
    if (remaining == null || remaining != decoded) {
      return _config.placeholder;
    }
    return value;
  }

  String? _redactNestedAssignments(String value) {
    final redacted = _redactClassifiedAssignments(
      value,
      ignoredValues: null,
      ignoredKeys: null,
    );
    return redacted == value ? null : redacted;
  }

  String? _redactNestedUrlValue(
    String value, {
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final uri = Uri.tryParse(value);
    final queryStart = value.indexOf('?');
    final fragmentStart = value.indexOf('#');
    final hasParameterShape =
        (queryStart >= 0 && value.substring(queryStart + 1).contains('=')) ||
            (fragmentStart >= 0 &&
                value.substring(fragmentStart + 1).contains('='));
    final isUrlShaped = _httpSchemePattern.hasMatch(value) ||
        hasParameterShape ||
        (uri != null &&
            (uri.hasQuery ||
                uri.userInfo.isNotEmpty ||
                (uri.fragment.isNotEmpty && uri.fragment.contains('='))));
    if (!isUrlShaped) return null;
    if (_malformedPercentEncodingPattern.hasMatch(value)) {
      return _config.placeholder;
    }
    if (remainingOperations <= 0) return _config.placeholder;

    final redacted = _redactUrl(
      value,
      remainingOperations: remainingOperations - 1,
      maxOutputLength: maxOutputLength,
    );
    return redacted == value ? null : redacted;
  }

  static const int _maxNestedUrlDecodePasses = 5;
  static const int _maxNestedUrlOperations = 16;
  static const int _maxUrlKeyDecodePasses = 5;
  static const int _maxRedactedUrlExpansionFactor = 4;
  static const int _redactedUrlExpansionSlack = 1024;

  static int _redactedUrlOutputLimit(int inputLength) =>
      inputLength * _maxRedactedUrlExpansionFactor + _redactedUrlExpansionSlack;

  static final RegExp _httpSchemePattern = RegExp(
    'https?://',
    caseSensitive: false,
  );

  static final RegExp _malformedPercentEncodingPattern = RegExp(
    '%(?![0-9A-Fa-f]{2})',
  );

  static String? _tryDecodeUrlComponent(String value) {
    if (_malformedPercentEncodingPattern.hasMatch(value)) return null;
    try {
      return Uri.decodeQueryComponent(value);
    } on Object {
      return null;
    }
  }

  static String? _decodeUrlKey(String value) {
    var decoded = value;
    for (var depth = 0; depth < _maxUrlKeyDecodePasses; depth++) {
      final candidate = _tryDecodeUrlComponent(decoded);
      if (candidate == null) return null;
      if (candidate == decoded) return decoded;
      decoded = candidate;
    }

    final remaining = _tryDecodeUrlComponent(decoded);
    if (remaining == null || remaining != decoded) return null;
    return decoded;
  }

  static String _mapParameterSegments(
    String value,
    String Function(String pair) transform,
  ) {
    final output = StringBuffer();
    var segmentStart = 0;
    for (var index = 0; index <= value.length; index++) {
      final isEnd = index == value.length;
      if (!isEnd) {
        final codeUnit = value.codeUnitAt(index);
        if (codeUnit != _ampersandCodeUnit && codeUnit != _semicolonCodeUnit) {
          continue;
        }
      }

      output.write(transform(value.substring(segmentStart, index)));
      if (!isEnd) output.writeCharCode(value.codeUnitAt(index));
      segmentStart = index + 1;
    }
    return output.toString();
  }

  /// Finds HTTP(S) URLs embedded in [text] and redacts their query parameters
  /// and userInfo credentials.
  ///
  /// Useful for sanitizing error messages that may contain full URLs with
  /// sensitive query parameters or credentials.
  String redactUrlsInText(String text) {
    if (!ISpectRedaction.enabled) return text;
    return text.replaceAllMapped(
      urlPattern,
      (match) {
        final candidate = match.group(0)!;
        final urlEnd = _embeddedUrlEnd(candidate);
        return '${redactUrl(candidate.substring(0, urlEnd))}'
            '${candidate.substring(urlEnd)}';
      },
    );
  }

  static int _embeddedUrlEnd(String candidate) {
    var end = candidate.length;
    while (end > 0) {
      final trailing = candidate.codeUnitAt(end - 1);
      if (trailing == _dotCodeUnit ||
          trailing == _commaCodeUnit ||
          trailing == _semicolonCodeUnit ||
          trailing == _colonCodeUnit ||
          trailing == _exclamationCodeUnit) {
        end--;
        continue;
      }
      if (trailing == _closeParenthesisCodeUnit &&
          _hasUnbalancedTrailingDelimiter(
            candidate,
            end,
            _openParenthesisCodeUnit,
            _closeParenthesisCodeUnit,
          )) {
        end--;
        continue;
      }
      if (trailing == _closeBracketCodeUnit &&
          _hasUnbalancedTrailingDelimiter(
            candidate,
            end,
            _openBracketCodeUnit,
            _closeBracketCodeUnit,
          )) {
        end--;
        continue;
      }
      if (trailing == _closeBraceCodeUnit &&
          _hasUnbalancedTrailingDelimiter(
            candidate,
            end,
            _openBraceCodeUnit,
            _closeBraceCodeUnit,
          )) {
        end--;
        continue;
      }
      break;
    }
    return end;
  }

  static bool _hasUnbalancedTrailingDelimiter(
    String value,
    int end,
    int opening,
    int closing,
  ) {
    var balance = 0;
    for (var index = 0; index < end; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit == opening) {
        balance++;
      } else if (codeUnit == closing) {
        balance--;
      }
    }
    return balance < 0;
  }

  // Shared patterns

  static final _urlCredentialPattern =
      RegExp(r'((?::)?//)([^:/@\s]+)(?::([^/@\s]*))?@');

  // Target redaction (static — Layer 2, trace pipeline)

  /// Redacts URL credentials and query params with sensitive keys in a target
  /// string. Used by the `trace()` pipeline for auto-redaction of the target
  /// field.
  static String redactTarget(String target, Set<String> redactKeys) {
    if (!ISpectRedaction.enabled) return target;
    return RedactionService(sensitiveKeys: redactKeys).redactUrl(target);
  }

  // Export string redaction (static — Layer 3, export)

  /// Regex-based redaction for export strings. Covers URL credentials,
  /// authentication schemes, sensitive assignments, query params, and JSON.
  ///
  /// URL credentials and authentication scheme tokens carry no key dependency
  /// and are always scrubbed. Key-based assignments, query parameters, and
  /// JSON patterns run only when [redactKeys] is non-empty.
  ///
  /// Used by toText(), toMarkdown(), LogExporter for exception.toString()
  /// and error strings that may contain sensitive data.
  static String redactExportString(String value, Set<String>? redactKeys) {
    if (!ISpectRedaction.enabled) return value;
    return _redactExportString(value, _exportPatternsFor(redactKeys));
  }

  static String _redactExportString(
    String value,
    _ExportKeyPatterns? patterns, {
    String mask = ph.defaultPlaceholder,
  }) {
    final scrubbed = _redactUnquotedAbsolutePaths(
      _redactQuotedAbsolutePaths(value, mask),
      mask,
    )
        .replaceAllMapped(
          _urlCredentialPattern,
          (m) => '${m[1]}${ph.userInfoRedactedPlaceholder}@',
        )
        .replaceAllMapped(
          _authorizationHeaderPattern,
          (m) => '${m[1]}${m[2]}$mask',
        )
        .replaceAllMapped(
          _embeddedJwtPattern,
          (m) => '${m[1]}$mask',
        )
        .replaceAllMapped(
          _embeddedKnownTokenPattern,
          (m) => '${m[1]}$mask',
        )
        .replaceAllMapped(
          _parameterAuthenticationPattern,
          (m) => '${m[1]} $mask',
        )
        .replaceAllMapped(
          _exportTokenPattern,
          (m) => '${m[1]} $mask',
        );

    if (patterns == null) return scrubbed;

    final assignmentRedacted = _maskSensitiveAssignments(
      scrubbed,
      patterns.matchesKey,
      mask,
    );
    final queryRedacted = _maskQueryParameters(
      assignmentRedacted,
      patterns.matchesKey,
      mask,
    );
    final redacted = queryRedacted
        .replaceAllMapped(
          patterns.jsonString,
          (m) => '"${m[1]}": "$mask"',
        )
        .replaceAllMapped(
          patterns.jsonScalar,
          (m) => '"${m[1]}": "$mask"',
        );

    return _maskSensitiveAssignments(
      redacted,
      patterns.matchesKey,
      mask,
    );
  }

  static String _redactQuotedAbsolutePaths(String value, String mask) {
    final output = StringBuffer();
    var copiedThrough = 0;
    var index = 0;
    while (index < value.length) {
      final quote = value.codeUnitAt(index);
      if (quote != _singleQuoteCodeUnit && quote != _doubleQuoteCodeUnit) {
        index++;
        continue;
      }

      final contentStart = index + 1;
      final replacement = _quotedPathReplacement(
        value,
        contentStart,
        mask,
      );
      if (replacement == null) {
        index++;
        continue;
      }

      final contentEnd = _quotedPathEnd(value, contentStart, quote);
      output
        ..write(value.substring(copiedThrough, contentStart))
        ..write(replacement);
      copiedThrough = contentEnd;
      index = contentEnd > contentStart ? contentEnd : contentStart;
    }
    output.write(value.substring(copiedThrough));
    return output.toString();
  }

  static String? _quotedPathReplacement(
    String value,
    int start,
    String mask,
  ) {
    if (_quotedFileUriStartPattern.matchAsPrefix(value, start) != null) {
      return 'file://$mask';
    }
    if (_quotedPosixPathStartPattern.matchAsPrefix(value, start) != null ||
        _quotedWindowsPathStartPattern.matchAsPrefix(value, start) != null ||
        _quotedUncPathStartPattern.matchAsPrefix(value, start) != null) {
      return mask;
    }
    return null;
  }

  static int _quotedPathEnd(String value, int start, int quote) {
    var escaped = false;
    for (var index = start; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit == _lineFeedCodeUnit ||
          codeUnit == _carriageReturnCodeUnit) {
        return index;
      }
      if (escaped) {
        escaped = false;
        continue;
      }
      if (codeUnit == _backslashCodeUnit) {
        escaped = true;
        continue;
      }
      if (codeUnit == quote) return index;
    }
    return value.length;
  }

  static String _redactUnquotedAbsolutePaths(String value, String mask) {
    final output = StringBuffer();
    var copiedThrough = 0;
    for (final match in _unquotedAbsolutePathStartPattern.allMatches(value)) {
      if (match.start < copiedThrough) continue;

      final prefix = match.group(1)!;
      final pathStart = match.start + prefix.length;
      final pathEnd = _unquotedPathEnd(value, pathStart, match.end);
      final pathPrefix = match.group(2)!;
      final replacement =
          pathPrefix.toLowerCase().startsWith('file:') ? 'file://$mask' : mask;
      output
        ..write(value.substring(copiedThrough, pathStart))
        ..write(replacement);
      copiedThrough = pathEnd;
    }
    if (copiedThrough == 0) return value;
    output.write(value.substring(copiedThrough));
    return output.toString();
  }

  static int _unquotedPathEnd(
    String value,
    int pathStart,
    int scanStart,
  ) {
    for (var index = scanStart; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit == _lineFeedCodeUnit ||
          codeUnit == _carriageReturnCodeUnit ||
          codeUnit == _doubleQuoteCodeUnit ||
          codeUnit == _singleQuoteCodeUnit ||
          codeUnit == _closeParenthesisCodeUnit ||
          codeUnit == _closeBracketCodeUnit ||
          codeUnit == _closeBraceCodeUnit ||
          codeUnit == _commaCodeUnit ||
          codeUnit == _semicolonCodeUnit) {
        return index;
      }
      if (!_isInlineWhitespace(codeUnit)) continue;

      var next = index + 1;
      while (
          next < value.length && _isInlineWhitespace(value.codeUnitAt(next))) {
        next++;
      }
      if (next >= value.length ||
          _startsAssignmentAt(value, next) ||
          _stackLocationSuffixPattern
              .hasMatch(value.substring(pathStart, index))) {
        return index;
      }
    }
    return value.length;
  }

  static _ExportKeyPatterns? _exportPatternsFor(Set<String>? keys) {
    if (keys == null || keys.isEmpty) return null;
    if (identical(keys, defaultSensitiveKeys) ||
        identical(keys, defaultSensitiveKeysLower)) {
      return _defaultExportKeyPatterns;
    }
    return _ExportKeyPatterns(keys);
  }

  static final _ExportKeyPatterns _defaultExportKeyPatterns =
      _ExportKeyPatterns(defaultSensitiveKeysLower);

  static final _exportTokenPattern = RegExp(
    r'\b(Bearer|Basic|Token|Digest|NTLM|Negotiate|OAuth|HOBA|Mutual|'
    r'SCRAM-SHA-\d+)\s+[^\s,;]+',
    caseSensitive: false,
  );

  static final _authorizationHeaderPattern = RegExp(
    r'\b((?:Proxy-)?Authorization)(\s*[:=]\s*)[^\r\n]*',
    caseSensitive: false,
  );

  static final _embeddedJwtPattern = RegExp(
    '(^|[^A-Za-z0-9_-])'
    r'[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
    r'(?=$|[^A-Za-z0-9_-])',
  );

  static final _embeddedKnownTokenPattern = RegExp(
    '(^|[^A-Za-z0-9_-])'
    '(?:(?:github_pat_|gh[pousr]_|xox[baprs]-|glpat-|sk-ant-|sk-|gsk_|'
    '(?:sk|pk|rk)_(?:live|test)_|AIza|sbp_|npm_|pypi-|pat_)'
    '[A-Za-z0-9._=-]{8,}|AKIA[A-Z0-9]{12,})',
  );

  static final _parameterAuthenticationPattern = RegExp(
    r'''\b(Digest|OAuth)\s+(?:[A-Za-z][A-Za-z0-9_-]*\s*=\s*(?:"(?:\\.|[^"\\])*"|"(?:\\.|[^"\\\r\n])*(?=[\r\n]|$)|'(?:\\.|[^'\\])*'|'(?:\\.|[^'\\\r\n])*(?=[\r\n]|$)|[^"'\s,]+)(?:\s*,\s*)?)+''',
    caseSensitive: false,
  );

  static final _quotedFileUriStartPattern = RegExp(
    r'''file:(?://[^/\s]*)?/''',
    caseSensitive: false,
  );

  static final _quotedPosixPathStartPattern = RegExp(
    '/(?:Users|home|private|var|tmp|data|storage|sdcard|mnt|'
    'opt|srv|etc|root|app|workspace)/',
    caseSensitive: false,
  );

  static final _quotedWindowsPathStartPattern = RegExp(r'[A-Za-z]:[\\/]');

  static final _quotedUncPathStartPattern = RegExp(
    r'''\\\\[^\\/\s]+[\\/]''',
  );

  static final _unquotedAbsolutePathStartPattern = RegExp(
    r'(^|[\s(=\[])('
    r'''file:(?://[^/\s]*)?/|'''
    '/(?:Users|home|private|var|tmp|data|storage|sdcard|mnt|'
    'opt|srv|etc|root|app|workspace)/|'
    r'''[A-Za-z]:[\\/]|'''
    r'''\\\\[^\\/\s]+[\\/]'''
    ')',
    caseSensitive: false,
    multiLine: true,
  );

  static final _stackLocationSuffixPattern = RegExp(r':\d+(?::\d+)?$');

  // Lightweight key-based redaction (static)

  /// Recursively redacts map values whose keys match any of the provided [keys]
  /// (case-insensitive).
  ///
  /// Unlike [redact], this method performs **only** exact key-name matching —
  /// no pattern-based content detection, no strategies. It is intended for
  /// call sites that need simple, per-call key lists (e.g. database logging).
  ///
  /// Returns the original [data] unchanged when it is not a [Map] or [Iterable],
  /// or when [keys] is empty.
  static Object? redactByKeys(
    Object? data,
    Iterable<String> keys, {
    int maxDepth = 100,
    String placeholder = ph.defaultPlaceholder,
  }) {
    if (!ISpectRedaction.enabled) return data;
    if (data == null || keys.isEmpty || maxDepth <= 0) return data;

    final lowerKeys = keys.map((k) => k.toLowerCase()).toSet();
    return _redactByKeysImpl(data, lowerKeys, maxDepth, placeholder);
  }

  static Object? _redactByKeysImpl(
    Object? data,
    Set<String> lowerKeys,
    int maxDepth,
    String placeholder,
  ) {
    if (data == null) return null;
    if (maxDepth <= 0) {
      // Fail closed: a container past the depth limit may hide sensitive keys.
      // Mirrors RedactionWalker, which returns the placeholder past maxDepth.
      return data is Map || data is Iterable ? placeholder : data;
    }
    if (data is Map) {
      final out = <String, Object?>{};
      data.forEach((k, v) {
        final normalizedKey = _safeMapKey(k);
        final hit = normalizedKey.isSafe &&
            lowerKeys.contains(normalizedKey.value.toLowerCase());
        out[normalizedKey.value] = !normalizedKey.isSafe || hit
            ? placeholder
            : _redactByKeysImpl(v, lowerKeys, maxDepth - 1, placeholder);
      });
      return out;
    }
    if (data is Iterable) {
      return data
          .map(
            (e) => _redactByKeysImpl(
              e as Object?,
              lowerKeys,
              maxDepth - 1,
              placeholder,
            ),
          )
          .toList();
    }
    return data;
  }
}

final class _ExportKeyPatterns {
  _ExportKeyPatterns(Set<String> keys)
      : this._(
          keys.map((key) => key.toLowerCase()).toSet(),
          keys.map(_canonicalizeKey).toSet(),
          keys.map(RegExp.escape).join('|'),
        );

  _ExportKeyPatterns._(this.keysLower, this.canonicalKeysLower, String keys)
      : jsonString = RegExp(
          '"($keys)"\\s*:\\s*"(?:\\\\.|[^"\\\\])*"',
          caseSensitive: false,
        ),
        jsonScalar = RegExp(
          '"($keys)"\\s*:\\s*(-?\\d[\\d.eE+-]*|true|false|null)',
          caseSensitive: false,
        );

  final Set<String> keysLower;
  final Set<String> canonicalKeysLower;
  final RegExp jsonString;
  final RegExp jsonScalar;

  bool matchesKey(String key) {
    final lower = key.trim().toLowerCase();
    if (keysLower.contains(lower)) return true;
    final canonical = _canonicalizeKey(key);
    if (canonicalKeysLower.contains(canonical)) return true;
    final tokens =
        canonical.split('_').where((token) => token.isNotEmpty).toList();
    for (var start = 0; start < tokens.length; start++) {
      final candidate = StringBuffer();
      for (var end = start; end < tokens.length; end++) {
        if (candidate.isNotEmpty) candidate.write('_');
        candidate.write(tokens[end]);
        if (canonicalKeysLower.contains(candidate.toString())) return true;
      }
    }
    return false;
  }

  static String _canonicalizeKey(String key) => key
      .replaceAllMapped(_acronymBoundary, (m) => '${m[1]}_${m[2]}')
      .replaceAllMapped(_camelBoundary, (m) => '${m[1]}_${m[2]}')
      .replaceAllMapped(
        _bracketBoundary,
        (m) => m[1]!.isEmpty ? '' : '_${m[1]}',
      )
      .replaceAll(RegExp(r'[.\-]'), '_')
      .toLowerCase();

  static final RegExp _camelBoundary = RegExp('([a-z0-9])([A-Z])');
  static final RegExp _acronymBoundary = RegExp('([A-Z]+)([A-Z][a-z])');
  static final RegExp _bracketBoundary = RegExp(r'\[([^\[\]]*)\]');
}
