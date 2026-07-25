import 'dart:collection';

/// Converts arbitrary diagnostic values into structures accepted by JSON
/// encoders while preserving maps and iterables.
abstract final class JsonValueNormalizer {
  /// Replacement emitted when a map or iterable refers to an ancestor.
  static const String circularReference = '<circular-reference>';

  /// Replacement emitted when traversal reaches [normalize]'s depth limit.
  static const String maxDepthReached = '<max-depth-reached>';

  /// Returns a JSON-safe snapshot of [value].
  ///
  /// Map keys become strings, non-finite numbers and unsupported leaf values
  /// become strings, and circular or excessively deep branches become stable
  /// markers.
  static Object? normalize(Object? value, {int maxDepth = 500}) {
    if (maxDepth < 1) {
      throw RangeError.range(maxDepth, 1, null, 'maxDepth');
    }
    return _normalize(
      value,
      depth: 0,
      maxDepth: maxDepth,
      ancestors: HashSet<Object>.identity(),
    );
  }

  static Object? _normalize(
    Object? value, {
    required int depth,
    required int maxDepth,
    required Set<Object> ancestors,
  }) {
    if (value == null || value is bool || value is String) return value;
    if (value is num) {
      return value is double && !value.isFinite ? value.toString() : value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is Uri) return value.toString();
    if (value is Enum) return value.name;
    if (depth >= maxDepth) return maxDepthReached;

    if (value is Map<Object?, Object?>) {
      if (!ancestors.add(value)) return circularReference;
      try {
        return <String, Object?>{
          for (final entry in value.entries)
            entry.key.toString(): _normalize(
              entry.value,
              depth: depth + 1,
              maxDepth: maxDepth,
              ancestors: ancestors,
            ),
        };
      } finally {
        ancestors.remove(value);
      }
    }

    if (value is Iterable<Object?>) {
      if (!ancestors.add(value)) return circularReference;
      try {
        return value
            .map(
              (item) => _normalize(
                item,
                depth: depth + 1,
                maxDepth: maxDepth,
                ancestors: ancestors,
              ),
            )
            .toList(growable: false);
      } finally {
        ancestors.remove(value);
      }
    }

    try {
      return value.toString();
    } catch (_) {
      return '<${value.runtimeType}>';
    }
  }
}
