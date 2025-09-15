typedef DbParams = Map<String, Object?>;

/// CRUD-like normalized commands
enum DbCommand {
  select,
  insert,
  update,
  delete,
  execute, // raw/custom
  transactionBegin,
  transactionCommit,
  transactionRollback,
}

/// DB operation descriptor
class DbOperation {
  const DbOperation({
    required this.command,
    this.sql,
    this.table,
    this.params,
    this.driver,
    this.database,
    this.host,
    this.port,
    this.schema,
    this.tags,
    this.context,
  });

  final DbCommand command;
  final String? sql;
  final String? table;
  final DbParams? params;
  final String? driver;
  final String? database;
  final String? host;
  final int? port;
  final String? schema;
  final Set<String>? tags;
  final Map<String, Object?>? context;
}

/// Result wrapper with metrics and driver object
class DbResult<T> {
  DbResult({
    required this.value,
    required this.durationMs,
    this.rowCount,
    this.notice,
    this.extra,
  });

  final T value;
  final int durationMs;
  final int? rowCount;
  final Object? notice;
  final Map<String, Object?>? extra;
}
