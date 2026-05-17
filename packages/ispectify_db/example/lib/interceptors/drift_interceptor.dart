/// Ready-to-copy interceptor for **drift** (formerly moor).
///
/// Uses drift's native [QueryInterceptor] — the idiomatic way
/// to hook into all SQL operations.
///
/// ## Setup
/// ```dart
/// import 'package:drift/drift.dart';
/// import 'package:drift/native.dart';
///
/// final executor = NativeDatabase.memory().interceptWith(
///   ISpectDriftInterceptor(logger: ISpectLogger()),
/// );
///
/// @DriftDatabase(tables: [...])
/// class AppDatabase extends _$AppDatabase {
///   AppDatabase() : super(executor);
/// }
/// ```
library;

import 'package:drift/drift.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Native drift [QueryInterceptor] that logs all SQL operations
/// via `ispectify_db`.
///
/// Plug it in with `executor.interceptWith(...)` — no wrapping needed.
/// Drift routes every query through the interceptor automatically.
final class ISpectDriftInterceptor extends QueryInterceptor {
  ISpectDriftInterceptor({
    required ISpectLogger logger,
    String source = defaultSource,
    this.config = const ISpectDbConfig(),
  })  : _logger = logger,
        _source = source;

  final ISpectLogger _logger;
  final String _source;
  final ISpectDbConfig config;

  /// Default source identifier.
  static const defaultSource = 'drift';

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'select',
        statement: statement,
        args: args,
        run: () => executor.runSelect(statement, args),
        projectResult: (rows) => {'rows': rows.length},
        config: config,
      );

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'insert',
        statement: statement,
        args: args,
        run: () => executor.runInsert(statement, args),
        projectResult: (id) => {'lastInsertId': id},
        config: config,
      );

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'update',
        statement: statement,
        args: args,
        run: () => executor.runUpdate(statement, args),
        projectResult: (n) => {'affected': n},
        config: config,
      );

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'delete',
        statement: statement,
        args: args,
        run: () => executor.runDelete(statement, args),
        projectResult: (n) => {'affected': n},
        config: config,
      );

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'execute',
        statement: statement,
        args: args,
        run: () => executor.runCustom(statement, args),
        config: config,
      );

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'batch',
        meta: {'batchSize': statements.statements.length},
        run: () => executor.runBatched(statements),
        projectResult: (_) => {'statements': statements.statements.length},
        config: config,
      );
}
