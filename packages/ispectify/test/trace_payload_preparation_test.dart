import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

const _failureTrigger = 'FAIL_REDACTION_SECRET';

final class _SelectivelyThrowingRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    if (data.toString().contains(_failureTrigger)) {
      throw StateError('redactor failed');
    }
    return super.redactForExport(
      data,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
  }
}

void main() {
  group('trace payload preparation', () {
    late ISpectLogger logger;

    setUp(() {
      ISpectRedaction.configure(service: _SelectivelyThrowingRedactor());
      logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
    });

    tearDown(ISpectRedaction.reset);

    test('a redaction failure in meta keeps the trace and drops the meta', () {
      logger.trace(
        category: dbCategory,
        source: 'sqlite',
        operation: 'query',
        meta: const {'note': _failureTrigger},
      );

      final entry = logger.history.single;
      expect(entry.key, ISpectLogType.dbQuery.key);
      expect(entry.additionalData?[TraceKeys.operation], 'query');
      expect(entry.additionalData, isNot(contains(TraceKeys.meta)));
      expect(entry.toJson().toString(), isNot(contains(_failureTrigger)));
    });

    test('a redaction failure in a value fails closed to the placeholder', () {
      logger.trace(
        category: dbCategory,
        source: 'sqlite',
        operation: 'query',
        value: _failureTrigger,
      );

      final entry = logger.history.single;
      expect(
        entry.additionalData?[TraceKeys.value],
        redactionFailedPlaceholder,
      );
    });

    test('redacts sensitive meta keys when redaction succeeds', () {
      logger.trace(
        category: dbCategory,
        source: 'sqlite',
        operation: 'query',
        meta: const {'password': 'hunter2'},
      );

      final meta = logger.history.single.additionalData?[TraceKeys.meta];
      expect(meta, isA<Map<String, Object?>>());
      expect((meta! as Map)['password'], isNot('hunter2'));
    });
  });

  group('StateTracePreparer', () {
    StateTracePreparer preparer({RedactionService? redactor}) =>
        StateTracePreparer(
          redactor: redactor,
          captureMode: DiagnosticCaptureMode.balanced,
          resourceLimits: DiagnosticResourceLimits.balanced,
        );

    test('prepareValue fails closed to the redaction-failed placeholder', () {
      final prepared = preparer(
        redactor: _SelectivelyThrowingRedactor(),
      ).prepareValue(const {'note': _failureTrigger});

      expect(prepared, redactionFailedPlaceholder);
    });

    test('prepareText surfaces the redaction-failed placeholder', () {
      final text = preparer(
        redactor: _SelectivelyThrowingRedactor(),
      ).prepareText(_failureTrigger);

      expect(text, redactionFailedPlaceholder);
    });

    test('prepareMeta collapses a failed redaction to an empty map', () {
      final meta = preparer(
        redactor: _SelectivelyThrowingRedactor(),
      ).prepareMeta(const {'note': _failureTrigger});

      expect(meta, isEmpty);
    });

    test('prepareValue passes bounded values through without a redactor', () {
      expect(
        preparer().prepareValue(const {'password': 'hunter2', 'count': 1}),
        {'password': 'hunter2', 'count': 1},
      );
    });

    test('prepareValue masks sensitive keys with an active redactor', () {
      final prepared = preparer(redactor: RedactionService())
          .prepareValue(const {'password': 'hunter2', 'count': 1});

      expect(prepared, isA<Map<String, Object?>>());
      final map = prepared! as Map;
      expect(map['password'], isNot('hunter2'));
      expect(map['count'], 1);
    });

    test('prepareAdditionalData returns an empty map on redaction failure', () {
      final prepared = StateTracePreparer.prepareAdditionalData(
        const {'note': _failureTrigger},
        enableRedaction: true,
        redactor: _SelectivelyThrowingRedactor(),
        captureMode: DiagnosticCaptureMode.balanced,
        resourceLimits: DiagnosticResourceLimits.balanced,
      );

      expect(prepared, isEmpty);
    });

    test('prepareAdditionalData keeps values unmasked when disabled', () {
      final prepared = StateTracePreparer.prepareAdditionalData(
        const {'password': 'hunter2'},
        enableRedaction: false,
        redactor: _SelectivelyThrowingRedactor(),
        captureMode: DiagnosticCaptureMode.balanced,
        resourceLimits: DiagnosticResourceLimits.balanced,
      );

      expect(prepared, {'password': 'hunter2'});
    });
  });
}
