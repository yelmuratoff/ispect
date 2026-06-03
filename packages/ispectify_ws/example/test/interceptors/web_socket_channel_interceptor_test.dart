import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws_example/interceptors/web_socket_channel_interceptor.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

ISpectLogData _firstByKey(ISpectLogger logger, String key) =>
    logger.history.firstWhere((e) => e.key == key);

Map<String, dynamic> _meta(ISpectLogData log) =>
    log.additionalData?[TraceKeys.meta] as Map<String, dynamic>;

void main() {
  group('ISpectWebSocketChannelDiagnostics', () {
    late ISpectLogger logger;
    late StreamChannelController<String> controller;

    setUp(() {
      logger = ISpectLogger();
      controller = StreamChannelController<String>();
    });

    test('emits an open state when the channel is wrapped', () {
      ISpectWebSocketChannelDiagnostics(logger: logger)
          .wrap(controller.foreign);

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(_meta(state)['state'], 'open');
    });

    test('logs inbound frames as ws-received', () async {
      final channel = ISpectWebSocketChannelDiagnostics(logger: logger)
          .wrap(controller.foreign);
      channel.stream.listen((_) {});

      controller.local.sink.add('inbound');
      await Future<void>.delayed(Duration.zero);

      final received = _firstByKey(logger, ISpectLogType.wsReceived.key);
      expect(_meta(received)['data'], 'inbound');
    });

    test('logs outbound frames as ws-sent and forwards them', () async {
      final channel = ISpectWebSocketChannelDiagnostics(logger: logger)
          .wrap(controller.foreign);

      final delivered = <String>[];
      controller.local.stream.listen(delivered.add);

      channel.sink.add('outbound');
      await Future<void>.delayed(Duration.zero);

      expect(
        logger.history.any((e) => e.key == ISpectLogType.wsSent.key),
        isTrue,
      );
      expect(delivered, contains('outbound'));
    });

    test('emits a closed state when the stream completes', () async {
      final channel = ISpectWebSocketChannelDiagnostics(logger: logger)
          .wrap(controller.foreign);
      channel.stream.listen((_) {});

      await controller.local.sink.close();
      await Future<void>.delayed(Duration.zero);

      final states = logger.history
          .where((e) => e.key == ISpectLogType.wsState.key)
          .map((e) => _meta(e)['state'])
          .toList();
      expect(states, contains('closed'));
    });

    test('shares one correlationId across open, inbound, and outbound',
        () async {
      final channel = ISpectWebSocketChannelDiagnostics(logger: logger)
          .wrap(controller.foreign);
      channel.stream.listen((_) {});

      channel.sink.add('out');
      controller.local.sink.add('in');
      await Future<void>.delayed(Duration.zero);

      final ids = logger.history
          .map((e) => e.additionalData?[TraceKeys.correlationId])
          .whereType<String>()
          .toSet();
      expect(ids, hasLength(1));
    });

    test('redacts the connection URL on inbound frames', () async {
      final channel = ISpectWebSocketChannelDiagnostics(
        logger: logger,
        url: 'wss://host/chat?token=secret123',
      ).wrap(controller.foreign);
      channel.stream.listen((_) {});

      controller.local.sink.add('inbound');
      await Future<void>.delayed(Duration.zero);

      final received = _firstByKey(logger, ISpectLogType.wsReceived.key);
      expect(_meta(received)['url'], isNot(contains('secret123')));
    });
  });
}
