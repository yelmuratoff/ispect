import 'dart:collection';
import 'dart:convert';

/// Cheap limits applied before JSON decoding and recursive presentation.
abstract final class JsonInputPreflight {
  static const int maxCharacters = 32 * 1024 * 1024;
  static const int maxEncodedBytes = 32 * 1024 * 1024;
  static const int maxNestingDepth = 64;
  static const int maxApproximateNodes = 100000;
  static const int maxViewerNodes = 20000;
  static const int maxViewerEncodedBytes = 1024 * 1024;

  static const String rejectedContent =
      '[JSON content exceeds safe viewing limits]';
  static const String invalidContent = 'Invalid JSON content.';
  static const String truncatedValue = '[JSON value truncated]';
  static const String circularReference = '[Circular JSON reference]';
  static const String maxDepthReached = '[JSON depth limit reached]';
  static const String maxNodesReached = '[JSON node limit reached]';
  static const String unprintableValue = '[Unprintable JSON value]';
  static const String invalidObjectKey = '[JSON object key is not a string]';
  static const String traversalMarkerKey = '__ispect_json_diagnostic__';

  static Object? decode(
    String source, {
    int characterLimit = maxCharacters,
    int encodedByteLimit = maxEncodedBytes,
    int nestingDepthLimit = maxNestingDepth,
    int approximateNodeLimit = maxApproximateNodes,
  }) {
    validate(
      source,
      characterLimit: characterLimit,
      encodedByteLimit: encodedByteLimit,
      nestingDepthLimit: nestingDepthLimit,
      approximateNodeLimit: approximateNodeLimit,
    );
    try {
      return jsonDecode(source);
    } on FormatException {
      // The parser attaches the source string to FormatException. Replacing
      // it prevents malformed diagnostic payloads from leaking through error
      // reporting or UI surfaces that stringify the exception.
      throw const FormatException(invalidContent);
    }
  }

  static void validate(
    String source, {
    int characterLimit = maxCharacters,
    int encodedByteLimit = maxEncodedBytes,
    int nestingDepthLimit = maxNestingDepth,
    int approximateNodeLimit = maxApproximateNodes,
  }) {
    validateCharacterSize(source, characterLimit: characterLimit);

    var encodedBytes = 0;
    var depth = 0;
    var approximateNodes = 1;
    var inString = false;
    var escaped = false;
    final containers = <int>[];

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

      if (encodedBytes > encodedByteLimit) {
        throw JsonInputLimitException(
          'JSON content exceeds the safe encoded byte limit of '
          '$encodedByteLimit.',
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
        continue;
      }

      if (codeUnit == _openBrace || codeUnit == _openBracket) {
        containers.add(codeUnit);
        depth++;
        approximateNodes++;
        if (codeUnit == _openBracket) approximateNodes++;
        if (depth > nestingDepthLimit) {
          throw JsonInputLimitException(
            'JSON nesting exceeds the safe depth limit of '
            '$nestingDepthLimit.',
          );
        }
      } else if (codeUnit == _closeBrace || codeUnit == _closeBracket) {
        if (containers.isNotEmpty) containers.removeLast();
        if (depth > 0) depth--;
      } else if (codeUnit == _colon) {
        approximateNodes++;
      } else if (codeUnit == _comma &&
          containers.isNotEmpty &&
          containers.last == _openBracket) {
        approximateNodes++;
      }

      if (approximateNodes > approximateNodeLimit) {
        throw JsonInputLimitException(
          'JSON structure exceeds the safe node limit of '
          '$approximateNodeLimit.',
        );
      }
    }
  }

  static void validateCharacterSize(
    String source, {
    int characterLimit = maxCharacters,
  }) {
    if (source.length > characterLimit) {
      throw JsonInputLimitException(
        'JSON content exceeds the safe character limit of $characterLimit.',
      );
    }
  }

  static void validateDecoded(
    Object? root, {
    int nestingDepthLimit = maxNestingDepth,
    int nodeLimit = maxViewerNodes,
    int encodedByteLimit = maxViewerEncodedBytes,
  }) {
    final snapshotter = _JsonViewerSnapshotter(
      maxBytes: encodedByteLimit,
      maxDepth: nestingDepthLimit,
      maxNodes: nodeLimit,
    )..snapshot(root);

    if (snapshotter.issues.contains(_JsonSnapshotIssue.depth)) {
      throw JsonInputLimitException(
        'JSON nesting exceeds the safe depth limit of $nestingDepthLimit.',
      );
    }
    if (snapshotter.issues.contains(_JsonSnapshotIssue.nodes)) {
      throw JsonInputLimitException(
        'JSON structure exceeds the safe node limit of $nodeLimit.',
      );
    }
    if (snapshotter.issues.contains(_JsonSnapshotIssue.bytes)) {
      throw JsonInputLimitException(
        'JSON content exceeds the safe encoded byte limit of '
        '$encodedByteLimit.',
      );
    }
    if (snapshotter.issues.contains(_JsonSnapshotIssue.cycle)) {
      throw const JsonInputLimitException(
        'JSON structure contains a repeated or cyclic container.',
      );
    }
    if (snapshotter.issues.contains(_JsonSnapshotIssue.invalidKey)) {
      throw const JsonInputLimitException(
        'JSON objects must use string keys.',
      );
    }
    if (snapshotter.issues.contains(_JsonSnapshotIssue.unprintable)) {
      throw const JsonInputLimitException(
        'JSON structure contains an unsupported or unreadable value.',
      );
    }
  }

  /// Takes one bounded, non-executing snapshot for JSON presentation.
  ///
  /// The returned graph contains only JSON-compatible primitives, immutable
  /// maps, and immutable lists. Caller-owned containers and arbitrary leaf
  /// objects are never retained. Cycles, excessive depth, exhausted budgets,
  /// invalid keys, and hostile collection traversal are represented by safe
  /// diagnostic strings inside the snapshot.
  static JsonInputSnapshot snapshotForViewer(
    Object? root, {
    int nestingDepthLimit = maxNestingDepth,
    int nodeLimit = maxViewerNodes,
    int encodedByteLimit = maxViewerEncodedBytes,
  }) {
    if (nestingDepthLimit < 0) {
      throw RangeError.range(
        nestingDepthLimit,
        0,
        null,
        'nestingDepthLimit',
      );
    }
    if (nodeLimit < 1) {
      throw RangeError.range(nodeLimit, 1, null, 'nodeLimit');
    }
    if (encodedByteLimit < 2) {
      throw RangeError.range(
        encodedByteLimit,
        2,
        null,
        'encodedByteLimit',
      );
    }

    return JsonInputSnapshot._(
      _JsonViewerSnapshotter(
        maxBytes: encodedByteLimit,
        maxDepth: nestingDepthLimit,
        maxNodes: nodeLimit,
      ).snapshot(root),
    );
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xd800 && codeUnit <= 0xdbff;

  static bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xdc00 && codeUnit <= 0xdfff;

  static const int _quote = 0x22;
  static const int _comma = 0x2c;
  static const int _colon = 0x3a;
  static const int _openBracket = 0x5b;
  static const int _backslash = 0x5c;
  static const int _closeBracket = 0x5d;
  static const int _openBrace = 0x7b;
  static const int _closeBrace = 0x7d;
}

final class JsonInputLimitException extends FormatException {
  const JsonInputLimitException(super.message);
}

/// Provenance wrapper for a graph normalized by [JsonInputPreflight].
///
/// The private constructor prevents downstream viewer services from marking a
/// caller-owned graph as trusted without passing through the preflight.
final class JsonInputSnapshot {
  const JsonInputSnapshot._(this.value);

  /// Bounded JSON-compatible root value.
  final Object? value;
}

enum _JsonSnapshotIssue {
  bytes,
  nodes,
  depth,
  cycle,
  invalidKey,
  unprintable,
}

final class _JsonViewerSnapshotter {
  _JsonViewerSnapshotter({
    required int maxBytes,
    required this.maxDepth,
    required int maxNodes,
  })  : _initialBytes = maxBytes,
        _initialNodes = maxNodes,
        _remainingBytes = maxBytes,
        _remainingNodes = maxNodes,
        _remainingTraversalSteps = maxNodes;

  static const int _maxKeyEncodedBytes = 4 * 1024;
  static const _noSnapshot = _NoJsonSnapshot();
  static const _nodeBudgetExceeded = _JsonNodeBudgetExceeded();

  final int _initialBytes;
  final int _initialNodes;
  final int maxDepth;
  final Set<Object> _ancestors = HashSet<Object>.identity();
  final Map<Map<String, dynamic>, int> _nextDiagnosticSuffix =
      HashMap<Map<String, dynamic>, int>.identity();
  final Set<_JsonSnapshotIssue> issues = <_JsonSnapshotIssue>{};

  int _remainingBytes;
  int _remainingNodes;
  int _remainingTraversalSteps;

  Object? snapshot(Object? root) {
    final result = _convert(root, depth: 0);
    if (!identical(result, _noSnapshot)) return result;

    _remainingBytes = _initialBytes;
    _remainingNodes = _initialNodes;
    _remainingTraversalSteps = _initialNodes;
    final fallback = _copyString(
      JsonInputPreflight.rejectedContent,
      truncationMarker: '',
    );
    return identical(fallback, _noSnapshot) ? '' : fallback;
  }

  Object? _convert(Object? value, {required int depth}) {
    if (_remainingNodes <= 0) {
      issues.add(_JsonSnapshotIssue.nodes);
      return _nodeBudgetExceeded;
    }
    _remainingNodes--;

    if (value == null) return _copyLiteral(null, 4);
    if (value is bool) return _copyLiteral(value, value ? 4 : 5);
    if (value is int) {
      final text = value.toString();
      return _copyLiteral(value, text.length);
    }
    if (value is double) {
      if (!value.isFinite) {
        issues.add(_JsonSnapshotIssue.unprintable);
        return _diagnostic(JsonInputPreflight.unprintableValue);
      }
      final text = value.toString();
      return _copyLiteral(value, text.length);
    }
    if (value is String) return _copyString(value);
    if (value is Enum) return _copyString(value.name);
    if (value is Map) return _copyMap(value, depth);
    if (value is Iterable) return _copyIterable(value, depth);

    issues.add(_JsonSnapshotIssue.unprintable);
    return _diagnostic(JsonInputPreflight.unprintableValue);
  }

  Object? _copyLiteral(Object? value, int encodedBytes) {
    if (!_takeBytes(encodedBytes)) return _noSnapshot;
    return value;
  }

  Object? _copyMap(Map<dynamic, dynamic> source, int depth) {
    if (_ancestors.contains(source)) {
      issues.add(_JsonSnapshotIssue.cycle);
      return _diagnostic(JsonInputPreflight.circularReference);
    }
    if (depth >= maxDepth) {
      issues.add(_JsonSnapshotIssue.depth);
      return _diagnostic(JsonInputPreflight.maxDepthReached);
    }
    if (!_takeBytes(2)) return _noSnapshot;

    final result = <String, dynamic>{};
    String? lastKey;
    if (!_ancestors.add(source)) {
      issues.add(_JsonSnapshotIssue.cycle);
      return _addMapDiagnostic(
        result,
        JsonInputPreflight.circularReference,
      )
          ? Map<String, dynamic>.unmodifiable(result)
          : _noSnapshot;
    }

    try {
      final Iterator<dynamic> iterator;
      try {
        iterator = source.entries.iterator;
      } on Object {
        issues.add(_JsonSnapshotIssue.unprintable);
        if (!_addMapDiagnostic(
          result,
          JsonInputPreflight.unprintableValue,
        )) {
          return _noSnapshot;
        }
        return Map<String, dynamic>.unmodifiable(result);
      }

      while (true) {
        if (!_takeTraversalStep()) {
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.maxNodesReached,
          )) {
            return _noSnapshot;
          }
          break;
        }

        final bool hasNext;
        try {
          hasNext = iterator.moveNext();
        } on Object {
          issues.add(_JsonSnapshotIssue.unprintable);
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.unprintableValue,
          )) {
            return _noSnapshot;
          }
          break;
        }
        if (!hasNext) break;

        final dynamic current;
        try {
          current = iterator.current;
        } on Object {
          issues.add(_JsonSnapshotIssue.unprintable);
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.unprintableValue,
          )) {
            return _noSnapshot;
          }
          break;
        }
        if (current is! MapEntry<dynamic, dynamic>) {
          issues.add(_JsonSnapshotIssue.unprintable);
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.unprintableValue,
          )) {
            return _noSnapshot;
          }
          break;
        }

        final dynamic rawKey;
        final dynamic rawValue;
        try {
          rawKey = current.key;
          rawValue = current.value;
        } on Object {
          issues.add(_JsonSnapshotIssue.unprintable);
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.unprintableValue,
          )) {
            return _noSnapshot;
          }
          break;
        }

        if (rawKey is! String) {
          issues.add(_JsonSnapshotIssue.invalidKey);
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.invalidObjectKey,
          )) {
            return _noSnapshot;
          }
          continue;
        }

        final checkpoint = _checkpoint();
        if (result.isNotEmpty && !_takeBytes(1)) {
          _restore(checkpoint);
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.truncatedValue,
          )) {
            return _noSnapshot;
          }
          break;
        }
        final copiedKey = _copyString(
          rawKey,
          maxEncodedBytes: _maxKeyEncodedBytes,
        );
        if (identical(copiedKey, _noSnapshot) || !_takeBytes(1)) {
          _restore(checkpoint);
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.truncatedValue,
          )) {
            return _noSnapshot;
          }
          break;
        }
        final copiedValue = _convert(rawValue, depth: depth + 1);
        if (identical(copiedValue, _nodeBudgetExceeded)) {
          _restore(checkpoint);
          final diagnostic = _diagnostic(JsonInputPreflight.maxNodesReached);
          if (result.isEmpty) {
            return identical(diagnostic, _noSnapshot)
                ? _noSnapshot
                : diagnostic;
          }
          if (!identical(diagnostic, _noSnapshot) && lastKey != null) {
            result[lastKey] = diagnostic;
          } else {
            return _noSnapshot;
          }
          break;
        }
        if (identical(copiedValue, _noSnapshot)) {
          _restore(checkpoint);
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.truncatedValue,
          )) {
            return _noSnapshot;
          }
          break;
        }

        final key = copiedKey! as String;
        if (result.containsKey(key)) {
          _restore(checkpoint);
          issues.add(_JsonSnapshotIssue.invalidKey);
          if (!_addMapDiagnostic(
            result,
            JsonInputPreflight.invalidObjectKey,
          )) {
            return _noSnapshot;
          }
          continue;
        }
        result[key] = copiedValue;
        lastKey = key;
      }
    } finally {
      _ancestors.remove(source);
    }

    return Map<String, dynamic>.unmodifiable(result);
  }

  Object? _copyIterable(Iterable<dynamic> source, int depth) {
    if (_ancestors.contains(source)) {
      issues.add(_JsonSnapshotIssue.cycle);
      return _diagnostic(JsonInputPreflight.circularReference);
    }
    if (depth >= maxDepth) {
      issues.add(_JsonSnapshotIssue.depth);
      return _diagnostic(JsonInputPreflight.maxDepthReached);
    }
    if (!_takeBytes(2)) return _noSnapshot;

    final result = <dynamic>[];
    if (!_ancestors.add(source)) {
      issues.add(_JsonSnapshotIssue.cycle);
      return _addListDiagnostic(
        result,
        JsonInputPreflight.circularReference,
      )
          ? List<dynamic>.unmodifiable(result)
          : _noSnapshot;
    }

    try {
      final Iterator<dynamic> iterator;
      try {
        iterator = source.iterator;
      } on Object {
        issues.add(_JsonSnapshotIssue.unprintable);
        if (!_addListDiagnostic(
          result,
          JsonInputPreflight.unprintableValue,
        )) {
          return _noSnapshot;
        }
        return List<dynamic>.unmodifiable(result);
      }

      while (true) {
        if (!_takeTraversalStep()) {
          if (!_addListDiagnostic(
            result,
            JsonInputPreflight.maxNodesReached,
          )) {
            return _noSnapshot;
          }
          break;
        }

        final bool hasNext;
        try {
          hasNext = iterator.moveNext();
        } on Object {
          issues.add(_JsonSnapshotIssue.unprintable);
          if (!_addListDiagnostic(
            result,
            JsonInputPreflight.unprintableValue,
          )) {
            return _noSnapshot;
          }
          break;
        }
        if (!hasNext) break;

        final dynamic current;
        try {
          current = iterator.current;
        } on Object {
          issues.add(_JsonSnapshotIssue.unprintable);
          if (!_addListDiagnostic(
            result,
            JsonInputPreflight.unprintableValue,
          )) {
            return _noSnapshot;
          }
          break;
        }

        final checkpoint = _checkpoint();
        if (result.isNotEmpty && !_takeBytes(1)) {
          _restore(checkpoint);
          if (!_addListDiagnostic(
            result,
            JsonInputPreflight.truncatedValue,
          )) {
            return _noSnapshot;
          }
          break;
        }
        final copied = _convert(current, depth: depth + 1);
        if (identical(copied, _nodeBudgetExceeded)) {
          _restore(checkpoint);
          final diagnostic = _diagnostic(JsonInputPreflight.maxNodesReached);
          if (result.isEmpty) {
            return identical(diagnostic, _noSnapshot)
                ? _noSnapshot
                : diagnostic;
          }
          if (!identical(diagnostic, _noSnapshot)) {
            result[result.length - 1] = diagnostic;
          } else {
            return _noSnapshot;
          }
          break;
        }
        if (identical(copied, _noSnapshot)) {
          _restore(checkpoint);
          if (!_addListDiagnostic(
            result,
            JsonInputPreflight.truncatedValue,
          )) {
            return _noSnapshot;
          }
          break;
        }
        result.add(copied);
      }
    } finally {
      _ancestors.remove(source);
    }

    return List<dynamic>.unmodifiable(result);
  }

  Object? _copyString(
    String value, {
    String truncationMarker = JsonInputPreflight.truncatedValue,
    int? maxEncodedBytes,
  }) {
    final available =
        maxEncodedBytes == null || _remainingBytes < maxEncodedBytes
            ? _remainingBytes
            : maxEncodedBytes;
    if (available < 2) {
      issues.add(_JsonSnapshotIssue.bytes);
      return _noSnapshot;
    }

    final contentBudget = available - 2;
    final full = _encodedPrefix(value, contentBudget);
    if (full.complete) {
      _remainingBytes -= full.bytes + 2;
      return value;
    }

    issues.add(_JsonSnapshotIssue.bytes);
    final marker = _encodedPrefix(truncationMarker, contentBudget);
    final markerText = truncationMarker.substring(0, marker.end);
    final prefixBudget = contentBudget - marker.bytes;
    final prefix = _encodedPrefix(value, prefixBudget);
    final result = '${value.substring(0, prefix.end)}$markerText';
    _remainingBytes -= prefix.bytes + marker.bytes + 2;
    return result;
  }

  Object? _diagnostic(String message) =>
      _copyString(message, truncationMarker: '');

  bool _addMapDiagnostic(Map<String, dynamic> result, String message) {
    final checkpoint = _checkpoint();
    if (_remainingNodes <= 0) return false;
    _remainingNodes--;
    if (result.isNotEmpty && !_takeBytes(1)) {
      _restore(checkpoint);
      return false;
    }
    final key = _copyString(_availableDiagnosticKey(result));
    if (identical(key, _noSnapshot) || !_takeBytes(1)) {
      _restore(checkpoint);
      return false;
    }
    final value = _diagnostic(message);
    if (identical(value, _noSnapshot)) {
      _restore(checkpoint);
      return false;
    }

    final diagnosticKey = key! as String;
    if (result.containsKey(diagnosticKey)) {
      _restore(checkpoint);
      return false;
    }
    result[diagnosticKey] = value;
    return true;
  }

  String _availableDiagnosticKey(Map<String, dynamic> result) {
    const base = JsonInputPreflight.traversalMarkerKey;
    var suffix = _nextDiagnosticSuffix[result] ?? 0;
    while (true) {
      final candidate = suffix == 0 ? base : '$base-$suffix';
      suffix++;
      if (!result.containsKey(candidate)) {
        _nextDiagnosticSuffix[result] = suffix;
        return candidate;
      }
    }
  }

  bool _addListDiagnostic(List<dynamic> result, String message) {
    final checkpoint = _checkpoint();
    if (_remainingNodes <= 0) return false;
    _remainingNodes--;
    if (result.isNotEmpty && !_takeBytes(1)) {
      _restore(checkpoint);
      return false;
    }
    final value = _diagnostic(message);
    if (identical(value, _noSnapshot)) {
      _restore(checkpoint);
      return false;
    }
    result.add(value);
    return true;
  }

  bool _takeBytes(int count) {
    if (count <= _remainingBytes) {
      _remainingBytes -= count;
      return true;
    }
    issues.add(_JsonSnapshotIssue.bytes);
    return false;
  }

  bool _takeTraversalStep() {
    if (_remainingTraversalSteps > 0) {
      _remainingTraversalSteps--;
      return true;
    }
    issues.add(_JsonSnapshotIssue.nodes);
    return false;
  }

  ({int bytes, int nodes}) _checkpoint() => (
        bytes: _remainingBytes,
        nodes: _remainingNodes,
      );

  void _restore(({int bytes, int nodes}) checkpoint) {
    _remainingBytes = checkpoint.bytes;
    _remainingNodes = checkpoint.nodes;
  }

  static ({int end, int bytes, bool complete}) _encodedPrefix(
    String value,
    int maxBytes,
  ) {
    var bytes = 0;
    var index = 0;
    while (index < value.length) {
      final codeUnit = value.codeUnitAt(index);
      final int width;
      final int codeUnits;
      if (codeUnit == _quote || codeUnit == _backslash) {
        width = 2;
        codeUnits = 1;
      } else if (codeUnit <= 0x1f) {
        width = 6;
        codeUnits = 1;
      } else if (codeUnit <= 0x7f) {
        width = 1;
        codeUnits = 1;
      } else if (codeUnit <= 0x7ff) {
        width = 2;
        codeUnits = 1;
      } else if (_isHighSurrogate(codeUnit)) {
        if (index + 1 < value.length &&
            _isLowSurrogate(value.codeUnitAt(index + 1))) {
          width = 4;
          codeUnits = 2;
        } else {
          // jsonEncode escapes unpaired UTF-16 surrogates as `\uXXXX`.
          width = 6;
          codeUnits = 1;
        }
      } else if (_isLowSurrogate(codeUnit)) {
        // A low surrogate without its high pair is escaped as `\uXXXX`.
        width = 6;
        codeUnits = 1;
      } else {
        width = 3;
        codeUnits = 1;
      }
      if (bytes + width > maxBytes) break;
      bytes += width;
      index += codeUnits;
    }
    return (end: index, bytes: bytes, complete: index == value.length);
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xd800 && codeUnit <= 0xdbff;

  static bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xdc00 && codeUnit <= 0xdfff;

  static const int _quote = 0x22;
  static const int _backslash = 0x5c;
}

final class _NoJsonSnapshot {
  const _NoJsonSnapshot();
}

final class _JsonNodeBudgetExceeded {
  const _JsonNodeBudgetExceeded();
}
