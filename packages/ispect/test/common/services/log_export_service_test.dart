import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/services/log_export_service.dart';

class _CapturingJsonService extends LogsJsonService {
  RedactionService? capturedRedactionService;
  bool capturedEnableRedaction = false;
  Set<String>? capturedRedactKeys;

  @override
  Future<void> shareLogsAsJsonFile(
    List<ISpectLogData> logs, {
    required ISpectShareCallback onShare,
    String fileName = 'ispect_logs',
    bool includeMetadata = true,
    RedactionService? redactionService,
    bool enableRedaction = true,
    ISpectMetadata? metadata,
  }) async {
    capturedRedactionService = redactionService;
    capturedEnableRedaction = enableRedaction;
  }

  @override
  Future<void> shareFilteredLogsAsJsonFile(
    List<ISpectLogData> logs,
    List<ISpectLogData> filteredLogs,
    ISpectFilter filter, {
    required ISpectShareCallback onShare,
    String fileName = 'ispect_filtered_logs',
    String fileType = 'json',
    RedactionService? redactionService,
    bool enableRedaction = true,
    Set<String>? redactKeys,
    ISpectMetadata? metadata,
  }) async {
    capturedEnableRedaction = enableRedaction;
    capturedRedactKeys = redactKeys;
  }
}

void main() {
  group('LogExportService.shareAllLogsAsJsonFile (L1)', () {
    test('redacts by default by supplying a redaction service', () async {
      final fake = _CapturingJsonService();
      final service = LogExportService(
        onShare: (_) async {},
        logsJsonService: fake,
      );

      await service.shareAllLogsAsJsonFile([ISpectLogData('entry')]);

      expect(fake.capturedRedactionService, isNotNull);
      expect(fake.capturedEnableRedaction, isTrue);
    });

    test('does not export when there are no logs', () async {
      final fake = _CapturingJsonService();
      final service = LogExportService(
        onShare: (_) async {},
        logsJsonService: fake,
      );

      await service.shareAllLogsAsJsonFile([]);

      expect(fake.capturedRedactionService, isNull);
    });
  });

  group('LogExportService.shareFilteredLogsAsFile (M8)', () {
    test('fails closed with default keys when redactKeys is null', () async {
      final fake = _CapturingJsonService();
      final service = LogExportService(
        onShare: (_) async {},
        logsJsonService: fake,
      );
      final logs = [ISpectLogData('entry')];

      await service.shareFilteredLogsAsFile(logs, logs, ISpectFilter());

      expect(fake.capturedEnableRedaction, isTrue);
      expect(fake.capturedRedactKeys, defaultSensitiveKeys);
    });
  });
}
