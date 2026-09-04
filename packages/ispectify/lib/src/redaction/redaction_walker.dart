import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/src/redaction/constants/detection_patterns.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;
import 'package:ispectify/src/redaction/key_canonicalizer.dart';
import 'package:ispectify/src/redaction/redaction_config.dart';
import 'package:ispectify/src/redaction/redaction_request.dart';
import 'package:ispectify/src/redaction/redaction_stats.dart';
import 'package:ispectify/src/redaction/strategies/redaction_strategy.dart';

const String _unprintableMapKey = '<unprintable-key>';

({String value, bool isSafe}) _safeMapKey(Object? key) => switch (key) {
      String() => (value: key, isSafe: true),
      null => (value: 'null', isSafe: true),
      bool() => (value: key ? 'true' : 'false', isSafe: true),
      num() => (value: key.toString(), isSafe: true),
      Enum() => (value: key.name, isSafe: true),
      _ => (value: _unprintableMapKey, isSafe: false),
    };

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

  /// Key classification and masking helpers bound to this walker's config.
  RedactionContext get context => _cachedContext ??= _createContext();

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

    final ctx = _cachedContext ??= _createContext();
    final binaryBytes = _binaryBytes(node);
    if (binaryBytes != null && config.redactBinary) {
      _trackStrategyHit(keyName);
      return ctx.redactUint8List(binaryBytes);
    }

    // Delegate leaf redaction to pluggable strategies. A strategy that throws
    // propagates by design: boundary callers (NetworkRedactionMixin.safeRedact
    // / processMapData) catch it, log a warning, and fail closed to a
    // placeholder — so failures stay loud rather than being silently swallowed.
    final strategyResult = strategy.tryRedact(
      node,
      keyName: keyName,
      context: ctx,
    );
    if (strategyResult != null) {
      _trackStrategyHit(keyName);
      return strategyResult;
    }

    // Typed binary must remain atomic when masking is deliberately disabled.
    // Typed list views also implement List; traversing them here would
    // materialize the entire buffer before an outbound byte budget can apply.
    if (binaryBytes != null) return node;

    // Structural traversal — strategies had no opinion, recurse into
    // containers or pass through leaf values unchanged.
    if (node is Map) return _redactMap(node, depth);
    if (node is List) return _redactList(node, keyName, depth);

    return node;
  }

  static Uint8List? _binaryBytes(Object? value) {
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

  RedactionContext _createContext() => RedactionContext.cached(
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
    final ctx = _cachedContext;
    if (keyName != null && ctx != null) {
      final classification = ctx.classifyKey(keyName);
      if (classification.fullyMasked || classification.sensitive) {
        stats.incrementKeyBased();
        return;
      }
    }
    stats.incrementPatternBased();
  }

  // Structural traversal

  Map<String, Object?> _redactMap(Map<Object?, Object?> input, int depth) {
    final result = <String, Object?>{};
    input.forEach((key, value) {
      final normalizedKey = _safeMapKey(key);
      result[normalizedKey.value] = normalizedKey.isSafe
          ? _redactNode(
              value,
              keyName: normalizedKey.value,
              depth: depth + 1,
            )
          : config.placeholder;
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

  // String masking

  String _maskString(String value, {required String? keyName}) {
    if (value == config.placeholder) return value;

    if (_isAuthorizationHeader(keyName)) {
      final match = authorizationSchemeRegex.firstMatch(value);
      if (match != null) {
        final scheme = match.group(1) ?? '';
        final separator = match.group(2) ?? ' ';
        return '$scheme$separator${config.placeholder}';
      }
      return config.placeholder;
    }

    final match = schemeRegex.firstMatch(value);
    if (match != null) {
      final prefix = match.group(0) ?? '';
      final remainder = value.substring(prefix.length);
      return '$prefix${_maskEdges(remainder)}';
    }

    if (_isCookieHeader(keyName)) {
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

  static bool _isAuthorizationHeader(String? keyName) => _hasTerminalKey(
        keyName,
        const {'authorization', 'proxy_authorization'},
      );

  static bool _isCookieHeader(String? keyName) => _hasTerminalKey(
        keyName,
        const {cookieHeaderKey, 'set_cookie'},
      );

  static bool _hasTerminalKey(String? keyName, Set<String> candidates) {
    if (keyName == null) return false;
    final canonical = canonicalizeKey(keyName);
    return candidates.any(
      (candidate) =>
          canonical == candidate || canonical.endsWith('_$candidate'),
    );
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

  // Content detection heuristics

  bool _looksLikeAuthorizationValue(String value) {
    if (value.length >= 32 && jwtRegex.hasMatch(value)) return true;
    if (value.length >= 5 && schemeRegex.hasMatch(value)) return true;
    return value.length >= 3 && tokenPrefixRegex.hasMatch(value);
  }

  bool _isLikelyBase64(String value) {
    if (value.length < 32) return false;
    final sanitized = value.replaceAll(base64LineBreakRegex, '');
    if (sanitized.length < 32) return false;
    if (!base64Regex.hasMatch(sanitized)) return false;
    if (sanitized.length % 4 == 1) return false;
    if (hexIdentifierRegex.hasMatch(sanitized)) return false;

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

  // Placeholders & binary helpers

  String _binaryPlaceholder(int length) => ph.binaryPlaceholder(length);

  String _base64Placeholder(int length) => ph.base64Placeholder(length);

  /// Replaces [data] with a compact human-readable byte-count placeholder.
  ///
  /// Diagnostics are outbound snapshots, not protocol buffers. Keeping the
  /// original allocation size would let a large capture multiply memory use
  /// during redaction, normalization, and JSON encoding.
  Uint8List _redactUint8List(Uint8List data) =>
      Uint8List.fromList(utf8.encode(_binaryPlaceholder(data.length)));

  // Ignore helpers (merge config-level and per-call overrides)

  bool _isIgnoredValue(String value) =>
      config.ignoredValues.contains(value) ||
      (request.ignoredValues?.contains(value) ?? false);

  bool _isIgnoredKey(String keyLower) =>
      config.ignoredKeyNamesLower.contains(keyLower) ||
      (request.ignoredKeysLower?.contains(keyLower) ?? false);
}
