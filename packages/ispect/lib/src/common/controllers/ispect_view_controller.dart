import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/cache/filter_cache.dart';

/// Result type for getTitles method with named fields for clarity.
///
/// - `all`: All non-null titles from logs (currently same as unique)
/// - `unique`: Unique titles from logs (deduplicated set)
typedef TitlesResult = ({List<String> all, List<String> unique});

/// Controller for managing the state of ISpectLogger views.
///
/// - Parameters: None required for initialization
/// - Return: ISpectViewController instance
/// - Usage example: final controller = ISpectViewController();
/// - Edge case notes: Handles null data gracefully with caching
class ISpectViewController extends ChangeNotifier {
  ISpectViewController({ISpectShareCallback? onShare}) : _onShare = onShare;

  ISpectFilter _filter = ISpectFilter();
  bool _expandedLogs = true;
  bool _isLogOrderReversed = true;
  ISpectLogData? _activeData;

  // JSON service for logs export/import
  final LogsJsonService _logsJsonService = const LogsJsonService();

  final ISpectShareCallback? _onShare;

  // Filter cache properties
  List<String>? _cachedTitles;
  List<Type>? _cachedTypes;
  String? _cachedSearchQuery;
  bool _filterCacheValid = false;

  // Simplified data filtering cache using generation-based approach
  final _filterCache = FilterCache();
  int _dataGeneration = 0;

  // Titles cache
  List<String>? _cachedAllTitles;
  List<String>? _cachedUniqueTitles;
  int? _lastTitlesDataHash;

  // Debounce timer for search query updates
  Timer? _filterDebounce;

  /// Retrieves the current log filter.
  ISpectFilter get filter => _filter;

  /// Updates the log filter and notifies listeners.
  set filter(ISpectFilter val) {
    if (_filter == val) return;
    _filter = val;
    _invalidateFilterCache();
    notifyListeners();
  }

  /// Gets the currently active data.
  ISpectLogData? get activeData => _activeData;

  /// Sets the active data and notifies listeners if changed.
  set activeData(ISpectLogData? data) {
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
  ///
  /// Uses debouncing to avoid excessive filtering on rapid input changes.
  /// The filter update is delayed by 300ms after the last query change.
  void updateFilterSearchQuery(String query) {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 300), () {
      _filter = _filter.copyWith(searchQuery: query);
      _invalidateFilterCache();
      notifyListeners();
    });
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
    final updatedTypes =
        currentTypes.where((t) => t != type).toList(growable: false);
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
    final updatedTitles =
        currentTitles.where((t) => t != title).toList(growable: false);
    if (updatedTitles.length == currentTitles.length) return;

    _updateFilter(titles: updatedTitles);
  }

  /// Updates filter with new values and notifies listeners if changed.
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
    notifyListeners();
  }

  /// Downloads logs as a file.
  Future<void> downloadLogsFile(String logs) async {
    final shareCallback = _ensureShareCallback();
    await LogsFileFactory.downloadFile(logs, onShare: shareCallback);
  }

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
          .toList(growable: false);
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
          .toList(growable: false);
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

  /// Applies current filters to log data with intelligent caching for performance.
  ///
  /// This method implements a generation-based caching strategy:
  /// 1. Checks if generation number matches (cache hit)
  /// 2. Applies filter only if cache is invalid
  /// 3. Updates cache with results
  ///
  /// **Performance Characteristics:**
  /// - O(1) for cache hits (when filter and data haven't changed)
  /// - O(n) for cache misses where n = number of logs
  ///
  /// **Cache Invalidation:**
  /// - Filter changes automatically invalidate via [filter] setter
  /// - Data changes require manual call to [onDataChanged]
  ///
  /// **Thread Safety:**
  /// This method is NOT thread-safe. Always call from the same isolate.
  ///
  /// {@tool snippet}
  /// Example usage:
  /// ```dart
  /// final filtered = controller.applyCurrentFilters(allLogs);
  /// print('Filtered ${filtered.length} logs from ${allLogs.length} total');
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  /// * [ISpectFilter], which defines filter behavior
  /// * [FilterCache], which implements the caching logic
  /// * [onDataChanged], which invalidates cache when data changes
  List<ISpectLogData> applyCurrentFilters(List<ISpectLogData> logsData) {
    if (logsData.isEmpty) return <ISpectLogData>[];
    return _filterCache.getFiltered(logsData, filter, _dataGeneration);
  }

  /// Invalidates the filter cache and increments data generation.
  ///
  /// Call this when the underlying data changes (not just the filter).
  void onDataChanged() {
    _dataGeneration++;
    _filterCache.invalidate();
  }

  /// Retrieves all titles and unique titles from log data with caching.
  ///
  /// Optimized to use a single-pass iteration instead of creating
  /// intermediate lists, reducing time complexity from O(2n) to O(n).
  ///
  /// Returns a named record with:
  /// - `all`: All unique titles (for backward compatibility)
  /// - `unique`: Unique titles (deduplicated)
  ///
  /// Example:
  /// ```dart
  /// final titles = controller.getTitles(logs);
  /// print('Found ${titles.unique.length} unique titles');
  /// ```
  TitlesResult getTitles(List<ISpectLogData> logsData) {
    // Simple length-based cache check
    final currentLength = logsData.length;

    // Return cached titles if data length hasn't changed
    if (_lastTitlesDataHash == currentLength &&
        _cachedAllTitles != null &&
        _cachedUniqueTitles != null) {
      return (all: _cachedAllTitles!, unique: _cachedUniqueTitles!);
    }

    // Single-pass extraction using Set for uniqueness
    final uniqueTitlesSet = <String>{};
    for (final data in logsData) {
      final title = data.title;
      if (title != null) {
        uniqueTitlesSet.add(title);
      }
    }

    // Convert to fixed-size list (no over-allocation)
    final uniqueTitles = uniqueTitlesSet.toList(growable: false);

    _cachedAllTitles = uniqueTitles;
    _cachedUniqueTitles = uniqueTitles;
    _lastTitlesDataHash = currentLength;

    return (all: uniqueTitles, unique: uniqueTitles);
  }

  /// Handles tap on a log item, toggling its selection state.
  void handleLogItemTap(ISpectLogData logEntry) {
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
  ISpectLogData getLogEntryAtIndex(
    List<ISpectLogData> filteredEntries,
    int index,
  ) {
    final actualIndex =
        isLogOrderReversed ? filteredEntries.length - 1 - index : index;
    return filteredEntries[actualIndex];
  }

  /// Copies log entry text to clipboard.
  void copyLogEntryText(
    BuildContext context,
    ISpectLogData logEntry,
    void Function(BuildContext, {required String value}) copyClipboard,
  ) {
    final text = logEntry.toJson(truncated: true).toString();
    copyClipboard(context, value: text);
  }

  /// Copies all logs to clipboard with specified formatting.
  void copyAllLogsToClipboard(
    BuildContext context,
    List<ISpectLogData> logs,
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
  Future<void> shareLogsAsFile(
    List<ISpectLogData> logs, {
    String fileType = 'json',
  }) async {
    final shareCallback = _ensureShareCallback();
    final filteredLogs = applyCurrentFilters(logs);
    if (filteredLogs.isEmpty) {
      ISpect.logger.info('No logs match the active filters. Skipping export.');
      return;
    }
    await _logsJsonService.shareFilteredLogsAsJsonFile(
      logs,
      filteredLogs,
      filter,
      fileName: 'ispect_logs_${DateTime.now().millisecondsSinceEpoch}',
      fileType: fileType,
      onShare: shareCallback,
    );
  }

  /// Shares all logs as JSON file without filtering.
  ///
  /// Exports all logs in JSON format for complete backup.
  Future<void> shareAllLogsAsJsonFile(List<ISpectLogData> logs) async {
    final shareCallback = _ensureShareCallback();
    if (logs.isEmpty) {
      ISpect.logger.info('No logs to export. Skipping file creation.');
      return;
    }
    await _logsJsonService.shareLogsAsJsonFile(
      logs,
      fileName: 'ispect_all_logs_${DateTime.now().millisecondsSinceEpoch}',
      onShare: shareCallback,
    );
  }

  /// Imports logs from JSON content.
  ///
  /// Parses JSON content and returns list of imported logs.
  /// Can be used to restore previously exported logs.
  Future<List<ISpectLogData>> importLogsFromJson(String jsonContent) async =>
      _logsJsonService.importFromJson(jsonContent);

  /// Validates if JSON content is valid for logs import.
  bool validateLogsJsonContent(String jsonContent) =>
      _logsJsonService.validateJsonStructure(jsonContent);

  ISpectShareCallback _ensureShareCallback() {
    final shareCallback = _onShare;
    if (shareCallback == null) {
      throw StateError(
        'Share callback is not configured. Provide onShare when constructing ISpectBuilder.',
      );
    }
    return shareCallback;
  }

  @override
  void dispose() {
    _filterDebounce?.cancel();
    super.dispose();
  }
}
