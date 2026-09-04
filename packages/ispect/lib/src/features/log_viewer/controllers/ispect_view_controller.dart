import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/managers/filter_manager.dart';
import 'package:ispect/src/common/managers/settings_manager.dart';
import 'package:ispect/src/common/services/log_export_service.dart';
import 'package:ispect/src/common/services/log_import_service.dart';
import 'package:ispect/src/features/log_viewer/controllers/display_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/search_highlight_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/selection_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/sorting_controller.dart';

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

/// Facade over focused controllers, unified via [Listenable.merge].
///
/// Each domain concern lives in its own [ChangeNotifier]:
/// - [SelectionController] — active/detail log selection
/// - [SearchHighlightController] — search match state and navigation
/// - [SortingController] — column sort state
/// - [DisplayController] — expand/collapse, order, grouping, timestamps
///
/// Consumers that need all updates use the facade directly as a [Listenable].
/// Consumers that care about a single concern can listen to the specific
/// sub-controller via [selection], [search], [sorting], or [display].
class ISpectViewController implements Listenable {
  ISpectViewController({
    ISpectShareCallback? onShare,
    ISpectMetadataProvider? metadataProvider,
    ISpectSettingsState? initialSettings,
    ISpectSettingsChangedCallback? onSettingsChanged,
    bool groupHttpLogs = true,
    DiagnosticResourceLimits? resourceLimits,
    DiagnosticProcessingPolicy? processingPolicy,
  }) {
    _onShare = onShare;
    _metadataProvider = metadataProvider;
    final resolvedResourceLimits =
        resourceLimits ??
        initialSettings?.resourceLimits ??
        ISpect.loggerIfInitialized?.options.resourceLimits ??
        DiagnosticResourceLimits.balanced;
    final resolvedProcessingPolicy =
        processingPolicy ??
        initialSettings?.processingPolicy ??
        ISpect.loggerIfInitialized?.options.processingPolicy ??
        DiagnosticProcessingPolicy.balanced;
    resolvedResourceLimits.validate();
    resolvedProcessingPolicy.validate();
    _resourceLimits = resolvedResourceLimits;
    _processingPolicy = resolvedProcessingPolicy;
    _rebuildLogServices();

    _display = DisplayController(initialSettings: initialSettings);
    if (initialSettings == null) {
      _display.setInitialGroupHttpLogs(value: groupHttpLogs);
    }

    _filterManager = FilterManager(
      initialFilter: ISpectFilter(resourceLimits: resolvedResourceLimits),
      excludedLogTypeKeys:
          initialSettings?.disabledLogTypes ?? const <String>{},
      resourceLimits: resolvedResourceLimits,
      processingPolicy: resolvedProcessingPolicy,
      onChanged: _onSubNotify,
    );
    _settingsManager = SettingsManager(
      initialSettings: initialSettings,
      onChanged: _onSubNotify,
      onUserSettingsChanged: onSettingsChanged,
    );

    _selection = SelectionController();
    _search = SearchHighlightController(filterManager: _filterManager);
    _sorting = SortingController(
      isLogOrderReversed: () => _display.isLogOrderReversed,
    );

    // Mirror display toggles back into settings so action-chip flips reach
    // `onSettingsChanged`. Equality guards in `SettingsManager` and
    // `DisplayController` prevent the bidirectional sync from looping.
    _display.addListener(_syncDisplayToSettings);

    _merged = Listenable.merge([
      _selection,
      _search,
      _sorting,
      _display,
      _pipelineNotifier,
    ]);
  }

  void _syncDisplayToSettings() {
    final current = _settingsManager.settings;
    final next = current.copyWith(
      expandedLogs: _display.expandedLogs,
      isLogOrderReversed: _display.isLogOrderReversed,
      groupHttpLogs: _display.groupHttpLogs,
      useRelativeTime: _display.useRelativeTime,
      compactNetworkUrls: _display.compactNetworkUrls,
    );
    if (next != current) {
      _settingsManager.updateSettings(next);
    }
  }

  // --- Sub-controllers (exposed for targeted listening) ---

  late final SelectionController _selection;
  late final SearchHighlightController _search;
  late final SortingController _sorting;
  late final DisplayController _display;

  /// Active/detail log selection.
  SelectionController get selection => _selection;

  /// Search match state and navigation.
  SearchHighlightController get search => _search;

  /// Column sort state.
  SortingController get sorting => _sorting;

  /// Display toggles (expand, order, grouping, timestamps).
  DisplayController get display => _display;

  // --- Internal dependencies ---

  late final FilterManager _filterManager;
  late final SettingsManager _settingsManager;
  late DiagnosticResourceLimits _resourceLimits;
  late DiagnosticProcessingPolicy _processingPolicy;
  late LogExportService _exportService;
  late LogImportService _importService;
  late final ISpectShareCallback? _onShare;
  late final ISpectMetadataProvider? _metadataProvider;

  DiagnosticResourceLimits get resourceLimits => _resourceLimits;
  DiagnosticProcessingPolicy get processingPolicy => _processingPolicy;

  void _rebuildLogServices() {
    final logsJsonService = LogsJsonService(
      resourceLimits: _resourceLimits,
      processingPolicy: _processingPolicy,
    );
    _exportService = LogExportService(
      onShare: _onShare,
      metadataProvider: _metadataProvider,
      logsJsonService: logsJsonService,
    );
    _importService = LogImportService(logsJsonService: logsJsonService);
  }

  /// Notifier for filter/settings pipeline changes (no own state).
  final _pipelineNotifier = _SignalNotifier();
  late final Listenable _merged;

  void _onSubNotify() => _pipelineNotifier.notify();

  // --- Listenable (merged) ---

  @override
  void addListener(VoidCallback listener) => _merged.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _merged.removeListener(listener);

  // --- Selection delegation ---

  ISpectLogData? get activeData => _selection.activeData;
  set activeData(ISpectLogData? data) => _selection.activeData = data;

  ISpectLogData? get detailData => _selection.detailData;
  set detailData(ISpectLogData? data) => _selection.detailData = data;

  void selectLog(ISpectLogData entry) => _selection.selectLog(entry);

  void openLogDetail(ISpectLogData entry) => _selection.openLogDetail(entry);

  void selectAndFollowDetail(ISpectLogData entry) =>
      _selection.selectAndFollowDetail(entry);

  void closeDetail() => _selection.closeDetail();

  void handleLogItemTap(ISpectLogData logEntry) =>
      _selection.handleLogItemTap(logEntry);

  // --- Search delegation ---

  TextEditingController get searchController => _search.searchController;
  SearchMode get searchMode => _search.searchMode;
  set searchMode(SearchMode mode) => _search.searchMode = mode;

  List<String> get searchMatchIds => _search.searchMatchIds;
  Set<String> get searchMatchIdSet => _search.searchMatchIdSet;
  int get focusedMatchIndex => _search.focusedMatchIndex;
  int get focusedMatchPosition => _search.focusedMatchPosition;
  int get searchMatchCount => _search.searchMatchCount;
  bool get hasSearchMatches => _search.hasSearchMatches;
  String? get focusedMatchId => _search.focusedMatchId;

  void updateSearchMatches(List<ISpectLogData> matches) =>
      _search.updateSearchMatches(matches);

  SearchMatchState matchStateFor(ISpectLogData logEntry) =>
      _search.matchStateFor(logEntry);

  SearchMatchState matchStateForTransaction(NetworkTransaction tx) =>
      _search.matchStateForTransaction(tx);

  void focusNextMatch() => _search.focusNextMatch();
  void focusPreviousMatch() => _search.focusPreviousMatch();

  List<ISpectLogData> findSearchMatches(List<ISpectLogData> logsData) =>
      _search.findSearchMatches(logsData);

  // --- Sorting delegation ---

  LogSortColumn get sortColumn => _sorting.sortColumn;
  LogSortDirection get sortDirection => _sorting.sortDirection;
  bool get isLogOrderReversed => _display.isLogOrderReversed;

  void toggleSort(LogSortColumn column) => _sorting.toggleSort(column);

  List<ISpectLogData> applySorting(List<ISpectLogData> entries) =>
      _sorting.applySorting(entries);

  ({ISpectLogData entry, int actualIndex})? getLogEntryAtIndex(
    List<ISpectLogData> filteredEntries,
    int index,
  ) => _sorting.getLogEntryAtIndex(filteredEntries, index);

  // --- Display delegation ---

  bool get expandedLogs => _display.expandedLogs;
  set expandedLogs(bool value) => _display.expandedLogs = value;

  void toggleExpandedLogs() => _display.toggleExpandedLogs();
  void toggleLogOrder() => _display.toggleLogOrder();

  bool get groupHttpLogs => _display.groupHttpLogs;
  void toggleGroupHttpLogs() => _display.toggleGroupHttpLogs();

  bool get useRelativeTime => _display.useRelativeTime;
  void toggleTimestampFormat() => _display.toggleTimestampFormat();

  bool get compactNetworkUrls => _display.compactNetworkUrls;
  void toggleCompactNetworkUrls() => _display.toggleCompactNetworkUrls();

  // --- Settings ---

  ISpectSettingsState get settings => _settingsManager.settings;

  void updateSettings(ISpectSettingsState newSettings) {
    _updateDiagnosticPolicies(
      newSettings.resourceLimits,
      newSettings.processingPolicy,
    );
    if (!setEquals(settings.disabledLogTypes, newSettings.disabledLogTypes)) {
      _filterManager.updateExcludedLogTypeKeys(newSettings.disabledLogTypes);
      _cachedLevelStats = null;
    }
    _settingsManager.updateSettings(newSettings);
    _display.applyFromSettings(newSettings);
  }

  void _updateDiagnosticPolicies(
    DiagnosticResourceLimits resourceLimits,
    DiagnosticProcessingPolicy processingPolicy,
  ) {
    resourceLimits.validate();
    processingPolicy.validate();
    if (_resourceLimits == resourceLimits &&
        _processingPolicy == processingPolicy) {
      return;
    }
    _resourceLimits = resourceLimits;
    _processingPolicy = processingPolicy;
    _rebuildLogServices();
    _filterManager.updatePolicies(resourceLimits, processingPolicy);
  }

  // --- Filter delegation ---

  ISpectFilter get filter => _filterManager.filter;
  set filter(ISpectFilter val) => _filterManager.filter = val;

  void updateFilterSearchQuery(String query) =>
      _filterManager.updateFilterSearchQuery(query);

  void searchByCorrelationId(String id) {
    searchController.text = id;
    _filterManager.updateFilterSearchQuery(id, immediate: true);
  }

  void addFilterType(Type type) => _filterManager.addFilterType(type);
  void removeFilterType(Type type) => _filterManager.removeFilterType(type);

  void addLogTypeKeyFilter(String key) =>
      _filterManager.addLogTypeKeyFilter(key);

  void removeLogTypeKeyFilter(String key) =>
      _filterManager.removeLogTypeKeyFilter(key);

  void setOnlyLogTypeKey(String key) => _filterManager.setOnlyLogTypeKey(key);

  void excludeLogTypeKey(String key, List<String> allKeys) =>
      _filterManager.excludeLogTypeKey(key, allKeys);

  void clearAllFilters() => _filterManager.clearAllFilters();

  List<ISpectLogData> applyCurrentFilters(List<ISpectLogData> logsData) =>
      _filterManager.applyCurrentFilters(logsData);

  List<ISpectLogData> applyFiltersWithoutSearch(List<ISpectLogData> logsData) =>
      _filterManager.applyFiltersWithoutSearch(logsData);

  void onDataChanged() => _filterManager.onDataChanged();

  int get outputGeneration => _filterManager.outputGeneration;

  LogTypeKeysResult getLogTypeKeys(List<ISpectLogData> logsData) =>
      _filterManager.getLogTypeKeys(logsData);

  /// Returns counts of `error`/`critical` and `warning` entries in [logsData].
  ({int errors, int warnings}) getLevelStats(List<ISpectLogData> logsData) {
    final cached = _cachedLevelStats;
    final previous = _cachedLevelStatsInput;
    if (cached != null &&
        identical(previous, logsData) &&
        _cachedLevelStatsLength == logsData.length) {
      return cached;
    }

    var errors = 0;
    var warnings = 0;
    var start = 0;
    if (cached != null &&
        previous != null &&
        _isAppendOnlyExtension(previous, logsData)) {
      errors = cached.errors;
      warnings = cached.warnings;
      start = previous.length;
    }
    for (var index = start; index < logsData.length; index++) {
      final captured = captureISpectLogWithoutPayload(logsData[index]);
      if (_filterManager.isExcluded(captured.key)) continue;
      final level = captured.logLevel;
      if (level == LogLevel.error || level == LogLevel.critical) {
        errors++;
      } else if (level == LogLevel.warning) {
        warnings++;
      }
    }
    final result = (errors: errors, warnings: warnings);
    _cachedLevelStats = result;
    _cachedLevelStatsInput = logsData;
    _cachedLevelStatsLength = logsData.length;
    return result;
  }

  static bool _isAppendOnlyExtension(
    List<ISpectLogData> previous,
    List<ISpectLogData> current,
  ) {
    if (previous.isEmpty || current.length < previous.length) return false;
    return identical(previous.first, current.first) &&
        identical(previous.last, current[previous.length - 1]);
  }

  ({int errors, int warnings})? _cachedLevelStats;
  List<ISpectLogData>? _cachedLevelStatsInput;
  int _cachedLevelStatsLength = -1;

  void handleLogTypeKeyFilterToggle(String key, {required bool isSelected}) =>
      _filterManager.handleLogTypeKeyFilterToggle(key, isSelected: isSelected);

  // --- Data operations (stateless delegation) ---

  Future<void> shareLogsFile(String logs) async =>
      _exportService.shareLogsFile(logs);

  void copyLogEntryText(
    BuildContext context,
    ISpectLogData logEntry,
    void Function(BuildContext, {required String value}) copyClipboard,
  ) {
    copyClipboard(
      context,
      value: LogExporter.toJsonLines(
        [logEntry],
        maxLogs: 1,
        resourceLimits: _resourceLimits,
      ),
    );
  }

  void copyAllLogsToClipboard(
    BuildContext context,
    List<ISpectLogData> logs,
    void Function(
      BuildContext, {
      required String value,
      String? title,
      bool? showValue,
    })
    copyClipboard,
    String title,
  ) {
    copyClipboard(
      context,
      value: LogExporter.toJsonLines(logs, resourceLimits: _resourceLimits),
      title: title,
      showValue: false,
    );
  }

  void clearLogsHistory(VoidCallback clearHistory) {
    clearHistory();
    _pipelineNotifier.notify();
  }

  Future<String> downloadLogsToDevice(
    List<ISpectLogData> logs, {
    String fileType = 'json',
    Set<String>? redactKeys,
  }) async {
    final filteredLogs = applyCurrentFilters(logs);
    return _exportService.saveFilteredLogsToDevice(
      logs,
      filteredLogs,
      filter,
      fileType: fileType,
      redactKeys: redactKeys,
    );
  }

  Future<void> shareLogsAsFile(
    List<ISpectLogData> logs, {
    String fileType = 'json',
    Set<String>? redactKeys,
  }) async {
    final filteredLogs = applyCurrentFilters(logs);
    await _exportService.shareFilteredLogsAsFile(
      logs,
      filteredLogs,
      filter,
      fileType: fileType,
      redactKeys: redactKeys,
    );
  }

  Future<void> shareAllLogsAsJsonFile(List<ISpectLogData> logs) async =>
      _exportService.shareAllLogsAsJsonFile(logs);

  Future<List<ISpectLogData>> importLogsFromJson(String jsonContent) async =>
      _importService.importLogsFromJson(jsonContent);

  Future<LogsImportResult> importLogsFromJsonWithReport(
    String jsonContent,
  ) async => _importService.importLogsFromJsonWithReport(jsonContent);

  bool validateLogsJsonContent(String jsonContent) =>
      _importService.validateLogsJsonContent(jsonContent);

  // --- Lifecycle ---

  void update() => _pipelineNotifier.notify();

  void dispose() {
    _display.removeListener(_syncDisplayToSettings);
    _search.dispose();
    _selection.dispose();
    _sorting.dispose();
    _display.dispose();
    _pipelineNotifier.dispose();
    _filterManager.dispose();
  }
}

/// Lightweight notifier for pipeline events (filter/settings changes).
class _SignalNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
