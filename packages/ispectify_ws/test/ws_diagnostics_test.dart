// ignore_for_file: deprecated_member_use_from_same_package
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:test/test.dart';

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

class _TypedMessage {
  const _TypedMessage(this.code);

  final String code;

  Map<String, dynamic> toJson() => <String, dynamic>{'referralCode': code};

  @override
  String toString() => '_TypedMessage($code)';
}

ISpectLogData _firstByKey(ISpectLogger logger, String key) =>
    logger.history.firstWhere((e) => e.key == key);

Map<String, dynamic> _meta(ISpectLogData log) =>
    log.additionalData?[TraceKeys.meta] as Map<String, dynamic>;

void main() {
  group('WsDiagnostics frames', () {
    late ISpectLogger logger;
    late WsDiagnostics diag;

    setUp(() {
      logger = ISpectLogger();
      diag = WsDiagnostics(logger: logger);
    });

    test('logs sent frame under ws-sent', () {
      diag.onSent({'k': 'v'});
      expect(
        logger.history.any((e) => e.key == ISpectLogType.wsSent.key),
        isTrue,
      );
    });

    test('logs received frame under ws-received', () {
      diag.onReceived({'msg': 'hello'});
      expect(
        logger.history.any((e) => e.key == ISpectLogType.wsReceived.key),
        isTrue,
      );
    });

    test('renders a typed message via toJson', () {
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(enableRedaction: false),
      ).onSent(const _TypedMessage('ABC123'));

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(_meta(sent)['data'], <String, dynamic>{'referralCode': 'ABC123'});
    });

    test('omits data when printSentData is false', () {
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(printSentData: false),
      ).onSent({'secret': 'value'});

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(_meta(sent).containsKey('data'), isFalse);
    });

    test('omits data when printReceivedData is false', () {
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(printReceivedData: false),
      ).onReceived({'foo': 'bar'});

      final rec = _firstByKey(logger, ISpectLogType.wsReceived.key);
      expect(_meta(rec).containsKey('data'), isFalse);
    });

    test('still logs when the redactor throws', () {
      WsDiagnostics(
        logger: logger,
        redactor: _ThrowingRedactor(),
      ).onSent({'boom': true});

      expect(logger.history, isNotEmpty);
    });

    test('attaches the source label to emitted logs', () {
      WsDiagnostics(logger: logger, source: 'socket_io').onSent({'k': 'v'});

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(sent.additionalData?[TraceKeys.source], 'socket_io');
    });

    test('does not log when disabled', () {
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(enabled: false),
      )
        ..onSent({'k': 'v'})
        ..onReceived({'k': 'v'})
        ..onStateChanged(WsConnectionState.open)
        ..onError(Exception('x'), StackTrace.current);

      expect(logger.history, isEmpty);
    });
  });

  group('WsDiagnostics filters', () {
    late ISpectLogger logger;

    setUp(() => logger = ISpectLogger());

    test('sentFilter receives the actual log data and can suppress', () {
      ISpectLogData? captured;
      WsDiagnostics(
        logger: logger,
        settings: ISpectWSInterceptorSettings(
          sentFilter: (log) {
            captured = log;
            return false;
          },
        ),
      ).onSent({'k': 'v'});

      expect(captured, isNotNull);
      expect(captured!.additionalData?[TraceKeys.operation], 'send');
      expect(
        logger.history.any((e) => e.key == ISpectLogType.wsSent.key),
        isFalse,
      );
    });

    test('receivedFilter can suppress received frames', () {
      WsDiagnostics(
        logger: logger,
        settings: ISpectWSInterceptorSettings(receivedFilter: (_) => false),
      ).onReceived({'k': 'v'});

      expect(
        logger.history.any((e) => e.key == ISpectLogType.wsReceived.key),
        isFalse,
      );
    });

    test('errorFilter can suppress connection errors', () {
      WsDiagnostics(
        logger: logger,
        settings: ISpectWSInterceptorSettings(errorFilter: (_) => false),
      ).onError(Exception('boom'), StackTrace.current);

      expect(logger.history, isEmpty);
    });
  });

  group('WsDiagnostics connection state', () {
    late ISpectLogger logger;

    setUp(() => logger = ISpectLogger());

    test('emits ws-state with the normalized state name', () {
      WsDiagnostics(logger: logger)
          .onStateChanged(WsConnectionState.open, url: 'wss://h/chat');

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(_meta(state)['state'], 'open');
    });

    test('keeps the raw client state as a stringified hint', () {
      WsDiagnostics(logger: logger).onStateChanged(
        WsConnectionState.closed,
        raw: const {'code': 1000},
      );

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(_meta(state)['raw'], contains('1000'));
    });
  });

  group('WsDiagnostics correlation', () {
    late ISpectLogger logger;

    setUp(() => logger = ISpectLogger());

    test('all events of one session share a single correlationId', () {
      WsDiagnostics(logger: logger)
        ..onStateChanged(WsConnectionState.open)
        ..onSent({'n': 1})
        ..onReceived({'n': 2})
        ..onError(Exception('x'), StackTrace.current);

      final ids = logger.history
          .map((e) => e.additionalData?[TraceKeys.correlationId])
          .whereType<String>()
          .toSet();
      expect(ids, hasLength(1));
    });

    test('newConnection starts a fresh correlationId', () {
      final diag = WsDiagnostics(logger: logger)..onSent({'phase': 'first'});
      final firstId =
          logger.history.last.additionalData?[TraceKeys.correlationId];

      diag
        ..newConnection()
        ..onSent({'phase': 'second'});
      final secondId =
          logger.history.last.additionalData?[TraceKeys.correlationId];

      expect(secondId, isNot(equals(firstId)));
    });
  });

  group('WsDiagnostics redaction', () {
    late ISpectLogger logger;

    setUp(() => logger = ISpectLogger());

    test('redacts sensitive keys in the sent payload', () {
      WsDiagnostics(
        logger: logger,
        redactor: RedactionService(sensitiveKeys: {'token'}),
      ).onSent({'token': 'ABC-SECRET', 'ok': true});

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(_meta(sent)['data'].toString(), isNot(contains('ABC-SECRET')));
    });

    test('preserves the payload when redaction is disabled', () {
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(enableRedaction: false),
      ).onReceived({'token': 'xyz'});

      final rec = _firstByKey(logger, ISpectLogType.wsReceived.key);
      expect((_meta(rec)['data'] as Map)['token'], 'xyz');
    });

    test('redacts metrics map values', () {
      WsDiagnostics(
        logger: logger,
        redactor: RedactionService(sensitiveKeys: {'authToken'}),
      ).onSent({'k': 'v'}, metrics: {'authToken': 'SENT-SECRET', 'sent': 3});

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(
        _meta(sent)['metrics'].toString(),
        isNot(contains('SENT-SECRET')),
      );
    });

    group('URL redaction covers every emit path', () {
      const url = 'wss://host/chat?token=secret123';

      void expectUrlRedacted(ISpectLogData log) {
        expect(
          log.additionalData?[TraceKeys.target],
          isNot(contains('secret123')),
        );
        expect(_meta(log)['url'], isNot(contains('secret123')));
      }

      test('sent', () {
        WsDiagnostics(logger: logger).onSent({'k': 'v'}, url: url);
        expectUrlRedacted(_firstByKey(logger, ISpectLogType.wsSent.key));
      });

      test('received', () {
        WsDiagnostics(logger: logger).onReceived({'k': 'v'}, url: url);
        expectUrlRedacted(_firstByKey(logger, ISpectLogType.wsReceived.key));
      });

      test('error', () {
        WsDiagnostics(logger: logger)
            .onError(Exception('boom'), StackTrace.current, url: url);
        expectUrlRedacted(_firstByKey(logger, ISpectLogType.wsError.key));
      });

      test('state', () {
        WsDiagnostics(logger: logger)
            .onStateChanged(WsConnectionState.open, url: url);
        expectUrlRedacted(_firstByKey(logger, ISpectLogType.wsState.key));
      });
    });
  });
}
