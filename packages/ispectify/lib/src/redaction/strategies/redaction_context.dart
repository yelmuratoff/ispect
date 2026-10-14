import 'dart:typed_data';

import 'package:ispectify/src/redaction/constants/credential_markers.dart';
import 'package:ispectify/src/redaction/key_canonicalizer.dart';
import 'package:ispectify/src/redaction/secret_metadata.dart';

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
  }) : _classificationCache = null;

  /// Caches at most 256 repeated field names for this context's lifetime.
  RedactionContext.cached({
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
  }) : _classificationCache = {};

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
  final Map<String, _KeyClassification>? _classificationCache;

  /// Classifies [keyName] as fully-masked and/or sensitive in a single
  /// normalization pass, so the per-key hot path avoids repeating
  /// trim/lowercase/canonicalize across separate [isSensitiveKey] and
  /// [isFullyMaskedKey] calls.
  ///
  /// Matching is case-insensitive, whitespace-trimmed, camelCase-aware, and
  /// treats dotted or bracketed path segments like snake-case segments.
  /// A metadata key such as `password_set` keeps the classification of its
  /// sensitive stem because no value is available to check; use
  /// [classifyEntry] to let non-secret metadata values through.
  ({bool fullyMasked, bool sensitive}) classifyKey(String? keyName) {
    if (keyName == null) return _noMatch;
    final classification = _cachedClassification(keyName);
    return (
      fullyMasked: classification.fullyMasked,
      sensitive: classification.sensitive,
    );
  }

  /// Classifies [keyName] like [classifyKey], but keeps a metadata key such
  /// as `password_set` or `token_type` sensitive unless [value] is non-secret
  /// metadata: `null`, a boolean, a number, or a short scheme, version, or
  /// timestamp string.
  ({bool fullyMasked, bool sensitive}) classifyEntry(
    String? keyName,
    Object? value,
  ) {
    if (keyName == null) return _noMatch;
    final classification = _cachedClassification(keyName);
    final metadata = classification.metadata;
    if (metadata != null && isSecretMetadataValue(metadata, value)) {
      return _noMatch;
    }
    return (
      fullyMasked: classification.fullyMasked,
      sensitive: classification.sensitive,
    );
  }

  _KeyClassification _cachedClassification(String keyName) {
    final cache = _classificationCache;
    final cached = cache?[keyName];
    if (cached != null) return cached;
    final classification = _classifyKey(keyName);
    if (cache != null && cache.length < _maxClassificationCacheEntries) {
      cache[keyName] = classification;
    }
    return classification;
  }

  _KeyClassification _classifyKey(String keyName) {
    final trimmed = keyName.trim();
    final lower = trimmed.toLowerCase();
    if (isIgnoredKey(lower)) return _noClassification;
    var fullyMasked = fullyMaskedKeyNamesLower.contains(lower);
    var sensitive = _matchesSensitive(lower);
    final needsCanonicalization = trimmed != lower ||
        trimmed.contains('.') ||
        trimmed.contains('-') ||
        trimmed.contains('[');
    if (!needsCanonicalization && !lower.contains('_')) {
      return (fullyMasked: fullyMasked, sensitive: sensitive, metadata: null);
    }

    final canonical = needsCanonicalization ? canonicalizeKey(trimmed) : lower;
    if (canonical != lower) {
      fullyMasked = fullyMasked || fullyMaskedKeyNamesLower.contains(canonical);
      sensitive = sensitive || _matchesSensitive(canonical);
    }
    final segments = (fullyMasked && sensitive) || !canonical.contains('_')
        ? (fullyMasked: fullyMasked, sensitive: sensitive)
        : _classifyCanonicalSegments(
            canonical,
            fullyMasked: fullyMasked,
            sensitive: sensitive,
          );
    if (!segments.fullyMasked && !segments.sensitive) {
      return _noClassification;
    }
    return (
      fullyMasked: segments.fullyMasked,
      sensitive: segments.sensitive,
      metadata: _secretMetadataQualifier(canonical) ??
          _secretMetadataQualifier(lower),
    );
  }

  /// Whether [keyName] is classified as sensitive. See [classifyKey].
  bool isSensitiveKey(String? keyName) => classifyKey(keyName).sensitive;

  /// Same as [isSensitiveKey] but expects an already-lowercased key.
  ///
  /// Cannot recover camelCase boundaries from an already-lowercased key, so
  /// prefer [isSensitiveKey] when the original-case key is available.
  @Deprecated(
    'Use isSensitiveKey, which classifies the original-case key. '
    'Will be removed in 8.0.0.',
  )
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
  static const _KeyClassification _noClassification =
      (fullyMasked: false, sensitive: false, metadata: null);
  static const int _maxClassificationCacheEntries = 256;

  SecretMetadataQualifier? _secretMetadataQualifier(String key) {
    if (sensitiveKeysLower.contains(key) ||
        fullyMaskedKeyNamesLower.contains(key)) {
      return null;
    }
    return secretMetadataQualifier(key);
  }

  bool _matchesSensitive(String lowerKey) {
    if (sensitiveKeysLower.contains(lowerKey)) return true;
    for (final pattern in sensitiveKeyPatterns) {
      if (pattern.hasMatch(lowerKey)) return true;
    }
    return false;
  }

  ({bool fullyMasked, bool sensitive}) _classifyCanonicalSegments(
    String canonical, {
    required bool fullyMasked,
    required bool sensitive,
  }) {
    var hasFullyMaskedMatch = fullyMasked;
    var hasSensitiveMatch = sensitive;
    final tokens = canonical
        .split('_')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    for (var start = 0; start < tokens.length; start++) {
      final candidate = StringBuffer();
      for (var end = start; end < tokens.length; end++) {
        if (candidate.isNotEmpty) candidate.write('_');
        candidate.write(tokens[end]);
        final value = candidate.toString();
        if (end < tokens.length - 1 &&
            trailingSegmentOnlyKeys.contains(value)) {
          continue;
        }
        if (!hasFullyMaskedMatch && fullyMaskedKeyNamesLower.contains(value)) {
          hasFullyMaskedMatch = true;
        }
        if (!hasSensitiveMatch && _matchesSensitive(value)) {
          hasSensitiveMatch = true;
        }
        if (hasFullyMaskedMatch && hasSensitiveMatch) {
          return (fullyMasked: true, sensitive: true);
        }
      }
    }
    return (
      fullyMasked: hasFullyMaskedMatch,
      sensitive: hasSensitiveMatch,
    );
  }
}

typedef _KeyClassification = ({
  bool fullyMasked,
  bool sensitive,
  SecretMetadataQualifier? metadata,
});
