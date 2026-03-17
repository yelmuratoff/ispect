import 'dart:async';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/cache/filter_cache.dart';

typedef TitlesResult = ({List<String> all, List<String> unique});

/// Handles all filtering-related state and operations.
class FilterManager {
  FilterManager({
    ISpectFilter? initialFilter,
    void Function()? onChanged,
    Duration debounceDuration = const Duration(milliseconds: 300),
  })  : _filter = initialFilter ?? ISpectFilter(),
        _onChanged = onChanged,
        _debounceDuration = debounceDuration;

  ISpectFilter _filter;
  final void Function()? _onChanged;
  final Duration _debounceDuration;

  // Generation-based cache for filtered results
  final _filterCache = FilterCache();
  int _dataGeneration = 0;

  /// Combined generation counter that increments on both data and filter
  /// changes. Use this to invalidate caches that depend on the filtered output
  /// (e.g. grouped network transactions).
  int get outputGeneration => _outputGeneration;
  int _outputGeneration = 0;

  // Debounce for search query updates
  Timer? _filterDebounce;
  bool _isDisposed = false;

  // Lightweight caches for current filter parts
  List<String>? _cachedTitles;
  Set<Type>? _cachedTypesSet;
  String? _cachedSearchQuery;
  bool _filterCacheValid = false;

  // Cache for title extraction
  List<String>? _cachedAllTitles;
  List<String>? _cachedUniqueTitles;
  int _lastTitlesGeneration = -1;

  ISpectFilter get filter => _filter;

  set filter(ISpectFilter val) {
    if (_filter == val) return;
    _filter = val;
    _invalidateFilterCache();
    _notify();
  }

  void updateFilterSearchQuery(String query) {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(_debounceDuration, () {
      if (_isDisposed) return;
      _filter = _filter.copyWith(searchQuery: query);
      _invalidateFilterCache();
      _notify();
    });
  }

  void addFilterType(Type type) {
    final currentTypesSet = _getCurrentTypesSet();
    if (currentTypesSet.contains(type)) return;
    _updateFilter(types: [...currentTypesSet, type]);
  }

  void removeFilterType(Type type) {
    final currentTypes = _getCurrentTypes();
    final updatedTypes =
        currentTypes.where((t) => t != type).toList(growable: false);
    if (updatedTypes.length == currentTypes.length) return;
    _updateFilter(types: updatedTypes);
  }

  void addFilterTitle(String title) {
    final currentTitles = _getCurrentTitles();
    if (currentTitles.contains(title)) return;
    _updateFilter(titles: [...currentTitles, title]);
  }

  void removeFilterTitle(String title) {
    final currentTitles = _getCurrentTitles();
    final updatedTitles =
        currentTitles.where((t) => t != title).toList(growable: false);
    if (updatedTitles.length == currentTitles.length) return;
    _updateFilter(titles: updatedTitles);
  }

  void handleTitleFilterToggle(String title, {required bool isSelected}) {
    if (isSelected) {
      addFilterTitle(title);
    } else {
      removeFilterTitle(title);
    }
  }

  /// Clear all title filters and set only the given title.
  void setOnlyTitle(String title) {
    _updateFilter(titles: [title]);
  }

  /// Clear all filters (titles, types, search query).
  void clearAllFilters() {
    _filterDebounce?.cancel();
    _updateFilter(titles: <String>[], types: <Type>[], searchQuery: '');
  }

  /// Exclude a specific title: add all other titles except this one.
  void excludeTitle(String title, List<String> allTitles) {
    final filtered = allTitles.where((t) => t != title).toList(growable: false);
    _updateFilter(titles: filtered);
  }

  void _updateFilter({
    List<String>? titles,
    List<Type>? types,
    String? searchQuery,
  }) {
    final newFilter = ISpectFilter(
      titles: titles ?? _getCurrentTitles(),
      types: types ?? _getCurrentTypes(),
      searchQuery: searchQuery ?? _getCurrentSearchQuery(),
    );
    if (newFilter == _filter) return;
    _filter = newFilter;
    _invalidateFilterCache();
    _notify();
  }

  List<ISpectLogData> applyCurrentFilters(List<ISpectLogData> logsData) {
    if (logsData.isEmpty) return <ISpectLogData>[];
    return _filterCache.getFiltered(logsData, filter, _dataGeneration);
  }

  void onDataChanged() {
    _dataGeneration++;
    _outputGeneration++;
    _filterCache.invalidate();
  }

  TitlesResult getTitles(List<ISpectLogData> logsData) {
    if (_lastTitlesGeneration == _dataGeneration) {
      final cachedAll = _cachedAllTitles;
      final cachedUnique = _cachedUniqueTitles;
      if (cachedAll != null && cachedUnique != null) {
        return (all: cachedAll, unique: cachedUnique);
      }
    }

    final allTitles = <String>[];
    final uniqueTitlesSet = <String>{};

    for (final data in logsData) {
      final title = data.title;
      if (title == null) continue;
      allTitles.add(title);
      uniqueTitlesSet.add(title);
    }

    final uniqueTitles = uniqueTitlesSet.toList(growable: false);

    _cachedAllTitles = allTitles;
    _cachedUniqueTitles = uniqueTitles;
    _lastTitlesGeneration = _dataGeneration;

    return (all: allTitles, unique: uniqueTitles);
  }

  void dispose() {
    _filterDebounce?.cancel();
    _filterDebounce = null;
    _isDisposed = true;
  }

  // Internal helpers
  void _invalidateFilterCache() {
    _outputGeneration++;
    _filterCacheValid = false;
    _cachedTitles = null;
    _cachedTypesSet = null;
    _cachedSearchQuery = null;
  }

  List<String> _getCurrentTitles() {
    final cached = _cachedTitles;
    if (_filterCacheValid && cached != null) return cached;
    final titles = _filter.titles.toList(growable: false);
    _cachedTitles = titles;
    _filterCacheValid = true;
    return titles;
  }

  Set<Type> _getCurrentTypesSet() {
    final cached = _cachedTypesSet;
    if (_filterCacheValid && cached != null) return cached;
    final types = _filter.types.toSet();
    _cachedTypesSet = types;
    _filterCacheValid = true;
    return types;
  }

  List<Type> _getCurrentTypes() =>
      _getCurrentTypesSet().toList(growable: false);

  String? _getCurrentSearchQuery() {
    if (!_filterCacheValid || _cachedSearchQuery == null) {
      final query = _filter.searchQuery;
      _cachedSearchQuery = (query == null || query.isEmpty) ? null : query;
      _filterCacheValid = true;
    }
    return _cachedSearchQuery;
  }

  void _notify() {
    if (_isDisposed) return;
    final cb = _onChanged;
    if (cb != null) cb();
  }
}
