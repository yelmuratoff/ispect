import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/src/redaction/strategies/redaction_strategy.dart';

/// Redacts values based on content patterns (tokens, JWTs, base64, binary).
///
/// Handles [String] content heuristics plus every [TypedData] view and
/// [ByteBuffer] as binary data. Returns `null` when no pattern matches,
/// allowing other strategies or fallback traversal to proceed.
class PatternBasedRedaction implements RedactionStrategy {
  const PatternBasedRedaction();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) {
    final binaryBytes = _binaryBytes(node);
    if (binaryBytes != null) {
      return context.redactBinary ? context.redactUint8List(binaryBytes) : null;
    }

    if (node is! String) return null;
    if (context.isIgnoredValue(node)) return null;

    // Authorization-like values (Bearer, JWT, ghp_ tokens, etc.).
    if (context.looksLikeAuthorizationValue(node)) {
      return context.maskString(node, keyName: keyName);
    }

    // Base64-like large strings.
    if (context.redactBase64 && context.isLikelyBase64(node)) {
      return context.base64Placeholder(node.length);
    }

    // Binary-looking strings (high ratio of non-printable characters).
    if (context.redactBinary && context.isProbablyBinaryString(node)) {
      return context.binaryPlaceholder(utf8.encode(node).length);
    }

    return null;
  }
}

Uint8List? _binaryBytes(Object? value) {
  if (value is ByteBuffer) return value.asUint8List();
  if (value is TypedData) {
    return Uint8List.view(
      value.buffer,
      value.offsetInBytes,
      value.lengthInBytes,
    );
  }
  return null;
}
