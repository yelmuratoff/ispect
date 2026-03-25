/// Ready-to-copy interceptor for **sembast** (document store).
///
/// Implements [StoreRef] and [RecordRef] interfaces — drop-in replacements.
/// Instance methods shadow Sembast's extension methods, so all operations
/// are automatically traced when using the typed wrapper.
///
/// ## Setup
/// ```dart
/// import 'package:sembast/sembast.dart';
///
/// final db = await databaseFactoryMemory.openDatabase('app.db');
///
/// // Option A: convenience extension
/// final store = intMapStoreFactory.store('users').traced(logger);
///
/// // Option B: explicit constructor
/// final store = ISpectSembastStore(
///   store: intMapStoreFactory.store('users'),
///   logger: logger,
/// );
///
/// // Store-level (traced)
/// await store.add(db, {'name': 'Alice'});
/// await store.find(db, finder: Finder(sortOrders: [SortOrder('name')]));
///
/// // Record-level (also traced)
/// final record = store.record(1);
/// await record.put(db, {'name': 'Bob'});
/// final value = await record.get(db);
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:sembast/sembast.dart' as sembast;

// ---------------------------------------------------------------------------
// Convenience extension
// ---------------------------------------------------------------------------

/// Wraps a [sembast.StoreRef] with `ispectify_db` logging.
extension ISpectSembastStoreExtension<K extends sembast.RecordKeyBase?,
    V extends sembast.RecordValueBase?> on sembast.StoreRef<K, V> {
  /// Returns a traced [ISpectSembastStore] backed by this store.
  ISpectSembastStore<K, V> traced(
    ISpectLogger logger, {
    String source = ISpectSembastStore.defaultSource,
  }) =>
      ISpectSembastStore(store: this, logger: logger, source: source);
}

// ---------------------------------------------------------------------------
// Store wrapper
// ---------------------------------------------------------------------------

/// Wraps a sembast [sembast.StoreRef] with `ispectify_db` logging.
///
/// Implements [sembast.StoreRef], allowing it to be used as a drop-in
/// replacement. Instance methods shadow Sembast's extension methods so that
/// CRUD operations are traced when using this type directly.
///
/// [record] returns a traced [ISpectSembastRecord] with covariant return
/// type, so record-level calls are also traced.
final class ISpectSembastStore<K extends sembast.RecordKeyBase?,
        V extends sembast.RecordValueBase?>
    implements sembast.StoreRef<K, V> {
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
  sembast.StoreRef<K, V> get delegate => _store;

  // --- StoreRef interface ---------------------------------------------------

  @override
  String get name => _store.name;

  /// Returns a traced [ISpectSembastRecord] for the given [key].
  @override
  ISpectSembastRecord<K, V> record(K key) => ISpectSembastRecord(
        delegate: _store.record(key),
        logger: _logger,
        source: _source,
      );

  @override
  sembast.RecordsRef<K, V> records(Iterable<K> keys) => _store.records(keys);

  @override
  sembast.StoreRef<RK, RV>
      cast<RK extends sembast.RecordKeyBase?, RV extends sembast.RecordValueBase?>() =>
          _store.cast<RK, RV>();

  // --- Traced store reads ---------------------------------------------------

  /// Find records matching a [finder].
  Future<List<sembast.RecordSnapshot<K, V>>> find(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'find',
        table: name,
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
        table: name,
        run: () => _store.findFirst(db, finder: finder),
        projectResult: (snap) => snap != null ? '1 record' : 'null',
      );

  /// Count records in the store.
  Future<int> count(
    sembast.DatabaseClient db, {
    sembast.Filter? filter,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'count',
        table: name,
        run: () => _store.count(db, filter: filter),
        projectResult: (n) => {'count': n},
      );

  // --- Traced store writes --------------------------------------------------

  /// Add a record with auto-generated key.
  Future<K> add(sembast.DatabaseClient db, V value) => _logger.dbTrace(
        source: _source,
        operation: 'insert',
        table: name,
        run: () => _store.add(db, value),
        projectResult: (key) => {'autoKey': key},
      );

  /// Add multiple records.
  Future<List<K>> addAll(sembast.DatabaseClient db, List<V> values) =>
      _logger.dbTrace(
        source: _source,
        operation: 'insert',
        table: name,
        meta: {'count': values.length},
        run: () => _store.addAll(db, values),
        projectResult: (keys) => {'inserted': keys.length},
      );

  /// Update records matching a [finder].
  Future<int> update(
    sembast.DatabaseClient db,
    V value, {
    sembast.Finder? finder,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'update',
        table: name,
        run: () => _store.update(db, value, finder: finder),
        projectResult: (n) => {'affected': n},
      );

  /// Delete records matching a [finder].
  Future<int> delete(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: name,
        run: () => _store.delete(db, finder: finder),
        projectResult: (n) => {'deleted': n},
      );

  /// Drop the entire store.
  Future<void> drop(sembast.DatabaseClient db) => _logger.dbTrace(
        source: _source,
        operation: 'clear',
        table: name,
        run: () => _store.drop(db),
      );

  // --- Passthrough reads (delegated to avoid SembastStoreRef casts) ---------

  /// Find a single key.
  Future<K?> findKey(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _store.findKey(db, finder: finder);

  /// Find multiple keys.
  Future<List<K>> findKeys(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _store.findKeys(db, finder: finder);

  /// Create a query with a finder.
  sembast.QueryRef<K, V> query({sembast.Finder? finder}) =>
      _store.query(finder: finder);

  /// Unsorted record stream.
  Stream<sembast.RecordSnapshot<K, V>> stream(
    sembast.DatabaseClient db, {
    sembast.Filter? filter,
  }) =>
      _store.stream(db, filter: filter);

  /// Stream of record count changes.
  Stream<int> onCount(sembast.Database db, {sembast.Filter? filter}) =>
      _store.onCount(db, filter: filter);

  /// Generate a new key.
  Future<K> generateKey(sembast.DatabaseClient db) =>
      _store.generateKey(db);

  /// Generate a new int key.
  Future<int> generateIntKey(sembast.DatabaseClient db) =>
      _store.generateIntKey(db);

  /// Listen for changes on the store.
  void addOnChangesListener(
    sembast.Database db,
    sembast.TransactionRecordChangeListener<K, V> onChanges,
  ) =>
      _store.addOnChangesListener(db, onChanges);

  /// Stop listening for changes.
  void removeOnChangesListener(
    sembast.Database db,
    sembast.TransactionRecordChangeListener<K, V> onChanges,
  ) =>
      _store.removeOnChangesListener(db, onChanges);

  // --- Sync variants --------------------------------------------------------

  /// Find records synchronously.
  List<sembast.RecordSnapshot<K, V>> findSync(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _store.findSync(db, finder: finder);

  /// Find the first record synchronously.
  sembast.RecordSnapshot<K, V>? findFirstSync(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _store.findFirstSync(db, finder: finder);

  /// Find a single key synchronously.
  K? findKeySync(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _store.findKeySync(db, finder: finder);

  /// Find multiple keys synchronously.
  List<K> findKeysSync(
    sembast.DatabaseClient db, {
    sembast.Finder? finder,
  }) =>
      _store.findKeysSync(db, finder: finder);

  /// Count records synchronously.
  int countSync(
    sembast.DatabaseClient db, {
    sembast.Filter? filter,
  }) =>
      _store.countSync(db, filter: filter);

  // --- Transaction ----------------------------------------------------------

  /// Run [action] inside a transaction with a shared transaction ID.
  Future<T> transaction<T>(
    sembast.Database db,
    Future<T> Function(sembast.Transaction txn) action,
  ) =>
      _logger.dbTransaction(
        source: _source,
        run: () => db.transaction(action),
      );

  // --- Equality (same as Sembast: name-based) -------------------------------

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is sembast.StoreRef) {
      return other.name == name;
    }
    return false;
  }

  @override
  String toString() => 'ISpectStore($name)';
}

// ---------------------------------------------------------------------------
// Record wrapper
// ---------------------------------------------------------------------------

/// Wraps a sembast [sembast.RecordRef] with `ispectify_db` logging.
///
/// Implements [sembast.RecordRef], allowing it to be used as a drop-in
/// replacement. Instance methods shadow Sembast's extension methods so that
/// CRUD operations are traced.
final class ISpectSembastRecord<K extends sembast.RecordKeyBase?,
        V extends sembast.RecordValueBase?>
    implements sembast.RecordRef<K, V> {
  const ISpectSembastRecord({
    required sembast.RecordRef<K, V> delegate,
    required ISpectLogger logger,
    String source = ISpectSembastStore.defaultSource,
  })  : _record = delegate,
        _logger = logger,
        _source = source;

  final sembast.RecordRef<K, V> _record;
  final ISpectLogger _logger;
  final String _source;

  /// The underlying record reference.
  sembast.RecordRef<K, V> get delegate => _record;

  // --- RecordRef interface --------------------------------------------------

  @override
  sembast.StoreRef<K, V> get store => _record.store;

  @override
  K get key => _record.key;

  @override
  sembast.RecordRef<RK, RV>
      cast<RK extends sembast.RecordKeyBase?, RV extends sembast.RecordValueBase?>() =>
          _record.cast<RK, RV>();

  // --- Traced reads ---------------------------------------------------------

  /// Get the record value.
  Future<V?> get(sembast.DatabaseClient db) => _logger.dbTrace(
        source: _source,
        operation: 'get',
        table: store.name,
        key: key.toString(),
        run: () => _record.get(db),
      );

  /// Get the record snapshot.
  Future<sembast.RecordSnapshot<K, V>?> getSnapshot(
    sembast.DatabaseClient db,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'get',
        table: store.name,
        key: key.toString(),
        run: () => _record.getSnapshot(db),
        projectResult: (snap) => snap != null ? '1 record' : 'null',
      );

  /// Check if the record exists.
  Future<bool> exists(sembast.DatabaseClient db) => _logger.dbTrace(
        source: _source,
        operation: 'lookup',
        table: store.name,
        key: key.toString(),
        run: () => _record.exists(db),
        projectResult: (val) => {'exists': val},
      );

  // --- Traced writes --------------------------------------------------------

  /// Create the record if it does not exist.
  Future<K?> add(sembast.DatabaseClient db, V value) => _logger.dbTrace(
        source: _source,
        operation: 'insert',
        table: store.name,
        key: key.toString(),
        run: () => _record.add(db, value),
      );

  /// Put (insert or update) the record.
  Future<V> put(
    sembast.DatabaseClient db,
    V value, {
    bool? merge,
    bool? ifNotExists,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'write',
        table: store.name,
        key: key.toString(),
        meta: (merge ?? false) ? {'merge': true} : null,
        run: () => _record.put(db, value, merge: merge, ifNotExists: ifNotExists),
      );

  /// Update the record. Returns null if not found.
  Future<V?> update(sembast.DatabaseClient db, V value) => _logger.dbTrace(
        source: _source,
        operation: 'update',
        table: store.name,
        key: key.toString(),
        run: () => _record.update(db, value),
      );

  /// Delete the record.
  Future<K?> delete(sembast.DatabaseClient db) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: store.name,
        key: key.toString(),
        run: () => _record.delete(db),
      );

  // --- Passthrough ----------------------------------------------------------

  /// Create a snapshot with a given value.
  sembast.RecordSnapshot<K, V> snapshot(V value) => _record.snapshot(value);

  /// Stream of record snapshot changes.
  Stream<sembast.RecordSnapshot<K, V>?> onSnapshot(sembast.Database db) =>
      _record.onSnapshot(db);

  // --- Sync variants --------------------------------------------------------

  /// Get the record value synchronously.
  V? getSync(sembast.DatabaseClient db) => _record.getSync(db);

  /// Get the record snapshot synchronously.
  sembast.RecordSnapshot<K, V>? getSnapshotSync(sembast.DatabaseClient db) =>
      _record.getSnapshotSync(db);

  /// Check if the record exists synchronously.
  bool existsSync(sembast.DatabaseClient db) => _record.existsSync(db);

  /// Stream of record snapshot changes (sync initial read).
  Stream<sembast.RecordSnapshot<K, V>?> onSnapshotSync(sembast.Database db) =>
      _record.onSnapshotSync(db);

  // --- Equality (same as Sembast: store + key) ------------------------------

  @override
  int get hashCode => key.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is sembast.RecordRef) {
      return other.store == store && other.key == key;
    }
    return false;
  }

  @override
  String toString() => 'ISpectRecord(${store.name}, $key)';
}
