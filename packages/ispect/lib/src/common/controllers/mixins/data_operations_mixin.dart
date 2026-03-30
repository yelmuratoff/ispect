import 'package:flutter/widgets.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/services/log_export_service.dart';
import 'package:ispect/src/common/services/log_import_service.dart';
import 'package:ispectify/ispectify.dart';

/// Manages log export, import, clipboard, and clear operations.
mixin DataOperationsMixin on ChangeNotifier {
  LogExportService get exportService;
  LogImportService get importService;
  ISpectFilter get filter;
  List<ISpectLogData> applyCurrentFilters(List<ISpectLogData> logsData);

  Future<void> downloadLogsFile(String logs) async =>
      exportService.downloadLogsFile(logs);

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
    notifyListeners();
  }

  Future<void> shareLogsAsFile(
    List<ISpectLogData> logs, {
    String fileType = 'json',
    Set<String>? redactKeys,
  }) async {
    final filteredLogs = applyCurrentFilters(logs);
    await exportService.shareFilteredLogsAsFile(
      logs,
      filteredLogs,
      filter,
      fileType: fileType,
      redactKeys: redactKeys,
    );
  }

  Future<void> shareAllLogsAsJsonFile(List<ISpectLogData> logs) async =>
      exportService.shareAllLogsAsJsonFile(logs);

  Future<List<ISpectLogData>> importLogsFromJson(String jsonContent) async =>
      importService.importLogsFromJson(jsonContent);

  bool validateLogsJsonContent(String jsonContent) =>
      importService.validateLogsJsonContent(jsonContent);
}
