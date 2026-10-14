import 'package:ispect/src/features/json_viewer/services/json_cache_service.dart';

/// Caches text match positions for highlighting purposes.
///
/// Matching is case-insensitive and runs on the source text, so the returned
/// match start indices are in source text coordinates.
class TextMatchService {
  TextMatchService._({int maxEntries = 500})
    : _cache = LRUCache<String, List<int>>(maxEntries: maxEntries);

  static final TextMatchService instance = TextMatchService._();

  final LRUCache<String, List<int>> _cache;

  /// Returns all match start positions of [query] within [text].
  /// Uses an internal LRU cache keyed by the (text|query) tuple.
  List<int> findMatches(String text, String query) {
    if (text.isEmpty || query.isEmpty) return const <int>[];

    final key =
        '${text.hashCode}:${query.hashCode}:${text.length}:${query.length}';

    final cached = _cache.get(key);
    if (cached != null) return cached;

    final matches = [
      for (final match in RegExp(
        RegExp.escape(query),
        caseSensitive: false,
      ).allMatches(text))
        match.start,
    ];

    _cache.put(key, matches);
    return matches;
  }

  void clear() => _cache.clear();
}
