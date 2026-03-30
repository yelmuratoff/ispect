import 'package:flutter/foundation.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/mixins/data_operations_mixin.dart';
import 'package:ispect/src/common/controllers/mixins/display_toggles_mixin.dart';
import 'package:ispect/src/common/controllers/mixins/search_highlight_mixin.dart';
import 'package:ispect/src/common/controllers/mixins/selection_mixin.dart';
import 'package:ispect/src/common/controllers/mixins/sorting_mixin.dart';
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

class ISpectViewController extends ChangeNotifier
    with
        SelectionMixin,
        SearchHighlightMixin,
        SortingMixin,
        DisplayTogglesMixin,
        DataOperationsMixin {
  ISpectViewController({
    ISpectShareCallback? onShare,
    ISpectSettingsState? initialSettings,
    bool groupHttpLogs = true,
  })  : _exportService = LogExportService(onShare: onShare),
        _importService = const LogImportService() {
    initialGroupHttpLogs = groupHttpLogs;
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

  // --- Mixin dependencies ---

  @override
  FilterManager get filterManager => _filterManager;

  @override
  LogExportService get exportService => _exportService;

  @override
  LogImportService get importService => _importService;

  // --- Settings ---

  ISpectSettingsState get settings => _settingsManager.settings;

  void updateSettings(ISpectSettingsState newSettings) =>
      _settingsManager.updateSettings(newSettings);

  // --- Filter delegation ---

  @override
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

  void addFilterTitle(String title) => _filterManager.addFilterTitle(title);

  void removeFilterTitle(String title) =>
      _filterManager.removeFilterTitle(title);

  void setOnlyTitle(String title) => _filterManager.setOnlyTitle(title);

  void excludeTitle(String title, List<String> allTitles) =>
      _filterManager.excludeTitle(title, allTitles);

  void clearAllFilters() => _filterManager.clearAllFilters();

  @override
  List<ISpectLogData> applyCurrentFilters(List<ISpectLogData> logsData) {
    var result = _filterManager.applyCurrentFilters(logsData);
    if (errorsOnly) result = _applyErrorsOnly(result);
    return result;
  }

  List<ISpectLogData> applyFiltersWithoutSearch(
    List<ISpectLogData> logsData,
  ) {
    var result = _filterManager.applyFiltersWithoutSearch(logsData);
    if (errorsOnly) result = _applyErrorsOnly(result);
    return result;
  }

  static List<ISpectLogData> _applyErrorsOnly(List<ISpectLogData> logs) => logs
      .where(
        (log) =>
            ISpectLogType.isErrorKey(log.key) ||
            log.additionalData?[TraceKeys.success] == false,
      )
      .toList();

  void onDataChanged() => _filterManager.onDataChanged();

  int get outputGeneration => _filterManager.outputGeneration;

  TitlesResult getTitles(List<ISpectLogData> logsData) =>
      _filterManager.getTitles(logsData);

  void handleTitleFilterToggle(String title, {required bool isSelected}) =>
      _filterManager.handleTitleFilterToggle(title, isSelected: isSelected);

  // --- Lifecycle ---

  void update() => notifyListeners();

  @override
  void dispose() {
    disposeSearch();
    _filterManager.dispose();
    super.dispose();
  }
}
