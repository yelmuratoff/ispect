import 'dart:collection';

import 'package:ispectify/ispectify.dart';

/// Generation-based cache for filtered log data.
///
/// Returns a stable [UnmodifiableListView] instance on cache hits,
/// enabling [identical] checks downstream.
class FilterCache {
  List<ISpectLogData> _cachedData = [];
  UnmodifiableListView<ISpectLogData>? _cachedView;
  ISpectFilter? _lastFilter;
  int _cacheGeneration = -1;

  /// Returns cached filtered data if generation and filter match,
  /// otherwise recomputes.
  List<ISpectLogData> getFiltered(
    List<ISpectLogData> data,
    ISpectFilter filter,
    int generation,
  ) {
    if (_isCacheValid(filter, generation)) {
      return _cachedView!;
    }

    _cachedData = data.where(filter.apply).toList(growable: false);
    _lastFilter = filter;
    _cacheGeneration = generation;
    _cachedView = UnmodifiableListView(_cachedData);
    return _cachedView!;
  }

  bool _isCacheValid(ISpectFilter filter, int generation) =>
      _cacheGeneration == generation && _lastFilter == filter;

  void invalidate() {
    _cacheGeneration = -1;
    _cachedView = null;
  }

  void clear() {
    _cachedData = [];
    _lastFilter = null;
    _cacheGeneration = -1;
    _cachedView = null;
  }
}
