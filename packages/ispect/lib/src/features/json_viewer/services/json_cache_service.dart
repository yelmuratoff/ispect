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
    if (!_cache.containsKey(key)) return null;
    // containsKey check above guarantees the entry exists.
    // `as V` is correct for generic V - works whether V is nullable or not.
    final value = _cache.remove(key) as V;
    _cache[key] = value;
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
    while (_cache.length > limit && _cache.isNotEmpty) {
      _cache.remove(_cache.keys.first);
    }
  }

  @override
  int get size => _cache.length;
}
