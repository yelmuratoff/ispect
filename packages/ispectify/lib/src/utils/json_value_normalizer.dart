import 'dart:collection';
import 'dart:typed_data';

/// Converts arbitrary diagnostic values into structures accepted by JSON
/// encoders while preserving maps and iterables.
abstract final class JsonValueNormalizer {
  /// Default maximum number of values visited in one normalization pass.
  static const int defaultMaxNodes = 10000;

  /// Default maximum number of entries retained from one map or iterable.
  static const int defaultMaxCollectionItems = 1000;

  /// Replacement emitted when a map or iterable refers to an ancestor.
  static const String circularReference = '<circular-reference>';

  /// Replacement emitted when traversal reaches [normalize]'s depth limit.
  static const String maxDepthReached = '<max-depth-reached>';

  /// Replacement emitted when traversal reaches its total node budget.
  static const String maxNodesReached = '<max-nodes-reached>';

  /// Replacement emitted when one collection exceeds its item budget.
  static const String maxCollectionItemsReached =
      '<max-collection-items-reached>';

  /// Replacement emitted when a diagnostic value cannot be inspected safely.
  static const String unprintableValue = '<unprintable-value>';

  /// Key used to retain a traversal marker when a map is truncated.
  static const String traversalMarkerKey = '<traversal-marker>';

  /// Returns a JSON-safe snapshot of [value].
  ///
  /// Map keys become strings, non-finite numbers and unsupported leaf values
  /// become strings, and circular or excessively deep branches become stable
  /// markers. Traversal is bounded globally by [maxNodes] and separately for
  /// every map or iterable by [maxCollectionItems], so lazy or unbounded
  /// iterables cannot hang an export.
  ///
  /// [preserveTypes] exists for redaction pipelines that retain `Type` tokens,
  /// all [TypedData] views, and [ByteBuffer] values as recognizable in-memory
  /// objects before their final JSON encoding pass.
  ///
  /// Custom `toJson()` methods are never invoked unless
  /// [allowCustomSerialization] is explicitly enabled. Even in that mode,
  /// unknown values whose conversion fails become [unprintableValue] instead
  /// of dispatching through `toString()` or `runtimeType`.
  static Object? normalize(
    Object? value, {
    int maxDepth = 500,
    int maxNodes = defaultMaxNodes,
    int maxCollectionItems = defaultMaxCollectionItems,
    bool preserveTypes = false,
    bool allowCustomSerialization = false,
    @Deprecated(
      'Use allowCustomSerialization. Unknown values are never stringified. '
      'Will be removed in 8.0.0.',
    )
    bool stringifyUnknown = false,
  }) {
    if (maxDepth < 1) {
      throw RangeError.range(maxDepth, 1, null, 'maxDepth');
    }
    if (maxNodes < 1) {
      throw RangeError.range(maxNodes, 1, null, 'maxNodes');
    }
    if (maxCollectionItems < 1) {
      throw RangeError.range(
        maxCollectionItems,
        1,
        null,
        'maxCollectionItems',
      );
    }
    final customSerializationEnabled =
        allowCustomSerialization || stringifyUnknown;
    return _normalize(
      value,
      depth: 0,
      maxDepth: maxDepth,
      maxCollectionItems: maxCollectionItems,
      preserveTypes: preserveTypes,
      allowCustomSerialization: customSerializationEnabled,
      ancestors: HashSet<Object>.identity(),
      budget: _NormalizationBudget(maxNodes),
    );
  }

  static Object? _normalize(
    Object? value, {
    required int depth,
    required int maxDepth,
    required int maxCollectionItems,
    required bool preserveTypes,
    required bool allowCustomSerialization,
    required Set<Object> ancestors,
    required _NormalizationBudget budget,
  }) {
    if (!budget.takeNode()) return maxNodesReached;
    if (value == null || value is bool || value is String) return value;
    if (value is num) {
      return value is double && !value.isFinite ? value.toString() : value;
    }
    if (value is DateTime || value is Uri) return unprintableValue;
    if (value is Enum) return value.name;
    if (value is Error || value is Exception || value is StackTrace) {
      return diagnosticDescriptor(value);
    }
    if (preserveTypes && value is Type) return value;
    if (preserveTypes && (value is TypedData || value is ByteBuffer)) {
      return value;
    }
    if (depth >= maxDepth) return maxDepthReached;

    if (value is Map) {
      if (!ancestors.add(value)) return circularReference;
      try {
        return _normalizeMap(
          value,
          depth: depth,
          maxDepth: maxDepth,
          maxCollectionItems: maxCollectionItems,
          preserveTypes: preserveTypes,
          allowCustomSerialization: allowCustomSerialization,
          ancestors: ancestors,
          budget: budget,
        );
      } finally {
        ancestors.remove(value);
      }
    }

    if (value is Iterable) {
      if (!ancestors.add(value)) return circularReference;
      try {
        return _normalizeIterable(
          value,
          depth: depth,
          maxDepth: maxDepth,
          maxCollectionItems: maxCollectionItems,
          preserveTypes: preserveTypes,
          allowCustomSerialization: allowCustomSerialization,
          ancestors: ancestors,
          budget: budget,
        );
      } finally {
        ancestors.remove(value);
      }
    }

    if (!allowCustomSerialization) return unprintableValue;
    if (!ancestors.add(value)) return circularReference;
    try {
      try {
        final encoded = (value as dynamic).toJson() as Object?;
        if (identical(encoded, value)) return circularReference;
        return _normalize(
          encoded,
          depth: depth + 1,
          maxDepth: maxDepth,
          maxCollectionItems: maxCollectionItems,
          preserveTypes: preserveTypes,
          allowCustomSerialization: allowCustomSerialization,
          ancestors: ancestors,
          budget: budget,
        );
      } catch (_) {
        return unprintableValue;
      }
    } finally {
      ancestors.remove(value);
    }
  }

  static Map<String, Object?> _normalizeMap(
    Map<dynamic, dynamic> value, {
    required int depth,
    required int maxDepth,
    required int maxCollectionItems,
    required bool preserveTypes,
    required bool allowCustomSerialization,
    required Set<Object> ancestors,
    required _NormalizationBudget budget,
  }) {
    final result = <String, Object?>{};
    final Iterator<dynamic> iterator;
    try {
      iterator = value.entries.iterator;
    } catch (_) {
      _addTraversalMarker(result, unprintableValue);
      return result;
    }

    var count = 0;
    while (count < maxCollectionItems) {
      final bool hasNext;
      try {
        hasNext = iterator.moveNext();
      } catch (_) {
        _addTraversalMarker(result, unprintableValue);
        return result;
      }
      if (!hasNext) return result;

      final dynamic current;
      try {
        current = iterator.current;
      } catch (_) {
        _addTraversalMarker(result, unprintableValue);
        return result;
      }
      if (current is! MapEntry<dynamic, dynamic>) {
        _addTraversalMarker(result, unprintableValue);
        return result;
      }

      final key = _normalizeMapKey(current.key);
      result[key.value] = key.isSafe
          ? _normalize(
              current.value,
              depth: depth + 1,
              maxDepth: maxDepth,
              maxCollectionItems: maxCollectionItems,
              preserveTypes: preserveTypes,
              allowCustomSerialization: allowCustomSerialization,
              ancestors: ancestors,
              budget: budget,
            )
          : unprintableValue;
      count++;
      if (!budget.hasCapacity) {
        _addTraversalMarker(result, maxNodesReached);
        return result;
      }
    }

    final bool hasMore;
    try {
      hasMore = iterator.moveNext();
    } catch (_) {
      _addTraversalMarker(result, unprintableValue);
      return result;
    }
    if (hasMore) {
      _addTraversalMarker(result, maxCollectionItemsReached);
    }
    return result;
  }

  static List<Object?> _normalizeIterable(
    Iterable<dynamic> value, {
    required int depth,
    required int maxDepth,
    required int maxCollectionItems,
    required bool preserveTypes,
    required bool allowCustomSerialization,
    required Set<Object> ancestors,
    required _NormalizationBudget budget,
  }) {
    final result = <Object?>[];
    final Iterator<dynamic> iterator;
    try {
      iterator = value.iterator;
    } catch (_) {
      return <Object?>[unprintableValue];
    }

    var count = 0;
    while (count < maxCollectionItems) {
      final bool hasNext;
      try {
        hasNext = iterator.moveNext();
      } catch (_) {
        result.add(unprintableValue);
        return result;
      }
      if (!hasNext) return List<Object?>.unmodifiable(result);

      final dynamic current;
      try {
        current = iterator.current;
      } catch (_) {
        result.add(unprintableValue);
        return List<Object?>.unmodifiable(result);
      }
      result.add(
        _normalize(
          current,
          depth: depth + 1,
          maxDepth: maxDepth,
          maxCollectionItems: maxCollectionItems,
          preserveTypes: preserveTypes,
          allowCustomSerialization: allowCustomSerialization,
          ancestors: ancestors,
          budget: budget,
        ),
      );
      count++;
      if (!budget.hasCapacity) {
        result.add(maxNodesReached);
        return List<Object?>.unmodifiable(result);
      }
    }

    final bool hasMore;
    try {
      hasMore = iterator.moveNext();
    } catch (_) {
      result.add(unprintableValue);
      return List<Object?>.unmodifiable(result);
    }
    if (hasMore) result.add(maxCollectionItemsReached);
    return List<Object?>.unmodifiable(result);
  }

  static _NormalizedMapKey _normalizeMapKey(Object? key) {
    if (key is String) return _NormalizedMapKey(key, isSafe: true);
    if (key == null) return const _NormalizedMapKey('null', isSafe: true);
    if (key is bool) {
      return _NormalizedMapKey(key ? 'true' : 'false', isSafe: true);
    }
    if (key is num) {
      return _NormalizedMapKey(key.toString(), isSafe: true);
    }
    if (key is Enum) return _NormalizedMapKey(key.name, isSafe: true);
    return const _NormalizedMapKey(
      '<unprintable-key>',
      isSafe: false,
    );
  }

  /// Returns a stable diagnostic type-family label without invoking virtual
  /// members on [value].
  static String diagnosticDescriptor(Object value) => switch (value) {
        StackTrace() => unprintableValue,
        FormatException() => 'FormatException',
        StateError() => 'StateError',
        ArgumentError() => 'ArgumentError',
        Error() => 'Error',
        Exception() => 'Exception',
        _ => unprintableValue,
      };

  static void _addTraversalMarker(
    Map<String, Object?> result,
    String marker,
  ) {
    var key = traversalMarkerKey;
    var suffix = 1;
    while (result.containsKey(key)) {
      key = '$traversalMarkerKey#$suffix';
      suffix++;
    }
    result[key] = marker;
  }
}

final class _NormalizationBudget {
  _NormalizationBudget(this._remaining);

  int _remaining;

  bool get hasCapacity => _remaining > 0;

  bool takeNode() {
    if (_remaining <= 0) return false;
    _remaining--;
    return true;
  }
}

final class _NormalizedMapKey {
  const _NormalizedMapKey(this.value, {required this.isSafe});

  final String value;
  final bool isSafe;
}
