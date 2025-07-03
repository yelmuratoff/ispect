import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

/// Controller for managing the state of ISpectify views.
///
/// - Parameters: None required for initialization
/// - Return: ISpectViewController instance
/// - Usage example: final controller = ISpectViewController();
/// - Edge case notes: Handles null data gracefully with caching
class ISpectViewController extends ChangeNotifier {
  ISpectifyFilter _filter = ISpectifyFilter();
  bool _expandedLogs = true;
  bool _isLogOrderReversed = true;
  ISpectifyData? _activeData;

  // JSON service for logs export/import
  final LogsJsonService _logsJsonService = const LogsJsonService();

  // Filter cache properties
  List<String>? _cachedTitles;
  List<Type>? _cachedTypes;
  String? _cachedSearchQuery;
  bool _filterCacheValid = false;

  // Data filtering cache
  List<ISpectifyData> _cachedFilteredData = <ISpectifyData>[];
  int _lastProcessedDataLength = 0;
  ISpectifyFilter? _lastAppliedFilter;
  int? _lastDataHash;

  // Titles cache
  List<String>? _cachedAllTitles;
  List<String>? _cachedUniqueTitles;
  int? _lastTitlesDataHash;

  /// Retrieves the current log filter.
  ISpectifyFilter get filter => _filter;

  /// Updates the log filter and notifies listeners.
  set filter(ISpectifyFilter val) {
    if (_filter == val) return;
    _filter = val;
    _invalidateFilterCache();
    notifyListeners();
  }

  /// Gets the currently active data.
  ISpectifyData? get activeData => _activeData;

  /// Sets the active data and notifies listeners if changed.
  set activeData(ISpectifyData? data) {
    if (_activeData == data) return;
    _activeData = data;
    notifyListeners();
  }

  /// Indicates whether logs are expanded.
  bool get expandedLogs => _expandedLogs;

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
    notifyListeners();
  }

  /// Adds a new filter type and notifies listeners.
  void addFilterType(Type type) {
    final currentTypes = _getCurrentTypes();
    if (currentTypes.contains(type)) return;

    _updateFilter(types: [...currentTypes, type]);
  }

  /// Removes a filter type and notifies listeners.
  void removeFilterType(Type type) {
    final currentTypes = _getCurrentTypes();
    final updatedTypes = currentTypes.where((t) => t != type).toList();
    if (updatedTypes.length == currentTypes.length) return;

    _updateFilter(types: updatedTypes);
  }

  /// Adds a new filter title and notifies listeners.
  void addFilterTitle(String title) {
    final currentTitles = _getCurrentTitles();
    if (currentTitles.contains(title)) return;

    _updateFilter(titles: [...currentTitles, title]);
  }

  /// Removes a filter title and notifies listeners.
  void removeFilterTitle(String title) {
    final currentTitles = _getCurrentTitles();
    final updatedTitles = currentTitles.where((t) => t != title).toList();
    if (updatedTitles.length == currentTitles.length) return;

    _updateFilter(titles: updatedTitles);
  }

  /// Updates filter with new values and notifies listeners if changed.
  void _updateFilter({
    List<String>? titles,
    List<Type>? types,
    String? searchQuery,
  }) {
    final newFilter = ISpectifyFilter(
      titles: titles ?? _getCurrentTitles(),
      types: types ?? _getCurrentTypes(),
      searchQuery: searchQuery ?? _getCurrentSearchQuery(),
    );
    if (newFilter == _filter) return;
    _filter = newFilter;
    _invalidateFilterCache();
    notifyListeners();
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

  /// Applies current filters to log data with caching for performance.
  List<ISpectifyData> applyCurrentFilters(List<ISpectifyData> logsData) {
    if (logsData.isEmpty) return <ISpectifyData>[];

    final currentFilter = filter;
    final currentDataHash = _calculateDataHash(logsData);

    // Return cached result if data and filter haven't changed
    if (_isCacheValid(logsData, currentFilter, currentDataHash)) {
      return _cachedFilteredData;
    }

    // Apply filter and update cache
    final filteredData = logsData.where(currentFilter.apply).toList();
    _updateFilterCache(logsData, currentFilter, currentDataHash, filteredData);

    return filteredData;
  }

  /// Checks if the current cache is valid.
  bool _isCacheValid(
    List<ISpectifyData> logsData,
    ISpectifyFilter currentFilter,
    int currentDataHash,
  ) =>
      logsData.length == _lastProcessedDataLength &&
      _cachedFilteredData.isNotEmpty &&
      _lastDataHash == currentDataHash &&
      _lastAppliedFilter == currentFilter;

  /// Updates the filter cache with new data.
  void _updateFilterCache(
    List<ISpectifyData> logsData,
    ISpectifyFilter currentFilter,
    int currentDataHash,
    List<ISpectifyData> filteredData,
  ) {
    _cachedFilteredData = filteredData;
    _lastProcessedDataLength = logsData.length;
    _lastAppliedFilter = currentFilter;
    _lastDataHash = currentDataHash;
  }

  /// Calculates a hash for the given data list for cache validation.
  int _calculateDataHash(List<ISpectifyData> data) {
    if (data.isEmpty) return 0;
    return Object.hashAll([
      data.length,
      data.first.hashCode,
      data.last.hashCode,
    ]);
  }

  /// Retrieves all titles and unique titles from log data with caching.
  (List<String>, List<String>) getTitles(List<ISpectifyData> logsData) {
    final currentHash = _calculateDataHash(logsData);

    // Return cached titles if data hasn't changed
    if (_lastTitlesDataHash == currentHash &&
        _cachedAllTitles != null &&
        _cachedUniqueTitles != null) {
      return (_cachedAllTitles!, _cachedUniqueTitles!);
    }

    // Extract and cache titles
    final allTitles =
        logsData.map((data) => data.title).whereType<String>().toList();
    final uniqueTitles = allTitles.toSet().toList();

    _cachedAllTitles = allTitles;
    _cachedUniqueTitles = uniqueTitles;
    _lastTitlesDataHash = currentHash;

    return (allTitles, uniqueTitles);
  }

  /// Handles tap on a log item, toggling its selection state.
  void handleLogItemTap(ISpectifyData logEntry) {
    activeData = activeData?.hashCode == logEntry.hashCode ? null : logEntry;
  }

  /// Handles toggle of title filter selection.
  void handleTitleFilterToggle(String title, {required bool isSelected}) {
    if (isSelected) {
      addFilterTitle(title);
    } else {
      removeFilterTitle(title);
    }
  }

  /// Retrieves log entry at the specified index, respecting sort order.
  ISpectifyData getLogEntryAtIndex(
    List<ISpectifyData> filteredEntries,
    int index,
  ) {
    final actualIndex =
        isLogOrderReversed ? filteredEntries.length - 1 - index : index;
    return filteredEntries[actualIndex];
  }

  /// Copies log entry text to clipboard.
  void copyLogEntryText(
    BuildContext context,
    ISpectifyData logEntry,
    void Function(BuildContext, {required String value}) copyClipboard,
  ) {
    final text = logEntry.toJson(truncated: true).toString();
    copyClipboard(context, value: text);
  }

  /// Copies all logs to clipboard with specified formatting.
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
    final logsText =
        logs.map((log) => log.toJson(truncated: true).toString()).join('\n');

    copyClipboard(
      context,
      value: logsText,
      title: title,
      showValue: false,
    );
  }

  /// Clears logs history and updates UI.
  void clearLogsHistory(VoidCallback clearHistory) {
    clearHistory();
    update();
  }

  /// Shares filtered logs as a downloadable JSON file.
  ///
  /// Exports logs in structured JSON format with metadata including
  /// filter information for better context and import capabilities.
  Future<void> shareLogsAsFile(List<ISpectifyData> logs) async {
    final filteredLogs = applyCurrentFilters(logs);
    await _logsJsonService.shareFilteredLogsAsJsonFile(
      logs,
      filteredLogs,
      filter,
      fileName: 'ispect_logs_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Shares all logs as JSON file without filtering.
  ///
  /// Exports all logs in JSON format for complete backup.
  Future<void> shareAllLogsAsJsonFile(List<ISpectifyData> logs) async {
    await _logsJsonService.shareLogsAsJsonFile(
      logs,
      fileName: 'ispect_all_logs_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Imports logs from JSON content.
  ///
  /// Parses JSON content and returns list of imported logs.
  /// Can be used to restore previously exported logs.
  Future<List<ISpectifyData>> importLogsFromJson(String jsonContent) async =>
      _logsJsonService.importFromJson(jsonContent);

  /// Validates if JSON content is valid for logs import.
  bool validateLogsJsonContent(String jsonContent) =>
      _logsJsonService.validateJsonStructure(jsonContent);
}
