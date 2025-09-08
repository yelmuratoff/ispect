/// Service responsible for caching computations in JSON viewer
class JsonViewerCacheService {
  final Map<String, List<int>> _searchMatchesCache = {};
  final Map<int, int> _visibleChildrenCountCache = {};

  /// Cache for search term results to avoid recomputing on navigation
  Map<String, List<int>> get searchMatchesCache => _searchMatchesCache;

  /// Cache for visible children count to avoid expensive recalculations
  Map<int, int> get visibleChildrenCountCache => _visibleChildrenCountCache;

  /// Clear all caches to free memory
  void clearAll() {
    _searchMatchesCache.clear();
    _visibleChildrenCountCache.clear();
  }

  /// Clear only search-related caches
  void clearSearchCaches() {
    _searchMatchesCache.clear();
  }

  /// Clear only node hierarchy caches
  void clearHierarchyCaches() {
    _visibleChildrenCountCache.clear();
  }

  /// Get cached search matches for a term
  List<int>? getCachedSearchMatches(String term) => _searchMatchesCache[term];

  /// Cache search matches for a term
  void cacheSearchMatches(String term, List<int> matches) {
    _searchMatchesCache[term] = matches;
  }

  /// Get cached visible children count for a node
  int? getCachedVisibleChildrenCount(int nodeHashCode) => _visibleChildrenCountCache[nodeHashCode];

  /// Cache visible children count for a node
  void cacheVisibleChildrenCount(int nodeHashCode, int count) {
    _visibleChildrenCountCache[nodeHashCode] = count;
  }

  /// Check if caches are getting too large and clean them if needed
  void maintainCaches({int maxSearchEntries = 100, int maxNodeEntries = 1000}) {
    if (_searchMatchesCache.length > maxSearchEntries) {
      // Keep only the most recent entries
      final entries = _searchMatchesCache.entries.toList();
      _searchMatchesCache.clear();
      final keepCount = maxSearchEntries ~/ 2;
      for (var i = entries.length - keepCount; i < entries.length; i++) {
        _searchMatchesCache[entries[i].key] = entries[i].value;
      }
    }

    if (_visibleChildrenCountCache.length > maxNodeEntries) {
      // Keep only the most recent entries
      final entries = _visibleChildrenCountCache.entries.toList();
      _visibleChildrenCountCache.clear();
      final keepCount = maxNodeEntries ~/ 2;
      for (var i = entries.length - keepCount; i < entries.length; i++) {
        _visibleChildrenCountCache[entries[i].key] = entries[i].value;
      }
    }
  }
}
