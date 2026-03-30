import 'dart:async';
import 'dart:collection';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/cache/filter_cache.dart';

typedef LogTypeKeysResult = ({List<String> all, List<String> unique});

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

  List<String>? _cachedLogTypeKeys;
  Set<Type>? _cachedTypesSet;
  String? _cachedSearchQuery;
  bool _filterCacheValid = false;

  // Cannot use FilterCache here because ISpectFilter uses identity equality.
  List<ISpectLogData>? _cachedNoSearchResult;
  int _noSearchResultGeneration = -1;
  ISpectFilter? _cachedNoSearchFilter;

  List<ISpectLogData> _cachedSearchMatches = const [];
  int _searchMatchesGeneration = -1;
  String? _lastSearchMatchQuery;
  List<ISpectLogData>? _lastSearchMatchInput;

  List<String>? _cachedAllKeys;
  List<String>? _cachedUniqueKeys;
  int _lastKeysGeneration = -1;

  ISpectFilter get filter => _filter;

  set filter(ISpectFilter val) {
    if (_filter == val) return;
    _filter = val;
    _invalidateFilterCache();
    _notify();
  }

  void updateFilterSearchQuery(String query, {bool immediate = false}) {
    _filterDebounce?.cancel();
    if (immediate) {
      _filter = _filter.copyWith(searchQuery: query);
      _invalidateSearchOnly();
      _notify();
      return;
    }
    _filterDebounce = Timer(_debounceDuration, () {
      if (_isDisposed) return;
      _filter = _filter.copyWith(searchQuery: query);
      _invalidateSearchOnly();
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

  void addLogTypeKeyFilter(String key) {
    final currentKeys = _getCurrentLogTypeKeys();
    if (currentKeys.contains(key)) return;
    _updateFilter(logTypeKeys: [...currentKeys, key]);
  }

  void removeLogTypeKeyFilter(String key) {
    final currentKeys = _getCurrentLogTypeKeys();
    final updatedKeys =
        currentKeys.where((k) => k != key).toList(growable: false);
    if (updatedKeys.length == currentKeys.length) return;
    _updateFilter(logTypeKeys: updatedKeys);
  }

  void handleLogTypeKeyFilterToggle(String key, {required bool isSelected}) {
    if (isSelected) {
      addLogTypeKeyFilter(key);
    } else {
      removeLogTypeKeyFilter(key);
    }
  }

  /// Clear all log type key filters and set only the given key.
  void setOnlyLogTypeKey(String key) {
    _updateFilter(logTypeKeys: [key]);
  }

  /// Clear all filters (log type keys, types, search query).
  void clearAllFilters() {
    _filterDebounce?.cancel();
    _updateFilter(
      logTypeKeys: <String>[],
      types: <Type>[],
      searchQuery: '',
    );
  }

  void clearLogTypeKeyFilters() {
    if (_getCurrentLogTypeKeys().isEmpty) return;
    _updateFilter(logTypeKeys: <String>[]);
  }

  /// Exclude a specific key: add all other keys except this one.
  void excludeLogTypeKey(String key, List<String> allKeys) {
    final filtered = allKeys.where((k) => k != key).toList(growable: false);
    _updateFilter(logTypeKeys: filtered);
  }

  void _updateFilter({
    List<String>? logTypeKeys,
    List<Type>? types,
    String? searchQuery,
  }) {
    final newFilter = ISpectFilter(
      logTypeKeys: logTypeKeys ?? _getCurrentLogTypeKeys(),
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

  /// Applies only log type key/type filters (no search query).
  /// Returns a stable reference on cache hits for [identical] checks.
  List<ISpectLogData> applyFiltersWithoutSearch(
    List<ISpectLogData> logsData,
  ) {
    if (logsData.isEmpty) return <ISpectLogData>[];
    if (_filter.types.isEmpty && _filter.logTypeKeys.isEmpty) {
      return logsData;
    }
    if (_noSearchResultGeneration == _outputGeneration &&
        _cachedNoSearchResult != null) {
      return _cachedNoSearchResult!;
    }
    final noSearchFilter = _cachedNoSearchFilter ??= ISpectFilter(
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
    // searchQuery is already trimmed in ISpectFilter constructor.
    if (query == null || query.isEmpty || logsData.isEmpty) {
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

  LogTypeKeysResult getLogTypeKeys(List<ISpectLogData> logsData) {
    if (_lastKeysGeneration == _dataGeneration) {
      final cachedAll = _cachedAllKeys;
      final cachedUnique = _cachedUniqueKeys;
      if (cachedAll != null && cachedUnique != null) {
        return (all: cachedAll, unique: cachedUnique);
      }
    }

    final allKeys = <String>[];
    final uniqueKeysSet = <String>{};

    for (final data in logsData) {
      final key = data.key;
      if (key == null) continue;
      allKeys.add(key);
      uniqueKeysSet.add(key);
    }

    final uniqueKeys = uniqueKeysSet.toList(growable: false);

    _cachedAllKeys = allKeys;
    _cachedUniqueKeys = uniqueKeys;
    _lastKeysGeneration = _dataGeneration;

    return (all: allKeys, unique: uniqueKeys);
  }

  void dispose() {
    _filterDebounce?.cancel();
    _filterDebounce = null;
    _isDisposed = true;
  }

  /// Targeted invalidation when only the search query changed.
  /// Keeps noSearch results valid (types/logTypeKeys unchanged).
  void _invalidateSearchOnly() {
    _outputGeneration++;
    _cachedSearchQuery = null;
    _searchMatchesGeneration = -1;
    _lastSearchMatchInput = null;
    // Bump noSearchResult generation to match so its cache stays valid.
    if (_cachedNoSearchResult != null) {
      _noSearchResultGeneration = _outputGeneration;
    }
  }

  void _invalidateFilterCache() {
    _outputGeneration++;
    _filterCacheValid = false;
    _cachedLogTypeKeys = null;
    _cachedTypesSet = null;
    _cachedSearchQuery = null;
    _noSearchResultGeneration = -1;
    _cachedNoSearchResult = null;
    _cachedNoSearchFilter = null;
    _searchMatchesGeneration = -1;
    _lastSearchMatchInput = null;
  }

  List<String> _getCurrentLogTypeKeys() {
    final cached = _cachedLogTypeKeys;
    if (_filterCacheValid && cached != null) return cached;
    final keys = _filter.logTypeKeys.toList(growable: false);
    _cachedLogTypeKeys = keys;
    _filterCacheValid = true;
    return keys;
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
