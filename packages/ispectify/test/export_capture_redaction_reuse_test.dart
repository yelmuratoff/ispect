import 'dart:convert';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

ISpectLogger _logger() => ISpectLogger(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        maxHistoryItems: 100,
      ),
    );

Map<String, Object?> _firstRecord(String jsonLines) =>
    jsonDecode(jsonLines.split('\n').first) as Map<String, Object?>;

void main() {
  setUp(ISpectRedaction.reset);
  tearDown(ISpectRedaction.reset);

  group('text and markdown reuse capture redaction', () {
    test('still masks sensitive payload values', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{
            'password': 'hunter2-plaintext',
            'order': 'A-1001',
          },
        );
      addTearDown(logger.dispose);

      final text = LogExporter.toText(logger.history);
      final markdown = LogExporter.toMarkdown(logger.history);

      expect(text, isNot(contains('hunter2-plaintext')));
      expect(markdown, isNot(contains('hunter2-plaintext')));
      expect(text, contains('A-1001'));
    });

    test('still strips private render hints', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{
            '_render-hints': 'internal-only',
            'order': 'A-1001',
          },
        );
      addTearDown(logger.dispose);

      final text = LogExporter.toText(logger.history);
      final markdown = LogExporter.toMarkdown(logger.history);

      expect(text, isNot(contains('internal-only')));
      expect(text, isNot(contains('_render-hints')));
      expect(markdown, isNot(contains('internal-only')));
    });

    test('re-redacts when the caller supplies a different service', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{'order': 'A-1001'},
        );
      addTearDown(logger.dispose);

      final text = LogExporter.toText(
        logger.history,
        redactionService: RedactionService(sensitiveKeys: const {'order'}),
      );

      expect(text, isNot(contains('A-1001')));
    });
  });

  group('console header masks the fields it prints', () {
    test('scrubs an embedded credential in a trace scalar', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{
            TraceKeys.source: 'auth Bearer eyJhbGciOiJIUzI1NiJ9.secret',
          },
        );
      addTearDown(logger.dispose);

      final rendered = const HumanLogEntryFormatter()
          .format(logger.history.single, ConsoleSettings());

      expect(rendered, isNot(contains('eyJhbGciOiJIUzI1NiJ9.secret')));
    });

    test('keeps a non-sensitive trace scalar readable', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{TraceKeys.source: 'checkout-api'},
        );
      addTearDown(logger.dispose);

      final rendered = const HumanLogEntryFormatter()
          .format(logger.history.single, ConsoleSettings());

      expect(rendered, contains('checkout-api'));
    });
  });

  group('capture reuses an already bounded payload', () {
    test('rebuilding under the same limits keeps the bounded instance', () {
      final first = ISpectLogData(
        'checkout',
        additionalData: const <String, dynamic>{'order': 'A-1001'},
      );

      final second = ISpectLogData(
        'checkout',
        additionalData: first.additionalData,
      );

      expect(identical(second.additionalData, first.additionalData), isTrue);
    });

    test('rebuilding after the redaction toggle flips bounds again', () {
      final first = ISpectLogData(
        'checkout',
        additionalData: const <String, dynamic>{'order': 'A-1001'},
      );

      ISpectRedaction.enabled = false;
      final second = ISpectLogData(
        'checkout',
        additionalData: first.additionalData,
      );

      expect(identical(second.additionalData, first.additionalData), isFalse);
    });

    test('rebuilding under different limits bounds again', () {
      final first = ISpectLogData(
        'checkout',
        additionalData: const <String, dynamic>{'order': 'A-1001'},
      );

      final second = ISpectLogData(
        'checkout',
        additionalData: first.additionalData,
        resourceLimits: DiagnosticResourceLimits.constrained,
      );

      expect(identical(second.additionalData, first.additionalData), isFalse);
      expect(second.additionalData!['order'], 'A-1001');
    });
  });

  group('masking is deferred to the first read', () {
    test('history entries expose masked payloads to consumers', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{
            'password': 'hunter2-plaintext',
            'order': 'A-1001',
          },
        );
      addTearDown(logger.dispose);

      final data = logger.history.single.additionalData!;

      expect(data['password'], isNot('hunter2-plaintext'));
      expect(data['order'], 'A-1001');
    });

    test('masked payload stays unmodifiable', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{'order': 'A-1001'},
        );
      addTearDown(logger.dispose);

      expect(
        () => logger.history.single.additionalData!['injected'] = 'x',
        throwsUnsupportedError,
      );
    });

    test('repeated reads return the same masked instance', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{'order': 'A-1001'},
        );
      addTearDown(logger.dispose);

      final entry = logger.history.single;

      expect(identical(entry.additionalData, entry.additionalData), isTrue);
    });

    test('entries built by the application are returned as captured', () {
      final entry = ISpectLogData(
        'checkout',
        additionalData: const <String, dynamic>{'password': 'hunter2'},
      );

      expect(entry.additionalData!['password'], 'hunter2');
    });
  });

  group('export reuses capture-time redaction', () {
    test('masks sensitive values emitted through the logger', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{
            'password': 'hunter2-plaintext',
            'order': 'A-1001',
          },
        );
      addTearDown(logger.dispose);

      final exported = LogExporter.toJsonLines(logger.history);

      expect(exported, isNot(contains('hunter2-plaintext')));
      expect(exported, contains('A-1001'));
    });

    test('matches the output produced without the capture-time mark', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{
            'authorization': 'Bearer secret-token-value',
            'order': 'A-1001',
          },
        );
      addTearDown(logger.dispose);

      final captured = logger.history.single;
      final viaReuse = _firstRecord(LogExporter.toJsonLines([captured]));
      final viaFullPass = _firstRecord(
        LogExporter.toJsonLines([captured.copyWith()]),
      );

      expect(viaReuse['additional-data'], viaFullPass['additional-data']);
      expect(viaReuse['message'], viaFullPass['message']);
      expect(viaReuse['key'], viaFullPass['key']);
    });

    test('re-redacts when the caller supplies a different service', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{'order': 'A-1001'},
        );
      addTearDown(logger.dispose);

      final exported = LogExporter.toJsonLines(
        logger.history,
        redactionService: RedactionService(sensitiveKeys: const {'order'}),
      );

      expect(exported, isNot(contains('A-1001')));
    });

    test('re-redacts when the caller supplies different redact keys', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{'order': 'A-1001'},
        );
      addTearDown(logger.dispose);

      final exported = LogExporter.toJsonLines(
        logger.history,
        redactKeys: const {'order'},
      );

      expect(exported, isNot(contains('A-1001')));
    });

    test('re-redacts after the global policy is reconfigured', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{'order': 'A-1001'},
        );
      addTearDown(logger.dispose);

      ISpectRedaction.configure(
        service: RedactionService(additionalSensitiveKeys: const {'order'}),
      );
      final exported = LogExporter.toJsonLines(logger.history);

      expect(exported, isNot(contains('A-1001')));
    });

    test('re-redacts entries rebuilt from persisted JSON', () {
      final logger = _logger()
        ..info(
          'checkout',
          additionalData: <String, dynamic>{'order': 'A-1001'},
        );
      addTearDown(logger.dispose);

      final restored = ISpectLogData(
        logger.history.single.message,
        key: logger.history.single.key,
        additionalData: const <String, dynamic>{'order': 'A-1001'},
      );
      final exported = LogExporter.toJsonLines(
        <ISpectLogData>[restored],
        redactKeys: const {'order'},
      );

      expect(exported, isNot(contains('A-1001')));
    });
  });
}
