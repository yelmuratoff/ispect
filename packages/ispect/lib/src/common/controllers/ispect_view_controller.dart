import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

/// Controller for managing the state of ISpectify views.
///
/// This class extends `ChangeNotifier` to provide state updates
/// when filters, log visibility, or log order change.
class ISpectViewController extends ChangeNotifier {
  ISpectifyFilter _filter = ISpectifyFilter();
  bool _expandedLogs = true;
  bool _isLogOrderReversed = true;
  ISpectifyData? _activeData;

  List<String>? _cachedTitles;
  List<Type>? _cachedTypes;
  String? _cachedSearchQuery;
  bool _filterCacheValid = false;

  // --- Логика фильтрации и кеширования ---

  List<ISpectifyData> _cachedFilteredData = <ISpectifyData>[];
  int _lastProcessedDataLength = 0;
  ISpectifyFilter? _lastAppliedFilter;
  int? _lastDataHash;

  List<String>? _cachedAllTitles;
  List<String>? _cachedUniqueTitles;
  int? _lastTitlesDataHash;

  /// Retrieves the current log filter.
  ISpectifyFilter get filter => _filter;

  /// Updates the log filter and notifies listeners with debouncing.
  set filter(ISpectifyFilter val) {
    if (_filter != val) {
      _filter = val;
      _invalidateFilterCache();
      _notifyWithDebounce();
    }
  }

  set activeData(ISpectifyData? data) {
    if (_activeData != data) {
      _activeData = data;
      notifyListeners();
    }
  }

  /// Indicates whether logs are expanded.
  bool get expandedLogs => _expandedLogs;

  ISpectifyData? get activeData => _activeData;

  /// Toggles the expanded logs state and notifies listeners.
  void toggleExpandedLogs() {
    _expandedLogs = !_expandedLogs;
    notifyListeners();
  }

  /// Indicates whether log order is reversed.
  bool get isLogOrderReversed => _isLogOrderReversed;

  /// Toggles the log order between normal and reversed.
  void toggleLogOrder() {
    _isLogOrderReversed = !_isLogOrderReversed;
    notifyListeners();
  }

  /// Updates the filter's search query and notifies listeners.
  void updateFilterSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    _invalidateFilterCache();
    _notifyWithDebounce();
  }

  /// Adds a new filter type and notifies listeners.
  void addFilterType(Type type) {
    final currentTypes = _getCurrentTypes();
    if (!currentTypes.contains(type)) {
      _filter = ISpectifyFilter(
        titles: _getCurrentTitles(),
        types: [...currentTypes, type],
        searchQuery: _getCurrentSearchQuery(),
      );
      _invalidateFilterCache();
      notifyListeners();
    }
  }

  /// Removes a filter type and notifies listeners.
  void removeFilterType(Type type) {
    final updatedTypes = _getCurrentTypes().where((t) => t != type).toList();
    if (updatedTypes.length != _getCurrentTypes().length) {
      _filter = ISpectifyFilter(
        titles: _getCurrentTitles(),
        types: updatedTypes,
        searchQuery: _getCurrentSearchQuery(),
      );
      _invalidateFilterCache();
      notifyListeners();
    }
  }

  /// Adds a new filter title and notifies listeners.
  void addFilterTitle(String title) {
    final currentTitles = _getCurrentTitles();
    if (!currentTitles.contains(title)) {
      _filter = ISpectifyFilter(
        titles: [...currentTitles, title],
        types: _getCurrentTypes(),
        searchQuery: _getCurrentSearchQuery(),
      );
      _invalidateFilterCache();
      notifyListeners();
    }
  }

  /// Removes a filter title and notifies listeners.
  void removeFilterTitle(String title) {
    final updatedTitles = _getCurrentTitles().where((t) => t != title).toList();
    if (updatedTitles.length != _getCurrentTitles().length) {
      _filter = ISpectifyFilter(
        titles: updatedTitles,
        types: _getCurrentTypes(),
        searchQuery: _getCurrentSearchQuery(),
      );
      _invalidateFilterCache();
      notifyListeners();
    }
  }

  /// Downloads logs as a file.
  Future<void> downloadLogsFile(String logs) async =>
      LogsFileFactory.downloadFile(logs);

  /// Forces a UI update.
  void update() => notifyListeners();

  /// Retrieves the current title filters with caching.
  List<String> _getCurrentTitles() {
    if (!_filterCacheValid || _cachedTitles == null) {
      _cachedTitles = (_filter.filters.firstWhere(
        (f) => f is TitleFilter,
        orElse: () => TitleFilter([]),
      ) as TitleFilter)
          .titles
          .toList();
    }
    return _cachedTitles!;
  }

  /// Retrieves the current type filters with caching.
  List<Type> _getCurrentTypes() {
    if (!_filterCacheValid || _cachedTypes == null) {
      _cachedTypes = (_filter.filters.firstWhere(
        (f) => f is TypeFilter,
        orElse: () => TypeFilter([]),
      ) as TypeFilter)
          .types
          .toList();
    }
    return _cachedTypes!;
  }

  /// Retrieves the current search query with caching.
  String? _getCurrentSearchQuery() {
    if (!_filterCacheValid || _cachedSearchQuery == null) {
      final query = (_filter.filters.firstWhere(
        (f) => f is SearchFilter,
        orElse: () => SearchFilter(''),
      ) as SearchFilter)
          .query;
      _cachedSearchQuery = query.isEmpty ? null : query;
    }
    return _cachedSearchQuery;
  }

  /// Invalidates the filter cache when filters change.
  void _invalidateFilterCache() {
    _filterCacheValid = false;
    _cachedTitles = null;
    _cachedTypes = null;
    _cachedSearchQuery = null;
  }

  /// Debounced notification to prevent excessive rebuilds.
  void _notifyWithDebounce() {
    // For search queries, we could add debouncing here if needed
    notifyListeners();
  }

  List<ISpectifyData> applyCurrentFilters(List<ISpectifyData> logsData) {
    final currentFilter = filter;
    final currentDataHash = _calculateDataHash(logsData);
    if (logsData.length == _lastProcessedDataLength &&
        logsData.isNotEmpty &&
        _cachedFilteredData.isNotEmpty &&
        _lastDataHash == currentDataHash &&
        _lastAppliedFilter == currentFilter) {
      return _cachedFilteredData;
    }
    final filteredData = logsData.where(currentFilter.apply).toList();
    _cachedFilteredData = filteredData;
    _lastProcessedDataLength = logsData.length;
    _lastAppliedFilter = currentFilter;
    _lastDataHash = currentDataHash;
    return filteredData;
  }

  int _calculateDataHash(List<ISpectifyData> data) {
    if (data.isEmpty) return 0;
    return Object.hashAll([
      data.length,
      data.first.hashCode,
      data.last.hashCode,
    ]);
  }

  (List<String>, List<String>) getTitles(List<ISpectifyData> logsData) {
    final currentHash = _calculateDataHash(logsData);
    if (_lastTitlesDataHash == currentHash &&
        _cachedAllTitles != null &&
        _cachedUniqueTitles != null) {
      return (_cachedAllTitles!, _cachedUniqueTitles!);
    }
    final allTitles = logsData.map((e) => e.title).whereType<String>().toList();
    final uniqueTitles = allTitles.toSet().toList();
    _cachedAllTitles = allTitles;
    _cachedUniqueTitles = uniqueTitles;
    _lastTitlesDataHash = currentHash;
    return (allTitles, uniqueTitles);
  }

  void handleLogItemTap(ISpectifyData logEntry) {
    if (activeData?.hashCode == logEntry.hashCode) {
      activeData = null;
    } else {
      activeData = logEntry;
    }
  }

  void handleTitleFilterToggle(String title, {required bool isSelected}) {
    if (isSelected) {
      addFilterTitle(title);
    } else {
      removeFilterTitle(title);
    }
  }

  ISpectifyData getLogEntryAtIndex(
    List<ISpectifyData> filteredEntries,
    int index,
  ) {
    final actualIndex =
        isLogOrderReversed ? filteredEntries.length - 1 - index : index;
    return filteredEntries[actualIndex];
  }

  void copyLogEntryText(
    BuildContext context,
    ISpectifyData logEntry,
    void Function(BuildContext, {required String value}) copyClipboard,
  ) {
    final text = logEntry.toJson(truncated: true).toString();
    copyClipboard(context, value: text);
  }

  void copyAllLogsToClipboard(
    BuildContext context,
    List<ISpectifyData> logs,
    void Function(
      BuildContext, {
      required String value,
      String? title,
      bool? showValue,
    }) copyClipboard,
    String title,
  ) {
    copyClipboard(
      context,
      value: logs.map((e) => e.toJson(truncated: true).toString()).join('\n'),
      title: title,
      showValue: false,
    );
  }

  void clearLogsHistory(VoidCallback clearHistory) {
    clearHistory();
    update();
  }

  Future<void> shareLogsAsFile(List<ISpectifyData> logs) async {
    final filteredLogs = applyCurrentFilters(logs);
    await downloadLogsFile(
      filteredLogs.formattedText,
    );
  }
}
