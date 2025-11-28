import 'dart:typed_data';

/// Provides redaction helpers and configuration to strategies at runtime.
class RedactionRuntime {
  const RedactionRuntime({
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

  bool isSensitiveKey(String? keyName) {
    if (keyName == null) return false;
    final lower = keyName.toLowerCase();
    if (isIgnoredKey(lower)) return false;
    if (sensitiveKeysLower.contains(lower)) return true;
    for (final pattern in sensitiveKeyPatterns) {
      if (pattern.hasMatch(lower)) return true;
    }
    return false;
  }
}

/// Redaction strategy interface.
///
/// Implementations return a non-null value when they apply a redaction to the
/// given node in the provided context. Returning null means "no opinion" and
/// allows other strategies or fallbacks to handle it.
abstract class RedactionStrategy {
  Object? tryRedact(
    Object? node, {
    required RedactionRuntime runtime,
    String? keyName,
  });
}
