/// Ready-to-copy interceptor for **sembast** (document store).
///
/// Provides traced wrappers around [StoreRef] and [RecordRef] operations.
/// Since sembast's public API is extension-based, this interceptor is a
/// **helper wrapper** rather than an interface implementation.
///
/// ## Setup
/// ```dart
/// import 'package:sembast/sembast.dart';
///
/// final db = await databaseFactoryMemory.openDatabase('app.db');
/// final store = intMapStoreFactory.store('users');
/// final traced = ISpectSembastStore(store: store, logger: logger);
///
/// await traced.put(db, 1, {'name': 'Alice'});
/// final value = await traced.get(db, 1);
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:sembast/sembast.dart' as sembast;

/// Wraps a sembast [StoreRef] with `ispectify_db` logging.
///
/// All read/write operations are traced. Transaction grouping is supported
/// via [transaction].
final class ISpectSembastStore<K extends sembast.RecordKeyBase?,
    V extends sembast.RecordValueBase?> {
  const ISpectSembastStore({
    required sembast.StoreRef<K, V> store,
    required ISpectLogger logger,
    String source = defaultSource,
  })  : _store = store,
        _logger = logger,
        _source = source;

  final sembast.StoreRef<K, V> _store;
  final ISpectLogger _logger;
  final String _source;

  /// Default source identifier.
  static const defaultSource = 'sembast';

  /// The underlying store reference.
  sembast.StoreRef<K, V> get store => _store;

  /// Store name.
  String get name => _store.name;

  // --- Record reads -------------------------------------------------------

  /// Get a record by key.
  Future<V?> get(sembast.DatabaseClient db, K key) => _logger.dbTrace(
        source: _source,
        operation: 'get',
        table: _store.name,
        key: key.toString(),
        run: () => _store.record(key).get(db),
      );

  /// Get a record snapshot by key.
  Future<sembast.RecordSnapshot<K, V>?> getSnapshot(
    sembast.DatabaseClient db,
    K key,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'get',
        table: _store.name,
        key: key.toString(),
        run: () => _store.record(key).getSnapshot(db),
        projectResult: (snap) => snap != null ? '1 record' : 'null',
      );

  /// Check if a record exists.
  Future<bool> exists(sembast.DatabaseClient db, K key) => _logger.dbTrace(
        source: _source,
        operation: 'lookup',
        table: _store.name,
        key: key.toString(),
        run: () => _store.record(key).exists(db),
        projectResult: (val) => {'exists': val},
      );

  // --- Record writes ------------------------------------------------------

  /// Put (insert or update) a record.
  Future<V> put(sembast.DatabaseClient db, K key, V value, {bool? merge}) =>
      _logger.dbTrace(
        source: _source,
        operation: 'write',
        table: _store.name,
        key: key.toString(),
        meta: (merge ?? false) ? {'merge': true} : null,
        run: () => _store.record(key).put(db, value, merge: merge),
      );

  /// Update an existing record.
  Future<V?> update(sembast.DatabaseClient db, K key, V value) =>
      _logger.dbTrace(
        source: _source,
        operation: 'update',
        table: _store.name,
        key: key.toString(),
        run: () => _store.record(key).update(db, value),
      );

  /// Add a record with auto-generated key.
  Future<K> add(sembast.DatabaseClient db, V value) => _logger.dbTrace(
        source: _source,
        operation: 'insert',
        table: _store.name,
        run: () => _store.add(db, value),
        projectResult: (key) => {'autoKey': key},
      );

  /// Delete a record by key.
  Future<K?> deleteRecord(sembast.DatabaseClient db, K key) =>
      _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: _store.name,
        key: key.toString(),
        run: () => _store.record(key).delete(db),
      );

  // --- Store queries ------------------------------------------------------

  /// Find records matching a [finder].
  Future<List<sembast.RecordSnapshot<K, V>>> find(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'find',
        table: _store.name,
        run: () => _store.find(db, finder: finder),
        projectResult: (snaps) => {'found': snaps.length},
      );

  /// Find the first record matching a [finder].
  Future<sembast.RecordSnapshot<K, V>?> findFirst(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'find',
        table: _store.name,
        run: () => _store.findFirst(db, finder: finder),
        projectResult: (snap) => snap != null ? '1 record' : 'null',
      );

  /// Count records in the store.
  Future<int> count(sembast.DatabaseClient db, {sembast.Filter? filter}) =>
      _logger.dbTrace(
        source: _source,
        operation: 'count',
        table: _store.name,
        run: () => _store.count(db, filter: filter),
        projectResult: (n) => {'count': n},
      );

  /// Delete records matching a [finder].
  Future<int> delete(sembast.DatabaseClient db, {sembast.Finder? finder}) =>
      _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: _store.name,
        run: () => _store.delete(db, finder: finder),
        projectResult: (n) => {'deleted': n},
      );

  /// Drop the entire store.
  Future<void> drop(sembast.DatabaseClient db) => _logger.dbTrace(
        source: _source,
        operation: 'clear',
        table: _store.name,
        run: () => _store.drop(db),
      );

  // --- Transaction --------------------------------------------------------

  /// Run [action] inside a transaction with a shared transaction ID.
  Future<T> transaction<T>(
    sembast.Database db,
    Future<T> Function(sembast.Transaction txn) action,
  ) =>
      _logger.dbTransaction(
        source: _source,
        run: () => db.transaction(action),
      );
}
