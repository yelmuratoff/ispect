import 'dart:convert';

/// Service to pretty-print JSON objects with a maximum depth limit.
/// Deeper nested values are replaced with "...".
class JsonTruncatorService {
  static String pretty(
    Object? json, {
    int maxDepth = 15,
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

  static Object? _truncateJson(
    Object? value,
    int currentDepth, {
    required int maxDepth,
  }) {
    if (currentDepth >= maxDepth) {
      return '...';
    }

    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(
          key.toString(),
          _truncateJson(
            val,
            currentDepth + 1,
            maxDepth: maxDepth,
          ),
        ),
      );
    }

    if (value is Iterable) {
      return value
          .map(
            (item) => _truncateJson(
              item,
              currentDepth + 1,
              maxDepth: maxDepth,
            ),
          )
          .toList();
    }

    if (value is String) {
      return value.length > 100 ? '${value.substring(0, 100)}...' : value;
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
          currentDepth + 1,
          maxDepth: maxDepth,
        ),
        _truncateJson(
          value.value,
          currentDepth + 1,
          maxDepth: maxDepth,
        ),
      );
    }

    // Fallback: stringify unrecognized types
    return value.toString();
  }
}
