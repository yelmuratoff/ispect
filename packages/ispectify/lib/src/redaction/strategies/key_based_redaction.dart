import 'dart:typed_data';

import 'package:ispectify/src/redaction/strategies/redaction_strategy.dart';

/// Redacts values based on sensitive key names.
class KeyBasedRedaction implements RedactionStrategy {
  const KeyBasedRedaction();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionRuntime runtime,
    String? keyName,
  }) {
    if (!runtime.isSensitiveKey(keyName)) return null;

    if (node is String) {
      if (runtime.isIgnoredValue(node)) return node;
      final lower = keyName?.toLowerCase();
      if (lower != null && runtime.fullyMaskedKeyNamesLower.contains(lower)) {
        return runtime.placeholder;
      }
      return runtime.maskString(node, keyName: keyName);
    }

    if (node is Uint8List) {
      return runtime.redactBinary ? runtime.redactUint8List(node) : node;
    }

    // For scalars and any other types behind sensitive keys, use placeholder.
    return runtime.placeholder;
  }
}
