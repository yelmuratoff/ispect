import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:test/test.dart';

/// Default config used across most tests in this file.
const _cfg = ISpectDbConfig(
  redactKeys: {'password', 'token'},
  maxValueLength: 50,
  maxArgsLength: 12,
  maxStatementLength: 40,
  attachStackOnError: true,
  enableTransactionMarkers: true,
  slowThreshold: Duration(milliseconds: 1),
);

final class _HostileDto {
  _HostileDto(this.secret);

  final String secret;
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    return <String, Object?>{'password': secret};
  }

  @override
  String toString() {
    toStringCalls++;
    return secret;
  }
}

final class _HostileException implements Exception {
  _HostileException(this.secret);

  final String secret;
  int calls = 0;

  @override
  String toString() {
    calls++;
    return secret;
  }
}

final class _HostileError extends Error {
  _HostileError(this.secret);

  final String secret;
  int calls = 0;

  @override
  String toString() {
    calls++;
    return secret;
  }
}

final class _HostileStackTrace implements StackTrace {
  _HostileStackTrace(this.secret);

  final String secret;
  int calls = 0;

  @override
  String toString() {
    calls++;
    return secret;
  }
}

final class _HostileKey {
  _HostileKey(this.secret);

  final String secret;
  int calls = 0;

  @override
  String toString() {
    calls++;
    return secret;
  }
}

final class _ThrowingLengthList<E> extends ListBase<E> {
  _ThrowingLengthList(Iterable<E> values) : _values = List<E>.of(values);

  final List<E> _values;
  int lengthCalls = 0;

  @override
  int get length {
    lengthCalls++;
    throw StateError('hostile length');
  }

  @override
  set length(int value) => _values.length = value;

  @override
  E operator [](int index) => _values[index];

  @override
  void operator []=(int index, E value) => _values[index] = value;
}

final class _DisablingLengthList<E> extends ListBase<E> {
  _DisablingLengthList(Iterable<E> values, this._disable)
      : _values = List<E>.of(values);

  final List<E> _values;
  final void Function() _disable;
  int lengthCalls = 0;

  @override
  int get length {
    lengthCalls++;
    _disable();
    return _values.length;
  }

  @override
  set length(int value) => _values.length = value;

  @override
  E operator [](int index) => _values[index];

  @override
  void operator []=(int index, E value) => _values[index] = value;
}

void main() {
  late ISpectLogger logger;

  setUp(() {
    ISpectRedaction.reset();
    logger = ISpectLogger.testing();
  });
  tearDown(ISpectRedaction.reset);

  group('db()', () {
    test('enabled logger without consumers bypasses preprocessing', () {
      final sinklessLogger = ISpectLogger(
        options: ISpectLoggerOptions(
          useConsoleLogs: false,
          useHistory: false,
        ),
      );
      addTearDown(sinklessLogger.dispose);
      final args = _ThrowingLengthList<Object?>(const ['secret']);

      sinklessLogger.db(
        source: 'sqflite',
        operation: 'query',
        args: args,
      );

      expect(args.lengthCalls, 0);
      expect(sinklessLogger.history, isEmpty);
    });

    test('logs fields and digest/truncation', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT * FROM users WHERE name = "VeryVeryLongName"',
        table: 'users',
        args: ['aaaaaaaaaaaa-too-long'],
        namedArgs: {'password': 'secret', 'q': 'short'},
        success: true,
        duration: const Duration(milliseconds: 10),
        meta: {'note': 'test'},
        config: _cfg,
      );

      expect(logger.history, isNotEmpty);
      final entry = logger.history.last;
      expect(entry.key, anyOf('db-query', 'db-result'));
      final add = entry.additionalData ?? {};

      // Envelope fields from trace().
      expect(add['category'], 'db');
      expect(add['source'], 'sqflite');
      expect(add['operation'], 'query');
      expect(add['target'], 'users');
      expect(add['durationMs'], greaterThanOrEqualTo(10));
      expect(add['slow'], isTrue);

      // DB-specific fields nested in TraceKeys.meta.
      final meta = add['meta'] as Map<String, dynamic>;
      expect(meta['statement'], isA<String>());
      expect(meta['statementDigest'], isA<String>());
      expect((meta['args'] as List).first, defaultPlaceholder);
      expect((meta['namedArgs'] as Map)['password'], '[REDACTED]');
    });

    test('sets error logs to LogLevel.error', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT 1',
        success: false,
        error: 'boom',
      );
      final last = logger.history.last;
      expect(last.key, 'db-error');
      expect(last.logLevel, LogLevel.error);
    });

    test('handles null statement and empty args', () {
      logger.db(
        source: 'kv',
        operation: 'get',
        key: 'myKey',
        args: [],
        namedArgs: {},
      );

      expect(logger.history, isNotEmpty);
      final add = logger.history.last.additionalData ?? {};
      // Database keys are identifiers and are redacted in the trace envelope.
      expect(add['key'], defaultPlaceholder);
      // DB-specific meta should not contain statement/statementDigest.
      final meta = add['meta'] as Map<String, dynamic>?;
      expect(meta?.containsKey('statement') ?? false, isFalse);
      expect(meta?.containsKey('statementDigest') ?? false, isFalse);
    });

    test('skips redaction when redact is false', () {
      // Per-call redact: false only affects _preprocessDb (statement
      // digest, positional args). trace() still applies its own
      // redaction from cfg.redact. To fully skip, use a config with
      // redact: false.
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT * FROM users',
        namedArgs: {'password': 'secret123'},
        redact: false,
        config: const ISpectDbConfig(redact: false),
      );

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      expect((meta['namedArgs'] as Map)['password'], 'secret123');
    });

    test('masks every positional arg when redaction is enabled', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT * FROM orders WHERE total > ?',
        args: [100, 'visible'],
      );

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      final args = meta['args'] as List;
      expect(args, [defaultPlaceholder, defaultPlaceholder]);
    });

    test('redacts positional args when statement mentions sensitive column',
        () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT * FROM users WHERE password = ?',
        args: ['super-secret'],
        config: _cfg,
      );

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      final args = meta['args'] as List;
      expect(args.first, '[REDACTED]');
    });

    test('logs value and projection correctly', () {
      logger.db(
        source: 'kv',
        operation: 'read',
        key: 'k',
        value: 'raw-value',
        projection: 'projected-value',
      );

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      expect(meta['value'], contains('projected-value'));
    });

    test('explicit null projection omits the raw value', () {
      const secret = 'NULL_PROJECTION_RAW_SECRET';

      logger.db(
        source: 'kv',
        operation: 'read',
        key: 'record',
        value: secret,
        projection: null,
      );

      final log = logger.history.last;
      final meta = log.additionalData?['meta'] as Map<String, dynamic>;
      expect(meta, isNot(containsPair('value', secret)));
      expect(log.textMessage, isNot(contains(secret)));
    });

    test('pickLogKey returns db-query for read operations', () {
      for (final op in [
        'query',
        'select',
        'get',
        'find',
        'list',
        'count',
      ]) {
        logger.db(source: 'test', operation: op, success: true);
        expect(logger.history.last.key, 'db-query', reason: 'op=$op');
      }
    });

    test('pickLogKey returns db-result for write operations', () {
      for (final op in ['insert', 'update', 'delete']) {
        logger.db(source: 'test', operation: op, success: true);
        expect(logger.history.last.key, 'db-result');
      }
    });

    test('logs sizeBytes for file operations', () {
      logger.db(
        source: 'file',
        operation: 'write',
        target: '/data/cache/image.png',
        sizeBytes: 2048,
        success: true,
      );

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      expect(meta['sizeBytes'], 2048);
    });

    test('logs cacheHit for cache operations', () {
      logger.db(
        source: 'cache',
        operation: 'get',
        key: 'user:123',
        cacheHit: true,
      );

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      expect(meta['cacheHit'], isTrue);
    });

    test('logs cache miss', () {
      logger.db(
        source: 'cache',
        operation: 'get',
        key: 'user:999',
        cacheHit: false,
      );

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      expect(meta['cacheHit'], isFalse);
    });

    test('omits sizeBytes and cacheHit when null', () {
      logger.db(source: 'kv', operation: 'get', key: 'k');

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>?;
      expect(meta?.containsKey('sizeBytes') ?? false, isFalse);
      expect(meta?.containsKey('cacheHit') ?? false, isFalse);
    });

    test('does not mark as slow when duration is under threshold', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        duration: Duration.zero,
        config: _cfg,
      );

      final add = logger.history.last.additionalData ?? {};
      // trace() always emits 'slow' when both duration and slowThreshold
      // are present; Duration.zero is NOT > threshold, so slow == false.
      expect(add['slow'], isFalse);
    });
  });

  group('redaction (H4/M4)', () {
    const token = 'ghp_1234567890abcdefghij';
    const databaseKey = 'customer@example.invalid';

    test('default path resolves the global service for every operation', () {
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const {'business_marker'},
          placeholder: '<GLOBAL_DB>',
        ),
      );

      logger.db(
        source: 'kv',
        operation: 'read',
        value: const <String, Object?>{
          'business_marker': 'database-secret',
        },
      );

      final meta = (logger.history.single.additionalData ?? const {})['meta']
          as Map<String, dynamic>;
      expect(
        (meta['value'] as Map)['business_marker'],
        contains('<GLOBAL_DB>'),
      );
      expect(
        (meta['value'] as Map)['business_marker'],
        isNot(contains('database-secret')),
      );

      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const {'business_marker'},
          placeholder: '<UPDATED_DB>',
        ),
      );
      logger.db(
        source: 'kv',
        operation: 'read',
        value: const <String, Object?>{
          'business_marker': 'updated-database-secret',
        },
      );
      final updatedMeta = (logger.history.last.additionalData ??
          const {})['meta'] as Map<String, dynamic>;

      expect(
        (updatedMeta['value'] as Map)['business_marker'],
        contains('<UPDATED_DB>'),
      );
      expect(
        (updatedMeta['value'] as Map)['business_marker'],
        isNot(contains('updated-database-secret')),
      );
    });

    test('per-call redactKeys take precedence over the global service', () {
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const {'global_marker'},
          placeholder: '<GLOBAL_DB>',
        ),
      );

      logger.db(
        source: 'kv',
        operation: 'read',
        value: const <String, Object?>{
          'local_marker': 'local-value',
          'global_marker': 'global-value',
        },
        redactKeys: const ['local_marker'],
      );

      final meta = (logger.history.single.additionalData ?? const {})['meta']
          as Map<String, dynamic>;
      final value = meta['value'] as Map;
      expect(value['local_marker'], contains(defaultPlaceholder));
      expect(value['global_marker'], 'global-value');
    });

    test('config redactKeys take precedence over the global service', () {
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const {'global_marker'},
          placeholder: '<GLOBAL_DB>',
        ),
      );

      logger.db(
        source: 'kv',
        operation: 'read',
        value: const <String, Object?>{
          'config_marker': 'config-value',
          'global_marker': 'global-value',
        },
        config: const ISpectDbConfig(
          redactKeys: {'config_marker'},
        ),
      );

      final meta = (logger.history.single.additionalData ?? const {})['meta']
          as Map<String, dynamic>;
      final value = meta['value'] as Map;
      expect(value['config_marker'], contains(defaultPlaceholder));
      expect(value['global_marker'], 'global-value');
    });

    test('removes database keys from successful log messages and metadata', () {
      logger.db(
        source: 'kv',
        operation: 'read',
        key: databaseKey,
        transactionId: 'transaction-audit',
      );

      final entry = logger.history.last;
      final additionalData = entry.additionalData ?? {};
      final meta = additionalData['meta'] as Map;

      expect(entry.message.toString(), isNot(contains(databaseKey)));
      expect(additionalData['key'], defaultPlaceholder);
      expect(meta['key'], defaultPlaceholder);
      expect(additionalData['correlationId'], 'transaction-audit');
    });

    test('removes database keys from failed traced operations', () async {
      await expectLater(
        logger.dbTrace<void>(
          source: 'kv',
          operation: 'read',
          key: databaseKey,
          transactionId: 'transaction-audit',
          run: () async => throw StateError('synthetic failure'),
        ),
        throwsA(isA<StateError>()),
      );

      final entry = logger.history.last;
      final additionalData = entry.additionalData ?? {};
      final meta = additionalData['meta'] as Map;

      expect(entry.message.toString(), isNot(contains(databaseKey)));
      expect(additionalData['key'], defaultPlaceholder);
      expect(meta['key'], defaultPlaceholder);
      expect(additionalData['correlationId'], 'transaction-audit');
    });

    test('keeps database keys raw when redaction is explicitly disabled', () {
      logger.db(
        source: 'kv',
        operation: 'read',
        key: databaseKey,
        redact: false,
      );

      final entry = logger.history.last;
      final additionalData = entry.additionalData ?? {};
      final meta = additionalData['meta'] as Map;

      expect(entry.message.toString(), contains(databaseKey));
      expect(additionalData['key'], databaseKey);
      expect(meta['key'], databaseKey);
    });

    test('masks token-shaped positional args even when no column is sensitive',
        () {
      logger.db(
        source: 'pg',
        operation: 'query',
        statement: 'SELECT * FROM t WHERE x = ?',
        args: const [token],
      );

      final meta = (logger.history.last.additionalData ?? {})['meta'] as Map;
      final args = meta['args'] as List;
      expect(args.first, isNot(token));
      expect(args.first.toString(), contains('[REDACTED]'));
    });

    test('masks token-shaped named arg values under non-sensitive keys', () {
      logger.db(
        source: 'pg',
        operation: 'query',
        statement: 'SELECT 1',
        namedArgs: const {'payload': token},
      );

      final meta = (logger.history.last.additionalData ?? {})['meta'] as Map;
      final namedArgs = meta['namedArgs'] as Map;
      expect(namedArgs['payload'], isNot(token));
      expect(namedArgs['payload'].toString(), contains('[REDACTED]'));
    });

    test('masks token-shaped result values under non-sensitive keys', () {
      logger.db(
        source: 'kv',
        operation: 'read',
        key: 'k',
        value: token,
      );

      final meta = (logger.history.last.additionalData ?? {})['meta'] as Map;
      expect(meta['value'], isNot(token));
      expect(meta['value'].toString(), contains('[REDACTED]'));
    });

    test('masks an opaque result value when the key name is sensitive', () {
      logger.db(
        source: 'kv',
        operation: 'read',
        key: 'password',
        value: 'hunter2plain',
      );

      final meta = (logger.history.last.additionalData ?? {})['meta'] as Map;
      expect(meta['value'], '[REDACTED]');
    });

    test('redacts credentials embedded in the db error message', () {
      logger.db(
        source: 'pg',
        operation: 'query',
        statement: 'SELECT 1',
        success: false,
        error: 'auth failed: Bearer sk-live-abcdef1234567890 '
            'via postgres://admin:s3cr3t@db.example.com',
      );

      final entry = logger.history.last;
      expect(entry.key, 'db-error');
      final meta = (entry.additionalData ?? {})['meta'] as Map;
      final dbError = meta['dbError'] as String;
      expect(dbError, contains('Bearer [REDACTED]'));
      expect(dbError, isNot(contains('sk-live-abcdef1234567890')));
      expect(dbError, isNot(contains('s3cr3t')));
    });

    test('keeps positional args and db error raw when redaction is disabled',
        () {
      logger.db(
        source: 'pg',
        operation: 'query',
        statement: 'SELECT * FROM t WHERE x = ?',
        args: const [token],
        success: false,
        error: 'Bearer sk-live-abcdef1234567890',
        redact: false,
        config: const ISpectDbConfig(redact: false),
      );

      final meta = (logger.history.last.additionalData ?? {})['meta'] as Map;
      expect((meta['args'] as List).first, token);
      expect(meta['dbError'], 'Bearer sk-live-abcdef1234567890');
    });

    test('global opt-out keeps every database diagnostic field raw', () {
      ISpectRedaction.enabled = false;
      addTearDown(() => ISpectRedaction.enabled = true);
      const statement = 'SELECT * FROM users WHERE password = ?';
      const rawError = 'Bearer sk-live-global-opt-out';

      logger.db(
        source: 'pg',
        operation: 'query',
        statement: statement,
        key: databaseKey,
        args: const [token],
        namedArgs: const {'password': token},
        value: const {'password': token},
        success: false,
        error: rawError,
      );

      final entry = logger.history.last;
      final additionalData = entry.additionalData ?? {};
      final meta = additionalData['meta'] as Map;
      expect(entry.message, contains(databaseKey));
      expect(additionalData['key'], databaseKey);
      expect(meta['statement'], statement);
      expect(meta['key'], databaseKey);
      expect((meta['args'] as List).single, token);
      expect((meta['namedArgs'] as Map)['password'], token);
      expect((meta['value'] as Map)['password'], token);
      expect(meta['dbError'], rawError);
    });

    test('captures and redacts DTO values in database diagnostics', () {
      const secret = 'violet-db-payload';
      final dto = _HostileDto(secret);
      logger.db(
        source: 'kv',
        operation: 'read',
        namedArgs: <String, Object?>{'payload': dto},
        value: dto,
        meta: <String, Object?>{'payload': dto},
      );

      final meta = (logger.history.last.additionalData ?? {})['meta'] as Map;
      final namedArgs = meta['namedArgs'] as Map;
      final userMeta = meta['userMeta'] as Map;
      expect(namedArgs['payload'], {'password': '[REDACTED]'});
      expect(meta['value'], {'password': '[REDACTED]'});
      expect(userMeta['payload'], {'password': '[REDACTED]'});
      expect(dto.toJsonCalls, 3);
      expect(dto.toStringCalls, 0);
      expect(meta.toString(), isNot(contains(secret)));
    });

    test('strict mode never formats errors, exceptions, or stack traces', () {
      const secret = 'HOSTILE_DB_DIAGNOSTIC_SECRET';
      final error = _HostileError(secret);
      final exception = _HostileException(secret);
      final stackTrace = _HostileStackTrace(secret);

      logger
        ..db(
          source: 'kv',
          operation: 'write',
          success: false,
          error: error,
          errorStackTrace: stackTrace,
          config: _cfg.copyWith(
            captureMode: DiagnosticCaptureMode.strict,
          ),
        )
        ..db(
          source: 'kv',
          operation: 'write',
          success: false,
          error: exception,
          config: const ISpectDbConfig(
            captureMode: DiagnosticCaptureMode.strict,
          ),
        );

      expect(error.calls, 0);
      expect(exception.calls, 0);
      expect(stackTrace.calls, 0);
      for (final entry in logger.history) {
        final encoded = entry.toText(enableRedaction: false);
        expect(encoded, isNot(contains(secret)));
      }
      expect(
        logger.history.first.stackTrace.toString(),
        JsonValueNormalizer.unprintableValue,
      );
    });

    test('redaction opt-out captures raw DTO values', () {
      const secret = 'violet-raw-db-payload';
      final dto = _HostileDto(secret);
      logger.db(
        source: 'kv',
        operation: 'read',
        namedArgs: <String, Object?>{'payload': dto},
        value: dto,
        meta: <String, Object?>{'payload': dto},
        redact: false,
        config: const ISpectDbConfig(redact: false),
      );

      final meta = (logger.history.last.additionalData ?? {})['meta'] as Map;
      final namedArgs = meta['namedArgs'] as Map;
      final userMeta = meta['userMeta'] as Map;
      expect(namedArgs['payload'], {'password': secret});
      expect(meta['value'], {'password': secret});
      expect(userMeta['payload'], {'password': secret});
      expect(dto.toJsonCalls, 3);
      expect(dto.toStringCalls, 0);
      expect(meta.toString(), contains(secret));
    });

    test('strict mode keeps DTO values opaque without executing formatters',
        () {
      final dto = _HostileDto('STRICT_DB_SECRET');

      logger.db(
        source: 'kv',
        operation: 'read',
        namedArgs: <String, Object?>{'payload': dto},
        value: dto,
        meta: <String, Object?>{'payload': dto},
        config: const ISpectDbConfig(
          captureMode: DiagnosticCaptureMode.strict,
        ),
      );

      final meta = (logger.history.last.additionalData ?? {})['meta'] as Map;
      expect(
        (meta['namedArgs'] as Map)['payload'],
        JsonValueNormalizer.unprintableValue,
      );
      expect(meta['value'], JsonValueNormalizer.unprintableValue);
      expect(
        (meta['userMeta'] as Map)['payload'],
        JsonValueNormalizer.unprintableValue,
      );
      expect(dto.toJsonCalls, 0);
      expect(dto.toStringCalls, 0);
    });

    test('never formats hostile structured keys', () {
      const secret = 'HOSTILE_DB_KEY_SECRET';
      final key = _HostileKey(secret);
      final hostileMap = <Object?, Object?>{key: secret};

      logger.db(
        source: 'kv',
        operation: 'read',
        args: <Object?>[hostileMap],
        namedArgs: <String, Object?>{'payload': hostileMap},
        value: hostileMap,
        meta: <String, Object?>{'payload': hostileMap},
      );

      final entry = logger.history.last;
      final encoded = jsonEncode(
        entry.toExportJson(redactionActive: false),
      );
      expect(key.calls, 0);
      expect(encoded, isNot(contains(secret)));
      expect(encoded, contains(JsonValueNormalizer.unprintableValue));
    });

    test('replaces multi-megabyte fields before active redaction', () {
      final huge = 'ACTIVE_DB_SECRET_${'x' * (3 * 1024 * 1024)}';

      logger.db(
        source: 'kv',
        operation: 'write',
        args: <Object?>[huge],
        namedArgs: <String, Object?>{'payload': huge},
        value: huge,
        meta: <String, Object?>{'payload': huge},
        success: false,
        error: huge,
      );

      final entry = logger.history.last;
      final additionalData = entry.additionalData ?? const {};
      final meta = additionalData['meta'] as Map;
      expect((meta['args'] as List).single, defaultPlaceholder);
      expect(
        (meta['namedArgs'] as Map)['payload'],
        LogExportOutput.truncatedMarker,
      );
      expect(meta['value'], LogExportOutput.truncatedMarker);
      expect(
        (meta['userMeta'] as Map)['payload'],
        LogExportOutput.truncatedMarker,
      );
      expect(meta['dbError'], LogExportOutput.truncatedMarker);
      final encoded = jsonEncode(
        entry.toExportJson(redactionActive: false),
      );
      expect(
        LogExportOutput.utf8Length(encoded),
        lessThan(LogExportOutput.maxRecordBytes),
      );
      expect(encoded, isNot(contains('ACTIVE_DB_SECRET_')));
    });

    test('bounds but preserves ordinary fields with explicit opt-out', () {
      final huge = 'ordinary-db-prefix-${'x' * (3 * 1024 * 1024)}';
      const config = ISpectDbConfig(
        redact: false,
        maxValueLength: LogExportOutput.maxPreparedValueBytes,
        maxArgsLength: LogExportOutput.maxPreparedValueBytes,
      );

      logger.db(
        source: 'kv',
        operation: 'read',
        value: huge,
        redact: false,
        config: config,
      );

      final meta =
          (logger.history.last.additionalData ?? const {})['meta'] as Map;
      final value = meta['value'] as String;
      expect(value, startsWith('ordinary-db-prefix-'));
      expect(value, endsWith(LogExportOutput.truncatedMarker));
      expect(
        LogExportOutput.utf8Length(value),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );

      logger.db(
        source: 'kv',
        operation: 'read',
        args: <Object?>[huge],
        redact: false,
        config: config,
      );
      final argsMeta =
          (logger.history.last.additionalData ?? const {})['meta'] as Map;
      final arg = (argsMeta['args'] as List).first as String;
      expect(arg, startsWith('ordinary-db-prefix-'));
      expect(
        LogExportOutput.utf8Length(arg),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );

      logger.db(
        source: 'kv',
        operation: 'read',
        namedArgs: <String, Object?>{'payload': huge},
        redact: false,
        config: config,
      );
      final namedMeta =
          (logger.history.last.additionalData ?? const {})['meta'] as Map;
      final namedArg = (namedMeta['namedArgs'] as Map)['payload'] as String;
      expect(namedArg, startsWith('ordinary-db-prefix-'));
      expect(
        LogExportOutput.utf8Length(namedArg),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );

      logger.db(
        source: 'kv',
        operation: 'read',
        meta: <String, Object?>{'payload': huge},
        redact: false,
        config: config,
      );
      final userMeta =
          (logger.history.last.additionalData ?? const {})['meta'] as Map;
      final metaValue = (userMeta['userMeta'] as Map)['payload'] as String;
      expect(metaValue, startsWith('ordinary-db-prefix-'));
      expect(
        LogExportOutput.utf8Length(metaValue),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );

      logger.db(
        source: 'kv',
        operation: 'read',
        success: false,
        error: huge,
        redact: false,
        config: config,
      );
      final errorData = logger.history.last.additionalData ?? const {};
      final errorText = errorData['error'] as String;
      expect(errorText, startsWith('ordinary-db-prefix-'));
      expect(
        LogExportOutput.utf8Length(errorText),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('caps large node graphs before database redaction', () {
      final graph = List<Object?>.generate(
        JsonValueNormalizer.defaultMaxNodes * 2,
        (index) => <String, Object?>{'index': index},
      );

      logger.db(
        source: 'kv',
        operation: 'read',
        meta: <String, Object?>{'graph': graph},
        redact: false,
        config: const ISpectDbConfig(redact: false),
      );

      final entry = logger.history.last;
      final encoded = jsonEncode(
        entry.toExportJson(redactionActive: false),
      );
      expect(
        encoded,
        anyOf(
          contains(JsonValueNormalizer.maxNodesReached),
          contains(JsonValueNormalizer.maxCollectionItemsReached),
        ),
      );
      expect(
        LogExportOutput.utf8Length(encoded),
        lessThan(LogExportOutput.maxRecordBytes),
      );
    });

    test('bounds a custom projection before custom-key redaction', () {
      const secretKey = 'tenantSecret';
      final huge = 'CUSTOM_PROJECTION_SECRET_${'x' * (3 * 1024 * 1024)}';
      var projectionCalls = 0;

      final result = logger.dbTraceSync<int>(
        source: 'kv',
        operation: 'read',
        run: () => 7,
        projectResult: (value) {
          projectionCalls++;
          return <String, Object?>{
            secretKey: huge,
            'visible': value,
          };
        },
        redactKeys: const [secretKey],
      );

      expect(result, 7);
      expect(projectionCalls, 1);
      final meta =
          (logger.history.last.additionalData ?? const {})['meta'] as Map;
      final value = meta['value'] as Map;
      expect(value[secretKey], defaultPlaceholder);
      expect(value['visible'], 7);
      expect(
        jsonEncode(value),
        isNot(contains('CUSTOM_PROJECTION_SECRET_')),
      );
    });

    test('replaces oversized SQL before redaction or digesting', () {
      const secret = 'ACTIVE_OVERSIZED_SQL_SECRET';
      final statement = 'SELECT $secret ${'x' * (3 * 1024 * 1024)}';

      logger.db(
        source: 'pg',
        operation: 'query',
        statement: statement,
      );

      final meta =
          (logger.history.single.additionalData ?? const {})['meta'] as Map;
      final encoded = jsonEncode(meta);
      expect(meta['statement'], startsWith('sql:'));
      expect(meta['statementDigest'], startsWith('sql:'));
      expect(encoded, isNot(contains(secret)));
      expect(encoded, isNot(contains('SELECT')));
      expect(
        LogExportOutput.utf8Length(encoded),
        lessThan(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('keeps only a bounded SQL prefix with explicit opt-out', () {
      const prefix = 'SELECT OPT_OUT_SQL_PREFIX ';
      final statement = '$prefix${'x' * (3 * 1024 * 1024)}';

      logger.db(
        source: 'pg',
        operation: 'query',
        statement: statement,
        redact: false,
        config: const ISpectDbConfig(
          redact: false,
          maxStatementLength: LogExportOutput.maxPreparedValueBytes,
        ),
      );

      final meta =
          (logger.history.single.additionalData ?? const {})['meta'] as Map;
      final retained = meta['statement'] as String;
      expect(retained, startsWith(prefix));
      expect(retained, endsWith(LogExportOutput.truncatedMarker));
      expect(
        LogExportOutput.utf8Length(retained),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(meta['statementDigest'], startsWith('sql:'));
    });
  });

  group('sqlDigest', () {
    test('returns null for null or empty input', () {
      expect(DbSqlDigest.compute(null), isNull);
      expect(DbSqlDigest.compute(''), isNull);
    });

    test('does not expose normalized single-quoted strings', () {
      final digest = DbSqlDigest.compute("SELECT * FROM t WHERE a = 'foo'");
      expect(digest, isNotNull);
      expect(digest, startsWith('sql:'));
      expect(digest, isNot(contains('foo')));
      expect(digest, isNot(contains('select')));
    });

    test('does not expose normalized double-quoted strings', () {
      final digest = DbSqlDigest.compute('SELECT * FROM t WHERE a = "bar"');
      expect(digest, isNotNull);
      expect(digest, startsWith('sql:'));
      expect(digest, isNot(contains('bar')));
    });

    test('separates statements that differ only by quoted table', () {
      final users = DbSqlDigest.compute('DELETE FROM "users" WHERE "id" = ?');
      final orders = DbSqlDigest.compute('DELETE FROM "orders" WHERE "id" = ?');

      expect(users, isNot(orders));
    });

    test('normalizes backslash and doubled-quote escapes without leaking', () {
      final digest = DbSqlDigest.compute(
        r"""SELECT 'first\'secret', 'second''secret',
        "third\"secret", "fourth""secret",
        `fifth\`secret`, `sixth``secret` FROM t""",
      );

      expect(digest, isNotNull);
      for (final secret in const [
        'first',
        'second',
        'third',
        'fourth',
        'fifth',
        'sixth',
        'secret',
      ]) {
        expect(digest, isNot(contains(secret)));
      }
    });

    test('strips line and block comments before building the digest', () {
      final digest = DbSqlDigest.compute(
        '''
SELECT * FROM users -- tenantSecret=LINE_SECRET
WHERE id = 1 # tenantSecret=HASH_SECRET
/* tenantSecret=BLOCK_SECRET */
AND active = 1
''',
      );

      expect(digest, isNotNull);
      expect(digest, isNot(contains('tenantsecret')));
      expect(digest, isNot(contains('line_secret')));
      expect(digest, isNot(contains('hash_secret')));
      expect(digest, isNot(contains('block_secret')));
    });

    test('strips nested and unterminated block comments fail closed', () {
      final nested = DbSqlDigest.compute(
        'SELECT 1 /* outer BLOCK_SECRET /* inner INNER_SECRET */ tail */',
      );
      final unterminated = DbSqlDigest.compute(
        'SELECT 1 /* tenantSecret=UNTERMINATED_SECRET',
      );

      expect(nested, isNot(contains('block_secret')));
      expect(nested, isNot(contains('inner_secret')));
      expect(unterminated, isNot(contains('unterminated_secret')));
    });

    test('unterminated quoted values fail closed', () {
      final single = DbSqlDigest.compute("SELECT 'SINGLE_SECRET");
      final dollar = DbSqlDigest.compute(
        r'SELECT $audit$DOLLAR_SECRET',
      );

      expect(single, isNot(contains('single_secret')));
      expect(dollar, isNot(contains('dollar_secret')));
    });

    test('normalizes untagged PostgreSQL dollar-quoted strings opaquely', () {
      final digest = DbSqlDigest.compute(
        r'SELECT * FROM t WHERE payload = $$synthetic-dollar-secret$$',
      );

      expect(digest, isNotNull);
      expect(digest, startsWith('sql:'));
      expect(digest, isNot(contains('synthetic-dollar-secret')));
    });

    test('normalizes tagged multiline PostgreSQL dollar-quoted strings', () {
      final digest = DbSqlDigest.compute(
        r'''SELECT * FROM t
WHERE payload = $audit$synthetic
dollar-secret$audit$''',
      );

      expect(digest, isNotNull);
      expect(digest, startsWith('sql:'));
      expect(digest, isNot(contains('synthetic')));
      expect(digest, isNot(contains('dollar-secret')));
    });

    test('produces a stable hash across PostgreSQL dollar-quoted values', () {
      final digest1 = DbSqlDigest.compute(
        r'SELECT * FROM t WHERE payload = $audit$first-value$audit$',
      );
      final digest2 = DbSqlDigest.compute(
        r'SELECT * FROM t WHERE payload = $audit$second-value$audit$',
      );

      expect(digest1, digest2);
    });

    test('normalizes digits to ?', () {
      final digest = DbSqlDigest.compute('SELECT * FROM t WHERE id = 42');
      expect(digest, isNotNull);
      expect(digest, startsWith('sql:'));
      expect(digest, isNot(contains('42')));
    });

    test('produces stable hash for identical normalized statements', () {
      final digest1 = DbSqlDigest.compute("SELECT * FROM t WHERE a = 'x'");
      final digest2 = DbSqlDigest.compute("SELECT * FROM t WHERE a = 'y'");
      expect(digest1, equals(digest2));
    });

    test('produces different hash for structurally different statements', () {
      final digest1 = DbSqlDigest.compute('SELECT * FROM users');
      final digest2 = DbSqlDigest.compute('DELETE FROM users');
      expect(digest1, isNot(equals(digest2)));
    });

    test('returns an opaque fixed-width fingerprint for long statements', () {
      final longStmt = 'SELECT ${'a, ' * 100}FROM t';
      final digest = DbSqlDigest.compute(longStmt)!;
      expect(digest, matches(RegExp(r'^sql:[0-9a-f]{1,8}$')));
      expect(digest, isNot(contains('SELECT')));
    });

    test('does not expose unquoted hexadecimal database keys', () {
      const secret = 'DEADBEEF';
      final digest = DbSqlDigest.compute('PRAGMA key=0x$secret');

      expect(digest, startsWith('sql:'));
      expect(digest, isNot(contains(secret.toLowerCase())));
      expect(digest, isNot(contains('pragma')));
    });

    test('fails closed before digesting multi-megabyte direct input', () {
      final first = DbSqlDigest.compute(
        'DIRECT_DIGEST_SECRET_A_${'a' * (3 * 1024 * 1024)}',
      );
      final second = DbSqlDigest.compute(
        'DIRECT_DIGEST_SECRET_B_${'b' * (3 * 1024 * 1024)}',
      );

      expect(first, startsWith('sql:'));
      expect(first, second);
      expect(first, isNot(contains('direct_digest_secret')));
    });
  });

  group('sampleRate', () {
    test('sampleRate 0.0 drops all logs', () {
      logger.db(
        source: 'test',
        operation: 'query',
        config: const ISpectDbConfig(sampleRate: 0),
      );
      expect(logger.history, isEmpty);
    });

    test('sampleRate 1.0 logs everything', () {
      for (var i = 0; i < 10; i++) {
        logger.db(
          source: 'test',
          operation: 'query',
          config: const ISpectDbConfig(sampleRate: 1),
        );
      }
      expect(logger.history.length, 10);
    });

    test('sampleRate null logs everything', () {
      for (var i = 0; i < 5; i++) {
        logger.db(source: 'test', operation: 'query');
      }
      expect(logger.history.length, 5);
    });

    test('per-call sample override takes precedence', () {
      logger.db(
        source: 'test',
        operation: 'query',
        sample: 0,
        config: const ISpectDbConfig(sampleRate: 1),
      );
      expect(logger.history, isEmpty);
    });

    test('dbTrace with sampleRate 0 still executes the callback', () async {
      var executed = false;
      await logger.dbTrace(
        source: 'test',
        operation: 'query',
        config: const ISpectDbConfig(sampleRate: 0),
        run: () async {
          executed = true;
        },
      );
      expect(executed, isTrue);
      expect(logger.history, isEmpty);
    });
  });

  group('dbTrace', () {
    test('captures error and stack trace', () async {
      Future<void> failing() async => Future<void>.error(StateError('x'));
      try {
        await logger.dbTrace<void>(
          source: 'kv',
          operation: 'write',
          key: 'a',
          run: () async => failing(),
          config: _cfg,
        );
        fail('should throw');
      } catch (_) {
        // expected
      }

      final entry = logger.history.last;
      expect(entry.key, 'db-error');
      expect(entry.stackTrace, isNotNull);
      final add = entry.additionalData ?? {};
      expect(add['success'], isFalse);
      expect(add['key'], defaultPlaceholder);
    });

    test('projects result and sets items count', () async {
      final res = await logger.dbTrace<List<Map<String, Object?>>>(
        source: 'sqflite',
        operation: 'query',
        table: 't',
        run: () async => [
          {'id': 1},
          {'id': 2},
        ],
        projectResult: (rows) => {'rows': rows.length},
      );
      expect(res.length, 2);
      final entry = logger.history.last;
      final add = entry.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      expect(meta['items'], 2);
      // Projected value is stored as-is (Map) in meta, not stringified.
      final projectedValue = meta['value'] as Map<String, dynamic>;
      expect(projectedValue['rows'], 2);
    });

    test('contains a hostile async result length getter', () async {
      final hostile = _ThrowingLengthList<int>([1, 2]);

      final result = await logger.dbTrace<_ThrowingLengthList<int>>(
        source: 'sqflite',
        operation: 'query',
        run: () async => hostile,
      );

      expect(identical(result, hostile), isTrue);
      expect(hostile.lengthCalls, 1);
      expect(logger.history, hasLength(1));
    });

    test('contains a hostile sync result length getter', () {
      final hostile = _ThrowingLengthList<int>([1, 2]);

      final result = logger.dbTraceSync<_ThrowingLengthList<int>>(
        source: 'sqflite',
        operation: 'query',
        run: () => hostile,
      );

      expect(identical(result, hostile), isTrue);
      expect(hostile.lengthCalls, 1);
      expect(logger.history, hasLength(1));
    });

    test('runtime disablement skips async projection and item inspection',
        () async {
      final hostile = _ThrowingLengthList<int>([1, 2]);
      var projectionCalls = 0;

      final result = await logger.dbTrace<_ThrowingLengthList<int>>(
        source: 'sqflite',
        operation: 'query',
        run: () async {
          logger.disable();
          return hostile;
        },
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );

      expect(identical(result, hostile), isTrue);
      expect(hostile.lengthCalls, 0);
      expect(projectionCalls, 0);
      expect(logger.history, isEmpty);
    });

    test('runtime disposal skips sync projection and item inspection',
        () async {
      final hostile = _ThrowingLengthList<int>([1, 2]);
      var projectionCalls = 0;
      late Future<void> disposal;

      final result = logger.dbTraceSync<_ThrowingLengthList<int>>(
        source: 'sqflite',
        operation: 'query',
        run: () {
          disposal = logger.dispose();
          return hostile;
        },
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );
      await disposal;

      expect(identical(result, hostile), isTrue);
      expect(hostile.lengthCalls, 0);
      expect(projectionCalls, 0);
      expect(logger.history, isEmpty);
    });

    test('length-triggered disablement skips async result projection',
        () async {
      final hostile = _DisablingLengthList<int>([1, 2], logger.disable);
      var projectionCalls = 0;

      final result = await logger.dbTrace<_DisablingLengthList<int>>(
        source: 'sqflite',
        operation: 'query',
        run: () async => hostile,
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );

      expect(identical(result, hostile), isTrue);
      expect(hostile.lengthCalls, 1);
      expect(projectionCalls, 0);
      expect(logger.history, isEmpty);
    });

    test('length-triggered disablement skips sync result projection', () {
      final hostile = _DisablingLengthList<int>([1, 2], logger.disable);
      var projectionCalls = 0;

      final result = logger.dbTraceSync<_DisablingLengthList<int>>(
        source: 'sqflite',
        operation: 'query',
        run: () => hostile,
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );

      expect(identical(result, hostile), isTrue);
      expect(hostile.lengthCalls, 1);
      expect(projectionCalls, 0);
      expect(logger.history, isEmpty);
    });

    test('records duration', () async {
      await logger.dbTrace(
        source: 'test',
        operation: 'query',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        },
      );

      final add = logger.history.last.additionalData ?? {};
      expect(add['durationMs'], isA<int>());
      expect(add['durationMs'] as int, greaterThanOrEqualTo(1));
    });

    test('logs entry even when projectResult throws', () async {
      final result = await logger.dbTrace<int>(
        source: 'sqflite',
        operation: 'query',
        run: () async => 42,
        projectResult: (_) => throw const FormatException('bad projection'),
      );

      expect(result, 42);
      expect(logger.history, hasLength(1));
      final trace = logger.history.single.additionalData!;
      expect(trace[TraceKeys.operation], 'query');
      expect(
        (trace[TraceKeys.meta] as Map<String, Object?>)['value'],
        isNull,
      );

      logger.db(source: 'test', operation: 'get');
      expect(logger.history, hasLength(2));
    });

    test('captures synchronous exception in run callback', () async {
      try {
        await logger.dbTrace<int>(
          source: 'db',
          operation: 'query',
          run: () => throw StateError('sync-boom'),
        );
        fail('should throw');
      } catch (_) {
        // expected
      }

      final entry = logger.history.last;
      expect(entry.key, 'db-error');
      final add = entry.additionalData ?? {};
      expect(add['error'], contains('sync-boom'));
    });

    test('passes sizeBytes and cacheHit through', () async {
      await logger.dbTrace(
        source: 'cache',
        operation: 'get',
        key: 'user:1',
        sizeBytes: 512,
        cacheHit: true,
        run: () async => 'cached-value',
      );

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      expect(meta['sizeBytes'], 512);
      expect(meta['cacheHit'], isTrue);
    });
  });

  group('dbStart / dbEnd', () {
    test('disabled logger returns an inert token without retaining inputs', () {
      logger.configure(options: ISpectLoggerOptions(enabled: false));

      final token = logger.dbStart(
        source: 'tenantSecret=SOURCE_SECRET',
        operation: 'tenantSecret=OPERATION_SECRET',
        statement: 'tenantSecret=STATEMENT_SECRET',
        target: 'tenantSecret=TARGET_SECRET',
        table: 'tenantSecret=TABLE_SECRET',
        key: 'tenantSecret=KEY_SECRET',
        args: const ['tenantSecret=ARG_SECRET'],
        namedArgs: const {'tenantSecret': 'NAMED_SECRET'},
        meta: const {'tenantSecret': 'META_SECRET'},
        transactionId: 'tenantSecret=TRANSACTION_SECRET',
      );

      expect(token.source, isNull);
      expect(token.operation, isNull);
      expect(token.statement, isNull);
      expect(token.target, isNull);
      expect(token.table, isNull);
      expect(token.key, isNull);
      expect(token.args, isNull);
      expect(token.namedArgs, isNull);
      expect(token.meta, isNull);
      expect(token.transactionId, isNull);
      expect(token.elapsed, Duration.zero);

      logger.dbEnd(token);
      expect(logger.history, isEmpty);
    });

    test('logs with measured duration', () async {
      final token = logger.dbStart(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT 1',
        table: 'users',
      );

      await Future<void>.delayed(const Duration(milliseconds: 5));

      logger.dbEnd(
        token,
        value: 'result',
        success: true,
        items: 1,
      );

      expect(logger.history, isNotEmpty);
      final add = logger.history.last.additionalData ?? {};
      expect(add['source'], 'sqflite');
      expect(add['operation'], 'query');
      expect(add['target'], 'users');
      expect(add['durationMs'], isA<int>());
      expect(add['durationMs'] as int, greaterThanOrEqualTo(1));
      final meta = add['meta'] as Map<String, dynamic>;
      expect(meta['items'], 1);
    });

    test('defaults source and operation to custom', () {
      final token = logger.dbStart();
      logger.dbEnd(token);

      final add = logger.history.last.additionalData ?? {};
      expect(add['source'], dbDefaultSource);
      expect(add['operation'], dbDefaultOperation);
    });

    test('merges token meta with dbEnd meta', () {
      final token = logger.dbStart(
        source: 'kv',
        operation: 'write',
        meta: {'a': '1'},
      );
      logger.dbEnd(token, meta: {'b': '2'});

      final add = logger.history.last.additionalData ?? {};
      // The merged meta from token+dbEnd is passed through _preprocessDb
      // and then to trace() as meta, which puts it under TraceKeys.meta.
      final meta = add['meta'] as Map<String, dynamic>;
      // User meta is nested under 'userMeta' inside the DB meta map.
      final userMeta = meta['userMeta'] as Map<String, dynamic>;
      expect(userMeta['a'], '1');
      expect(userMeta['b'], '2');
    });

    test('bounds merged metadata without formatting hostile keys', () {
      const secret = 'HOSTILE_DB_END_KEY_SECRET';
      final key = _HostileKey(secret);
      final hostileMap = <Object?, Object?>{key: secret};
      final token = logger.dbStart(
        source: 'kv',
        operation: 'write',
        meta: <String, Object?>{'start': hostileMap},
      );

      logger.dbEnd(
        token,
        meta: <String, Object?>{'end': hostileMap},
      );

      final encoded = jsonEncode(
        logger.history.last.toExportJson(redactionActive: false),
      );
      expect(key.calls, 0);
      expect(encoded, isNot(contains(secret)));
      expect(encoded, contains(JsonValueNormalizer.unprintableValue));
    });

    test('infers error from error parameter', () {
      final token = logger.dbStart(source: 'db', operation: 'write');
      logger.dbEnd(token, error: 'connection lost');

      final entry = logger.history.last;
      expect(entry.key, 'db-error');
      final add = entry.additionalData ?? {};
      expect(add['success'], isFalse);
      expect(add['error'], 'connection lost');
    });

    test('uses monotonic Stopwatch for duration', () async {
      final token = logger.dbStart(source: 'db', operation: 'read');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      logger.dbEnd(token, success: true);

      final add = logger.history.last.additionalData ?? {};
      final durationMs = add['durationMs'] as int;
      expect(durationMs, greaterThanOrEqualTo(5));
    });

    test('passes sizeBytes and cacheHit through dbEnd', () {
      final token = logger.dbStart(source: 'file', operation: 'read');
      logger.dbEnd(
        token,
        success: true,
        sizeBytes: 4096,
        cacheHit: false,
      );

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'] as Map<String, dynamic>;
      expect(meta['sizeBytes'], 4096);
      expect(meta['cacheHit'], isFalse);
    });

    test('runtime disablement still stops manual span timing', () async {
      final token = logger.dbStart(source: 'db', operation: 'read');
      await Future<void>.delayed(const Duration(milliseconds: 2));

      logger
        ..disable()
        ..dbEnd(token);
      final stoppedAt = token.elapsed;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(token.elapsed, stoppedAt);
      expect(logger.history, isEmpty);

      logger
        ..enable()
        ..dbEnd(token);
      expect(logger.history, hasLength(1));
    });
  });

  group('dbTransaction', () {
    test('transaction markers with shared transactionId', () async {
      await logger.dbTransaction(
        source: 'sqflite',
        logMarkers: true,
        run: () async {
          await logger.dbTrace(
            source: 'sqflite',
            operation: 'update',
            statement: 'UPDATE t SET a=?',
            args: [1],
            run: () async => 1,
          );
        },
      );

      final txLogs = logger.history.where(
        (e) =>
            (e.additionalData?['operation'] as String?)
                ?.startsWith('transaction-') ??
            false,
      );
      expect(txLogs.length, greaterThanOrEqualTo(2));
      final ids = txLogs
          .map((e) => e.additionalData?['transactionId'])
          .whereType<String>()
          .toSet();
      expect(ids.length, 1);
    });

    test('does not commit after rollback', () async {
      await expectLater(
        () => logger.dbTransaction(
          source: 'sqflite',
          logMarkers: true,
          run: () async => throw StateError('fail'),
        ),
        throwsA(isA<StateError>()),
      );

      final txLogs = logger.history.where(
        (e) =>
            (e.additionalData?['operation'] as String?)
                ?.startsWith('transaction-') ??
            false,
      );
      final ops = txLogs.map((e) => e.additionalData?['operation']).toList();
      expect(ops, contains('transaction-begin'));
      expect(ops, contains('transaction-rollback'));
      expect(ops, isNot(contains('transaction-commit')));
    });

    test('nested transaction replaces outer transaction ID', () async {
      await logger.dbTransaction(
        source: 'sqflite',
        logMarkers: true,
        run: () async {
          logger.db(source: 'sqflite', operation: 'insert');

          await logger.dbTransaction(
            source: 'sqflite',
            logMarkers: true,
            run: () async {
              logger.db(source: 'sqflite', operation: 'update');
            },
          );

          logger.db(source: 'sqflite', operation: 'delete');
        },
      );

      // traceTransaction injects transactionId via its own zone key,
      // which trace() reads into additionalData['transactionId'].
      final insertLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'insert',
      );
      final updateLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'update',
      );
      final deleteLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'delete',
      );

      final outerTxnId = insertLog.additionalData?['transactionId'] as String?;
      final innerTxnId = updateLog.additionalData?['transactionId'] as String?;

      // Inner and outer have different IDs.
      expect(outerTxnId, isNotNull);
      expect(innerTxnId, isNotNull);
      expect(outerTxnId, isNot(equals(innerTxnId)));

      // Outer zone restores after inner completes.
      expect(deleteLog.additionalData?['transactionId'], outerTxnId);
    });

    test('succeeds without markers and emits no transaction logs', () async {
      final result = await logger.dbTransaction(
        source: 'sqflite',
        logMarkers: false,
        run: () async {
          logger.db(source: 'sqflite', operation: 'insert');
          return 42;
        },
      );

      expect(result, 42);

      final txLogs = logger.history.where(
        (e) =>
            (e.additionalData?['operation'] as String?)
                ?.startsWith('transaction-') ??
            false,
      );
      expect(txLogs, isEmpty);

      // The inner db call still got a transactionId.
      final insertLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'insert',
      );
      expect(insertLog.additionalData?['transactionId'], isNotNull);
    });

    test('propagates transactionId to nested db calls via Zone', () async {
      await logger.dbTransaction(
        source: 'sqflite',
        logMarkers: true,
        run: () async {
          logger.db(source: 'sqflite', operation: 'insert');
        },
      );

      // traceTransaction injects its own zone-based transactionId,
      // which trace() reads and places in additionalData.
      final insertLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'insert',
      );
      final txnId = insertLog.additionalData?['transactionId'] as String?;
      expect(txnId, isNotNull);
      expect(txnId!.length, 16);
    });
  });

  group('ISpectDbConfig', () {
    test('redactKeys is a Set', () {
      const config = ISpectDbConfig(redactKeys: {'a', 'b'});
      expect(config.redactKeys, containsAll(['a', 'b']));
    });

    test('assert rejects sampleRate outside 0..1', () {
      expect(
        () => ISpectDbConfig(sampleRate: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ISpectDbConfig(sampleRate: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('toString includes all field values', () {
      const config = ISpectDbConfig(
        sampleRate: 0.5,
        maxValueLength: 100,
      );
      final str = config.toString();
      expect(str, contains('ISpectDbConfig('));
      expect(str, contains('sampleRate: 0.5'));
      expect(str, contains('redact: true'));
      expect(str, contains('maxValueLength: 100'));
    });

    test('copyWith preserves unchanged fields', () {
      const original = ISpectDbConfig(
        sampleRate: 0.5,
        redact: false,
        maxValueLength: 100,
        attachStackOnError: true,
      );
      final copied = original.copyWith(maxValueLength: 200);
      expect(copied.sampleRate, 0.5);
      expect(copied.redact, isFalse);
      expect(copied.maxValueLength, 200);
      expect(copied.attachStackOnError, isTrue);
    });

    test('copyWith resets nullable fields to null', () {
      const original = ISpectDbConfig(
        sampleRate: 0.5,
        slowThreshold: Duration(seconds: 1),
      );
      final reset = original.copyWith(
        sampleRate: null,
        slowThreshold: null,
      );
      expect(reset.sampleRate, isNull);
      expect(reset.slowThreshold, isNull);
    });
  });

  group('ISpectDbTxn', () {
    test('returns null outside of transaction zone', () {
      expect(ISpectDbTxn.currentTransactionId(), isNull);
    });

    test('returns txnId inside transaction zone', () async {
      String? captured;
      await ISpectDbTxn.runInTransactionZone('txn-123', () async {
        captured = ISpectDbTxn.currentTransactionId();
      });
      expect(captured, 'txn-123');
    });
  });

  group('ISpectDbToken', () {
    test('toString includes source and operation', () {
      final token = logger.dbStart(source: 'sqflite', operation: 'query');
      final str = token.toString();
      expect(str, contains('ISpectDbToken('));
      expect(str, contains('source: sqflite'));
      expect(str, contains('operation: query'));
      expect(str, contains('elapsed:'));
    });

    test('stopTiming is idempotent — elapsed stays stable', () async {
      final token = logger.dbStart(source: 'db', operation: 'read');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      token.stopTiming();
      final first = token.elapsed;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      token.stopTiming();
      final second = token.elapsed;
      expect(first, equals(second));
    });
  });

  group('genId', () {
    test('produces 16-char hex string', () {
      final id = ISpectDbCore.genId();
      expect(id.length, 16);
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(id), isTrue);
    });

    test('produces unique values', () {
      final ids = List.generate(100, (_) => ISpectDbCore.genId()).toSet();
      expect(ids.length, 100);
    });
  });

  group('buildMessage', () {
    test('includes all fields', () {
      final msg = DbMessageFormatter.build(
        operation: 'query',
        table: 'users',
        target: 'primary',
        key: 'id',
        items: 5,
        affected: 3,
        sizeBytes: 2048,
        cacheHit: true,
        duration: const Duration(milliseconds: 42),
        success: true,
        value: 'data',
      );
      expect(
        msg,
        isNot(contains('[sqflite]')),
        reason: 'source belongs to entry header, not body',
      );
      expect(msg, startsWith('query'));
      expect(msg, contains('users → primary'));
      expect(msg, contains('Key: id'));
      expect(msg, contains('Items: 5'));
      expect(msg, contains('Affected: 3'));
      expect(msg, contains('Size: 2.0 KB'));
      expect(msg, contains('Cache: HIT'));
      expect(msg, contains('Duration: 42ms'));
      expect(msg, contains('Success: true'));
      expect(msg, contains('Value: data'));
    });

    test('formats cache miss', () {
      final msg = DbMessageFormatter.build(
        operation: 'get',
        cacheHit: false,
      );
      expect(msg, contains('Cache: MISS'));
    });

    test('formats bytes correctly', () {
      final small = DbMessageFormatter.build(
        operation: 'write',
        sizeBytes: 500,
      );
      expect(small, contains('Size: 500 B'));

      final kb = DbMessageFormatter.build(
        operation: 'write',
        sizeBytes: 1536,
      );
      expect(kb, contains('Size: 1.5 KB'));

      final mb = DbMessageFormatter.build(
        operation: 'write',
        sizeBytes: 2 * 1024 * 1024,
      );
      expect(mb, contains('Size: 2.0 MB'));

      final gb = DbMessageFormatter.build(
        operation: 'write',
        sizeBytes: 3 * 1024 * 1024 * 1024,
      );
      expect(gb, contains('Size: 3.0 GB'));
    });

    test('formats zero bytes', () {
      final msg = DbMessageFormatter.build(
        operation: 'write',
        sizeBytes: 0,
      );
      expect(msg, contains('Size: 0 B'));
    });

    test('shows table only when target is null', () {
      final msg = DbMessageFormatter.build(
        operation: 'query',
        table: 'users',
      );
      expect(msg, equals('query users'));
      expect(msg, isNot(contains('→')));
    });

    test('shows target only when table is null', () {
      final msg = DbMessageFormatter.build(
        operation: 'read',
        target: '/data/config.json',
      );
      expect(msg, equals('read /data/config.json'));
      expect(msg, isNot(contains('→')));
    });

    test('shows table → target when both present', () {
      final msg = DbMessageFormatter.build(
        operation: 'query',
        table: 'users',
        target: 'idx_email',
      );
      expect(msg, contains('users → idx_email'));
    });

    test('minimal message with only required fields', () {
      final msg = DbMessageFormatter.build(
        operation: 'get',
      );
      expect(msg, equals('get'));
    });
  });

  group('redactPositionalArgs (direct)', () {
    test('redacts args even when statement has no sensitive columns', () {
      final args = ISpectDbCore.redactPositionalArgs(
        [1, 'visible', true],
        ['password', 'token'],
        'SELECT * FROM orders WHERE total > ?',
      );
      expect(args, ['[REDACTED]', '[REDACTED]', '[REDACTED]']);
    });

    test('redacts all args when statement mentions a sensitive column', () {
      final args = ISpectDbCore.redactPositionalArgs(
        ['secret', 42],
        ['password', 'token'],
        'INSERT INTO users (name, password) VALUES (?, ?)',
      );
      expect(args, ['[REDACTED]', '[REDACTED]']);
    });

    test('redacts all args when statement is null (precaution)', () {
      final args = ISpectDbCore.redactPositionalArgs(
        ['a', 'b'],
        ['password'],
        null,
      );
      expect(args, ['[REDACTED]', '[REDACTED]']);
    });

    test('returns empty list as-is', () {
      final args = ISpectDbCore.redactPositionalArgs(
        [],
        ['password'],
        'SELECT 1',
      );
      expect(args, isEmpty);
    });

    test('preserves null elements in redacted list', () {
      final args = ISpectDbCore.redactPositionalArgs(
        [null, 'secret'],
        ['password'],
        null,
      );
      expect(args, [null, '[REDACTED]']);
    });
  });

  group('truncateValue', () {
    test('returns null for null input', () {
      expect(ISpectDbCore.truncateValue(null, 10), isNull);
    });

    test('truncates long strings', () {
      final result = ISpectDbCore.truncateValue('a' * 100, 10);
      expect(result, isA<String>());
      expect((result! as String).length, lessThanOrEqualTo(15));
    });

    test('returns non-string values unchanged', () {
      expect(ISpectDbCore.truncateValue(42, 5), 42);
      expect(ISpectDbCore.truncateValue(true, 5), true);
      expect(
        ISpectDbCore.truncateValue(['a', 'b'], 5),
        ['a', 'b'],
      );
    });
  });

  group('clean', () {
    test('removes null and empty-string values', () {
      final result = ISpectDbCore.clean({
        'keep': 'value',
        'removeNull': null,
        'removeEmpty': '',
        'keepZero': 0,
        'keepFalse': false,
      });
      expect(result, containsPair('keep', 'value'));
      expect(result, containsPair('keepZero', 0));
      expect(result, containsPair('keepFalse', false));
      expect(result.containsKey('removeNull'), isFalse);
      expect(result.containsKey('removeEmpty'), isFalse);
    });
  });

  group('resource limits', () {
    test('config copyWith preserves and replaces a local policy', () {
      const original = ISpectDbConfig(
        resourceLimits: DiagnosticResourceLimits.constrained,
      );

      expect(
        original.copyWith().resourceLimits,
        same(DiagnosticResourceLimits.constrained),
      );
      expect(
        original
            .copyWith(resourceLimits: DiagnosticResourceLimits.extended)
            .resourceLimits,
        same(DiagnosticResourceLimits.extended),
      );
      expect(
        original
            .copyWith(
              resourceLimits: DiagnosticResourceLimits.extended,
              inheritResourceLimits: true,
            )
            .resourceLimits,
        isNull,
      );
    });

    test('local database scalar budget bounds trace fields', () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxDatabaseScalarBytes: 64,
        maxDatabaseDiagnosticsBytes: 128,
        maxDatabaseMetadataBytes: 256,
      );

      logger.db(
        source: 's' * 1024,
        operation: 'query',
        config: ISpectDbConfig(
          redact: false,
          resourceLimits: limits,
        ),
      );

      final source = logger.history.last.additionalData?[TraceKeys.source];
      expect(source, isA<String>());
      expect(
        LogExportOutput.utf8Length(source! as String),
        lessThanOrEqualTo(64),
      );
      expect(source, contains(LogExportOutput.truncatedMarker));
    });
  });
}
