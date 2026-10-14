import 'dart:convert';
import 'dart:developer';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/service_extensions/service_extension_handler.dart';
import 'package:test/test.dart';

const _secret = 'synthetic-secret-value';

Map<String, Object?> _call(
  ISpectLogger? logger,
  String method, [
  Map<String, String> parameters = const {},
]) {
  final response = ServiceExtensionHandler.handle(
    method,
    parameters,
    logger: logger,
  );
  expect(response.errorCode, isNull, reason: response.errorDetail);
  return jsonDecode(response.result!) as Map<String, Object?>;
}

ServiceExtensionResponse _callError(
  ISpectLogger? logger,
  String method, [
  Map<String, String> parameters = const {},
]) {
  final response = ServiceExtensionHandler.handle(
    method,
    parameters,
    logger: logger,
  );
  expect(response.result, isNull);
  return response;
}

List<Map<String, Object?>> _logs(Map<String, Object?> body) =>
    (body['logs']! as List<Object?>).cast<Map<String, Object?>>();

List<Object?> _messages(Map<String, Object?> body) =>
    _logs(body).map((log) => log['message']).toList();

ISpectLogger _loggerWithRawHistory(List<ISpectLogData> logs) {
  final options = ISpectLoggerOptions(useConsoleLogs: false);
  return ISpectLogger(
    options: options,
    history: DefaultISpectLoggerHistory(options, history: logs),
  );
}

ISpectLogData _unmaskedSecretLog() => ISpectLogData(
      'request failed',
      key: ISpectLogType.httpError.key,
      logLevel: LogLevel.error,
      additionalData: const {
        TraceKeys.target: 'https://api.example.test/me?token=$_secret',
        TraceKeys.correlationId: 'req-1',
        'nested': {'api_key': _secret},
      },
    );

void main() {
  late ISpectLogger logger;

  setUp(() {
    ISpectRedaction.reset();
    logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
  });

  tearDown(() async {
    await logger.dispose();
    ISpectRedaction.reset();
  });

  group('getSummary', () {
    test('counts levels and keys and lists recent errors', () {
      logger
        ..info('first')
        ..warning('careful')
        ..error('broken')
        ..info('last');

      final body = _call(logger, ISpectServiceExtensions.getSummary);

      expect(body['protocolVersion'], ISpectServiceExtensions.protocolVersion);
      expect(body['entries'], 4);
      expect(body['errorCount'], 1);
      expect(body['levels'], containsPair('info', 2));
      expect(body['topKeys'], containsPair('info', 2));
      final recentErrors =
          (body['recentErrors']! as List<Object?>).cast<Map<String, Object?>>();
      expect(recentErrors.single['message'], 'broken');
    });

    test('redacts recent errors and secret-shaped log keys', () {
      final raw = _loggerWithRawHistory([
        _unmaskedSecretLog(),
        ISpectLogData('custom', key: 'Bearer $_secret'),
      ]);
      addTearDown(raw.dispose);

      final body = _call(raw, ISpectServiceExtensions.getSummary);

      expect(body['recentErrors'], hasLength(1));
      expect(jsonEncode(body), isNot(contains(_secret)));
    });

    test('counts errors the way ISpectLogData.isError classifies them', () {
      final raw = _loggerWithRawHistory([
        ISpectLogData('levelless', key: ISpectLogType.httpError.key),
        ISpectLogData(
          'failed trace',
          logLevel: LogLevel.info,
          additionalData: const {TraceKeys.success: false},
        ),
        ISpectLogData('fine', logLevel: LogLevel.info),
      ]);
      addTearDown(raw.dispose);

      final body = _call(raw, ISpectServiceExtensions.getSummary);

      expect(body['errorCount'], 2);
      expect(body['recentErrors'], hasLength(2));
    });

    test('reports an empty history without time bounds', () {
      final body = _call(logger, ISpectServiceExtensions.getSummary);

      expect(body['entries'], 0);
      expect(body.containsKey('firstTime'), isFalse);
      expect(body['recentErrors'], isEmpty);
    });
  });

  group('getLogs', () {
    test('returns the newest matches in chronological order', () {
      for (var i = 0; i < 5; i++) {
        logger.info('log $i');
      }

      final body = _call(logger, ISpectServiceExtensions.getLogs, {
        'limit': '2',
      });

      expect(_messages(body), ['log 3', 'log 4']);
      expect(body['hasMore'], isTrue);
      expect(body['cursor'], logger.history.last.id);
    });

    test('pages back from beforeId to the older matches', () {
      for (var i = 0; i < 5; i++) {
        logger.info('log $i');
      }
      final newest = _call(logger, ISpectServiceExtensions.getLogs, {
        'limit': '2',
      });

      final older = _call(logger, ISpectServiceExtensions.getLogs, {
        'limit': '2',
        'beforeId': _logs(newest).first['id']! as String,
      });
      final oldest = _call(logger, ISpectServiceExtensions.getLogs, {
        'limit': '2',
        'beforeId': _logs(older).first['id']! as String,
      });

      expect(_messages(older), ['log 1', 'log 2']);
      expect(older['hasMore'], isTrue);
      expect(_messages(oldest), ['log 0']);
      expect(oldest['hasMore'], isFalse);
    });

    test('rejects afterId and beforeId together', () {
      logger.info('only');
      final id = logger.history.single.id;

      final response = _callError(logger, ISpectServiceExtensions.getLogs, {
        'afterId': id,
        'beforeId': id,
      });

      expect(response.errorCode, ServiceExtensionResponse.invalidParams);
      expect(response.errorDetail, contains('not both'));
    });

    test('pages forward from afterId so polling returns only new logs', () {
      logger.info('old');
      final first = _call(logger, ISpectServiceExtensions.getLogs);
      logger
        ..info('new 1')
        ..info('new 2');

      final next = _call(logger, ISpectServiceExtensions.getLogs, {
        'afterId': first['cursor']! as String,
      });

      expect(_messages(next), ['new 1', 'new 2']);
      expect(next['hasMore'], isFalse);
      expect(next['cursor'], logger.history.last.id);

      final idle = _call(logger, ISpectServiceExtensions.getLogs, {
        'afterId': next['cursor']! as String,
      });
      expect(_logs(idle), isEmpty);
      expect(idle['cursor'], next['cursor']);
    });

    test('advances the cursor past trailing logs that do not match', () {
      logger
        ..error('first failure')
        ..info('noise 1');
      final first = _call(logger, ISpectServiceExtensions.getLogs, {
        'minLevel': 'error',
      });
      expect(first['cursor'], logger.history.last.id);

      logger
        ..info('noise 2')
        ..error('second failure')
        ..info('noise 3');
      final next = _call(logger, ISpectServiceExtensions.getLogs, {
        'minLevel': 'error',
        'afterId': first['cursor']! as String,
      });

      expect(_messages(next), ['second failure']);
      expect(next['cursor'], logger.history.last.id);
    });

    test('keeps the cursor on the last returned log when a page is full', () {
      logger.info('start');
      final start = logger.history.single.id;
      for (var i = 0; i < 3; i++) {
        logger.info('log $i');
      }

      final body = _call(logger, ISpectServiceExtensions.getLogs, {
        'afterId': start,
        'limit': '2',
      });

      expect(_messages(body), ['log 0', 'log 1']);
      expect(body['hasMore'], isTrue);
      expect(body['cursor'], logger.history[2].id);
    });

    test('bounds long messages and keys in compact entries', () async {
      final raw = _loggerWithRawHistory([
        ISpectLogData('cart sync ' * 400, key: 'cart sync ' * 400),
      ]);
      addTearDown(raw.dispose);

      final entry = _logs(_call(raw, ISpectServiceExtensions.getLogs)).single;

      expect(utf8.encode(entry['message']! as String).length, lessThan(600));
      expect(utf8.encode(entry['key']! as String).length, lessThan(300));
    });

    test('filters by minLevel, keys, and query', () {
      logger
        ..info('checkout started')
        ..warning('checkout slow')
        ..error('checkout failed')
        ..error('profile failed');

      final severe = _call(logger, ISpectServiceExtensions.getLogs, {
        'minLevel': 'warning',
        'query': 'checkout',
      });
      expect(_messages(severe), ['checkout slow', 'checkout failed']);

      final byKey = _call(logger, ISpectServiceExtensions.getLogs, {
        'keys': ' warning , missing-key ',
      });
      expect(_messages(byKey), ['checkout slow']);
    });

    test('redacts sensitive values that reached history unmasked', () async {
      final raw = _loggerWithRawHistory([_unmaskedSecretLog()]);
      addTearDown(raw.dispose);

      final body = _call(raw, ISpectServiceExtensions.getLogs);

      final entry = _logs(body).single;
      expect(entry['key'], ISpectLogType.httpError.key);
      expect(entry['level'], 'error');
      expect(entry[TraceKeys.correlationId], 'req-1');
      expect(entry[TraceKeys.target], contains('api.example.test'));
      expect(jsonEncode(body), isNot(contains(_secret)));
    });

    test('rejects an evicted afterId with a restart hint', () {
      final response = _callError(logger, ISpectServiceExtensions.getLogs, {
        'afterId': 'missing',
      });

      expect(response.errorCode, ServiceExtensionResponse.invalidParams);
      expect(response.errorDetail, contains('without afterId'));
    });

    test('rejects an evicted beforeId with a restart hint', () {
      final response = _callError(logger, ISpectServiceExtensions.getLogs, {
        'beforeId': 'missing',
      });

      expect(response.errorCode, ServiceExtensionResponse.invalidParams);
      expect(response.errorDetail, contains('without beforeId'));
    });

    test('omits the cursor when the history is empty', () {
      final body = _call(logger, ISpectServiceExtensions.getLogs);

      expect(_logs(body), isEmpty);
      expect(body['hasMore'], isFalse);
      expect(body.containsKey('cursor'), isFalse);
    });

    test('rejects an out-of-range limit and an unknown level', () {
      final limit = _callError(logger, ISpectServiceExtensions.getLogs, {
        'limit': '${ISpectServiceExtensions.maxLimit + 1}',
      });
      expect(limit.errorCode, ServiceExtensionResponse.invalidParams);

      final level = _callError(logger, ISpectServiceExtensions.getLogs, {
        'minLevel': 'fatal',
      });
      expect(level.errorCode, ServiceExtensionResponse.invalidParams);
      expect(level.errorDetail, contains('critical'));
    });
  });

  group('getLog', () {
    test('returns the full record with sensitive values redacted', () {
      final raw = _loggerWithRawHistory([_unmaskedSecretLog()]);
      addTearDown(raw.dispose);

      final body = _call(raw, ISpectServiceExtensions.getLog, {
        'id': raw.history.single.id,
      });

      final record = body['log']! as Map<String, Object?>;
      expect(body['level'], 'error');
      expect(record['message'], 'request failed');
      expect(jsonEncode(record), isNot(contains(_secret)));
      expect(jsonEncode(record), contains(defaultPlaceholder));
    });

    test('honors the global redaction opt-out', () {
      ISpectRedaction.enabled = false;
      final raw = _loggerWithRawHistory([_unmaskedSecretLog()]);
      addTearDown(raw.dispose);

      final body = _call(raw, ISpectServiceExtensions.getLog, {
        'id': raw.history.single.id,
      });

      expect(jsonEncode(body), contains(_secret));
    });

    test('rejects a missing or unknown id', () {
      expect(
        _callError(logger, ISpectServiceExtensions.getLog).errorCode,
        ServiceExtensionResponse.invalidParams,
      );
      expect(
        _callError(logger, ISpectServiceExtensions.getLog, {
          'id': 'unknown',
        }).errorCode,
        ServiceExtensionResponse.invalidParams,
      );
    });
  });

  group('getTrace', () {
    test('returns every entry sharing a correlation id', () {
      logger
        ..httpRequest(source: 'test', operation: 'GET', correlationId: 'req-1')
        ..httpRequest(source: 'test', operation: 'GET', correlationId: 'req-2')
        ..httpError(
          source: 'test',
          operation: 'GET',
          error: Exception('timeout'),
          correlationId: 'req-1',
        );

      final body = _call(logger, ISpectServiceExtensions.getTrace, {
        'id': 'req-1',
      });

      expect(
        _logs(body).map((log) => log['key']),
        [ISpectLogType.httpRequest.key, ISpectLogType.httpError.key],
      );
      expect(body['hasMore'], isFalse);
    });

    test('matches entries by transaction id', () {
      final raw = _loggerWithRawHistory([
        ISpectLogData(
          'insert order',
          additionalData: const {TraceKeys.transactionId: 'tx-1'},
        ),
        ISpectLogData(
          'other transaction',
          additionalData: const {TraceKeys.transactionId: 'tx-2'},
        ),
      ]);
      addTearDown(raw.dispose);

      final body = _call(raw, ISpectServiceExtensions.getTrace, {
        'id': 'tx-1',
      });

      expect(_messages(body), ['insert order']);
    });

    test('caps a long trace at maxLimit and reports the rest', () {
      for (var i = 0; i <= ISpectServiceExtensions.maxLimit; i++) {
        logger.httpRequest(
          source: 'test',
          operation: 'GET $i',
          correlationId: 'req-1',
        );
      }

      final body = _call(logger, ISpectServiceExtensions.getTrace, {
        'id': 'req-1',
      });

      expect(_logs(body), hasLength(ISpectServiceExtensions.maxLimit));
      expect(_logs(body).first[TraceKeys.operation], 'GET 0');
      expect(body['hasMore'], isTrue);
    });
  });

  test('answers an error when the logger is unavailable', () async {
    expect(
      _callError(null, ISpectServiceExtensions.getSummary).errorCode,
      ServiceExtensionResponse.extensionError,
    );

    await logger.dispose();
    expect(
      _callError(logger, ISpectServiceExtensions.getSummary).errorDetail,
      contains('not initialized'),
    );
  });

  test('rejects an unknown method', () {
    expect(
      _callError(logger, 'ext.ispect.unknown').errorCode,
      ServiceExtensionResponse.invalidParams,
    );
  });

  test('register installs every method once per isolate', () {
    ISpectServiceExtensions.register(() => logger);
    ISpectServiceExtensions.register(() => null);

    for (final method in [
      ISpectServiceExtensions.getSummary,
      ISpectServiceExtensions.getLogs,
      ISpectServiceExtensions.getLog,
      ISpectServiceExtensions.getTrace,
    ]) {
      expect(
        () => registerExtension(
          method,
          (_, __) async => ServiceExtensionResponse.result('{}'),
        ),
        throwsArgumentError,
        reason: method,
      );
    }
  });
}
