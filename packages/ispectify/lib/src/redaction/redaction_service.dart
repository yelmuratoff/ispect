import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;
import 'package:ispectify/src/redaction/map_key.dart';
import 'package:ispectify/src/redaction/redaction_config.dart';
import 'package:ispectify/src/redaction/redaction_request.dart';
import 'package:ispectify/src/redaction/redaction_walker.dart';
import 'package:ispectify/src/redaction/scrub/assignment_tokenizer.dart';
import 'package:ispectify/src/redaction/scrub/export_string_scrubber.dart';
import 'package:ispectify/src/redaction/scrub/url_redactor.dart';

export 'package:ispectify/src/redaction/constants/key_defaults.dart';

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
  })  : _usesDefaultStrategy = strategy == null,
        _strategy = strategy ??
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
  int _configurationRevision = 0;
  final bool _usesDefaultStrategy;
  final RedactionStrategy _strategy;
  late final ExportKeyPatterns? _exportKeyPatterns =
      ExportStringScrubber.patternsFor(_config.sensitiveKeysLower);
  late final UrlRedactor _urlRedactor = UrlRedactor(
    placeholder: () => _config.placeholder,
    exportKeyPatterns: () => _exportKeyPatterns,
    keyMatcher: () => _configuredKeyMatcher(
      ignoredValues: null,
      ignoredKeys: null,
    ),
    redactValue: (value, keyName) => redact(value, keyName: keyName),
  );

  /// Monotonically increases whenever an ignore-list mutation method is
  /// invoked, allowing cached redacted views to detect policy updates.
  int get configurationRevision => _configurationRevision;

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
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    if (!ISpectRedaction.enabled) return headers;
    resourceLimits.validate();
    final request = RedactionRequest.fromOverrides(ignoredValues, ignoredKeys);
    final headerAware = _createWalker(request).redactHeaders(headers);
    return _hardenRedactedHeaders(
      originalHeaders: headers,
      headerAware: headerAware,
      request: request,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
  }

  Map<String, Object?> _hardenRedactedHeaders({
    required Map<String, Object?> originalHeaders,
    required Map<String, Object?> headerAware,
    required RedactionRequest request,
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
    required DiagnosticResourceLimits resourceLimits,
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
          resourceLimits: resourceLimits,
        );
        final scrubbedValue = _scrubHeaderValue(
          entry.value,
          request: request,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
          resourceLimits: resourceLimits,
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
    required DiagnosticResourceLimits resourceLimits,
  }) {
    if (_isIgnoredHeaderValue(name, request)) return name;
    try {
      final scrubbed = redactForExport(
        name,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        resourceLimits: resourceLimits,
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
    required DiagnosticResourceLimits resourceLimits,
  }) {
    if (value is String && _isIgnoredHeaderValue(value, request)) {
      return value;
    }
    if (value is TypedData || value is ByteBuffer || value is Type) {
      return _safeHeaderExport(
        value,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        resourceLimits: resourceLimits,
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
            resourceLimits: resourceLimits,
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
              resourceLimits: resourceLimits,
            ),
            value: _scrubHeaderValue(
              entry.value,
              request: request,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
              resourceLimits: resourceLimits,
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
      resourceLimits: resourceLimits,
    );
  }

  Object? _safeHeaderExport(
    Object? value, {
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    try {
      final scrubbed = redactForExport(
        value,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        resourceLimits: resourceLimits,
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
  /// retained for structured metadata. [resourceLimits] applies the caller's
  /// traversal and byte budgets to every normalization pass.
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      _redactForExport(
        data,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        resourceLimits: resourceLimits,
      );

  /// Prepares a schema envelope while treating [rootValueKeys] as values.
  ///
  /// This is for discriminator fields such as a diagnostic log's root `key`:
  /// their values are still scrubbed as free text, but their schema-level key
  /// name does not cause the whole value to be structurally masked. Nested
  /// fields with the same name continue to receive normal key redaction.
  /// [resourceLimits] applies the caller's traversal and byte budgets.
  Object? redactEnvelopeForExport(
    Object? data, {
    required Set<String> rootValueKeys,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      _redactForExport(
        data,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        rootValueKeys: rootValueKeys,
        resourceLimits: resourceLimits,
      );

  Object? _redactForExport(
    Object? data, {
    required DiagnosticResourceLimits resourceLimits,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    Set<String>? rootValueKeys,
  }) {
    try {
      resourceLimits.validate();
      final redactionActive = ISpectRedaction.enabled;
      final normalized = LogExportOutput.boundJsonValue(
        data,
        resourceLimits: resourceLimits,
        preserveTypes: true,
        replaceOversizedStrings: redactionActive,
      );
      if (!redactionActive) return normalized;
      final prepared = LogExportOutput.replaceTruncatedPrefixes(
        normalized,
        resourceLimits: resourceLimits,
      );
      if (_usesDefaultStrategy &&
          (prepared == null ||
              prepared is bool ||
              prepared is num ||
              prepared is String &&
                  prepared.length < 32 &&
                  !ExportStringScrubber.requiresScrub(prepared))) {
        return prepared;
      }
      final structurallyRedacted = _redactNormalizedForExport(
        prepared,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        rootValueKeys: rootValueKeys,
      );
      final exportReady = _usesDefaultStrategy
          ? structurallyRedacted
          : LogExportOutput.boundJsonValue(
              structurallyRedacted,
              resourceLimits: resourceLimits,
              preserveTypes: true,
              replaceOversizedStrings: true,
            );
      final scrubbed = _scrubExportValue(
        exportReady,
        _exportKeyPatterns,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      return LogExportOutput.boundJsonValue(
        scrubbed,
        resourceLimits: resourceLimits,
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
    ExportKeyPatterns? patterns, {
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
      if (!ExportStringScrubber.requiresScrub(value)) return value;
      final assignmentRedacted = _redactClassifiedAssignments(
        redactUrlsInText(value),
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      final queryRedacted = AssignmentTokenizer.maskQueryParameters(
        assignmentRedacted,
        _configuredKeyMatcher(
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        ),
        _config.placeholder,
      );
      final redacted = ExportStringScrubber.scrub(
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
    final queryRedacted = AssignmentTokenizer.maskQueryParameters(
      assignmentRedacted,
      _configuredKeyMatcher(
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      ),
      _config.placeholder,
    );
    final redacted = ExportStringScrubber.scrub(
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
      AssignmentTokenizer.maskSensitiveAssignments(
        value,
        _configuredKeyMatcher(
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        ),
        _config.placeholder,
      );

  bool Function(String key) _configuredKeyMatcher({
    required Set<String>? ignoredValues,
    required Set<String>? ignoredKeys,
  }) {
    if (!ISpectRedaction.enabled) return (_) => false;
    final context = _createWalker(
      RedactionRequest.fromOverrides(ignoredValues, ignoredKeys),
    ).context;
    return (key) => _isConfiguredSensitiveKey(
          key,
          context: context,
          ignoredKeys: ignoredKeys,
        );
  }

  bool _isConfiguredSensitiveKey(
    String key, {
    required RedactionContext context,
    required Set<String>? ignoredKeys,
  }) {
    try {
      final classification = context.classifyKey(key);
      if (classification.fullyMasked || classification.sensitive) return true;
      final normalized = key.trim().toLowerCase();
      if (!_assignmentCredentialKeys.contains(normalized)) return false;
      return !_isIgnoredKeyName(normalized, ignoredKeys);
    } on Object {
      return true;
    }
  }

  // Credential only as an assignment target: SQLCipher's `PRAGMA key = x`
  // and the `?key=` API-key parameter convention.
  static const Set<String> _assignmentCredentialKeys = <String>{'key'};

  bool _isIgnoredKeyName(String normalized, Set<String>? ignoredKeys) =>
      _config.ignoredKeyNamesLower.contains(normalized) ||
      (ignoredKeys?.any((key) => key.toLowerCase() == normalized) ?? false);

  /// Like [redactHeaders], but also returns [RedactionStats] describing
  /// what was redacted and why.
  @Deprecated(
    'Redaction provenance is reported by NetworkPayloadSanitizer. '
    'Will be removed in 8.0.0.',
  )
  HeaderRedactionResult redactHeadersWithStats(
    Map<String, Object?> headers, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    if (!ISpectRedaction.enabled) {
      return HeaderRedactionResult(headers: headers, stats: RedactionStats());
    }
    resourceLimits.validate();
    final request = RedactionRequest.fromOverrides(ignoredValues, ignoredKeys);
    final walker = _createWalker(request);
    final headerAware = walker.redactHeaders(headers);
    final result = _hardenRedactedHeaders(
      originalHeaders: headers,
      headerAware: headerAware,
      request: request,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
      stats: walker.stats,
    );
    return HeaderRedactionResult(headers: result, stats: walker.stats);
  }

  /// Like [redact], but also returns [RedactionStats] describing
  /// what was redacted and why.
  @Deprecated(
    'Redaction provenance is reported by NetworkPayloadSanitizer. '
    'Will be removed in 8.0.0.',
  )
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
    _updateConfig(
      _config.copyWithIgnoredValues({..._config.ignoredValues, value}),
    );
  }

  /// Add multiple string values to the ignore list (exact matches).
  void ignoreValues(Iterable<String> values) {
    _updateConfig(
      _config.copyWithIgnoredValues(
        {..._config.ignoredValues, ...values},
      ),
    );
  }

  /// Remove a string value from the ignore list.
  void unignoreValue(String value) {
    _updateConfig(
      _config.copyWithIgnoredValues(
        {..._config.ignoredValues}..remove(value),
      ),
    );
  }

  /// Clear all ignored string values.
  void clearIgnoredValues() {
    _updateConfig(_config.copyWithIgnoredValues({}));
  }

  // Mutation API — ignored keys

  /// Add a key name to the ignore list (case-insensitive).
  void ignoreKey(String keyName) {
    _updateConfig(
      _config.copyWithIgnoredKeys(
        {..._config.ignoredKeyNamesLower, keyName.toLowerCase()},
      ),
    );
  }

  /// Add multiple key names to the ignore list (case-insensitive).
  void ignoreKeys(Iterable<String> keyNames) {
    _updateConfig(
      _config.copyWithIgnoredKeys(
        {
          ..._config.ignoredKeyNamesLower,
          ...keyNames.map((e) => e.toLowerCase()),
        },
      ),
    );
  }

  /// Remove a key name from the ignore list.
  void unignoreKey(String keyName) {
    _updateConfig(
      _config.copyWithIgnoredKeys(
        {..._config.ignoredKeyNamesLower}..remove(keyName.toLowerCase()),
      ),
    );
  }

  /// Clear all ignored key names.
  void clearIgnoredKeys() {
    _updateConfig(_config.copyWithIgnoredKeys({}));
  }

  void _updateConfig(RedactionConfig config) {
    _config = config;
    _configurationRevision++;
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
    return _urlRedactor.redactUrl(url);
  }

  /// Finds HTTP(S) URLs embedded in [text] and redacts their query parameters
  /// and userInfo credentials.
  ///
  /// Useful for sanitizing error messages that may contain full URLs with
  /// sensitive query parameters or credentials.
  String redactUrlsInText(String text) {
    if (!ISpectRedaction.enabled) return text;
    return _urlRedactor.redactUrlsInText(text);
  }

  // Target redaction (static — Layer 2, trace pipeline)

  /// Redacts URL credentials and query params with sensitive keys in a target
  /// string.
  @Deprecated(
    'Unused by the toolkit; call redactUrl on a configured service instead. '
    'Will be removed in 8.0.0.',
  )
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
    return ExportStringScrubber.scrub(
      value,
      ExportStringScrubber.patternsFor(redactKeys),
    );
  }

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
        final normalizedKey = safeMapKey(k);
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
