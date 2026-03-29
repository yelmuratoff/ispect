/// String constants used as keys in the structured log `additionalData` map.
///
/// Using constants instead of inline strings prevents typos and enables
/// rename-safe refactoring across the package.
abstract final class DbLogKeys {
  static const source = 'source';
  static const operation = 'operation';
  static const statement = 'statement';
  static const statementDigest = 'statementDigest';
  static const target = 'target';
  static const table = 'table';
  static const key = 'key';
  static const args = 'args';
  static const namedArgs = 'namedArgs';
  static const durationMs = 'durationMs';
  static const slow = 'slow';
  static const success = 'success';
  static const affected = 'affected';
  static const items = 'items';
  static const sizeBytes = 'sizeBytes';
  static const cacheHit = 'cacheHit';
  static const value = 'value';
  static const meta = 'meta';
  static const transactionId = 'transactionId';
  static const error = 'error';
}

/// Log key values used to categorize DB log entries.
abstract final class DbLogCategory {
  static const error = 'db-error';
  static const query = 'db-query';
  static const result = 'db-result';
}

/// Operation names recognized as read (query) operations.
///
/// Used by [ISpectDbCore.pickLogKey] to classify operations as
/// [DbLogCategory.query] vs [DbLogCategory.result].
const dbReadOperations = <String>{
  'query', 'select', 'read', 'get', // SQL / KV
  'fetch', 'find', 'list', 'lookup', 'scan', 'count', // NoSQL / search
};

/// Default source fallback for [dbStart]/[dbEnd].
const dbDefaultSource = 'custom';

/// Default operation fallback for [dbStart]/[dbEnd].
const dbDefaultOperation = 'custom';

/// Transaction marker operation names.
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
