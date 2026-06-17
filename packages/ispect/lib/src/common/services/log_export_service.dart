import 'package:ispect/ispect.dart';

/// Service responsible for exporting/sharing logs.
class LogExportService {
  LogExportService({
    ISpectShareCallback? onShare,
    ISpectMetadataProvider? metadataProvider,
    LogsJsonService? logsJsonService,
  })  : _onShare = onShare,
        _metadataProvider = metadataProvider,
        _logsJsonService = logsJsonService ?? const LogsJsonService();

  final ISpectShareCallback? _onShare;
  final ISpectMetadataProvider? _metadataProvider;
  final LogsJsonService _logsJsonService;

  Future<void> shareLogsFile(String logs) async {
    final shareCallback = _ensureShareCallback();
    await LogsFileFactory.shareFile(logs, onShare: shareCallback);
  }

  Future<void> shareFilteredLogsAsFile(
    List<ISpectLogData> allLogs,
    List<ISpectLogData> filteredLogs,
    ISpectFilter filter, {
    String fileNamePrefix = 'ispect_logs_',
    String fileType = 'json',
    Set<String>? redactKeys,
  }) async {
    if (filteredLogs.isEmpty) {
      ISpect.logger.info('No logs match the active filters. Skipping export.');
      return;
    }

    final shareCallback = _ensureShareCallback();
    final metadata = await _metadataProvider?.call();
    await _logsJsonService.shareFilteredLogsAsJsonFile(
      allLogs,
      filteredLogs,
      filter,
      fileName: '$fileNamePrefix${DateTime.now().millisecondsSinceEpoch}',
      fileType: fileType,
      onShare: shareCallback,
      enableRedaction: redactKeys != null,
      redactKeys: redactKeys,
      metadata: metadata,
    );
  }

  Future<void> shareAllLogsAsJsonFile(List<ISpectLogData> logs) async {
    if (logs.isEmpty) {
      ISpect.logger.info('No logs to export. Skipping file creation.');
      return;
    }
    final shareCallback = _ensureShareCallback();
    final metadata = await _metadataProvider?.call();
    await _logsJsonService.shareLogsAsJsonFile(
      logs,
      fileName: 'ispect_all_logs_${DateTime.now().millisecondsSinceEpoch}',
      onShare: shareCallback,
      metadata: metadata,
    );
  }

  Future<String> saveFilteredLogsToDevice(
    List<ISpectLogData> allLogs,
    List<ISpectLogData> filteredLogs,
    ISpectFilter filter, {
    String fileNamePrefix = 'ispect_logs_',
    String fileType = 'json',
    Set<String>? redactKeys,
  }) async {
    if (filteredLogs.isEmpty) {
      ISpect.logger.info('No logs match the active filters. Skipping export.');
      return '';
    }

    final metadata = await _metadataProvider?.call();
    return _logsJsonService.saveFilteredLogsToDevice(
      allLogs,
      filteredLogs,
      filter,
      fileName: '$fileNamePrefix${DateTime.now().millisecondsSinceEpoch}',
      fileType: fileType,
      enableRedaction: redactKeys != null,
      redactKeys: redactKeys,
      metadata: metadata,
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
