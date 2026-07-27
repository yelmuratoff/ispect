// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:collection';

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

final class _PayloadCountingRedactor extends RedactionService {
  int payloadCalls = 0;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    if (data == 'FILTER-ERROR-PAYLOAD') {
      payloadCalls++;
    }
    return super.redactForExport(
      data,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
  }
}

final class _SerializationProbe {
  _SerializationProbe(this.onSerialize);

  final void Function() onSerialize;

  Map<String, Object?> toJson() {
    onSerialize();
    return const {'password': 'synthetic-secret'};
  }
}

final class _StringificationProbe {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return 'customer-alpha-private-value';
  }
}

final class _IterableProbe extends IterableBase<Object?> {
  int iteratorCalls = 0;

  @override
  Iterator<Object?> get iterator {
    iteratorCalls++;
    return const <Object?>['private-frame'].iterator;
  }
}

final class _HostileWsException implements Exception {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_WS_EXCEPTION');
  }
}

final class _HostileWsStack implements StackTrace {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_WS_STACK');
  }
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

    test('describes a typed message without invoking toJson', () {
      var serializationCount = 0;
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          enableRedaction: false,
          printSentData: true,
        ),
      ).onSent(_SerializationProbe(() => serializationCount++));

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(serializationCount, 0);
      expect(
        _meta(sent)['data'],
        JsonValueNormalizer.unprintableValue,
      );
      expect(_meta(sent)['data'], isNot(contains('synthetic-secret')));
    });

    test('omits data when printSentData is false', () {
      WsDiagnostics(
        logger: logger,
      ).onSent({'secret': 'value'});

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(_meta(sent).containsKey('data'), isFalse);
    });

    test('omits data when printReceivedData is false', () {
      WsDiagnostics(
        logger: logger,
      ).onReceived({'foo': 'bar'});

      final rec = _firstByKey(logger, ISpectLogType.wsReceived.key);
      expect(_meta(rec).containsKey('data'), isFalse);
    });

    test('does not inspect frames when payload capture is disabled', () {
      var serializationCount = 0;
      WsDiagnostics(
        logger: logger,
      )
        ..onSent(_SerializationProbe(() => serializationCount++))
        ..onReceived(_SerializationProbe(() => serializationCount++));

      expect(serializationCount, 0);
      expect(_meta(logger.history[0]).containsKey('data'), isFalse);
      expect(_meta(logger.history[1]).containsKey('data'), isFalse);
    });

    test('still logs when the redactor throws', () {
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(printSentData: true),
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

    test('filter shutdown aborts payload traversal and emission', () {
      final payload = _IterableProbe();

      WsDiagnostics(
        logger: logger,
        settings: ISpectWSInterceptorSettings(
          printSentData: true,
          sentFilter: (_) {
            logger.disable();
            return true;
          },
        ),
      ).onSent(payload);

      expect(payload.iteratorCalls, 0);
      expect(logger.history, isEmpty);
    });

    test('errorFilter can suppress connection errors', () {
      WsDiagnostics(
        logger: logger,
        settings: ISpectWSInterceptorSettings(errorFilter: (_) => false),
      ).onError(Exception('boom'), StackTrace.current);

      expect(logger.history, isEmpty);
    });

    test('error filter shutdown aborts error payload redaction', () {
      final redactor = _PayloadCountingRedactor();

      WsDiagnostics(
        logger: logger,
        redactor: redactor,
        settings: ISpectWSInterceptorSettings(
          errorFilter: (_) {
            logger.disable();
            return true;
          },
        ),
      ).onError('FILTER-ERROR-PAYLOAD', StackTrace.empty);

      expect(redactor.payloadCalls, 0);
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
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(printStateData: true),
      ).onStateChanged(
        WsConnectionState.closed,
        raw: const {'code': 1000},
      );

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(_meta(state)['raw'], contains('1000'));
    });

    test('redacts sensitive values from the raw client state', () {
      const secret = 'WS-STATE-SECRET';

      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(printStateData: true),
        redactor: RedactionService(sensitiveKeys: {'tenantSecret'}),
      ).onStateChanged(
        WsConnectionState.closed,
        raw: const {'tenantSecret': secret},
      );

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(_meta(state)['raw'], isNot(contains(secret)));
    });

    test('preserves raw client state when redaction is disabled', () {
      const secret = 'WS-RAW-STATE-SECRET';

      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          enableRedaction: false,
          printStateData: true,
        ),
      ).onStateChanged(
        WsConnectionState.closed,
        raw: const {'tenantSecret': secret},
      );

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(_meta(state)['raw'], contains(secret));
    });

    test('bounds raw state without executing its formatter', () {
      final raw = _StringificationProbe();

      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          enableRedaction: false,
          printStateData: true,
        ),
      ).onStateChanged(WsConnectionState.closed, raw: raw);

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(raw.calls, 0);
      expect(
        _meta(state)['raw'],
        JsonValueNormalizer.unprintableValue,
      );
    });

    test('bounds multi-megabyte raw state after an opt-out', () {
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          enableRedaction: false,
          printStateData: true,
        ),
      ).onStateChanged(
        WsConnectionState.closed,
        raw: 's' * (4 * 1024 * 1024),
      );

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(
        LogExportOutput.utf8Length(_meta(state)['raw'] as String),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('default state capture omits raw data without inspecting it', () {
      final raw = _StringificationProbe();

      WsDiagnostics(logger: logger).onStateChanged(
        WsConnectionState.closed,
        raw: raw,
      );

      final state = _firstByKey(logger, ISpectLogType.wsState.key);
      expect(_meta(state), isNot(contains('raw')));
      expect(raw.calls, 0);
    });
  });

  group('WsDiagnostics errors', () {
    late ISpectLogger logger;

    setUp(() => logger = ISpectLogger());

    test('redacts the error and stack with configured sensitive keys', () {
      const secret = 'WS-ERROR-SECRET';
      final error = Exception('{"tenantSecret":"$secret"}');
      final stackTrace = StackTrace.fromString(
        'request https://api.example.com?tenantSecret=$secret',
      );

      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(printErrorData: true),
        redactor: RedactionService(sensitiveKeys: {'tenantSecret'}),
      ).onError(error, stackTrace);

      final log = _firstByKey(logger, ISpectLogType.wsError.key);
      expect(log.textMessage, isNot(contains(secret)));
      expect(log.stackTrace.toString(), isNot(contains(secret)));
    });

    test('omits error details when their print flags are false', () {
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          printErrorMessage: false,
        ),
      ).onError(Exception('secret'), StackTrace.current);

      final log = _firstByKey(logger, ISpectLogType.wsError.key);
      expect(log.exception, isNull);
      expect(log.error, isNull);
      expect(log.stackTrace, isNull);
      expect(log.additionalData?[TraceKeys.error], isNull);
    });

    test('preserves bounded ordinary error text when redaction is disabled',
        () {
      const error = 'WS-RAW-ERROR-SECRET';
      final stackTrace = StackTrace.fromString('WS-RAW-STACK-SECRET');

      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(enableRedaction: false),
      ).onError(error, stackTrace);

      final log = _firstByKey(logger, ISpectLogType.wsError.key);
      expect(log.exception, isNull);
      expect(log.additionalData?[TraceKeys.error], contains(error));
      expect(log.stackTrace, isNull);
    });

    test('does not execute opt-out error or stack formatters', () {
      final error = _HostileWsException();
      final stackTrace = _HostileWsStack();

      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          enableRedaction: false,
          printErrorData: true,
        ),
      ).onError(error, stackTrace);

      final log = _firstByKey(logger, ISpectLogType.wsError.key);
      expect(error.calls, 0);
      expect(stackTrace.calls, 0);
      expect('${log.exception}', isNot(contains('HOSTILE_WS')));
      expect('${log.stackTrace}', isNot(contains('HOSTILE_WS')));
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

    test('disabled newConnection invalidates the previous correlationId', () {
      final diag = WsDiagnostics(logger: logger)..onSent({'phase': 'first'});
      final firstId =
          logger.history.last.additionalData?[TraceKeys.correlationId];

      logger.disable();
      diag.newConnection();
      logger.enable();
      diag.onSent({'phase': 'second'});

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
        settings: const ISpectWSInterceptorSettings(printSentData: true),
        redactor: RedactionService(sensitiveKeys: {'token'}),
      ).onSent({'token': 'ABC-SECRET', 'ok': true});

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(_meta(sent)['data'].toString(), isNot(contains('ABC-SECRET')));
    });

    test('redacts sensitive keys in a JSON-encoded frame', () {
      const secret = 'WS-JSON-STRING-SECRET';

      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(printSentData: true),
      ).onSent(
        '{"event":"login","password":"$secret"}',
      );

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(_meta(sent)['data'], isA<String>());
      expect(_meta(sent)['data'], isNot(contains(secret)));
    });

    test('scrubs malformed JSON with configured sensitive keys', () {
      const secret = 'WS-MALFORMED-CUSTOM-SECRET';

      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(printSentData: true),
        redactor: RedactionService(sensitiveKeys: {'tenantSecret'}),
      ).onSent('{"tenantSecret":"$secret",}');

      final sent = _firstByKey(logger, ISpectLogType.wsSent.key);
      expect(_meta(sent)['data'], isA<String>());
      expect(_meta(sent)['data'], isNot(contains(secret)));
    });

    test('preserves the payload when redaction is disabled', () {
      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          enableRedaction: false,
          printReceivedData: true,
        ),
      ).onReceived({'token': 'xyz'});

      final rec = _firstByKey(logger, ISpectLogType.wsReceived.key);
      expect((_meta(rec)['data'] as Map)['token'], 'xyz');
    });

    test('preserves a JSON-encoded frame when redaction is disabled', () {
      const frame = '{"password":"WS-RAW-SECRET"}';

      WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          enableRedaction: false,
          printReceivedData: true,
        ),
      ).onReceived(frame);

      final rec = _firstByKey(logger, ISpectLogType.wsReceived.key);
      expect(_meta(rec)['data'], frame);
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

  group('WsDiagnostics production settings', () {
    test('retain only error events', () {
      final logger = ISpectLogger();
      WsDiagnostics(
        logger: logger,
        settings: ISpectWSInterceptorSettingsBuilder.production().build(),
      )
        ..onSent({'event': 'outgoing'})
        ..onReceived({'event': 'incoming'})
        ..onStateChanged(WsConnectionState.open)
        ..onError(Exception('failed'), StackTrace.current);

      expect(logger.history, hasLength(1));
      expect(logger.history.single.key, ISpectLogType.wsError.key);
    });
  });
}
