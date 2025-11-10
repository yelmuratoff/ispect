import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/cache/filter_cache.dart';

typedef TitlesResult = ({List<String> all, List<String> unique});

class ISpectViewController extends ChangeNotifier {
  ISpectViewController({
    ISpectShareCallback? onShare,
    ISpectSettingsState? initialSettings,
  })  : _onShare = onShare,
        _settings = initialSettings ??
            const ISpectSettingsState(
              enabled: true,
              useConsoleLogs: true,
              useHistory: true,
            );

  ISpectFilter _filter = ISpectFilter();
  bool _expandedLogs = true;
  bool _isLogOrderReversed = true;
  ISpectLogData? _activeData;

  ISpectSettingsState _settings;

  final LogsJsonService _logsJsonService = const LogsJsonService();

  final ISpectShareCallback? _onShare;

  List<String>? _cachedTitles;
  Set<Type>? _cachedTypesSet; // Set for O(1) lookups
  String? _cachedSearchQuery;
  bool _filterCacheValid = false;

  // Generation-based cache for filtered results
  final _filterCache = FilterCache();
  int _dataGeneration = 0;

  List<String>? _cachedAllTitles;
  List<String>? _cachedUniqueTitles;
  int? _lastTitlesDataHash;

  Timer? _filterDebounce;

  ISpectSettingsState get settings => _settings;

  void updateSettings(ISpectSettingsState newSettings) {
    if (_settings == newSettings) return;
    _settings = newSettings;
    notifyListeners();
  }

  ISpectFilter get filter => _filter;

  set filter(ISpectFilter val) {
    if (_filter == val) return;
    _filter = val;
    _invalidateFilterCache();
    notifyListeners();
  }

  ISpectLogData? get activeData => _activeData;

  set activeData(ISpectLogData? data) {
    if (_activeData == data) return;
    _activeData = data;
    notifyListeners();
  }

  bool get expandedLogs => _expandedLogs;

  void toggleExpandedLogs() {
    _expandedLogs = !_expandedLogs;
    notifyListeners();
  }

  bool get isLogOrderReversed => _isLogOrderReversed;

  void toggleLogOrder() {
    _isLogOrderReversed = !_isLogOrderReversed;
    notifyListeners();
  }

  // Debounced search to reduce churn while typing
  void updateFilterSearchQuery(String query) {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 300), () {
      _filter = _filter.copyWith(searchQuery: query);
      _invalidateFilterCache();
      notifyListeners();
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

  Future<void> downloadLogsFile(String logs) async {
    final shareCallback = _ensureShareCallback();
    await LogsFileFactory.downloadFile(logs, onShare: shareCallback);
  }

  void update() => notifyListeners();

  List<String> _getCurrentTitles() {
    if (!_filterCacheValid || _cachedTitles == null) {
      // Directly access titles from ISpectFilter
      _cachedTitles = _filter.titles.toList(growable: false);
      _filterCacheValid = true;
    }
    return _cachedTitles!;
  }

  Set<Type> _getCurrentTypesSet() {
    if (!_filterCacheValid || _cachedTypesSet == null) {
      // Use the filter's exposed types set directly
      _cachedTypesSet = _filter.types.toSet();
      _filterCacheValid = true;
    }
    return _cachedTypesSet!;
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

  void _invalidateFilterCache() {
    _filterCacheValid = false;
    _cachedTitles = null;
    _cachedTypesSet = null;
    _cachedSearchQuery = null;
  }

  // Generation-based cache: O(1) hits, O(n) misses. Call onDataChanged when data updates.
  List<ISpectLogData> applyCurrentFilters(List<ISpectLogData> logsData) {
    if (logsData.isEmpty) return <ISpectLogData>[];
    return _filterCache.getFiltered(logsData, filter, _dataGeneration);
  }

  void onDataChanged() {
    _dataGeneration++;
    _filterCache.invalidate();
  }

  // Single-pass unique title extraction with simple length-based cache
  TitlesResult getTitles(List<ISpectLogData> logsData) {
    final currentLength = logsData.length;

    if (_lastTitlesDataHash == currentLength &&
        _cachedAllTitles != null &&
        _cachedUniqueTitles != null) {
      return (all: _cachedAllTitles!, unique: _cachedUniqueTitles!);
    }

    final uniqueTitlesSet = <String>{};
    for (final data in logsData) {
      final title = data.title;
      if (title != null) {
        uniqueTitlesSet.add(title);
      }
    }

    final uniqueTitles = uniqueTitlesSet.toList(growable: false);

    _cachedAllTitles = uniqueTitles;
    _cachedUniqueTitles = uniqueTitles;
    _lastTitlesDataHash = currentLength;

    return (all: uniqueTitles, unique: uniqueTitles);
  }

  void handleLogItemTap(ISpectLogData logEntry) {
    activeData = activeData?.hashCode == logEntry.hashCode ? null : logEntry;
  }

  void handleTitleFilterToggle(String title, {required bool isSelected}) {
    if (isSelected) {
      addFilterTitle(title);
    } else {
      removeFilterTitle(title);
    }
  }

  ISpectLogData getLogEntryAtIndex(
    List<ISpectLogData> filteredEntries,
    int index,
  ) {
    final actualIndex =
        isLogOrderReversed ? filteredEntries.length - 1 - index : index;
    return filteredEntries[actualIndex];
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

  void clearLogsHistory(VoidCallback clearHistory) {
    clearHistory();
    update();
  }

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

  Future<List<ISpectLogData>> importLogsFromJson(String jsonContent) async =>
      _logsJsonService.importFromJson(jsonContent);

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
