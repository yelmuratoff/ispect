import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws_example/interceptors/ws_interceptor.dart';
import 'package:test/test.dart';
import 'package:ws/ws.dart';

void main() {
  group('ISpectWSInterceptor', () {
    late ISpectLogger logger;

    setUp(() => logger = ISpectLogger());

    test('setClient invokes onClientReady with the bound client', () async {
      final client = WebSocketClient();
      WebSocketClient? ready;

      ISpectWSInterceptor(logger: logger, onClientReady: (c) => ready = c)
          .setClient(client);

      expect(identical(ready, client), isTrue);
      await client.close();
    });

    test('logs sent and received frames under their keys', () async {
      final client = WebSocketClient();
      final interceptor = ISpectWSInterceptor(logger: logger)
        ..setClient(client)
        ..onSend({'k': 'v'}, (_) {})
        ..onMessage({'msg': 'hi'}, (_) {});

      expect(
          logger.history.any((e) => e.key == ISpectLogType.wsSent.key), isTrue);
      expect(
        logger.history.any((e) => e.key == ISpectLogType.wsReceived.key),
        isTrue,
      );

      await interceptor.dispose();
      await client.close();
    });

    test('all frames of one client share a single correlationId', () async {
      final client = WebSocketClient();
      ISpectWSInterceptor(logger: logger)
        ..setClient(client)
        ..onSend({'n': 1}, (_) {})
        ..onMessage({'n': 2}, (_) {})
        ..onSend({'n': 3}, (_) {});

      final ids = logger.history
          .where((e) => e.key != ISpectLogType.wsState.key)
          .map((e) => e.additionalData?[TraceKeys.correlationId])
          .whereType<String>()
          .toSet();
      expect(ids, hasLength(1));

      await client.close();
    });

    test('rebinding via setClient regenerates the correlationId', () async {
      final first = WebSocketClient();
      final second = WebSocketClient();

      final interceptor = ISpectWSInterceptor(logger: logger)
        ..setClient(first)
        ..onSend({'phase': 'first'}, (_) {});
      final firstId =
          logger.history.last.additionalData?[TraceKeys.correlationId];

      interceptor
        ..setClient(second)
        ..onSend({'phase': 'second'}, (_) {});
      final secondId =
          logger.history.last.additionalData?[TraceKeys.correlationId];

      expect(secondId, isNot(equals(firstId)));

      await interceptor.dispose();
      await first.close();
      await second.close();
    });

    test('forwards data to the next callback', () {
      Object? forwarded;
      ISpectWSInterceptor(logger: logger)
          .onSend({'k': 'v'}, (o) => forwarded = o);
      expect(forwarded, isNotNull);
    });
  });
}
