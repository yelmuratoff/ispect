import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;
import 'package:ispectify/src/redaction/redaction_config.dart';
import 'package:ispectify/src/redaction/redaction_request.dart';
import 'package:ispectify/src/redaction/redaction_walker.dart';

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
///   placeholder: '***',
/// );
///
/// final headers = redactor.redactHeaders({
///   'authorization': 'Bearer abc123',
///   'content-type': 'application/json',
/// });
/// // {authorization: ***, content-type: application/json}
///
/// final body = redactor.redact({
///   'user': 'alice',
///   'password': 'p@ss',
/// });
/// // {user: alice, password: ***}
/// ```
class RedactionService {
  RedactionService({
    Set<String>? sensitiveKeys,
    List<RegExp>? sensitiveKeyPatterns,
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
          sensitiveKeysLower: sensitiveKeys == null
              ? defaultSensitiveKeysLower
              : sensitiveKeys.map((e) => e.toLowerCase()).toSet(),
          sensitiveKeyPatterns:
              sensitiveKeyPatterns ?? defaultSensitiveKeyPatterns,
          maxDepth: maxDepth ?? 100,
          visibleEdgeLength: visibleEdgeLength ?? 2,
          placeholder: placeholder ?? ph.defaultPlaceholder,
          redactBinary: redactBinary ?? true,
          redactBase64: redactBase64 ?? true,
          ignoredValues: {...?ignoredValues, ...ISpectLogType.keys},
          ignoredKeyNamesLower: {
            ...?(ignoredKeys?.map((e) => e.toLowerCase())),
          },
          fullyMaskedKeyNamesLower: fullyMaskedKeys == null
              ? defaultFullyMaskedKeysLower
              : fullyMaskedKeys.map((e) => e.toLowerCase()).toSet(),
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

  /// Redacts header values, respecting optional per-call overrides.
  Map<String, Object?> redactHeaders(
    Map<String, Object?> headers, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      _createWalker(
        RedactionRequest.fromOverrides(ignoredValues, ignoredKeys),
      ).redactHeaders(headers);

  /// Redacts any JSON-like payload (Map/List/scalars).
  Object? redact(
    Object? data, {
    String? keyName,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      _createWalker(
        RedactionRequest.fromOverrides(ignoredValues, ignoredKeys),
      ).redact(data, keyName: keyName);

  /// Like [redactHeaders], but also returns [RedactionStats] describing
  /// what was redacted and why.
  HeaderRedactionResult redactHeadersWithStats(
    Map<String, Object?> headers, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final walker = _createWalker(
      RedactionRequest.fromOverrides(ignoredValues, ignoredKeys),
    );
    final result = walker.redactHeaders(headers);
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
    final walker = _createWalker(
      RedactionRequest.fromOverrides(ignoredValues, ignoredKeys),
    );
    final result = walker.redact(data, keyName: keyName);
    return RedactionResult(data: result, stats: walker.stats);
  }

  RedactionWalker _createWalker(RedactionRequest request) =>
      RedactionWalker(_config, request, _strategy);

  // ---------------------------------------------------------------------------
  // Mutation API — ignored values
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Mutation API — ignored keys
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // URL redaction
  // ---------------------------------------------------------------------------

  /// Redacts query-parameter values and userInfo credentials in a URL string.
  ///
  /// Returns the original [url] unchanged when there is nothing to redact
  /// (no query parameters and no userInfo). When the URL cannot be parsed,
  /// falls back to regex-based sanitization of credentials and sensitive
  /// query parameters rather than returning it verbatim.
  String redactUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      // Malformed URL — Uri APIs are unavailable. Best-effort regex sanitize
      // so credentials and sensitive query params don't survive verbatim.
      return redactExportString(url, _config.sensitiveKeysLower);
    }

    final hasParams = uri.queryParameters.isNotEmpty;
    final hasUserInfo = uri.userInfo.isNotEmpty;
    if (!hasParams && !hasUserInfo) return url;

    final redactedParams = hasParams
        ? uri.queryParameters.map(
            (key, value) =>
                MapEntry(key, redact(value, keyName: key)?.toString() ?? ''),
          )
        : null;

    return uri
        .replace(
          userInfo: hasUserInfo ? ph.userInfoRedactedPlaceholder : null,
          queryParameters: redactedParams,
        )
        .toString();
  }

  /// Finds HTTP(S) URLs embedded in [text] and redacts their query parameters
  /// and userInfo credentials.
  ///
  /// Useful for sanitizing error messages that may contain full URLs with
  /// sensitive query parameters or credentials.
  String redactUrlsInText(String text) => text.replaceAllMapped(
        urlPattern,
        (match) => redactUrl(match.group(0)!),
      );

  // ---------------------------------------------------------------------------
  // Shared patterns
  // ---------------------------------------------------------------------------

  static final _urlCredentialPattern =
      RegExp(r'://([^:/@\s]+)(?::([^/@\s]*))?@');

  // ---------------------------------------------------------------------------
  // Target redaction (static — Layer 2, trace pipeline)
  // ---------------------------------------------------------------------------

  /// Redacts URL credentials and query params with sensitive keys in a target
  /// string. Used by the `trace()` pipeline for auto-redaction of the target
  /// field.
  static String redactTarget(String target, Set<String> redactKeys) {
    // 1. URL credentials: ://user:pass@host → ://***:***@host
    var result = target.replaceAllMapped(
      _urlCredentialPattern,
      (m) => m[2] != null ? '://***:***@' : '://***@',
    );
    // 2. Query params with sensitive keys
    if (result.contains('?')) {
      for (final key in redactKeys) {
        final escaped = RegExp.escape(key);
        result = result.replaceAllMapped(
          RegExp('([?&])($escaped)=([^&\\s]*)', caseSensitive: false),
          (m) => '${m[1]}${m[2]}=***',
        );
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Export string redaction (static — Layer 3, export)
  // ---------------------------------------------------------------------------

  /// Regex-based redaction for export strings. Covers URL credentials,
  /// Bearer/Basic tokens, query params, and JSON patterns.
  ///
  /// Used by toText(), toMarkdown(), LogExporter for exception.toString()
  /// and error strings that may contain sensitive data.
  static String redactExportString(String value, Set<String>? redactKeys) {
    if (redactKeys == null || redactKeys.isEmpty) return value;

    // A single alternation over all keys compiles two regexes instead of one
    // per key, which matters when [redactKeys] is the full default set.
    final keys = redactKeys.map(RegExp.escape).join('|');

    return value
        .replaceAllMapped(
          _urlCredentialPattern,
          (m) => m[2] != null ? '://***:***@' : '://***@',
        )
        .replaceAllMapped(
          _exportTokenPattern,
          (m) => '${m[1]} ***',
        )
        .replaceAllMapped(
          RegExp('([?&])($keys)=([^&\\s]*)', caseSensitive: false),
          (m) => '${m[1]}${m[2]}=***',
        )
        .replaceAllMapped(
          RegExp('"($keys)"\\s*:\\s*"[^"]*"', caseSensitive: false),
          (m) => '"${m[1]}": "***"',
        );
  }

  static final _exportTokenPattern = RegExp(
    r'(Bearer|Basic|Token)\s+[A-Za-z0-9+/=._~-]+',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // Lightweight key-based redaction (static)
  // ---------------------------------------------------------------------------

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
    int maxDepth = 50,
    String placeholder = redactedMask,
  }) {
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
    if (data == null || maxDepth <= 0) return data;
    if (data is Map) {
      final out = <String, Object?>{};
      data.forEach((k, v) {
        final keyStr = k.toString();
        final hit = lowerKeys.contains(keyStr.toLowerCase());
        out[keyStr] = hit
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
