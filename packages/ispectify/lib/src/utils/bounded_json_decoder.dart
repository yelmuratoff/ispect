import 'dart:collection';
import 'dart:convert';

/// Why bounded JSON decoding rejected an input.
///
/// The reason is safe to surface in diagnostics because it never retains the
/// input or parser context.
enum BoundedJsonRejection {
  characterLimit,
  encodedByteLimit,
  depthLimit,
  nodeLimit,
  collectionLimit,
  malformed,
}

/// A source-free JSON decoding failure.
final class BoundedJsonException extends FormatException {
  const BoundedJsonException(this.reason)
      : super(BoundedJsonDecoder.rejectedMessage);

  final BoundedJsonRejection reason;

  bool get isLimit => reason != BoundedJsonRejection.malformed;
}

/// Decodes untrusted JSON within fixed allocation and traversal budgets.
///
/// [validateSource] performs a single string/escape-aware scan before
/// `jsonDecode`, preventing oversized, deeply nested, or excessively wide
/// inputs from reaching the allocating parser. [validateDecoded] then checks
/// the decoded tree iteratively as a defense in depth.
/// `maxRootCollectionItems` can widen only the root envelope while nested
/// collections remain constrained by `maxCollectionItems`.
abstract final class BoundedJsonDecoder {
  static const int defaultMaxCharacters = 1024 * 1024;
  static const int defaultMaxEncodedBytes = 1024 * 1024;
  static const int defaultMaxDepth = 64;
  static const int defaultMaxNodes = 10000;
  static const int defaultMaxCollectionItems = 1000;

  static const String rejectedMessage = 'Invalid or unsafe JSON input.';

  static Object? decode(
    String source, {
    int maxCharacters = defaultMaxCharacters,
    int maxEncodedBytes = defaultMaxEncodedBytes,
    int maxDepth = defaultMaxDepth,
    int maxNodes = defaultMaxNodes,
    int maxCollectionItems = defaultMaxCollectionItems,
    int? maxRootCollectionItems,
  }) {
    validateSource(
      source,
      maxCharacters: maxCharacters,
      maxEncodedBytes: maxEncodedBytes,
      maxDepth: maxDepth,
      maxNodes: maxNodes,
      maxCollectionItems: maxCollectionItems,
      maxRootCollectionItems: maxRootCollectionItems,
    );

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      // jsonDecode attaches the original input to its FormatException.
      throw const BoundedJsonException(BoundedJsonRejection.malformed);
    }

    validateDecoded(
      decoded,
      maxDepth: maxDepth,
      maxNodes: maxNodes,
      maxCollectionItems: maxCollectionItems,
      maxRootCollectionItems: maxRootCollectionItems,
    );
    return decoded;
  }

  /// Rejects unsafe source structure before the allocating JSON parser runs.
  static void validateSource(
    String source, {
    int maxCharacters = defaultMaxCharacters,
    int maxEncodedBytes = defaultMaxEncodedBytes,
    int maxDepth = defaultMaxDepth,
    int maxNodes = defaultMaxNodes,
    int maxCollectionItems = defaultMaxCollectionItems,
    int? maxRootCollectionItems,
  }) {
    final rootCollectionLimit = maxRootCollectionItems ?? maxCollectionItems;
    _validateLimits(
      maxCharacters: maxCharacters,
      maxEncodedBytes: maxEncodedBytes,
      maxDepth: maxDepth,
      maxNodes: maxNodes,
      maxCollectionItems: maxCollectionItems,
      maxRootCollectionItems: rootCollectionLimit,
    );
    if (source.length > maxCharacters) {
      throw const BoundedJsonException(
        BoundedJsonRejection.characterLimit,
      );
    }

    var encodedBytes = 0;
    var nodes = 0;
    var inString = false;
    var escaped = false;
    var bareTokenOpen = false;
    final containers = <_SourceContainer>[];

    void takeNode() {
      nodes++;
      if (nodes > maxNodes) {
        throw const BoundedJsonException(BoundedJsonRejection.nodeLimit);
      }
    }

    for (var index = 0; index < source.length; index++) {
      final codeUnit = source.codeUnitAt(index);
      if (codeUnit <= 0x7f) {
        encodedBytes++;
      } else if (codeUnit <= 0x7ff) {
        encodedBytes += 2;
      } else if (_isHighSurrogate(codeUnit) &&
          index + 1 < source.length &&
          _isLowSurrogate(source.codeUnitAt(index + 1))) {
        encodedBytes += 4;
        index++;
      } else {
        encodedBytes += 3;
      }
      if (encodedBytes > maxEncodedBytes) {
        throw const BoundedJsonException(
          BoundedJsonRejection.encodedByteLimit,
        );
      }

      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (codeUnit == _backslash) {
          escaped = true;
        } else if (codeUnit == _quote) {
          inString = false;
        }
        continue;
      }

      if (codeUnit == _quote) {
        inString = true;
        bareTokenOpen = false;
        takeNode();
        continue;
      }
      if (_isJsonWhitespace(codeUnit)) {
        bareTokenOpen = false;
        continue;
      }

      if (codeUnit == _openBrace || codeUnit == _openBracket) {
        bareTokenOpen = false;
        if (containers.length >= maxDepth) {
          throw const BoundedJsonException(
            BoundedJsonRejection.depthLimit,
          );
        }
        takeNode();
        containers.add(
          _SourceContainer(
            codeUnit,
            maxItems:
                containers.isEmpty ? rootCollectionLimit : maxCollectionItems,
          ),
        );
        continue;
      }

      if (codeUnit == _closeBrace || codeUnit == _closeBracket) {
        bareTokenOpen = false;
        if (containers.isEmpty ||
            !_isMatchingContainer(containers.last.opening, codeUnit)) {
          throw const BoundedJsonException(BoundedJsonRejection.malformed);
        }
        containers.removeLast();
        continue;
      }

      if (codeUnit == _comma) {
        bareTokenOpen = false;
        if (containers.isNotEmpty) {
          final container = containers.last;
          container.separators++;
          if (container.separators >= container.maxItems) {
            throw const BoundedJsonException(
              BoundedJsonRejection.collectionLimit,
            );
          }
        }
        continue;
      }

      if (codeUnit == _colon) {
        bareTokenOpen = false;
        continue;
      }

      if (!bareTokenOpen) {
        bareTokenOpen = true;
        takeNode();
      }
    }

    if (inString || escaped || containers.isNotEmpty) {
      throw const BoundedJsonException(BoundedJsonRejection.malformed);
    }
  }

  /// Validates a decoded JSON-like tree without recursive traversal.
  static void validateDecoded(
    Object? value, {
    int maxDepth = defaultMaxDepth,
    int maxNodes = defaultMaxNodes,
    int maxCollectionItems = defaultMaxCollectionItems,
    int? maxRootCollectionItems,
  }) {
    final rootCollectionLimit = maxRootCollectionItems ?? maxCollectionItems;
    _validateLimits(
      maxCharacters: 1,
      maxEncodedBytes: 1,
      maxDepth: maxDepth,
      maxNodes: maxNodes,
      maxCollectionItems: maxCollectionItems,
      maxRootCollectionItems: rootCollectionLimit,
    );

    final pending = <(Object?, int)>[(value, 0)];
    final visitedContainers = HashSet<Object>.identity();
    var nodes = 1;

    void takeNodes(int count) {
      nodes += count;
      if (nodes > maxNodes) {
        throw const BoundedJsonException(BoundedJsonRejection.nodeLimit);
      }
    }

    while (pending.isNotEmpty) {
      final (node, parentDepth) = pending.removeLast();
      final collectionLimit =
          parentDepth == 0 ? rootCollectionLimit : maxCollectionItems;
      if (node is Map) {
        if (!visitedContainers.add(node)) {
          throw const BoundedJsonException(BoundedJsonRejection.malformed);
        }
        if (node.length > collectionLimit) {
          throw const BoundedJsonException(
            BoundedJsonRejection.collectionLimit,
          );
        }
        final depth = parentDepth + 1;
        if (depth > maxDepth) {
          throw const BoundedJsonException(BoundedJsonRejection.depthLimit);
        }
        takeNodes(node.length * 2);
        for (final entry in node.entries) {
          if (entry.key is! String) {
            throw const BoundedJsonException(BoundedJsonRejection.malformed);
          }
          pending.add((entry.value, depth));
        }
      } else if (node is List) {
        if (!visitedContainers.add(node)) {
          throw const BoundedJsonException(BoundedJsonRejection.malformed);
        }
        if (node.length > collectionLimit) {
          throw const BoundedJsonException(
            BoundedJsonRejection.collectionLimit,
          );
        }
        final depth = parentDepth + 1;
        if (depth > maxDepth) {
          throw const BoundedJsonException(BoundedJsonRejection.depthLimit);
        }
        takeNodes(node.length);
        for (final item in node) {
          pending.add((item, depth));
        }
      } else if (node != null &&
          node is! bool &&
          node is! num &&
          node is! String) {
        throw const BoundedJsonException(BoundedJsonRejection.malformed);
      }
    }
  }

  /// Whether [source] has the outer shape of a complete JSON value.
  ///
  /// This lets mixed text/JSON diagnostic fields preserve ordinary text while
  /// malformed structured JSON still fails closed.
  static bool looksLikeJson(String source) {
    var start = 0;
    while (
        start < source.length && _isJsonWhitespace(source.codeUnitAt(start))) {
      start++;
    }
    if (start == source.length) return false;

    var end = source.length;
    while (end > start && _isJsonWhitespace(source.codeUnitAt(end - 1))) {
      end--;
    }

    final first = source.codeUnitAt(start);
    final last = source.codeUnitAt(end - 1);
    if (first == _openBrace) {
      if (last != _closeBrace) return false;
      final valueStart = _skipJsonWhitespace(source, start + 1, end - 1);
      return valueStart == end - 1 || source.codeUnitAt(valueStart) == _quote;
    }
    if (first == _openBracket) {
      if (last != _closeBracket) return false;
      final valueStart = _skipJsonWhitespace(source, start + 1, end - 1);
      return valueStart == end - 1 ||
          _canStartJsonValue(source.codeUnitAt(valueStart));
    }
    if (first == _quote) {
      return last == _quote && _hasSingleQuotedValue(source, start, end);
    }
    if (first == _minus || _isDigit(first)) {
      return _looksLikeJsonNumber(source, start, end);
    }
    return _matchesAscii(source, start, end, 'true') ||
        _matchesAscii(source, start, end, 'false') ||
        _matchesAscii(source, start, end, 'null');
  }

  static int _skipJsonWhitespace(String source, int start, int end) {
    var index = start;
    while (index < end && _isJsonWhitespace(source.codeUnitAt(index))) {
      index++;
    }
    return index;
  }

  static bool _hasSingleQuotedValue(String source, int start, int end) {
    var escaped = false;
    for (var index = start + 1; index < end; index++) {
      final codeUnit = source.codeUnitAt(index);
      if (escaped) {
        escaped = false;
      } else if (codeUnit == _backslash) {
        escaped = true;
      } else if (codeUnit == _quote) {
        return index == end - 1;
      }
    }
    return false;
  }

  static bool _canStartJsonValue(int codeUnit) =>
      codeUnit == _quote ||
      codeUnit == _openBrace ||
      codeUnit == _openBracket ||
      codeUnit == _minus ||
      _isDigit(codeUnit) ||
      codeUnit == _lowercaseT ||
      codeUnit == _lowercaseF ||
      codeUnit == _lowercaseN;

  static bool _looksLikeJsonNumber(String source, int start, int end) {
    var index = start;
    if (source.codeUnitAt(index) == _minus) {
      index++;
      if (index == end) return false;
    }

    final firstDigit = source.codeUnitAt(index);
    if (firstDigit == _zero) {
      index++;
    } else if (firstDigit >= _one && firstDigit <= _nine) {
      do {
        index++;
      } while (index < end && _isDigit(source.codeUnitAt(index)));
    } else {
      return false;
    }

    if (index < end && source.codeUnitAt(index) == _period) {
      index++;
      final fractionStart = index;
      while (index < end && _isDigit(source.codeUnitAt(index))) {
        index++;
      }
      if (index == fractionStart) return false;
    }

    if (index < end) {
      final codeUnit = source.codeUnitAt(index);
      if (codeUnit == _lowercaseE || codeUnit == _uppercaseE) {
        index++;
        if (index < end) {
          final sign = source.codeUnitAt(index);
          if (sign == _plus || sign == _minus) index++;
        }
        final exponentStart = index;
        while (index < end && _isDigit(source.codeUnitAt(index))) {
          index++;
        }
        if (index == exponentStart) return false;
      }
    }
    return index == end;
  }

  static bool _matchesAscii(
    String source,
    int start,
    int end,
    String expected,
  ) {
    if (end - start != expected.length) return false;
    for (var index = 0; index < expected.length; index++) {
      if (source.codeUnitAt(start + index) != expected.codeUnitAt(index)) {
        return false;
      }
    }
    return true;
  }

  static void _validateLimits({
    required int maxCharacters,
    required int maxEncodedBytes,
    required int maxDepth,
    required int maxNodes,
    required int maxCollectionItems,
    required int maxRootCollectionItems,
  }) {
    _requirePositive(maxCharacters, 'maxCharacters');
    _requirePositive(maxEncodedBytes, 'maxEncodedBytes');
    _requirePositive(maxDepth, 'maxDepth');
    _requirePositive(maxNodes, 'maxNodes');
    _requirePositive(maxCollectionItems, 'maxCollectionItems');
    _requirePositive(maxRootCollectionItems, 'maxRootCollectionItems');
  }

  static void _requirePositive(int value, String name) {
    if (value < 1) throw RangeError.range(value, 1, null, name);
  }

  static bool _isMatchingContainer(int opening, int closing) =>
      (opening == _openBrace && closing == _closeBrace) ||
      (opening == _openBracket && closing == _closeBracket);

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xd800 && codeUnit <= 0xdbff;

  static bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xdc00 && codeUnit <= 0xdfff;

  static bool _isJsonWhitespace(int codeUnit) =>
      codeUnit == _space ||
      codeUnit == _tab ||
      codeUnit == _lineFeed ||
      codeUnit == _carriageReturn;

  static bool _isDigit(int codeUnit) => codeUnit >= _zero && codeUnit <= _nine;

  static const int _tab = 0x09;
  static const int _lineFeed = 0x0a;
  static const int _carriageReturn = 0x0d;
  static const int _space = 0x20;
  static const int _quote = 0x22;
  static const int _plus = 0x2b;
  static const int _comma = 0x2c;
  static const int _minus = 0x2d;
  static const int _period = 0x2e;
  static const int _zero = 0x30;
  static const int _one = 0x31;
  static const int _nine = 0x39;
  static const int _colon = 0x3a;
  static const int _uppercaseE = 0x45;
  static const int _openBracket = 0x5b;
  static const int _backslash = 0x5c;
  static const int _closeBracket = 0x5d;
  static const int _lowercaseF = 0x66;
  static const int _lowercaseN = 0x6e;
  static const int _lowercaseT = 0x74;
  static const int _lowercaseE = 0x65;
  static const int _openBrace = 0x7b;
  static const int _closeBrace = 0x7d;
}

final class _SourceContainer {
  _SourceContainer(this.opening, {required this.maxItems});

  final int opening;
  final int maxItems;
  int separators = 0;
}
