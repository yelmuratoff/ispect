/// Ready-to-copy interceptor for **sqflite** / **sqflite_common**.
///
/// Implements the full [Database] interface — drop-in replacement.
///
/// ## Setup
/// ```dart
/// final db = await openDatabase('app.db');
/// final traced = ISpectSqfliteDatabase(delegate: db, logger: logger);
/// final rows = await traced.rawQuery('SELECT * FROM users');
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Wraps a sqflite [Database] with `ispectify_db` logging.
///
/// Raw methods ([rawQuery], [rawInsert], …) and convenience methods
/// ([query], [insert], …) are both traced independently.
/// Transaction inner calls carry a shared `transactionId`.
final class ISpectSqfliteDatabase implements Database {
  const ISpectSqfliteDatabase({
    required Database delegate,
    required ISpectLogger logger,
    String source = defaultSource,
    this.config = const ISpectDbConfig(),
  })  : _db = delegate,
        _logger = logger,
        _source = source;

  final Database _db;
  final ISpectLogger _logger;
  final String _source;
  final ISpectDbConfig config;

  /// Default source identifier.
  static const defaultSource = 'sqflite';

  /// The underlying [Database] instance.
  Database get delegate => _db;

  // --- Traced raw methods -------------------------------------------------

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) =>
      _logger.dbTrace(
        source: _source,
        operation: 'query',
        statement: sql,
        args: arguments,
        run: () => _db.rawQuery(sql, arguments),
        projectResult: (rows) => {'rows': rows.length},
        config: config,
      );

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) =>
      _logger.dbTrace(
        source: _source,
        operation: 'insert',
        statement: sql,
        args: arguments,
        run: () => _db.rawInsert(sql, arguments),
        projectResult: (id) => {'lastInsertId': id},
        config: config,
      );

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) =>
      _logger.dbTrace(
        source: _source,
        operation: 'update',
        statement: sql,
        args: arguments,
        run: () => _db.rawUpdate(sql, arguments),
        projectResult: (n) => {'affected': n},
        config: config,
      );

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) =>
      _logger.dbTrace(
        source: _source,
        operation: 'delete',
        statement: sql,
        args: arguments,
        run: () => _db.rawDelete(sql, arguments),
        projectResult: (n) => {'affected': n},
        config: config,
      );

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _logger.dbTrace(
        source: _source,
        operation: 'execute',
        statement: sql,
        args: arguments,
        run: () => _db.execute(sql, arguments),
        config: config,
      );

  // --- Traced convenience methods -----------------------------------------

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'query',
        table: table,
        namedArgs:
            whereArgs != null ? {'where': where, 'args': whereArgs} : null,
        run: () => _db.query(
          table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        ),
        projectResult: (rows) => {'rows': rows.length},
        config: config,
      );

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'insert',
        table: table,
        namedArgs: values,
        run: () => _db.insert(
          table,
          values,
          nullColumnHack: nullColumnHack,
          conflictAlgorithm: conflictAlgorithm,
        ),
        projectResult: (id) => {'lastInsertId': id},
        config: config,
      );

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'update',
        table: table,
        namedArgs: values,
        run: () => _db.update(
          table,
          values,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: conflictAlgorithm,
        ),
        projectResult: (n) => {'affected': n},
        config: config,
      );

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: table,
        run: () => _db.delete(table, where: where, whereArgs: whereArgs),
        projectResult: (n) => {'affected': n},
        config: config,
      );

  // --- Transaction --------------------------------------------------------

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) =>
      _logger.dbTransaction(
        source: _source,
        run: () => _db.transaction(action, exclusive: exclusive),
        config: config,
      );

  @override
  Future<T> readTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) =>
      _logger.dbTransaction(
        source: _source,
        run: () => _db.readTransaction(action),
        config: config,
      );

  // --- Passthrough --------------------------------------------------------

  @override
  String get path => _db.path;

  @override
  bool get isOpen => _db.isOpen;

  @override
  Database get database => this;

  @override
  Batch batch() => _db.batch();

  @override
  Future<QueryCursor> queryCursor(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
  }) =>
      _db.queryCursor(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
        bufferSize: bufferSize,
      );

  @override
  Future<QueryCursor> rawQueryCursor(
    String sql,
    List<Object?>? arguments, {
    int? bufferSize,
  }) =>
      _db.rawQueryCursor(sql, arguments, bufferSize: bufferSize);

  @override
  Future<void> close() => _db.close();

  @override
  // ignore: deprecated_member_use
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) =>
      // ignore: deprecated_member_use
      _db.devInvokeMethod(method, arguments);

  @override
  // ignore: deprecated_member_use
  Future<T> devInvokeSqlMethod<T>(
    String method,
    String sql, [
    List<Object?>? arguments,
  ]) =>
      // ignore: deprecated_member_use
      _db.devInvokeSqlMethod(method, sql, arguments);
}
