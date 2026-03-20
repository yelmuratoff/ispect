import 'dart:async';
import 'dart:collection';

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

  final _filterCache = FilterCache();
  int _dataGeneration = 0;

  int get outputGeneration => _outputGeneration;
  int _outputGeneration = 0;

  Timer? _filterDebounce;
  bool _isDisposed = false;

  List<String>? _cachedTitles;
  Set<Type>? _cachedTypesSet;
  String? _cachedSearchQuery;
  bool _filterCacheValid = false;

  // Cannot use FilterCache here because ISpectFilter uses identity equality.
  List<ISpectLogData>? _cachedNoSearchResult;
  int _noSearchResultGeneration = -1;

  List<ISpectLogData> _cachedSearchMatches = const [];
  int _searchMatchesGeneration = -1;
  String? _lastSearchMatchQuery;
  List<ISpectLogData>? _lastSearchMatchInput;

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

  /// Applies only title/type filters (no search query).
  /// Returns a stable reference on cache hits for [identical] checks.
  List<ISpectLogData> applyFiltersWithoutSearch(
    List<ISpectLogData> logsData,
  ) {
    if (logsData.isEmpty) return <ISpectLogData>[];
    if (_filter.titles.isEmpty &&
        _filter.types.isEmpty &&
        _filter.logTypeKeys.isEmpty) {
      return logsData;
    }
    if (_noSearchResultGeneration == _outputGeneration &&
        _cachedNoSearchResult != null) {
      return _cachedNoSearchResult!;
    }
    final noSearchFilter = ISpectFilter(
      titles: _filter.titles.toList(),
      types: _filter.types.toList(),
      logTypeKeys: _filter.logTypeKeys.toList(),
    );
    final result = logsData.where(noSearchFilter.apply).toList(growable: false);
    _cachedNoSearchResult = UnmodifiableListView(result);
    _noSearchResultGeneration = _outputGeneration;
    return _cachedNoSearchResult!;
  }

  /// Returns log entries matching the current search query.
  /// Cached by generation + query + input list identity.
  List<ISpectLogData> findSearchMatches(List<ISpectLogData> logsData) {
    final query = _filter.searchQuery;
    if (query == null || query.trim().isEmpty || logsData.isEmpty) {
      return const [];
    }
    if (_searchMatchesGeneration == _outputGeneration &&
        _lastSearchMatchQuery == query &&
        identical(logsData, _lastSearchMatchInput)) {
      return _cachedSearchMatches;
    }
    final searchFilter = SearchFilter(query);
    _cachedSearchMatches =
        logsData.where(searchFilter.apply).toList(growable: false);
    _searchMatchesGeneration = _outputGeneration;
    _lastSearchMatchQuery = query;
    _lastSearchMatchInput = logsData;
    return _cachedSearchMatches;
  }

  void onDataChanged() {
    _dataGeneration++;
    _outputGeneration++;
    _filterCache.invalidate();
    _noSearchResultGeneration = -1;
    _cachedNoSearchResult = null;
    _searchMatchesGeneration = -1;
    _lastSearchMatchInput = null;
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

  void _invalidateFilterCache() {
    _outputGeneration++;
    _filterCacheValid = false;
    _cachedTitles = null;
    _cachedTypesSet = null;
    _cachedSearchQuery = null;
    _noSearchResultGeneration = -1;
    _cachedNoSearchResult = null;
    _searchMatchesGeneration = -1;
    _lastSearchMatchInput = null;
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
