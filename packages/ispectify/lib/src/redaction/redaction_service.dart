import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart'
    as ph;
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
          sensitiveKeysLower: (sensitiveKeys ?? defaultSensitiveKeys)
              .map((e) => e.toLowerCase())
              .toSet(),
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
          fullyMaskedKeyNamesLower:
              (fullyMaskedKeys ?? defaultFullyMaskedKeys)
                  .map((e) => e.toLowerCase())
                  .toSet(),
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
  /// (no query parameters and no userInfo) or the URL cannot be parsed.
  String redactUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

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
    List<String> keys, {
    int maxDepth = 50,
    String placeholder = redactedMask,
  }) {
    if (data == null || keys.isEmpty || maxDepth <= 0) return data;
    if (data is Map) {
      final out = <String, Object?>{};
      data.forEach((k, v) {
        final keyStr = k.toString();
        final keyLower = keyStr.toLowerCase();
        final hit = keys.any((rk) => rk.toLowerCase() == keyLower);
        out[keyStr] = hit
            ? placeholder
            : redactByKeys(
                v,
                keys,
                maxDepth: maxDepth - 1,
                placeholder: placeholder,
              );
      });
      return out;
    }
    if (data is Iterable) {
      return data
          .map(
            (e) => redactByKeys(
              e as Object?,
              keys,
              maxDepth: maxDepth - 1,
              placeholder: placeholder,
            ),
          )
          .toList();
    }
    return data;
  }
}
