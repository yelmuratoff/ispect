/// Ready-to-copy interceptor for **drift** (formerly moor).
///
/// Implements [QueryExecutor] — plug it in as a wrapping executor.
///
/// ## Setup
/// ```dart
/// @DriftDatabase(tables: [...])
/// class AppDatabase extends _$AppDatabase {
///   AppDatabase()
///       : super(ISpectDriftExecutor(
///           delegate: NativeDatabase.memory(),
///           logger: ISpectLogger(),
///         ));
/// }
/// ```
library;

import 'package:drift/drift.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Wraps a drift [QueryExecutor] with `ispectify_db` logging.
///
/// Transparently logs every SQL statement drift generates,
/// including batched and transactional writes.
final class ISpectDriftExecutor implements QueryExecutor {
  const ISpectDriftExecutor({
    required QueryExecutor delegate,
    required ISpectLogger logger,
    String source = defaultSource,
  })  : _executor = delegate,
        _logger = logger,
        _source = source;

  final QueryExecutor _executor;
  final ISpectLogger _logger;
  final String _source;

  /// Default source identifier.
  static const defaultSource = 'drift';

  @override
  SqlDialect get dialect => _executor.dialect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) =>
      _executor.ensureOpen(user);

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'select',
        statement: statement,
        args: args,
        run: () => _executor.runSelect(statement, args),
        projectResult: (rows) => {'rows': rows.length},
      );

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _logger.dbTrace(
        source: _source,
        operation: 'insert',
        statement: statement,
        args: args,
        run: () => _executor.runInsert(statement, args),
        projectResult: (id) => {'lastInsertId': id},
      );

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _logger.dbTrace(
        source: _source,
        operation: 'update',
        statement: statement,
        args: args,
        run: () => _executor.runUpdate(statement, args),
        projectResult: (n) => {'affected': n},
      );

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _logger.dbTrace(
        source: _source,
        operation: 'delete',
        statement: statement,
        args: args,
        run: () => _executor.runDelete(statement, args),
        projectResult: (n) => {'affected': n},
      );

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _logger.dbTrace(
        source: _source,
        operation: 'execute',
        statement: statement,
        args: args,
        run: () => _executor.runCustom(statement, args),
      );

  @override
  Future<void> runBatched(BatchedStatements statements) => _logger.dbTrace(
        source: _source,
        operation: 'batch',
        run: () => _executor.runBatched(statements),
        meta: {'batchSize': statements.statements.length},
        projectResult: (_) => {'statements': statements.statements.length},
      );

  @override
  TransactionExecutor beginTransaction() => _ISpectDriftTxnExecutor(
        delegate: _executor.beginTransaction(),
        logger: _logger,
        source: _source,
      );

  @override
  QueryExecutor beginExclusive() => ISpectDriftExecutor(
        delegate: _executor.beginExclusive(),
        logger: _logger,
        source: _source,
      );

  @override
  Future<void> close() => _executor.close();
}

/// Transaction executor that preserves logging through transaction scope.
final class _ISpectDriftTxnExecutor extends ISpectDriftExecutor
    implements TransactionExecutor {
  _ISpectDriftTxnExecutor({
    required TransactionExecutor delegate,
    required super.logger,
    required super.source,
  })  : _txn = delegate,
        super(delegate: delegate);

  final TransactionExecutor _txn;

  @override
  bool get supportsNestedTransactions => _txn.supportsNestedTransactions;

  @override
  Future<void> send() => _txn.send();

  @override
  Future<void> rollback() => _txn.rollback();
}
