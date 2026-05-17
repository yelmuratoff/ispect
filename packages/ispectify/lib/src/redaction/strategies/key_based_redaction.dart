import 'dart:typed_data';

import 'package:ispectify/src/redaction/strategies/redaction_strategy.dart';

/// Redacts values based on key names: fully-masked keys and sensitive keys.
///
/// Fully-masked keys always produce [RedactionContext.placeholder] regardless
/// of whether the key is also classified as sensitive. Sensitive keys get
/// partial masking (edge-visible) for strings and placeholder for other types.
class KeyBasedRedaction implements RedactionStrategy {
  const KeyBasedRedaction();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) {
    if (keyName == null) return null;

    final lower = keyName.toLowerCase();

    // Fully-masked keys: replace the entire string value with placeholder.
    if (context.fullyMaskedKeyNamesLower.contains(lower)) {
      if (node is String && !context.isIgnoredValue(node)) {
        return context.placeholder;
      }
    }

    // Sensitive keys: redact the value.
    if (!context.isSensitiveKeyLower(lower)) return null;

    if (node is String) {
      if (context.isIgnoredValue(node)) return node;
      return context.maskString(node, keyName: keyName);
    }

    if (node is Uint8List) {
      return context.redactBinary ? context.redactUint8List(node) : node;
    }

    // Scalars and any other types behind sensitive keys → placeholder.
    return context.placeholder;
  }
}
