/// Service responsible for caching computations in JSON viewer
class JsonViewerCacheService {
  final Map<String, List<int>> _searchMatchesCache = {};
  final Map<int, int> _visibleChildrenCountCache = {};

  // LRU tracking for efficient cache eviction
  final Map<String, DateTime> _searchAccessTimes = {};
  final Map<int, DateTime> _nodeAccessTimes = {};

  /// Cache for search term results to avoid recomputing on navigation
  Map<String, List<int>> get searchMatchesCache => _searchMatchesCache;

  /// Cache for visible children count to avoid expensive recalculations
  Map<int, int> get visibleChildrenCountCache => _visibleChildrenCountCache;

  /// Clear all caches to free memory
  void clearAll() {
    _searchMatchesCache.clear();
    _visibleChildrenCountCache.clear();
    _searchAccessTimes.clear();
    _nodeAccessTimes.clear();
  }

  /// Clear only search-related caches
  void clearSearchCaches() {
    _searchMatchesCache.clear();
    _searchAccessTimes.clear();
  }

  /// Clear only node hierarchy caches
  void clearHierarchyCaches() {
    _visibleChildrenCountCache.clear();
    _nodeAccessTimes.clear();
  }

  /// Get cached search matches for a term with LRU tracking
  List<int>? getCachedSearchMatches(String term) {
    final matches = _searchMatchesCache[term];
    if (matches != null) {
      _searchAccessTimes[term] = DateTime.now();
    }
    return matches;
  }

  /// Cache search matches for a term
  void cacheSearchMatches(String term, List<int> matches) {
    _searchMatchesCache[term] = matches;
    _searchAccessTimes[term] = DateTime.now();
  }

  /// Get cached visible children count for a node with LRU tracking
  int? getCachedVisibleChildrenCount(int nodeHashCode) {
    final count = _visibleChildrenCountCache[nodeHashCode];
    if (count != null) {
      _nodeAccessTimes[nodeHashCode] = DateTime.now();
    }
    return count;
  }

  /// Cache visible children count for a node
  void cacheVisibleChildrenCount(int nodeHashCode, int count) {
    _visibleChildrenCountCache[nodeHashCode] = count;
    _nodeAccessTimes[nodeHashCode] = DateTime.now();
  }

  /// Efficient LRU-based cache maintenance
  void maintainCaches({int maxSearchEntries = 100, int maxNodeEntries = 1000}) {
    _maintainSearchCache(maxSearchEntries);
    _maintainNodeCache(maxNodeEntries);
  }

  void _maintainSearchCache(int maxEntries) {
    if (_searchMatchesCache.length <= maxEntries) return;

    // Sort by access time and remove oldest entries
    final sortedEntries = _searchAccessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final removeCount = _searchMatchesCache.length - maxEntries ~/ 2;
    for (var i = 0; i < removeCount; i++) {
      final key = sortedEntries[i].key;
      _searchMatchesCache.remove(key);
      _searchAccessTimes.remove(key);
    }
  }

  void _maintainNodeCache(int maxEntries) {
    if (_visibleChildrenCountCache.length <= maxEntries) return;

    // Sort by access time and remove oldest entries
    final sortedEntries = _nodeAccessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final removeCount = _visibleChildrenCountCache.length - maxEntries ~/ 2;
    for (var i = 0; i < removeCount; i++) {
      final key = sortedEntries[i].key;
      _visibleChildrenCountCache.remove(key);
      _nodeAccessTimes.remove(key);
    }
  }
}
