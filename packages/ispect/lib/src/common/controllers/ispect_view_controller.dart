import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/managers/filter_manager.dart';
import 'package:ispect/src/common/managers/settings_manager.dart';
import 'package:ispect/src/common/services/log_export_service.dart';
import 'package:ispect/src/common/services/log_import_service.dart';

/// Column used for sorting desktop log table.
enum LogSortColumn { type, time, message }

/// Direction for sorting desktop log table.
enum LogSortDirection { ascending, descending }

/// Search behavior mode.
enum SearchMode {
  /// Highlights matching cards and scrolls to them, keeping all logs visible.
  highlight,

  /// Filters out non-matching logs (legacy behavior).
  filter,
}

/// Visual state of a log card relative to the current search.
enum SearchMatchState {
  /// Not a search match.
  none,

  /// Matches the search query but is not the currently focused result.
  match,

  /// The currently focused search result (navigated to via ↑/↓).
  focused,
}

class ISpectViewController extends ChangeNotifier {
  ISpectViewController({
    ISpectShareCallback? onShare,
    ISpectSettingsState? initialSettings,
    bool groupHttpLogs = true,
  })  : _groupHttpLogs = groupHttpLogs,
        _exportService = LogExportService(onShare: onShare),
        _importService = const LogImportService() {
    _settingsManager = SettingsManager(
      initialSettings: initialSettings,
      onChanged: notifyListeners,
    );
    _filterManager = FilterManager(
      initialFilter: ISpectFilter(),
      onChanged: notifyListeners,
    );
  }

  late final FilterManager _filterManager;
  late final SettingsManager _settingsManager;
  final LogExportService _exportService;
  final LogImportService _importService;

  bool _expandedLogs = true;
  bool _isLogOrderReversed = true;
  bool _groupHttpLogs;
  ISpectLogData? _activeData;

  // --- Desktop: detail panel data (separate from selection highlight) ---
  ISpectLogData? _detailData;

  // --- Desktop: relative time toggle ---
  bool _useRelativeTime = false;

  // --- Search mode: highlight vs filter ---
  SearchMode _searchMode = SearchMode.highlight;
  List<int> _searchMatchIds = const [];
  Set<int> _searchMatchIdSet = const {};
  int _focusedMatchIndex = -1;

  // --- Desktop: column sorting ---
  LogSortColumn _sortColumn = LogSortColumn.time;
  LogSortDirection _sortDirection = LogSortDirection.descending;

  ISpectSettingsState get settings => _settingsManager.settings;

  void updateSettings(ISpectSettingsState newSettings) =>
      _settingsManager.updateSettings(newSettings);

  ISpectFilter get filter => _filterManager.filter;

  set filter(ISpectFilter val) => _filterManager.filter = val;

  ISpectLogData? get activeData => _activeData;

  set activeData(ISpectLogData? data) {
    if (_activeData == data) return;
    _activeData = data;
    notifyListeners();
  }

  // --- Detail panel (desktop: double-click opens detail) ---
  ISpectLogData? get detailData => _detailData;

  set detailData(ISpectLogData? data) {
    if (_detailData == data) return;
    _detailData = data;
    notifyListeners();
  }

  /// Single click on desktop: select/highlight only.
  // ignore: use_setters_to_change_properties
  void selectLog(ISpectLogData entry) {
    activeData = entry;
  }

  /// Double click on desktop: open detail panel.
  void openLogDetail(ISpectLogData entry) {
    _activeData = entry;
    _detailData = _detailData == entry ? null : entry;
    notifyListeners();
  }

  /// Select a log and update the detail panel in a single notification.
  void selectAndFollowDetail(ISpectLogData entry) {
    _activeData = entry;
    _detailData = entry;
    notifyListeners();
  }

  /// Close the detail panel without clearing selection.
  void closeDetail() {
    if (_detailData == null) return;
    _detailData = null;
    notifyListeners();
  }

  // --- Relative time ---
  bool get useRelativeTime => _useRelativeTime;

  void toggleTimestampFormat() {
    _useRelativeTime = !_useRelativeTime;
    notifyListeners();
  }

  // --- Column sorting ---
  LogSortColumn get sortColumn => _sortColumn;
  LogSortDirection get sortDirection => _sortDirection;

  void toggleSort(LogSortColumn column) {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == LogSortDirection.ascending
          ? LogSortDirection.descending
          : LogSortDirection.ascending;
    } else {
      _sortColumn = column;
      _sortDirection = LogSortDirection.ascending;
    }
    notifyListeners();
  }

  /// Sort a filtered list by the current sort column/direction.
  List<ISpectLogData> applySorting(List<ISpectLogData> entries) {
    if (_sortColumn == LogSortColumn.time) {
      return entries;
    }
    final sorted = List<ISpectLogData>.of(entries);
    switch (_sortColumn) {
      case LogSortColumn.type:
        sorted.sort((a, b) => (a.key ?? '').compareTo(b.key ?? ''));
      case LogSortColumn.message:
        sorted.sort((a, b) {
          final aMsg = a.isHttpLog ? (a.httpLogText ?? '') : (a.textMessage);
          final bMsg = b.isHttpLog ? (b.httpLogText ?? '') : (b.textMessage);
          return aMsg.compareTo(bMsg);
        });
      case LogSortColumn.time:
        break; // handled above
    }
    if (_sortDirection == LogSortDirection.descending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  bool get expandedLogs => _expandedLogs;

  set expandedLogs(bool value) {
    if (_expandedLogs == value) return;
    _expandedLogs = value;
    notifyListeners();
  }

  void toggleExpandedLogs() {
    _expandedLogs = !_expandedLogs;
    notifyListeners();
  }

  bool get isLogOrderReversed => _isLogOrderReversed;

  // --- HTTP transaction grouping ---
  bool get groupHttpLogs => _groupHttpLogs;

  void toggleGroupHttpLogs() {
    _groupHttpLogs = !_groupHttpLogs;
    notifyListeners();
  }

  void toggleLogOrder() {
    _isLogOrderReversed = !_isLogOrderReversed;
    notifyListeners();
  }

  // Debounced search to reduce churn while typing
  void updateFilterSearchQuery(String query) =>
      _filterManager.updateFilterSearchQuery(query);

  void addFilterType(Type type) => _filterManager.addFilterType(type);

  void removeFilterType(Type type) => _filterManager.removeFilterType(type);

  void addFilterTitle(String title) => _filterManager.addFilterTitle(title);

  void removeFilterTitle(String title) =>
      _filterManager.removeFilterTitle(title);

  void setOnlyTitle(String title) => _filterManager.setOnlyTitle(title);

  void excludeTitle(String title, List<String> allTitles) =>
      _filterManager.excludeTitle(title, allTitles);

  void clearAllFilters() => _filterManager.clearAllFilters();

  Future<void> downloadLogsFile(String logs) async =>
      _exportService.downloadLogsFile(logs);

  void update() => notifyListeners();

  List<ISpectLogData> applyCurrentFilters(List<ISpectLogData> logsData) =>
      _filterManager.applyCurrentFilters(logsData);

  void onDataChanged() => _filterManager.onDataChanged();

  /// Generation counter for the filtered output, incremented on both
  /// data and filter changes. Used to invalidate grouped-transaction cache.
  int get outputGeneration => _filterManager.outputGeneration;

  // Single-pass unique title extraction with simple length-based cache
  TitlesResult getTitles(List<ISpectLogData> logsData) =>
      _filterManager.getTitles(logsData);

  void handleLogItemTap(ISpectLogData logEntry) {
    activeData = activeData == logEntry ? null : logEntry;
  }

  void handleTitleFilterToggle(String title, {required bool isSelected}) =>
      _filterManager.handleTitleFilterToggle(title, isSelected: isSelected);

  ({ISpectLogData entry, int actualIndex})? getLogEntryAtIndex(
    List<ISpectLogData> filteredEntries,
    int index,
  ) {
    final actualIndex =
        isLogOrderReversed ? filteredEntries.length - 1 - index : index;
    if (actualIndex < 0 || actualIndex >= filteredEntries.length) {
      return null;
    }
    return (
      entry: filteredEntries[actualIndex],
      actualIndex: actualIndex,
    );
  }

  void copyLogEntryText(
    BuildContext context,
    ISpectLogData logEntry,
    void Function(BuildContext, {required String value}) copyClipboard,
  ) {
    final text = logEntry.toJson(truncated: true).toString();
    copyClipboard(context, value: text);
  }

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

  // --- Search mode ---

  SearchMode get searchMode => _searchMode;

  /// Ordered list of matched log IDs.
  List<int> get searchMatchIds => _searchMatchIds;

  /// Set of matched log IDs for O(1) lookup.
  Set<int> get searchMatchIdSet => _searchMatchIdSet;

  int get focusedMatchIndex => _focusedMatchIndex;

  /// 1-based position of the focused match for display (e.g. "3/12").
  int get focusedMatchPosition =>
      _focusedMatchIndex >= 0 ? _focusedMatchIndex + 1 : 0;

  int get searchMatchCount => _searchMatchIds.length;

  bool get hasSearchMatches => _searchMatchIds.isNotEmpty;

  /// The ID of the currently focused search match, or -1.
  int get focusedMatchId {
    if (_focusedMatchIndex < 0 ||
        _focusedMatchIndex >= _searchMatchIds.length) {
      return -1;
    }
    return _searchMatchIds[_focusedMatchIndex];
  }

  set searchMode(SearchMode mode) {
    if (_searchMode == mode) return;
    _searchMode = mode;
    _searchMatchIds = const [];
    _searchMatchIdSet = const {};
    _focusedMatchIndex = -1;
    notifyListeners();
  }

  /// Updates the search matches by log IDs.
  ///
  /// Only resets the focused index when matches actually change.
  void updateSearchMatches(List<ISpectLogData> matches) {
    final newIds = matches.map((e) => e.id).toList();
    if (_searchMatchIds.length == newIds.length && _idsEqual(newIds)) {
      return;
    }
    _searchMatchIds = newIds;
    _searchMatchIdSet = newIds.toSet();
    if (newIds.isEmpty) {
      _focusedMatchIndex = -1;
    } else if (_focusedMatchIndex < 0 || _focusedMatchIndex >= newIds.length) {
      _focusedMatchIndex = 0;
    }
  }

  bool _idsEqual(List<int> other) {
    for (var i = 0; i < _searchMatchIds.length; i++) {
      if (_searchMatchIds[i] != other[i]) return false;
    }
    return true;
  }

  void focusNextMatch() {
    if (_searchMatchIds.isEmpty) return;
    _focusedMatchIndex = (_focusedMatchIndex + 1) % _searchMatchIds.length;
    notifyListeners();
  }

  void focusPreviousMatch() {
    if (_searchMatchIds.isEmpty) return;
    _focusedMatchIndex = (_focusedMatchIndex - 1 + _searchMatchIds.length) %
        _searchMatchIds.length;
    notifyListeners();
  }

  /// Applies title/type filters only (no search query filtering).
  List<ISpectLogData> applyFiltersWithoutSearch(
    List<ISpectLogData> logsData,
  ) =>
      _filterManager.applyFiltersWithoutSearch(logsData);

  /// Finds log entries matching the current search query.
  List<ISpectLogData> findSearchMatches(List<ISpectLogData> logsData) =>
      _filterManager.findSearchMatches(logsData);

  void clearLogsHistory(VoidCallback clearHistory) {
    clearHistory();
    update();
  }

  Future<void> shareLogsAsFile(
    List<ISpectLogData> logs, {
    String fileType = 'json',
  }) async {
    final filteredLogs = applyCurrentFilters(logs);
    await _exportService.shareFilteredLogsAsFile(
      logs,
      filteredLogs,
      filter,
      fileType: fileType,
    );
  }

  Future<void> shareAllLogsAsJsonFile(List<ISpectLogData> logs) async =>
      _exportService.shareAllLogsAsJsonFile(logs);

  Future<List<ISpectLogData>> importLogsFromJson(String jsonContent) async =>
      _importService.importLogsFromJson(jsonContent);

  bool validateLogsJsonContent(String jsonContent) =>
      _importService.validateLogsJsonContent(jsonContent);

  @override
  void dispose() {
    _filterManager.dispose();
    super.dispose();
  }
}
