import 'package:ispect/src/features/json_viewer/services/json_cache_service.dart';

/// Caches text match positions for highlighting purposes.
///
/// Key is built from `text.toLowerCase()` and `query.toLowerCase()` to avoid
/// repeated case transformations during rendering. Values are match start
/// indices (in source text coordinates).
class TextMatchService {
  TextMatchService._({int maxEntries = 500})
      : _cache = LRUCache<String, List<int>>(maxEntries: maxEntries);

  static final TextMatchService instance = TextMatchService._();

  final LRUCache<String, List<int>> _cache;

  /// Returns all match start positions of [query] within [text].
  /// Uses an internal LRU cache keyed by the normalized tuple (text|query).
  List<int> findMatches(String text, String query) {
    if (text.isEmpty || query.isEmpty) return const <int>[];

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final key = '$lowerText|$lowerQuery';

    final cached = _cache.get(key);
    if (cached != null) return cached;

    final matches = <int>[];
    var pos = 0;
    while (true) {
      pos = lowerText.indexOf(lowerQuery, pos);
      if (pos == -1) break;
      matches.add(pos);
      pos += lowerQuery.length;
    }

    _cache.put(key, matches);
    return matches;
  }

  void clear() => _cache.clear();
}
