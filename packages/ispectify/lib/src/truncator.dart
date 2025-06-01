import 'dart:convert';

/// Service to pretty-print JSON objects with a maximum depth limit.
/// Deeper nested values are replaced with "...".
class JsonTruncatorService {
  /// Default maximum depth for JSON structure traversal.
  static const int _defaultMaxDepth = 15;

  /// Default string truncation limit.
  static const int _stringTruncateLimit = 100;

  /// Default iterable size limit.
  static const int _defaultIterableSizeLimit = 100;

  /// Value indicating no limit should be applied to iterables.
  static const int _unlimitedIterableSize = -1;

  /// Default truncation marker.
  static const String _truncationMarker = '...';

  /// Pretty-prints a JSON object with depth limitation.
  ///
  /// Limits the depth of nested structures to [maxDepth].
  /// Truncates strings longer than 100 characters.
  /// Limits iterables to first [maxIterableSize] elements.
  /// Set [maxIterableSize] to [_unlimitedIterableSize] (-1) for unlimited iterable size.
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
  /// Handles different data types appropriately:
  /// - Maps and iterables are traversed recursively
  /// - Strings are truncated if too long
  /// - Iterables are truncated to first [maxIterableSize] elements (unless set to -1)
  /// - Primitive types are returned as-is
  /// - Special objects (DateTime, RegExp, Duration) are converted to appropriate representations
  static Object? _truncateJson(
    Object? value,
    int currentDepth, {
    required int maxDepth,
    required int maxIterableSize,
  }) {
    // Depth limit reached
    if (currentDepth >= maxDepth) {
      return _truncationMarker;
    }

    // Handle null case
    if (value == null) {
      return null;
    }

    // Increment depth for recursive calls
    final nextDepth = currentDepth + 1;

    // Process based on type
    if (value is Map) {
      return _processTruncatedMap(
        value,
        nextDepth,
        maxDepth,
        maxIterableSize,
      );
    }

    if (value is Iterable) {
      return _processTruncatedIterable(
        value,
        nextDepth,
        maxDepth,
        maxIterableSize,
      );
    }

    if (value is String) {
      return _truncateString(value);
    }

    if (value is num || value is bool) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is RegExp) {
      return value.pattern;
    }

    if (value is Duration) {
      return value.inMilliseconds;
    }

    if (value is MapEntry) {
      return MapEntry(
        _truncateJson(
          value.key,
          currentDepth,
          maxDepth: maxDepth,
          maxIterableSize: maxIterableSize,
        ),
        _truncateJson(
          value.value,
          currentDepth,
          maxDepth: maxDepth,
          maxIterableSize: maxIterableSize,
        ),
      );
    }

    // Fallback: stringify unrecognized types
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

  /// Processes an iterable by truncating all its items.
  /// Limits the iterable to first [maxIterableSize] elements if maxIterableSize is not [_unlimitedIterableSize].
  static List<Object?> _processTruncatedIterable(
    Iterable<Object?> value,
    int nextDepth,
    int maxDepth,
    int maxIterableSize,
  ) {
    // Truncate large iterables when maxIterableSize is not _unlimitedIterableSize (-1)
    if (maxIterableSize != _unlimitedIterableSize &&
        value.length > maxIterableSize) {
      // Take only the first maxIterableSize elements and process them
      return value
          .take(maxIterableSize)
          .map(
            (item) => _truncateJson(
              item,
              nextDepth,
              maxDepth: maxDepth,
              maxIterableSize: maxIterableSize,
            ),
          )
          .toList()
        ..add(_truncationMarker);
    }

    // Process full iterable without truncation
    return value
        .map(
          (item) => _truncateJson(
            item,
            nextDepth,
            maxDepth: maxDepth,
            maxIterableSize: maxIterableSize,
          ),
        )
        .toList();
  }

  /// Truncates a string if it exceeds the limit.
  static String _truncateString(String value) =>
      value.length > _stringTruncateLimit
          ? '${value.substring(0, _stringTruncateLimit)}$_truncationMarker'
          : value;
}
