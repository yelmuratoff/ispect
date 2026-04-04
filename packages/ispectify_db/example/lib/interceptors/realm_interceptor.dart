/// Ready-to-copy interceptor for **Realm**.
///
/// Implements [Realm] — drop-in replacement. All public methods are overridden
/// so the base class never accesses internal FFI handles on this instance.
///
/// ## Setup
/// ```dart
/// final config = Configuration.inMemory([RealmTask.schema]);
/// final Realm realm = ISpectRealm(
///   delegate: Realm(config),
///   logger: logger,
/// );
///
/// realm.write(() {
///   realm.add(RealmTask(ObjectId(), 'Buy milk'));
/// });
/// final task = realm.find<RealmTask>(someId);
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:realm/realm.dart';

/// Drop-in replacement for [Realm] with `ispectify_db` logging.
///
/// Traced: [find], [all], [query] (reads); [add], [addAll], [delete],
/// [deleteMany], [deleteAll] (writes); [write], [writeAsync] (transactions).
///
/// Passthrough: [close], [isClosed], [isInTransaction], [isFrozen], [config],
/// [schema], [dynamic], [refresh], [refreshAsync], [freeze], [beginWrite],
/// [beginWriteAsync], [writeCopy].
final class ISpectRealm implements Realm {
  const ISpectRealm({
    required Realm delegate,
    required ISpectLogger logger,
    String source = defaultSource,
    this.logConfig = const ISpectDbConfig(),
  })  : _realm = delegate,
        _logger = logger,
        _source = source;

  final Realm _realm;
  final ISpectLogger _logger;
  final String _source;
  final ISpectDbConfig logConfig;

  /// Default source identifier.
  static const defaultSource = 'realm';

  /// The underlying [Realm] instance.
  Realm get delegate => _realm;

  // --- Traced reads (fire-and-forget) ---------------------------------------

  @override
  T? find<T extends RealmObject>(Object? primaryKey) {
    final result = _realm.find<T>(primaryKey);
    _logger.db(
      source: _source,
      operation: 'get',
      table: '$T',
      key: primaryKey.toString(),
      success: true,
      cacheHit: result != null,
      config: logConfig,
    );
    return result;
  }

  @override
  RealmResults<T> all<T extends RealmObject>() {
    final results = _realm.all<T>();
    _logger.db(
      source: _source,
      operation: 'query',
      table: '$T',
      success: true,
      items: results.length,
      config: logConfig,
    );
    return results;
  }

  @override
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
      config: logConfig,
    );
    return results;
  }

  // --- Traced writes (fire-and-forget, must be inside write block) ----------

  @override
  T add<T extends RealmObject>(T object, {bool update = false}) {
    final result = _realm.add<T>(object, update: update);
    _logger.db(
      source: _source,
      operation: 'write',
      table: '$T',
      success: true,
      meta: {'update': update},
      config: logConfig,
    );
    return result;
  }

  @override
  void addAll<T extends RealmObject>(Iterable<T> items, {bool update = false}) {
    _realm.addAll<T>(items, update: update);
    _logger.db(
      source: _source,
      operation: 'write',
      table: '$T',
      success: true,
      meta: {'count': items.length, 'update': update},
      config: logConfig,
    );
  }

  @override
  void delete<T extends RealmObjectBase>(T object) {
    _realm.delete(object);
    _logger.db(
      source: _source,
      operation: 'delete',
      table: '${object.runtimeType}',
      success: true,
      config: logConfig,
    );
  }

  @override
  void deleteMany<T extends RealmObject>(Iterable<T> items) {
    final count = items.length;
    _realm.deleteMany(items);
    _logger.db(
      source: _source,
      operation: 'delete',
      table: '$T',
      success: true,
      meta: {'count': count},
      config: logConfig,
    );
  }

  @override
  void deleteAll<T extends RealmObject>() {
    _realm.deleteAll<T>();
    _logger.db(
      source: _source,
      operation: 'clear',
      table: '$T',
      success: true,
      config: logConfig,
    );
  }

  // --- Traced transactions --------------------------------------------------

  @override
  T write<T>(T Function() writeCallback) => _logger.dbTraceSync(
        source: _source,
        operation: 'transaction',
        run: () => _realm.write(writeCallback),
        config: logConfig,
      );

  @override
  Future<T> writeAsync<T>(
    T Function() writeCallback, [
    CancellationToken? cancellationToken,
  ]) =>
      _logger.dbTrace(
        source: _source,
        operation: 'transaction',
        run: () => _realm.writeAsync(writeCallback, cancellationToken),
        config: logConfig,
      );

  // --- Passthrough ----------------------------------------------------------

  @override
  void close() => _realm.close();

  @override
  bool get isClosed => _realm.isClosed;

  @override
  bool get isInTransaction => _realm.isInTransaction;

  @override
  bool get isFrozen => _realm.isFrozen;

  @override
  Configuration get config => _realm.config;

  @override
  RealmSchema get schema => _realm.schema;

  @override
  set schema(RealmSchema value) => _realm.schema = value;

  @override
  DynamicRealm get dynamic => _realm.dynamic;

  @override
  void disableAutoRefreshForTesting() => _realm.disableAutoRefreshForTesting();

  @override
  bool refresh() => _realm.refresh();

  @override
  Future<bool> refreshAsync() => _realm.refreshAsync();

  @override
  ISpectRealm freeze() => ISpectRealm(
        delegate: _realm.freeze(),
        logger: _logger,
        source: _source,
        logConfig: logConfig,
      );

  @override
  Transaction beginWrite() => _realm.beginWrite();

  @override
  Future<Transaction> beginWriteAsync([
    CancellationToken? cancellationToken,
  ]) =>
      _realm.beginWriteAsync(cancellationToken);

  @override
  void writeCopy(Configuration config) => _realm.writeCopy(config);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is ISpectRealm) return _realm == other._realm;
    if (other is Realm) return _realm == other;
    return false;
  }

  @override
  int get hashCode => _realm.hashCode;
}
