import 'dart:collection';

/// Interface for cache services to follow Dependency Inversion Principle
abstract interface class CacheService<K, V> {
  V? get(K key);
  void put(K key, V value);
  void clear();
  void maintain({int maxEntries});
  int get size;
}

class LRUCache<K, V> implements CacheService<K, V> {
  LRUCache({this.maxEntries = 100});

  final int maxEntries;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  @override
  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  @override
  void put(K key, V value) {
    _cache.remove(key);
    _cache[key] = value;

    if (_cache.length > maxEntries) {
      maintain();
    }
  }

  @override
  void clear() {
    _cache.clear();
  }

  @override
  void maintain({int? maxEntries}) {
    final limit = maxEntries ?? this.maxEntries;
    while (_cache.length > limit) {
      _cache.remove(_cache.keys.first);
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
