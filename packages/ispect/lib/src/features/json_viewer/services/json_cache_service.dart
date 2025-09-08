/// Interface for cache services to follow Dependency Inversion Principle
abstract interface class CacheService<K, V> {
  V? get(K key);
  void put(K key, V value);
  void clear();
  void maintain({int maxEntries});
  int get size;
}

/// Generic LRU cache implementation following SRP
class LRUCache<K, V> implements CacheService<K, V> {
  LRUCache({this.maxEntries = 100});

  final int maxEntries;
  final Map<K, V> _cache = {};
  final Map<K, DateTime> _accessTimes = {};

  @override
  V? get(K key) {
    final value = _cache[key];
    if (value != null) {
      _accessTimes[key] = DateTime.now();
    }
    return value;
  }

  @override
  void put(K key, V value) {
    _cache[key] = value;
    _accessTimes[key] = DateTime.now();

    if (_cache.length > maxEntries) {
      maintain();
    }
  }

  @override
  void clear() {
    _cache.clear();
    _accessTimes.clear();
  }

  @override
  void maintain({int? maxEntries}) {
    final limit = maxEntries ?? this.maxEntries;
    if (_cache.length <= limit) return;

    final sortedEntries = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final removeCount = _cache.length - limit ~/ 2;
    for (var i = 0; i < removeCount; i++) {
      final key = sortedEntries[i].key;
      _cache.remove(key);
      _accessTimes.remove(key);
    }
  }

  @override
  int get size => _cache.length;
}

/// Specialized search cache service following SRP
class SearchCacheService {
  SearchCacheService({int maxEntries = 100})
      : _cache = LRUCache<String, List<int>>(maxEntries: maxEntries);

  final LRUCache<String, List<int>> _cache;

  /// Get cached search matches for a term
  List<int>? getCachedMatches(String term) => _cache.get(term);

  /// Cache search matches for a term
  void cacheMatches(String term, List<int> matches) =>
      _cache.put(term, matches);

  /// Clear search cache
  void clear() => _cache.clear();

  /// Maintain cache size
  void maintain({int? maxEntries}) => _cache.maintain(maxEntries: maxEntries);

  /// Get cache size
  int get size => _cache.size;
}

/// Specialized node hierarchy cache service following SRP
class NodeHierarchyCacheService {
  NodeHierarchyCacheService({int maxEntries = 1000})
      : _cache = LRUCache<int, int>(maxEntries: maxEntries);

  final LRUCache<int, int> _cache;

  /// Get cached visible children count for a node
  int? getCachedCount(int nodeHashCode) => _cache.get(nodeHashCode);

  /// Cache visible children count for a node
  void cacheCount(int nodeHashCode, int count) =>
      _cache.put(nodeHashCode, count);

  /// Clear hierarchy cache
  void clear() => _cache.clear();

  /// Maintain cache size
  void maintain({int? maxEntries}) => _cache.maintain(maxEntries: maxEntries);

  /// Get cache size
  int get size => _cache.size;
}
