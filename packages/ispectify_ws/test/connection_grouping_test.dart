// ignore_for_file: deprecated_member_use_from_same_package
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:test/test.dart';
import 'package:ws/ws.dart';

void main() {
  group('ISpectWSInterceptor connection grouping', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger();
    });

    test('setClient invokes onClientReady callback with the bound client',
        () async {
      final client = WebSocketClient();
      WebSocketClient? ready;

      ISpectWSInterceptor(
        logger: logger,
        onClientReady: (c) => ready = c,
      ).setClient(client);

      expect(identical(ready, client), isTrue);

      await client.close();
    });

    test('all send/receive logs share one correlationId per client', () async {
      final client = WebSocketClient();
      ISpectWSInterceptor(logger: logger)
        ..setClient(client)
        ..onSend({'n': 1}, (_) {})
        ..onMessage({'n': 2}, (_) {})
        ..onSend({'n': 3}, (_) {});

      final ids = logger.history
          .map((e) => e.additionalData?[TraceKeys.correlationId])
          .whereType<String>()
          .toSet();
      expect(ids, hasLength(1));

      await client.close();
    });

    test('rebinding via setClient regenerates correlationId', () async {
      final first = WebSocketClient();
      final second = WebSocketClient();

      final interceptor = ISpectWSInterceptor(logger: logger)
        ..setClient(first)
        ..onSend({'phase': 'first'}, (_) {});

      final firstId = logger
          .history.last.additionalData?[TraceKeys.correlationId] as String;

      interceptor
        ..setClient(second)
        ..onSend({'phase': 'second'}, (_) {});

      final secondId = logger
          .history.last.additionalData?[TraceKeys.correlationId] as String;

      expect(secondId, isNot(equals(firstId)));

      await first.close();
      await second.close();
    });

    test('without setClient correlationId is null and a warning is logged', () {
      ISpectWSInterceptor(logger: logger).onSend({'k': 'v'}, (_) {});

      final sent = logger.history.firstWhere(
        (e) => e.key == ISpectLogType.wsSent.key,
      );
      expect(sent.additionalData?[TraceKeys.correlationId], isNull);

      final warnings = logger.history.where(
        (e) =>
            e.logLevel == LogLevel.warning &&
            (e.message?.contains('_client is null') ?? false),
      );
      expect(warnings, isNotEmpty);
    });

    test('sensitive keys are redacted in sent payload', () async {
      final client = WebSocketClient();
      ISpectWSInterceptor(
        logger: logger,
        redactor: RedactionService(sensitiveKeys: {'token'}),
      )
        ..setClient(client)
        ..onSend({'token': 'ABC-SECRET', 'ok': true}, (_) {});

      final sent = logger.history.firstWhere(
        (e) => e.key == ISpectLogType.wsSent.key,
      );
      final meta = sent.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
      final data = meta['data'];

      expect(data.toString(), isNot(contains('ABC-SECRET')));

      await client.close();
    });

    test('onMessage preserves payload unchanged when redaction is disabled',
        () async {
      final client = WebSocketClient();
      final interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(enableRedaction: false),
      )..setClient(client);

      Object? forwarded;
      interceptor.onMessage({'token': 'xyz'}, (payload) => forwarded = payload);

      expect(forwarded, isA<Map<dynamic, dynamic>>());
      expect((forwarded! as Map)['token'], 'xyz');

      final received = logger.history.firstWhere(
        (e) => e.key == ISpectLogType.wsReceived.key,
      );
      final meta =
          received.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
      final data = meta['data'] as Map<dynamic, dynamic>;
      expect(data['token'], 'xyz');

      await client.close();
    });

    test('next callback is always invoked, even when logging fails', () async {
      final client = WebSocketClient();
      Object? forwarded;

      ISpectWSInterceptor(
        logger: logger,
        redactor: _ThrowingRedactor(),
      )
        ..setClient(client)
        ..onSend({'k': 'v'}, (obj) => forwarded = obj);

      expect(forwarded, isNotNull);

      await client.close();
    });
  });
}

class _ThrowingRedactor extends RedactionService {
  @override
  Object? redact(
    Object? input, {
    Set<String>? ignoredKeys,
    Set<String>? ignoredValues,
    String? keyName,
  }) {
    throw StateError('redaction failed');
  }
}
