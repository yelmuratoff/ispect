import 'dart:convert';

import 'package:ispectify/src/utils/string_extension.dart';

/// Pretty-prints JSON objects with depth and size limits.
///
/// Deeper nested values are replaced with `...`.
class JsonTruncator {
  /// Default maximum depth for JSON structure traversal.
  static const int _defaultMaxDepth = 20;

  /// Default iterable size limit.
  static const int _defaultIterableSizeLimit = 500;

  /// Value indicating no limit should be applied to iterables.
  static const int _unlimitedIterableSize = -1;

  /// Default truncation marker.
  static const String _truncationMarker = '...';

  /// Pretty-prints a JSON object with depth limitation.
  ///
  /// Limits the depth of nested structures to [maxDepth].
  /// Truncates strings longer than [kDefaultStringTruncateLimit] characters.
  /// Limits iterables to first [maxIterableSize] elements.
  /// Set [maxIterableSize] to -1 for unlimited iterable size.
  ///
  /// Returns a formatted JSON string or an error message if formatting fails.
  static String pretty(
    Object? json, {
    int maxDepth = _defaultMaxDepth,
    int maxIterableSize = _defaultIterableSizeLimit,
  }) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final truncated = _truncateJson(
        json,
        0,
        maxDepth: maxDepth,
        maxIterableSize: maxIterableSize,
      );
      return encoder.convert(truncated);
    } catch (e) {
      return '<Failed to format JSON: $e>';
    }
  }

  /// Recursively truncates a JSON structure to enforce maximum depth.
  ///
  /// Handles maps, iterables, strings, primitives, and common Dart types
  /// (DateTime, RegExp, Duration). Unrecognized types are stringified.
  static Object? _truncateJson(
    Object? value,
    int currentDepth, {
    required int maxDepth,
    required int maxIterableSize,
  }) {
    if (currentDepth >= maxDepth) return _truncationMarker;
    if (value == null) return null;

    final nextDepth = currentDepth + 1;

    if (value is Map) {
      return _processTruncatedMap(value, nextDepth, maxDepth, maxIterableSize);
    }

    if (value is Iterable) {
      return _processTruncatedIterable(
        value,
        nextDepth,
        maxDepth,
        maxIterableSize,
      );
    }

    if (value is String) return truncateString(value);
    if (value is num || value is bool) return value;
    if (value is DateTime) return value.toIso8601String();
    if (value is RegExp) return value.pattern;
    if (value is Duration) return value.inMilliseconds;

    return value.toString();
  }

  /// Processes a map by truncating all its entries.
  static Map<String, Object?> _processTruncatedMap(
    Map<Object?, Object?> value,
    int nextDepth,
    int maxDepth,
    int maxIterableSize,
  ) =>
      value.map(
        (key, val) => MapEntry(
          key.toString(),
          _truncateJson(
            val,
            nextDepth,
            maxDepth: maxDepth,
            maxIterableSize: maxIterableSize,
          ),
        ),
      );

  /// Processes an iterable by truncating its items.
  ///
  /// Limits to first [maxIterableSize] elements unless set to -1.
  static List<Object?> _processTruncatedIterable(
    Iterable<Object?> value,
    int nextDepth,
    int maxDepth,
    int maxIterableSize,
  ) {
    var items = value;
    var exceeded = false;

    if (maxIterableSize != _unlimitedIterableSize) {
      final limited = value.take(maxIterableSize + 1).toList();
      exceeded = limited.length > maxIterableSize;
      items = exceeded ? limited.take(maxIterableSize) : limited;
    }

    final result = items
        .map(
          (item) => _truncateJson(
            item,
            nextDepth,
            maxDepth: maxDepth,
            maxIterableSize: maxIterableSize,
          ),
        )
        .toList();

    if (exceeded) result.add(_truncationMarker);
    return result;
  }
}
