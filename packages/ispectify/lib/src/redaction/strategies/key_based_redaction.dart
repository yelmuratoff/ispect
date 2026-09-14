import 'dart:typed_data';

import 'package:ispectify/src/redaction/strategies/redaction_strategy.dart';

/// Redacts values based on key names: fully-masked keys and sensitive keys.
///
/// Fully-masked keys produce [RedactionContext.placeholder] regardless of
/// value type, except for an explicitly ignored string value. Sensitive keys
/// get partial masking (edge-visible) for strings and placeholder for other
/// types.
class KeyBasedRedaction implements RedactionStrategy {
  const KeyBasedRedaction();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) {
    if (keyName == null) return null;

    final classification = context.classifyKey(keyName);

    // Structured and binary full-mask values can never fall through merely
    // because the same key is absent from the sensitive-key set.
    if (classification.fullyMasked) {
      if (node is String && context.isIgnoredValue(node)) return node;
      return context.placeholder;
    }

    // Sensitive keys: redact the value.
    if (!classification.sensitive) return null;

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
