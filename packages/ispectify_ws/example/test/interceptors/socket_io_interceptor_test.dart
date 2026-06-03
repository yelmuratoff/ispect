import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws_example/interceptors/socket_io_interceptor.dart';
import 'package:test/test.dart';

ISpectLogData _firstByKey(ISpectLogger logger, String key) =>
    logger.history.firstWhere((e) => e.key == key);

Map<String, dynamic> _meta(ISpectLogData log) =>
    log.additionalData?[TraceKeys.meta] as Map<String, dynamic>;

void main() {
  group('ISpectSocketIoDiagnostics', () {
    late ISpectLogger logger;

    setUp(() => logger = ISpectLogger());

    test('records an outbound event under ws-sent with its name', () {
      ISpectSocketIoDiagnostics(logger: logger)
          .recordSent('chat', {'text': 'hi'});

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(sent.additionalData?[TraceKeys.source], 'socket_io');
      expect((_meta(sent)['data'] as Map)['event'], 'chat');
    });

    test('records an inbound event under ws-received', () {
      ISpectSocketIoDiagnostics(logger: logger)
          .recordReceived('update', [1, 2]);

      final received = _firstByKey(logger, ISpectLogType.wsReceived.key);
      expect((_meta(received)['data'] as Map)['event'], 'update');
    });

    test('records connect and disconnect as ws-state transitions', () {
      ISpectSocketIoDiagnostics(logger: logger)
        ..recordConnect()
        ..recordDisconnect('io client disconnect');

      final states = logger.history
          .where((e) => e.key == ISpectLogType.wsState.key)
          .map((e) => _meta(e)['state'])
          .toList();
      expect(states, ['open', 'closed']);
    });

    test('records a connection error under ws-error', () {
      ISpectSocketIoDiagnostics(logger: logger).recordError(Exception('boom'));

      expect(
        logger.history.any((e) => e.key == ISpectLogType.wsError.key),
        isTrue,
      );
    });

    test('all events of one session share a single correlationId', () {
      ISpectSocketIoDiagnostics(logger: logger)
        ..recordConnect()
        ..recordSent('chat', 'a')
        ..recordReceived('chat', 'b')
        ..recordError(Exception('x'));

      final ids = logger.history
          .map((e) => e.additionalData?[TraceKeys.correlationId])
          .whereType<String>()
          .toSet();
      expect(ids, hasLength(1));
    });

    test('redacts sensitive values in the recorded payload', () {
      ISpectSocketIoDiagnostics(
        logger: logger,
        redactor: RedactionService(sensitiveKeys: {'token'}),
      ).recordSent('auth', {'token': 'SECRET-IO'});

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(_meta(sent)['data'].toString(), isNot(contains('SECRET-IO')));
    });

    test('redacts the connection URL', () {
      ISpectSocketIoDiagnostics(
        logger: logger,
        url: 'wss://host/io?token=secret123',
      ).recordConnect();

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(_meta(state)['url'], isNot(contains('secret123')));
    });
  });
}
