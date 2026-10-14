/// String constants used as keys in the structured log `additionalData` map.
///
/// Using constants instead of inline strings prevents typos and enables
/// rename-safe refactoring across the package.
abstract final class DbLogKeys {
  @Deprecated('Use TraceKeys.source instead. Will be removed in 8.0.0.')
  static const source = 'source';
  @Deprecated('Use TraceKeys.operation instead. Will be removed in 8.0.0.')
  static const operation = 'operation';
  static const statement = 'statement';
  static const statementDigest = 'statementDigest';
  @Deprecated('Use TraceKeys.target instead. Will be removed in 8.0.0.')
  static const target = 'target';
  static const table = 'table';
  static const key = 'key';
  static const args = 'args';
  static const namedArgs = 'namedArgs';
  @Deprecated('Use TraceKeys.durationMs instead. Will be removed in 8.0.0.')
  static const durationMs = 'durationMs';
  @Deprecated('Use TraceKeys.slow instead. Will be removed in 8.0.0.')
  static const slow = 'slow';
  @Deprecated('Use TraceKeys.success instead. Will be removed in 8.0.0.')
  static const success = 'success';
  static const affected = 'affected';
  static const items = 'items';
  static const sizeBytes = 'sizeBytes';
  static const cacheHit = 'cacheHit';
  static const value = 'value';
  @Deprecated('Use TraceKeys.meta instead. Will be removed in 8.0.0.')
  static const meta = 'meta';
  static const userMeta = 'userMeta';
  @Deprecated('Use TraceKeys.transactionId instead. Will be removed in 8.0.0.')
  static const transactionId = 'transactionId';
  @Deprecated('Use TraceKeys.error instead. Will be removed in 8.0.0.')
  static const error = 'error';
  static const dbError = 'dbError';
}

/// Log key values used to categorize DB log entries.
abstract final class DbLogCategory {
  static const error = 'db-error';
  static const query = 'db-query';
  static const result = 'db-result';
}

/// Operation names once recognized as read (query) operations.
///
/// Not consulted when choosing a log key: [ISpectDbCore.pickLogKey] and every
/// emitted DB trace classify by `dbCategory.secondaryOperations`.
@Deprecated(
  'Use dbCategory.secondaryOperations, the set DB traces classify by. '
  'Removal target: 8.0.0.',
)
const dbReadOperations = <String>{
  'query', 'select', 'read', 'get', // SQL / KV
  'fetch', 'find', 'list', 'lookup', 'scan', 'count', // NoSQL / search
};

/// Default source fallback for [dbStart]/[dbEnd].
const dbDefaultSource = 'custom';

/// Default operation fallback for [dbStart]/[dbEnd].
const dbDefaultOperation = 'custom';

/// Transaction marker operation names.
@Deprecated(
  'Markers come from traceTransaction(logMarkers: true); read the trace '
  'operation instead. Will be removed in 8.0.0.',
)
abstract final class DbTxnOps {
  static const begin = 'transaction-begin';
  static const commit = 'transaction-commit';
  static const rollback = 'transaction-rollback';
}

/// Human-readable labels for [buildMessage] output.
abstract final class DbMessageLabels {
  static const keyPrefix = 'Key: ';
  static const valuePrefix = 'Value: ';
  static const itemsPrefix = 'Items: ';
  static const affectedPrefix = 'Affected: ';
  static const sizePrefix = 'Size: ';
  static const durationSuffix = 'ms';
  static const durationPrefix = 'Duration: ';
  static const successPrefix = 'Success: ';
  static const cacheHit = 'Cache: HIT';
  static const cacheMiss = 'Cache: MISS';
}
