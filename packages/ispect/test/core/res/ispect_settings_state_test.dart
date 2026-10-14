import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  const defaults = ISpectSettingsState(
    enabled: true,
    useConsoleLogs: true,
    useHistory: true,
  );

  test('round-trips custom diagnostic policies', () {
    final settings = defaults.copyWith(
      captureMode: DiagnosticCaptureMode.strict,
      resourceLimits: DiagnosticResourceLimits.balanced.copyWith(
        maxCapturedValueBytes: 512 * 1024,
        maxLogRecordBytes: 2 * 1024 * 1024,
      ),
      processingPolicy: DiagnosticProcessingPolicy.balanced.copyWith(
        importChunkSize: 40,
        searchDebounce: const Duration(milliseconds: 175),
      ),
    );

    final restored = ISpectSettingsState.fromJson(settings.toJson());

    expect(restored, settings);
    expect(restored.hashCode, settings.hashCode);
    expect(restored.captureMode, DiagnosticCaptureMode.strict);
  });

  test('old settings snapshots restore balanced diagnostic policies', () {
    final restored = ISpectSettingsState.fromMap(const {
      'enabled': true,
      'use_console_logs': true,
      'use_history': true,
    });

    expect(restored.resourceLimits, DiagnosticResourceLimits.balanced);
    expect(restored.processingPolicy, DiagnosticProcessingPolicy.balanced);
    expect(restored.captureMode, DiagnosticCaptureMode.balanced);
  });

  test('old settings snapshots restore constructor defaults', () {
    final restored = ISpectSettingsState.fromMap(const {
      'enabled': true,
      'use_console_logs': true,
      'use_history': true,
    });

    expect(restored, defaults);
  });

  test('missing logger toggles fall back to the logger defaults', () {
    final restored = ISpectSettingsState.fromMap(const {'expanded_logs': true});
    final loggerDefaults = ISpectLoggerOptions();

    expect(restored.enabled, loggerDefaults.enabled);
    expect(restored.useHistory, loggerDefaults.useHistory);
    expect(restored.useConsoleLogs, loggerDefaults.useConsoleLogs);
  });

  test('explicit false logger toggles survive restoration', () {
    final restored = ISpectSettingsState.fromMap(const {
      'enabled': false,
      'use_console_logs': false,
      'use_history': false,
    });

    expect(restored.enabled, isFalse);
    expect(restored.useConsoleLogs, isFalse);
    expect(restored.useHistory, isFalse);
  });

  test('rejects negative persisted capacities at runtime', () {
    expect(
      () => ISpectSettingsState.fromMap(const {
        'enabled': true,
        'use_console_logs': true,
        'use_history': true,
        'max_history_items': -1,
      }),
      throwsArgumentError,
    );
    expect(
      () => ISpectSettingsState.fromMap(const {
        'enabled': true,
        'use_console_logs': true,
        'use_history': true,
        'log_truncate_length': -1,
      }),
      throwsArgumentError,
    );
  });

  test('equal share requests with distinct path lists share a hashCode', () {
    const paths = ['a.txt', 'b.txt'];
    final a = ISpectShareRequest(subject: 's', filePaths: List.of(paths));
    final b = ISpectShareRequest(subject: 's', filePaths: List.of(paths));

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
