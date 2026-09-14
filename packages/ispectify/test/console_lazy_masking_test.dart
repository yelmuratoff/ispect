import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _CountingRedactionService extends RedactionService {
  int exportCalls = 0;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    exportCalls++;
    return super.redactForExport(
      data,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
  }
}

void main() {
  late _CountingRedactionService service;

  setUp(() {
    ISpectRedaction.reset();
    service = _CountingRedactionService();
    ISpectRedaction.configure(service: service);
  });

  tearDown(ISpectRedaction.reset);

  test('rendering a console line does not mask the payload', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false, maxHistoryItems: 10),
    )..info(
        'checkout',
        additionalData: <String, dynamic>{'order': 'A-1001'},
      );
    addTearDown(logger.dispose);

    final entry = logger.history.single;
    service.exportCalls = 0;

    const HumanLogEntryFormatter().format(entry, ConsoleSettings());
    final afterRender = service.exportCalls;

    entry.additionalData;
    final afterPayloadRead = service.exportCalls;

    expect(afterPayloadRead, greaterThan(afterRender));
  });

  test('reading the payload twice masks it once', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false, maxHistoryItems: 10),
    )..info(
        'checkout',
        additionalData: <String, dynamic>{'order': 'A-1001'},
      );
    addTearDown(logger.dispose);

    final entry = logger.history.single..additionalData;
    final afterFirst = service.exportCalls;
    entry.additionalData;

    expect(service.exportCalls, afterFirst);
  });
}
