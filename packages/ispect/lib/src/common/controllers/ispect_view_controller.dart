import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/managers/filter_manager.dart';
import 'package:ispect/src/common/managers/settings_manager.dart';
import 'package:ispect/src/common/services/log_export_service.dart';
import 'package:ispect/src/common/services/log_import_service.dart';

class ISpectViewController extends ChangeNotifier {
  ISpectViewController({
    ISpectShareCallback? onShare,
    ISpectSettingsState? initialSettings,
  })  : _exportService = LogExportService(onShare: onShare),
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
  ISpectLogData? _activeData;

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
  void updateFilterSearchQuery(String query) =>
      _filterManager.updateFilterSearchQuery(query);

  void addFilterType(Type type) => _filterManager.addFilterType(type);

  void removeFilterType(Type type) => _filterManager.removeFilterType(type);

  void addFilterTitle(String title) => _filterManager.addFilterTitle(title);

  void removeFilterTitle(String title) =>
      _filterManager.removeFilterTitle(title);

  Future<void> downloadLogsFile(String logs) async =>
      _exportService.downloadLogsFile(logs);

  void update() => notifyListeners();

  List<ISpectLogData> applyCurrentFilters(List<ISpectLogData> logsData) =>
      _filterManager.applyCurrentFilters(logsData);

  void onDataChanged() => _filterManager.onDataChanged();

  // Single-pass unique title extraction with simple length-based cache
  TitlesResult getTitles(List<ISpectLogData> logsData) =>
      _filterManager.getTitles(logsData);

  void handleLogItemTap(ISpectLogData logEntry) {
    activeData = activeData?.hashCode == logEntry.hashCode ? null : logEntry;
  }

  void handleTitleFilterToggle(String title, {required bool isSelected}) =>
      _filterManager.handleTitleFilterToggle(title, isSelected: isSelected);

  ({ISpectLogData entry, int actualIndex}) getLogEntryAtIndex(
    List<ISpectLogData> filteredEntries,
    int index,
  ) {
    final actualIndex =
        isLogOrderReversed ? filteredEntries.length - 1 - index : index;
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
