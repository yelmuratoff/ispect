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

  void addLogTypeKeyFilter(String key) =>
      _filterManager.addLogTypeKeyFilter(key);

  void removeLogTypeKeyFilter(String key) =>
      _filterManager.removeLogTypeKeyFilter(key);

  void setOnlyLogTypeKey(String key) => _filterManager.setOnlyLogTypeKey(key);

  void excludeLogTypeKey(String key, List<String> allKeys) =>
      _filterManager.excludeLogTypeKey(key, allKeys);

  void clearAllFilters() => _filterManager.clearAllFilters();

  // Errors-only cache to avoid re-filtering on every rebuild.
  List<ISpectLogData>? _errorsOnlyCache;
  int _errorsOnlyCacheGen = -1;
  bool _errorsOnlyCacheWithSearch = false;

  @override
  List<ISpectLogData> applyCurrentFilters(List<ISpectLogData> logsData) {
    final result = _filterManager.applyCurrentFilters(logsData);
    if (!errorsOnly) return result;
    return _getCachedErrorsOnly(result, withSearch: true);
  }

  List<ISpectLogData> applyFiltersWithoutSearch(
    List<ISpectLogData> logsData,
  ) {
    final result = _filterManager.applyFiltersWithoutSearch(logsData);
    if (!errorsOnly) return result;
    return _getCachedErrorsOnly(result, withSearch: false);
  }

  List<ISpectLogData> _getCachedErrorsOnly(
    List<ISpectLogData> source, {
    required bool withSearch,
  }) {
    final gen = outputGeneration;
    if (_errorsOnlyCacheGen == gen &&
        _errorsOnlyCacheWithSearch == withSearch &&
        _errorsOnlyCache != null) {
      return _errorsOnlyCache!;
    }
    _errorsOnlyCache =
        source.where((log) => log.isError).toList(growable: false);
    _errorsOnlyCacheGen = gen;
    _errorsOnlyCacheWithSearch = withSearch;
    return _errorsOnlyCache!;
  }

  void onDataChanged() => _filterManager.onDataChanged();

  int get outputGeneration => _filterManager.outputGeneration;

  LogTypeKeysResult getLogTypeKeys(List<ISpectLogData> logsData) =>
      _filterManager.getLogTypeKeys(logsData);

  void handleLogTypeKeyFilterToggle(String key, {required bool isSelected}) =>
      _filterManager.handleLogTypeKeyFilterToggle(key, isSelected: isSelected);

  // --- Lifecycle ---

  void update() => notifyListeners();

  @override
  void dispose() {
    disposeSearch();
    _filterManager.dispose();
    super.dispose();
  }
}
