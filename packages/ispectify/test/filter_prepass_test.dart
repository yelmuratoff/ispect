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
  group('excluded log keys', () {
    late _CountingRedactionService service;
    late ISpectLogger logger;

    setUp(() {
      ISpectRedaction.reset();
      service = _CountingRedactionService();
      ISpectRedaction.configure(service: service);
      logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        filter: ISpectFilter(excludedLogTypeKeys: const {'noisy'}),
      );
    });

    tearDown(() {
      logger.dispose();
      ISpectRedaction.reset();
    });

    test('skip capture and redaction entirely', () {
      logger.logData(ISpectLogData('drop me', key: 'noisy'));

      expect(logger.history, isEmpty);
      expect(service.exportCalls, 0);
    });

    test('still let other keys through the redacted path', () {
      logger.logData(ISpectLogData('keep me', key: 'kept'));

      expect(logger.history.single.message, 'keep me');
      expect(service.exportCalls, greaterThan(0));
    });
  });

  test('a filter without exclusions runs on the redacted entry', () {
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
      filter: ISpectFilter(logTypeKeys: const ['kept']),
    );
    addTearDown(logger.dispose);

    logger
      ..logData(ISpectLogData('a', key: 'kept'))
      ..logData(ISpectLogData('b', key: 'other'));

    expect(logger.history.map((e) => e.message), ['a']);
  });
}
