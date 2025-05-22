import 'dart:convert';

/// Service to pretty-print JSON objects with a maximum depth limit.
/// Deeper nested values are replaced with "...".
class JsonTruncatorService {
  /// Default maximum depth for JSON structure traversal.
  static const int _defaultMaxDepth = 15;

  /// Default string truncation limit.
  static const int _stringTruncateLimit = 100;

  /// Default truncation marker.
  static const String _truncationMarker = '...';

  /// Pretty-prints a JSON object with depth limitation.
  ///
  /// Limits the depth of nested structures to [maxDepth].
  /// Truncates strings longer than 100 characters.
  ///
  /// Returns a formatted JSON string or an error message if formatting fails.
  static String pretty(
    Object? json, {
    int maxDepth = _defaultMaxDepth,
  }) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final truncated = _truncateJson(
        json,
        0,
        maxDepth: maxDepth,
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
  /// - Primitive types are returned as-is
  /// - Special objects (DateTime, RegExp, Duration) are converted to appropriate representations
  static Object? _truncateJson(
    Object? value,
    int currentDepth, {
    required int maxDepth,
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
      return _processTruncatedMap(value, nextDepth, maxDepth);
    }

    if (value is Iterable) {
      return _processTruncatedIterable(value, nextDepth, maxDepth);
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
        _truncateJson(value.key, currentDepth, maxDepth: maxDepth),
        _truncateJson(value.value, currentDepth, maxDepth: maxDepth),
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
  ) =>
      value.map(
        (key, val) => MapEntry(
          key.toString(),
          _truncateJson(
            val,
            nextDepth,
            maxDepth: maxDepth,
          ),
        ),
      );

  /// Processes an iterable by truncating all its items.
  static List<Object?> _processTruncatedIterable(
    Iterable<Object?> value,
    int nextDepth,
    int maxDepth,
  ) =>
      value
          .map(
            (item) => _truncateJson(
              item,
              nextDepth,
              maxDepth: maxDepth,
            ),
          )
          .toList();

  /// Truncates a string if it exceeds the limit.
  static String _truncateString(String value) =>
      value.length > _stringTruncateLimit
          ? '${value.substring(0, _stringTruncateLimit)}$_truncationMarker'
          : value;
}
