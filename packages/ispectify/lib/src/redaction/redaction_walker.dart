import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/src/redaction/constants/detection_patterns.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;
import 'package:ispectify/src/redaction/redaction_config.dart';
import 'package:ispectify/src/redaction/redaction_request.dart';
import 'package:ispectify/src/redaction/redaction_stats.dart';
import 'package:ispectify/src/redaction/strategies/redaction_strategy.dart';

/// Recursive tree-walker that delegates leaf redaction to [RedactionStrategy]
/// and handles structural traversal (Maps, Lists) with depth limiting.
///
/// Receives an immutable [RedactionConfig] snapshot at construction time rather
/// than a reference to the [RedactionService]. This ensures that in-flight
/// walkers are unaffected by concurrent config mutations (e.g. calls to
/// `ignoreValue()` or `ignoreKey()` on the service).
final class RedactionWalker {
  RedactionWalker(this.config, this.request, this.strategy)
      : _cachedContext = null,
        stats = RedactionStats();

  final RedactionConfig config;
  final RedactionRequest request;
  final RedactionStrategy strategy;

  /// Counters populated during traversal.
  final RedactionStats stats;

  RedactionContext? _cachedContext;

  Map<String, Object?> redactHeaders(Map<String, Object?> headers) {
    final out = <String, Object?>{};
    headers.forEach((key, value) {
      out[key] = _redactNode(value, keyName: key, depth: 0);
    });
    return out;
  }

  Object? redact(Object? data, {String? keyName}) =>
      _redactNode(data, keyName: keyName, depth: 0);

  Object? _redactNode(
    Object? node, {
    required String? keyName,
    required int depth,
  }) {
    if (node == null) return null;
    if (depth >= config.maxDepth) {
      stats.incrementDepthLimited();
      return config.placeholder;
    }

    // Delegate leaf redaction to pluggable strategies.
    final ctx = _cachedContext ??= _createContext();
    final strategyResult = strategy.tryRedact(
      node,
      keyName: keyName,
      context: ctx,
    );
    if (strategyResult != null) {
      _trackStrategyHit(keyName);
      return strategyResult;
    }

    // Structural traversal — strategies had no opinion, recurse into
    // containers or pass through leaf values unchanged.
    if (node is Map) return _redactMap(node, depth);
    if (node is List) return _redactList(node, keyName, depth);

    return node;
  }

  RedactionContext _createContext() => RedactionContext(
        placeholder: config.placeholder,
        redactBinary: config.redactBinary,
        redactBase64: config.redactBase64,
        sensitiveKeysLower: config.sensitiveKeysLower,
        sensitiveKeyPatterns: config.sensitiveKeyPatterns,
        fullyMaskedKeyNamesLower: config.fullyMaskedKeyNamesLower,
        isIgnoredValue: _isIgnoredValue,
        isIgnoredKey: _isIgnoredKey,
        maskString: (value, {keyName}) => _maskString(value, keyName: keyName),
        binaryPlaceholder: _binaryPlaceholder,
        base64Placeholder: _base64Placeholder,
        redactUint8List: _redactUint8List,
        looksLikeAuthorizationValue: _looksLikeAuthorizationValue,
        isLikelyBase64: _isLikelyBase64,
        isProbablyBinaryString: _isProbablyBinaryString,
      );

  /// Determines whether the hit was key-based or pattern-based.
  void _trackStrategyHit(String? keyName) {
    if (keyName != null) {
      final lower = keyName.toLowerCase();
      if (config.fullyMaskedKeyNamesLower.contains(lower) ||
          (_cachedContext?.isSensitiveKeyLower(lower) ?? false)) {
        stats.incrementKeyBased();
        return;
      }
    }
    stats.incrementPatternBased();
  }

  // ---------------------------------------------------------------------------
  // Structural traversal
  // ---------------------------------------------------------------------------

  Map<Object?, Object?> _redactMap(Map<Object?, Object?> input, int depth) {
    if (input is Map<String, Object?>) {
      final result = <String, Object?>{};
      input.forEach((key, value) {
        result[key] = _redactNode(value, keyName: key, depth: depth + 1);
      });
      return result;
    }

    final result = <Object?, Object?>{};
    input.forEach((key, value) {
      result[key] = _redactNode(
        value,
        keyName: key?.toString(),
        depth: depth + 1,
      );
    });
    return result;
  }

  List<Object?> _redactList(
    List<Object?> input,
    String? keyName,
    int depth,
  ) =>
      input
          .map(
            (value) => _redactNode(
              value,
              keyName: keyName,
              depth: depth + 1,
            ),
          )
          .toList(growable: false);

  // ---------------------------------------------------------------------------
  // String masking
  // ---------------------------------------------------------------------------

  String _maskString(String value, {required String? keyName}) {
    if (value == config.placeholder) return value;

    final match = schemeRegex.firstMatch(value);
    if (match != null) {
      final prefix = match.group(0) ?? '';
      final remainder = value.substring(prefix.length);
      return '$prefix${_maskEdges(remainder)}';
    }

    if (keyName != null && keyName.toLowerCase() == cookieHeaderKey) {
      return value.split(';').map((part) {
        final trimmed = part.trim();
        final separatorIndex = trimmed.indexOf('=');
        if (separatorIndex <= 0) return trimmed;
        final name = trimmed.substring(0, separatorIndex);
        final cookieValue = trimmed.substring(separatorIndex + 1);
        return '$name=${_maskEdges(cookieValue)}';
      }).join('; ');
    }

    return _maskEdges(value);
  }

  /// Masks a string keeping [visibleEdgeLength] characters on each side.
  ///
  /// When the string is too short (≤ `edge * 3`), showing edges would expose
  /// most of the value, so the entire string is replaced with placeholder.
  String _maskEdges(String input) {
    if (input.isEmpty) return config.placeholder;
    final edge = config.visibleEdgeLength;
    if (input.length <= edge * 3) return config.placeholder;

    final start = input.substring(0, edge);
    final end = input.substring(input.length - edge);
    return '$start…$end (${config.placeholder})';
  }

  // ---------------------------------------------------------------------------
  // Content detection heuristics
  // ---------------------------------------------------------------------------

  bool _looksLikeAuthorizationValue(String value) {
    if (jwtRegex.hasMatch(value)) return true;
    if (schemeRegex.hasMatch(value)) return true;
    return tokenPrefixRegex.hasMatch(value);
  }

  bool _isLikelyBase64(String value) {
    final sanitized = value.replaceAll(whitespaceRegex, '');
    if (sanitized.length < 32) return false;
    if (!base64Regex.hasMatch(sanitized)) return false;
    if (sanitized.length % 4 == 1) return false;

    final sampleLength = sanitized.length > 256 ? 256 : sanitized.length;
    final sample = sanitized.substring(0, sampleLength);
    return _canDecodeBase64Sample(sample);
  }

  bool _canDecodeBase64Sample(String sample) {
    if (_tryDecodeWithCodec(sample, base64)) return true;
    if (_tryDecodeWithCodec(sample, base64Url)) return true;
    return false;
  }

  bool _tryDecodeWithCodec(String input, Base64Codec codec) {
    try {
      codec.decode(input);
      return true;
    } on FormatException {
      final remainder = input.length % 4;
      if (remainder == 0) return false;
      final padded = input.padRight(input.length + (4 - remainder), '=');
      try {
        codec.decode(padded);
        return true;
      } on FormatException {
        return false;
      }
    }
  }

  bool _isProbablyBinaryString(String value) {
    const maxNonPrintable = 8;
    const maxInspected = 1024;
    const ratioThreshold = 0.2;
    const ratioSampleFloor = 16;

    var inspected = 0;
    var nonPrintable = 0;
    for (final codePoint in value.runes) {
      if (inspected >= maxInspected) break;
      inspected++;
      if (_isPrintableCodePoint(codePoint)) continue;
      nonPrintable++;
      if (nonPrintable > maxNonPrintable) return true;
      if (inspected >= ratioSampleFloor &&
          nonPrintable / inspected > ratioThreshold) {
        return true;
      }
    }
    return false;
  }

  bool _isPrintableCodePoint(int codePoint) {
    if (codePoint == 0xFFFD) return false;
    if (codePoint == 0x09 || codePoint == 0x0A || codePoint == 0x0D) {
      return true;
    }
    if (codePoint >= 0x20 && codePoint <= 0x7E) return true;
    if (codePoint == 0x85 || codePoint == 0x2028 || codePoint == 0x2029) {
      return true;
    }
    if (codePoint >= 0xA0 && codePoint <= 0xD7FF) return true;
    if (codePoint >= 0xE000 && codePoint <= 0x10FFFF) return true;
    return false;
  }

  // ---------------------------------------------------------------------------
  // Placeholders & binary helpers
  // ---------------------------------------------------------------------------

  String _binaryPlaceholder(int length) => ph.binaryPlaceholder(length);

  String _base64Placeholder(int length) => ph.base64Placeholder(length);

  /// Replaces [data] with a same-length buffer containing a human-readable
  /// placeholder followed by zero-padding.
  ///
  /// Preserving the original length ensures that downstream code relying on
  /// fixed-size byte arrays (e.g. protocol frames, chunked transfer) does not
  /// break when redaction is enabled.
  Uint8List _redactUint8List(Uint8List data) {
    final placeholder = _binaryPlaceholder(data.length);
    final placeholderBytes = Uint8List.fromList(utf8.encode(placeholder));
    final length = placeholderBytes.length > data.length
        ? data.length
        : placeholderBytes.length;
    final result = Uint8List(data.length)
      ..setRange(0, length, placeholderBytes.take(length));
    for (var i = length; i < data.length; i++) {
      result[i] = 0;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Ignore helpers (merge config-level and per-call overrides)
  // ---------------------------------------------------------------------------

  bool _isIgnoredValue(String value) =>
      config.ignoredValues.contains(value) ||
      (request.ignoredValues?.contains(value) ?? false);

  bool _isIgnoredKey(String keyLower) =>
      config.ignoredKeyNamesLower.contains(keyLower) ||
      (request.ignoredKeysLower?.contains(keyLower) ?? false);
}
