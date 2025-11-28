import 'package:ispectify/src/redaction/strategies/redaction_strategy.dart';

/// Redacts based on content patterns (tokens, JWTs, base64, binary).
class PatternBasedRedaction implements RedactionStrategy {
  const PatternBasedRedaction();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionRuntime runtime,
    String? keyName,
  }) {
    if (node is! String) return null;

    if (runtime.isIgnoredValue(node)) return null;

    // Obvious authorization-like values
    if (runtime.looksLikeAuthorizationValue(node)) {
      return runtime.maskString(node, keyName: keyName);
    }

    // Base64-like large strings
    if (runtime.redactBase64 && runtime.isLikelyBase64(node)) {
      return runtime.base64Placeholder(node.length);
    }

    // Binary-looking strings
    if (runtime.redactBinary && runtime.isProbablyBinaryString(node)) {
      return runtime.binaryPlaceholder(node.codeUnits.length);
    }

    // Cookie headers: redact each value (keep key names)
    if (keyName != null && keyName.toLowerCase() == 'cookie') {
      return runtime.maskString(node, keyName: keyName);
    }

    return null;
  }
}
