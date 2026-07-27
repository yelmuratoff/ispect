import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:test/test.dart';

final class _CountingRedactor extends RedactionService {
  _CountingRedactor(String key, String placeholder)
      : super(
          sensitiveKeys: {key},
          sensitiveKeyPatterns: const <RegExp>[],
          fullyMaskedKeys: {key},
          visibleEdgeLength: 0,
          placeholder: placeholder,
        );

  int calls = 0;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    calls++;
    return super.redactForExport(
      data,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
  }
}

WsDiagnostics _diagnostics(
  ISpectLogger logger, {
  RedactionService? redactor,
  String source = WsDiagnostics.defaultSource,
}) =>
    WsDiagnostics(
      logger: logger,
      settings: const ISpectWSInterceptorSettings(printSentData: true),
      redactor: redactor,
      source: source,
    );

String _latestMeta(ISpectLogger logger) =>
    logger.history.last.additionalData?[TraceKeys.meta].toString() ?? '';

void main() {
  group('WsDiagnostics redaction policy', () {
    setUp(ISpectRedaction.reset);
    tearDown(ISpectRedaction.reset);

    test('uses the globally configured redaction service', () {
      const secret = 'WS-GLOBAL-SECRET';
      final global = _CountingRedactor('tenantSecret', '[WS-GLOBAL]');
      ISpectRedaction.configure(service: global);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final diagnostics = _diagnostics(logger)
        ..onSent(<String, Object?>{'tenantSecret': secret});

      expect(diagnostics.redactor, same(global));
      expect(_latestMeta(logger), contains('[WS-GLOBAL]'));
      expect(_latestMeta(logger), isNot(contains(secret)));
    });

    test('sees global reconfiguration after construction and first use', () {
      final first = _CountingRedactor('firstSecret', '[WS-FIRST]');
      final second = _CountingRedactor('secondSecret', '[WS-SECOND]');
      ISpectRedaction.configure(service: first);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final diagnostics = _diagnostics(logger)
        ..onSent(
          const <String, Object?>{'firstSecret': 'WS-FIRST-VALUE'},
        );
      final firstCalls = first.calls;

      ISpectRedaction.configure(service: second);
      diagnostics.onSent(
        const <String, Object?>{'secondSecret': 'WS-SECOND-VALUE'},
      );

      expect(diagnostics.redactor, same(second));
      expect(first.calls, firstCalls);
      expect(second.calls, greaterThan(0));
      expect(_latestMeta(logger), contains('[WS-SECOND]'));
      expect(_latestMeta(logger), isNot(contains('WS-SECOND-VALUE')));
    });

    test('keeps an explicit redactor pinned for payload and source', () {
      final explicit = _CountingRedactor('tenantSecret', '[WS-EXPLICIT]');
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const <String>{},
          sensitiveKeyPatterns: const <RegExp>[],
        ),
      );
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final diagnostics = _diagnostics(
        logger,
        redactor: explicit,
        source: 'adapter tenantSecret=WS-SOURCE-VALUE',
      );

      ISpectRedaction.configure(
        service: _CountingRedactor('otherSecret', '[WS-OTHER]'),
      );
      diagnostics.onSent(
        const <String, Object?>{'tenantSecret': 'WS-EXPLICIT-VALUE'},
      );

      expect(diagnostics.redactor, same(explicit));
      expect(explicit.calls, greaterThan(0));
      expect(_latestMeta(logger), contains('[WS-EXPLICIT]'));
      expect(_latestMeta(logger), isNot(contains('WS-EXPLICIT-VALUE')));
      expect(
        logger.history.last.additionalData?[TraceKeys.source],
        contains('[WS-EXPLICIT]'),
      );
      expect(
        logger.history.last.additionalData?[TraceKeys.source],
        isNot(contains('WS-SOURCE-VALUE')),
      );
    });

    test('global disable overrides an explicit redactor', () {
      const secret = 'WS-GLOBALLY-DISABLED';
      final explicit = _CountingRedactor('tenantSecret', '[WS-EXPLICIT]');
      ISpectRedaction.configure(enabled: false);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final diagnostics = _diagnostics(logger, redactor: explicit)
        ..onSent(<String, Object?>{'tenantSecret': secret});

      expect(diagnostics.redactor, same(explicit));
      expect(explicit.calls, 0);
      expect(_latestMeta(logger), contains(secret));
      expect(_latestMeta(logger), isNot(contains('[WS-EXPLICIT]')));
    });
  });
}
