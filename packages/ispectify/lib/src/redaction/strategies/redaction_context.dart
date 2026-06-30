import 'dart:typed_data';

/// Provides redaction helpers and configuration to strategies at call-time.
///
/// Acts as a mediator between the tree-walking engine and pluggable strategies,
/// exposing only the capabilities strategies need without coupling them to
/// walker internals.
final class RedactionContext {
  const RedactionContext({
    required this.placeholder,
    required this.redactBinary,
    required this.redactBase64,
    required this.sensitiveKeysLower,
    required this.sensitiveKeyPatterns,
    required this.fullyMaskedKeyNamesLower,
    required this.isIgnoredValue,
    required this.isIgnoredKey,
    required this.maskString,
    required this.binaryPlaceholder,
    required this.base64Placeholder,
    required this.redactUint8List,
    required this.looksLikeAuthorizationValue,
    required this.isLikelyBase64,
    required this.isProbablyBinaryString,
  });

  final String placeholder;
  final bool redactBinary;
  final bool redactBase64;
  final Set<String> sensitiveKeysLower;
  final List<RegExp> sensitiveKeyPatterns;
  final Set<String> fullyMaskedKeyNamesLower;

  final bool Function(String value) isIgnoredValue;
  final bool Function(String lowerKeyName) isIgnoredKey;
  final String Function(String value, {String? keyName}) maskString;
  final String Function(int length) binaryPlaceholder;
  final String Function(int length) base64Placeholder;
  final Uint8List Function(Uint8List data) redactUint8List;

  final bool Function(String value) looksLikeAuthorizationValue;
  final bool Function(String value) isLikelyBase64;
  final bool Function(String value) isProbablyBinaryString;

  /// Classifies [keyName] as fully-masked and/or sensitive in a single
  /// normalization pass, so the per-key hot path avoids repeating
  /// trim/lowercase/canonicalize across separate [isSensitiveKey] and
  /// [isFullyMaskedKey] calls.
  ///
  /// Matching is case-insensitive, whitespace-trimmed, and camelCase-aware:
  /// `accessToken` is normalized to `access_token` before matching, so the
  /// default snake/kebab key set and patterns also cover the camelCase keys
  /// that dominate Dart/JS JSON payloads.
  ({bool fullyMasked, bool sensitive}) classifyKey(String? keyName) {
    if (keyName == null) return _noMatch;
    final trimmed = keyName.trim();
    final lower = trimmed.toLowerCase();
    if (isIgnoredKey(lower)) return _noMatch;
    final canonical = trimmed == lower ? null : _canonicalizeKey(trimmed);
    return (
      fullyMasked: fullyMaskedKeyNamesLower.contains(lower) ||
          (canonical != null && fullyMaskedKeyNamesLower.contains(canonical)),
      sensitive: _matchesSensitive(lower) ||
          (canonical != null && _matchesSensitive(canonical)),
    );
  }

  /// Whether [keyName] is classified as sensitive. See [classifyKey].
  bool isSensitiveKey(String? keyName) => classifyKey(keyName).sensitive;

  /// Same as [isSensitiveKey] but expects an already-lowercased key.
  ///
  /// Cannot recover camelCase boundaries from an already-lowercased key, so
  /// prefer [isSensitiveKey] when the original-case key is available.
  bool isSensitiveKeyLower(String lowerKey) {
    final trimmed = lowerKey.trim();
    if (isIgnoredKey(trimmed)) return false;
    return _matchesSensitive(trimmed);
  }

  /// Whether [keyName]'s value must be fully replaced with the placeholder
  /// (no edge-visible characters). See [classifyKey].
  bool isFullyMaskedKey(String? keyName) => classifyKey(keyName).fullyMasked;

  static const ({bool fullyMasked, bool sensitive}) _noMatch =
      (fullyMasked: false, sensitive: false);

  bool _matchesSensitive(String lowerKey) {
    if (sensitiveKeysLower.contains(lowerKey)) return true;
    for (final pattern in sensitiveKeyPatterns) {
      if (pattern.hasMatch(lowerKey)) return true;
    }
    return false;
  }

  /// Normalizes camelCase / PascalCase boundaries to `_`, then lowercases.
  /// `accessToken`, `AccessToken`, and `XMLHttpToken` → `access_token` /
  /// `xml_http_token`.
  static String _canonicalizeKey(String key) => key
      .replaceAllMapped(_acronymBoundary, (m) => '${m[1]}_${m[2]}')
      .replaceAllMapped(_camelBoundary, (m) => '${m[1]}_${m[2]}')
      .toLowerCase();

  static final RegExp _camelBoundary = RegExp('([a-z0-9])([A-Z])');
  static final RegExp _acronymBoundary = RegExp('([A-Z]+)([A-Z][a-z])');
}
