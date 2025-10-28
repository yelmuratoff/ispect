import 'package:ispectify/ispectify.dart';

/// Simple cache for filtered log data.
///
/// Uses a generation-based approach to track data changes,
/// which is simpler and more performant than complex hash calculations.
class FilterCache {
  List<ISpectifyData> _cachedData = [];
  ISpectifyFilter? _lastFilter;
  int _cacheGeneration = -1;

  /// Gets filtered data, using cache if valid.
  ///
  /// - `data`: The complete list of logs to filter
  /// - `filter`: The filter to apply
  /// - `generation`: Current data generation number (incremented on changes)
  ///
  /// Returns cached data if the generation and filter match,
  /// otherwise applies the filter and caches the result.
  List<ISpectifyData> getFiltered(
    List<ISpectifyData> data,
    ISpectifyFilter filter,
    int generation,
  ) {
    if (_isCacheValid(filter, generation)) {
      return _cachedData;
    }

    _cachedData = data.where(filter.apply).toList(growable: false);
    _lastFilter = filter;
    _cacheGeneration = generation;
    return _cachedData;
  }

  /// Checks if the cache is valid for the given filter and generation.
  bool _isCacheValid(ISpectifyFilter filter, int generation) =>
      _cacheGeneration == generation && _lastFilter == filter;

  /// Invalidates the cache, forcing a refresh on next access.
  void invalidate() {
    _cacheGeneration = -1;
  }

  /// Clears all cached data.
  void clear() {
    _cachedData = [];
    _lastFilter = null;
    _cacheGeneration = -1;
  }
}
