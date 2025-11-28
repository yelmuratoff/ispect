import 'package:ispect/ispect.dart';

/// Service responsible for exporting/sharing logs.
class LogExportService {
  LogExportService({
    ISpectShareCallback? onShare,
    LogsJsonService? logsJsonService,
  })  : _onShare = onShare,
        _logsJsonService = logsJsonService ?? const LogsJsonService();

  final ISpectShareCallback? _onShare;
  final LogsJsonService _logsJsonService;

  Future<void> downloadLogsFile(String logs) async {
    final shareCallback = _ensureShareCallback();
    await LogsFileFactory.downloadFile(logs, onShare: shareCallback);
  }

  Future<void> shareFilteredLogsAsFile(
    List<ISpectLogData> allLogs,
    List<ISpectLogData> filteredLogs,
    ISpectFilter filter, {
    String fileNamePrefix = 'ispect_logs_',
    String fileType = 'json',
  }) async {
    if (filteredLogs.isEmpty) {
      ISpect.logger.info('No logs match the active filters. Skipping export.');
      return;
    }

    final shareCallback = _ensureShareCallback();
    await _logsJsonService.shareFilteredLogsAsJsonFile(
      allLogs,
      filteredLogs,
      filter,
      fileName: '$fileNamePrefix${DateTime.now().millisecondsSinceEpoch}',
      fileType: fileType,
      onShare: shareCallback,
    );
  }

  Future<void> shareAllLogsAsJsonFile(List<ISpectLogData> logs) async {
    if (logs.isEmpty) {
      ISpect.logger.info('No logs to export. Skipping file creation.');
      return;
    }
    final shareCallback = _ensureShareCallback();
    await _logsJsonService.shareLogsAsJsonFile(
      logs,
      fileName: 'ispect_all_logs_${DateTime.now().millisecondsSinceEpoch}',
      onShare: shareCallback,
    );
  }

  ISpectShareCallback _ensureShareCallback() {
    final shareCallback = _onShare;
    if (shareCallback == null) {
      throw StateError(
        'Share callback is not configured. Provide onShare when constructing ISpectBuilder.',
      );
    }
    return shareCallback;
  }
}
