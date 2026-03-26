/// Ready-to-copy interceptor for **Realm**.
///
/// Wraps [Realm] — Realm has no native interception hooks and relies on FFI
/// internals, so `implements Realm` is impractical. Use the [delegate] getter
/// for any API not covered by the traced methods.
///
/// ## Setup
/// ```dart
/// final config = Configuration.inMemory([RealmTask.schema]);
/// final realm = Realm(config);
/// final traced = ISpectRealm(delegate: realm, logger: logger);
///
/// traced.write(() {
///   traced.add(RealmTask(ObjectId(), 'Buy milk'));
/// });
/// final task = traced.find<RealmTask>(someId);
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:realm/realm.dart';

/// Wraps a [Realm] instance with `ispectify_db` logging.
///
/// Traced: [find], [all], [query] (reads); [add], [addAll], [delete],
/// [deleteMany], [deleteAll] (writes); [write], [writeAsync] (transactions).
///
/// Passthrough: [close], [isClosed], [isInTransaction], [isFrozen], [config],
/// [schema], [refresh], [refreshAsync], [freeze], [beginWrite],
/// [beginWriteAsync].
///
/// Access the underlying [Realm] via [delegate] for anything else.
final class ISpectRealm {
  const ISpectRealm({
    required Realm delegate,
    required ISpectLogger logger,
    String source = defaultSource,
  })  : _realm = delegate,
        _logger = logger,
        _source = source;

  final Realm _realm;
  final ISpectLogger _logger;
  final String _source;

  /// Default source identifier.
  static const defaultSource = 'realm';

  /// The underlying [Realm] instance.
  Realm get delegate => _realm;

  // --- Traced reads (fire-and-forget) ---------------------------------------

  /// Finds an object by primary key and logs the lookup.
  T? find<T extends RealmObject>(Object? primaryKey) {
    final result = _realm.find<T>(primaryKey);
    _logger.db(
      source: _source,
      operation: 'get',
      table: '$T',
      key: primaryKey.toString(),
      success: true,
      cacheHit: result != null,
    );
    return result;
  }

  /// Returns all objects of type [T] and logs the query.
  RealmResults<T> all<T extends RealmObject>() {
    final results = _realm.all<T>();
    _logger.db(
      source: _source,
      operation: 'query',
      table: '$T',
      success: true,
      items: results.length,
    );
    return results;
  }

  /// Runs an RQL query and logs the statement with result count.
  RealmResults<T> query<T extends RealmObject>(
    String query, [
    List<Object?> args = const [],
  ]) {
    final results = _realm.query<T>(query, args);
    _logger.db(
      source: _source,
      operation: 'query',
      table: '$T',
      statement: query,
      args: args,
      success: true,
      items: results.length,
    );
    return results;
  }

  // --- Traced writes (fire-and-forget, must be inside write block) ----------

  /// Adds an object and logs the write.
  T add<T extends RealmObject>(T object, {bool update = false}) {
    final result = _realm.add<T>(object, update: update);
    _logger.db(
      source: _source,
      operation: 'write',
      table: '$T',
      success: true,
      meta: {'update': update},
    );
    return result;
  }

  /// Adds multiple objects and logs the write with count.
  void addAll<T extends RealmObject>(Iterable<T> items,
      {bool update = false}) {
    _realm.addAll<T>(items, update: update);
    _logger.db(
      source: _source,
      operation: 'write',
      table: '$T',
      success: true,
      meta: {'count': items.length, 'update': update},
    );
  }

  /// Deletes an object and logs the operation.
  void delete<T extends RealmObjectBase>(T object) {
    _realm.delete(object);
    _logger.db(
      source: _source,
      operation: 'delete',
      table: '${object.runtimeType}',
      success: true,
    );
  }

  /// Deletes multiple objects and logs the operation.
  void deleteMany<T extends RealmObject>(Iterable<T> items) {
    final count = items.length;
    _realm.deleteMany(items);
    _logger.db(
      source: _source,
      operation: 'delete',
      table: '$T',
      success: true,
      meta: {'count': count},
    );
  }

  /// Deletes all objects of type [T] and logs the operation.
  void deleteAll<T extends RealmObject>() {
    _realm.deleteAll<T>();
    _logger.db(
      source: _source,
      operation: 'clear',
      table: '$T',
      success: true,
    );
  }

  // --- Traced transactions --------------------------------------------------

  /// Executes a sync write transaction and traces the duration.
  T write<T>(T Function() writeCallback) => _logger.dbTraceSync(
        source: _source,
        operation: 'transaction',
        run: () => _realm.write(writeCallback),
      );

  /// Executes an async write transaction and traces the duration.
  Future<T> writeAsync<T>(
    T Function() writeCallback, [
    CancellationToken? cancellationToken,
  ]) =>
      _logger.dbTrace(
        source: _source,
        operation: 'transaction',
        run: () => _realm.writeAsync(writeCallback, cancellationToken),
      );

  // --- Passthrough ----------------------------------------------------------

  /// Closes the Realm instance.
  void close() => _realm.close();

  /// Whether this Realm is closed.
  bool get isClosed => _realm.isClosed;

  /// Whether a write transaction is currently active.
  bool get isInTransaction => _realm.isInTransaction;

  /// Whether this is a frozen Realm snapshot.
  bool get isFrozen => _realm.isFrozen;

  /// The configuration used to open this Realm.
  Configuration get config => _realm.config;

  /// The schema for this Realm.
  RealmSchema get schema => _realm.schema;

  /// Refreshes the Realm to the latest version.
  bool refresh() => _realm.refresh();

  /// Refreshes the Realm to the latest version asynchronously.
  Future<bool> refreshAsync() => _realm.refreshAsync();

  /// Returns a frozen snapshot, wrapped for tracing.
  ISpectRealm freeze() => ISpectRealm(
        delegate: _realm.freeze(),
        logger: _logger,
        source: _source,
      );

  /// Begins a manual write transaction.
  Transaction beginWrite() => _realm.beginWrite();

  /// Begins a manual write transaction asynchronously.
  Future<Transaction> beginWriteAsync([
    CancellationToken? cancellationToken,
  ]) =>
      _realm.beginWriteAsync(cancellationToken);
}
