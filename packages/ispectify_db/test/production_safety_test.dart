import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:test/test.dart';

final class _HostileDiagnostic {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    throw StateError('disabled diagnostics must not be serialized');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('disabled diagnostics must not be formatted');
  }
}

final class _HostileStackTrace implements StackTrace {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('disabled stack traces must not be formatted');
  }
}

void main() {
  test(
    'direct database logging retains nothing when ISPECT_ENABLED is omitted',
    () {
      final logger = ISpectLogger();
      final token = logger.dbStart(
        source: 'audit',
        operation: 'read',
        statement: 'SELECT synthetic-private-value',
        key: 'customer@example.invalid',
        meta: const {'token': 'synthetic-private-value'},
      );

      logger
        ..db(
          source: 'audit',
          operation: 'read',
          key: 'customer@example.invalid',
          value: 'synthetic-private-value',
        )
        ..dbEnd(token);

      expect(logger.history, isEmpty);
      expect(token.source, isNull);
      expect(token.operation, isNull);
      expect(token.statement, isNull);
      expect(token.key, isNull);
      expect(token.meta, isNull);
      expect(token.elapsed, Duration.zero);
    },
    skip: kISpectEnabled
        ? 'This assertion is only applicable to disabled builds.'
        : false,
  );

  test(
    'disabled DB entrypoints do not inspect or retain hostile inputs',
    () async {
      final logger = ISpectLogger();
      final diagnostic = _HostileDiagnostic();
      final stackTrace = _HostileStackTrace();
      var asyncRuns = 0;
      var syncRuns = 0;
      var transactionRuns = 0;
      var projectionCalls = 0;

      logger.db(
        source: 'disabled-source',
        operation: 'disabled-operation',
        statement: 'SELECT disabled-statement',
        value: diagnostic,
        projection: diagnostic,
        args: <Object?>[diagnostic],
        namedArgs: <String, Object?>{'password': diagnostic},
        meta: <String, Object?>{'password': diagnostic},
        error: diagnostic,
        errorStackTrace: stackTrace,
      );

      final asyncResult = await logger.dbTrace<_HostileDiagnostic>(
        source: 'disabled-source',
        operation: 'disabled-operation',
        statement: 'SELECT disabled-async-statement',
        args: <Object?>[diagnostic],
        meta: <String, Object?>{'password': diagnostic},
        run: () async {
          asyncRuns++;
          return diagnostic;
        },
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );
      final syncResult = logger.dbTraceSync<_HostileDiagnostic>(
        source: 'disabled-source',
        operation: 'disabled-operation',
        statement: 'SELECT disabled-sync-statement',
        args: <Object?>[diagnostic],
        meta: <String, Object?>{'password': diagnostic},
        run: () {
          syncRuns++;
          return diagnostic;
        },
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );

      final token = logger.dbStart(
        source: 'disabled-source',
        operation: 'disabled-operation',
        statement: 'SELECT disabled-token-statement',
        args: <Object?>[diagnostic],
        meta: <String, Object?>{'password': diagnostic},
      );
      logger.dbEnd(
        token,
        value: diagnostic,
        error: diagnostic,
        meta: <String, Object?>{'password': diagnostic},
      );

      final transactionResult = await logger.dbTransaction<int>(
        source: 'disabled-source',
        meta: <String, Object?>{'password': diagnostic},
        logMarkers: true,
        run: () async {
          transactionRuns++;
          expect(ISpectDbTxn.currentTransactionId(), isNull);
          return 7;
        },
      );

      expect(asyncResult, same(diagnostic));
      expect(syncResult, same(diagnostic));
      expect(transactionResult, 7);
      expect(asyncRuns, 1);
      expect(syncRuns, 1);
      expect(transactionRuns, 1);
      expect(projectionCalls, 0);
      expect(diagnostic.toJsonCalls, 0);
      expect(diagnostic.toStringCalls, 0);
      expect(stackTrace.calls, 0);
      expect(token.source, isNull);
      expect(token.operation, isNull);
      expect(token.statement, isNull);
      expect(token.args, isNull);
      expect(token.meta, isNull);
      expect(logger.history, isEmpty);
    },
    skip: kISpectEnabled
        ? 'This assertion is only applicable to disabled builds.'
        : false,
  );
}
