// ignore_for_file: invalid_use_of_visible_for_testing_member
/// Ready-to-copy interceptor for **isar_community** (Isar Community Edition).
///
/// Provides traced wrappers around [IsarCollection] operations.
/// Since Isar uses code generation and collections are tightly coupled
/// to the [Isar] instance, this interceptor implements [IsarCollection]
/// and acts as a transparent decorator.
///
/// ## Setup
/// ```dart
/// import 'package:isar_community/isar.dart';
///
/// final isar = await Isar.open([UserSchema]);
/// final users = ISpectIsarCollection<User>(
///   delegate: isar.users,
///   logger: logger,
///   collectionName: 'users',
/// );
///
/// await isar.writeTxn(() => users.put(User()..name = 'Alice'));
/// final user = await users.get(1);
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Wraps an Isar [IsarCollection] with `ispectify_db` logging.
///
/// This class implements [IsarCollection], allowing it to be used
/// as a drop-in replacement anywhere `IsarCollection<T>` is expected.
///
/// Each CRUD operation is traced with timing, key/count information,
/// and collection name. Call these methods inside `isar.writeTxn()` or
/// `isar.txn()` as you normally would.
final class ISpectIsarCollection<T> implements IsarCollection<T> {
  const ISpectIsarCollection({
    required IsarCollection<T> delegate,
    required ISpectLogger logger,
    required String collectionName,
    String source = defaultSource,
  })  : _collection = delegate,
        _logger = logger,
        _name = collectionName,
        _source = source;

  final IsarCollection<T> _collection;
  final ISpectLogger _logger;
  final String _name;
  final String _source;

  /// Default source identifier.
  static const defaultSource = 'isar';

  /// The underlying [IsarCollection].
  IsarCollection<T> get delegate => _collection;

  @override
  Isar get isar => _collection.isar;

  @override
  CollectionSchema<T> get schema => _collection.schema;

  @override
  String get name => _name;

  // --- Reads (Async) ------------------------------------------------------

  @override
  Future<T?> get(Id id) => _logger.dbTrace(
        source: _source,
        operation: 'get',
        table: _name,
        key: id.toString(),
        run: () => _collection.get(id),
        projectResult: (val) => val != null ? '1 object' : 'null',
      );

  @override
  Future<List<T?>> getAll(List<Id> ids) => _logger.dbTrace(
        source: _source,
        operation: 'getAll',
        table: _name,
        meta: {'ids': ids.length},
        run: () => _collection.getAll(ids),
        projectResult: (items) => {
          'requested': ids.length,
          'found': items.where((e) => e != null).length,
        },
      );

  @override
  Future<T?> getByIndex(String indexName, IndexKey key) => _logger.dbTrace(
        source: _source,
        operation: 'getByIndex',
        table: _name,
        meta: {'index': indexName, 'key': key.toString()},
        run: () => _collection.getByIndex(indexName, key),
        projectResult: (val) => val != null ? '1 object' : 'null',
      );

  @override
  Future<List<T?>> getAllByIndex(String indexName, List<IndexKey> keys) =>
      _logger.dbTrace(
        source: _source,
        operation: 'getAllByIndex',
        table: _name,
        meta: {'index': indexName, 'keys': keys.length},
        run: () => _collection.getAllByIndex(indexName, keys),
        projectResult: (items) => {
          'requested': keys.length,
          'found': items.where((e) => e != null).length,
        },
      );

  // --- Reads (Sync) -------------------------------------------------------

  @override
  T? getSync(Id id) => _logger.dbTraceSync(
        source: _source,
        operation: 'getSync',
        table: _name,
        key: id.toString(),
        run: () => _collection.getSync(id),
        projectResult: (val) => val != null ? '1 object' : 'null',
      );

  @override
  List<T?> getAllSync(List<Id> ids) => _logger.dbTraceSync(
        source: _source,
        operation: 'getAllSync',
        table: _name,
        meta: {'ids': ids.length},
        run: () => _collection.getAllSync(ids),
        projectResult: (items) => {
          'requested': ids.length,
          'found': items.where((e) => e != null).length,
        },
      );

  @override
  T? getByIndexSync(String indexName, IndexKey key) => _logger.dbTraceSync(
        source: _source,
        operation: 'getByIndexSync',
        table: _name,
        meta: {'index': indexName, 'key': key.toString()},
        run: () => _collection.getByIndexSync(indexName, key),
        projectResult: (val) => val != null ? '1 object' : 'null',
      );

  @override
  List<T?> getAllByIndexSync(String indexName, List<IndexKey> keys) =>
      _logger.dbTraceSync(
        source: _source,
        operation: 'getAllByIndexSync',
        table: _name,
        meta: {'index': indexName, 'keys': keys.length},
        run: () => _collection.getAllByIndexSync(indexName, keys),
        projectResult: (items) => {
          'requested': keys.length,
          'found': items.where((e) => e != null).length,
        },
      );

  // --- Writes (Async) -----------------------------------------------------

  @override
  Future<Id> put(T object) => _logger.dbTrace(
        source: _source,
        operation: 'put',
        table: _name,
        run: () => _collection.put(object),
        projectResult: (id) => {'id': id},
      );

  @override
  Future<List<Id>> putAll(List<T> objects) => _logger.dbTrace(
        source: _source,
        operation: 'putAll',
        table: _name,
        run: () => _collection.putAll(objects),
        projectResult: (ids) => {'inserted': ids.length},
      );

  @override
  Future<Id> putByIndex(String indexName, T object) => _logger.dbTrace(
        source: _source,
        operation: 'putByIndex',
        table: _name,
        meta: {'index': indexName},
        run: () => _collection.putByIndex(indexName, object),
        projectResult: (id) => {'id': id},
      );

  @override
  Future<List<Id>> putAllByIndex(String indexName, List<T> objects) =>
      _logger.dbTrace(
        source: _source,
        operation: 'putAllByIndex',
        table: _name,
        meta: {'index': indexName},
        run: () => _collection.putAllByIndex(indexName, objects),
        projectResult: (ids) => {'inserted': ids.length},
      );

  // --- Writes (Sync) ------------------------------------------------------

  @override
  Id putSync(T object, {bool saveLinks = true}) => _logger.dbTraceSync(
        source: _source,
        operation: 'putSync',
        table: _name,
        run: () => _collection.putSync(object, saveLinks: saveLinks),
        projectResult: (id) => {'id': id},
      );

  @override
  List<Id> putAllSync(List<T> objects, {bool saveLinks = true}) =>
      _logger.dbTraceSync(
        source: _source,
        operation: 'putAllSync',
        table: _name,
        run: () => _collection.putAllSync(objects, saveLinks: saveLinks),
        projectResult: (ids) => {'inserted': ids.length},
      );

  @override
  Id putByIndexSync(String indexName, T object, {bool saveLinks = true}) =>
      _logger.dbTraceSync(
        source: _source,
        operation: 'putByIndexSync',
        table: _name,
        meta: {'index': indexName},
        run: () => _collection.putByIndexSync(
          indexName,
          object,
          saveLinks: saveLinks,
        ),
        projectResult: (id) => {'id': id},
      );

  @override
  List<Id> putAllByIndexSync(
    String indexName,
    List<T> objects, {
    bool saveLinks = true,
  }) =>
      _logger.dbTraceSync(
        source: _source,
        operation: 'putAllByIndexSync',
        table: _name,
        meta: {'index': indexName},
        run: () => _collection.putAllByIndexSync(
          indexName,
          objects,
          saveLinks: saveLinks,
        ),
        projectResult: (ids) => {'inserted': ids.length},
      );

  // --- Deletes (Async) ----------------------------------------------------

  @override
  Future<bool> delete(Id id) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: _name,
        key: id.toString(),
        run: () => _collection.delete(id),
        projectResult: (deleted) => {'deleted': deleted},
      );

  @override
  Future<int> deleteAll(List<Id> ids) => _logger.dbTrace(
        source: _source,
        operation: 'deleteAll',
        table: _name,
        meta: {'ids': ids.length},
        run: () => _collection.deleteAll(ids),
        projectResult: (count) => {'deleted': count},
      );

  @override
  Future<bool> deleteByIndex(String indexName, IndexKey key) => _logger.dbTrace(
        source: _source,
        operation: 'deleteByIndex',
        table: _name,
        meta: {'index': indexName, 'key': key.toString()},
        run: () => _collection.deleteByIndex(indexName, key),
        projectResult: (deleted) => {'deleted': deleted},
      );

  @override
  Future<int> deleteAllByIndex(String indexName, List<IndexKey> keys) =>
      _logger.dbTrace(
        source: _source,
        operation: 'deleteAllByIndex',
        table: _name,
        meta: {'index': indexName, 'keys': keys.length},
        run: () => _collection.deleteAllByIndex(indexName, keys),
        projectResult: (count) => {'deleted': count},
      );

  @override
  Future<void> clear() => _logger.dbTrace(
        source: _source,
        operation: 'clear',
        table: _name,
        run: _collection.clear,
      );

  // --- Deletes (Sync) -----------------------------------------------------

  @override
  bool deleteSync(Id id) => _logger.dbTraceSync(
        source: _source,
        operation: 'deleteSync',
        table: _name,
        key: id.toString(),
        run: () => _collection.deleteSync(id),
        projectResult: (deleted) => {'deleted': deleted},
      );

  @override
  int deleteAllSync(List<Id> ids) => _logger.dbTraceSync(
        source: _source,
        operation: 'deleteAllSync',
        table: _name,
        meta: {'ids': ids.length},
        run: () => _collection.deleteAllSync(ids),
        projectResult: (count) => {'deleted': count},
      );

  @override
  bool deleteByIndexSync(String indexName, IndexKey key) => _logger.dbTraceSync(
        source: _source,
        operation: 'deleteByIndexSync',
        table: _name,
        meta: {'index': indexName, 'key': key.toString()},
        run: () => _collection.deleteByIndexSync(indexName, key),
        projectResult: (deleted) => {'deleted': deleted},
      );

  @override
  int deleteAllByIndexSync(String indexName, List<IndexKey> keys) =>
      _logger.dbTraceSync(
        source: _source,
        operation: 'deleteAllByIndexSync',
        table: _name,
        meta: {'index': indexName, 'keys': keys.length},
        run: () => _collection.deleteAllByIndexSync(indexName, keys),
        projectResult: (count) => {'deleted': count},
      );

  @override
  void clearSync() => _logger.dbTraceSync(
        source: _source,
        operation: 'clearSync',
        table: _name,
        run: _collection.clearSync,
      );

  // --- Aggregations -------------------------------------------------------

  @override
  Future<int> count() => _logger.dbTrace(
        source: _source,
        operation: 'count',
        table: _name,
        run: _collection.count,
        projectResult: (n) => {'count': n},
      );

  @override
  int countSync() => _logger.dbTraceSync(
        source: _source,
        operation: 'countSync',
        table: _name,
        run: _collection.countSync,
        projectResult: (n) => {'count': n},
      );

  @override
  Future<int> getSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'getSize',
        table: _name,
        run: () => _collection.getSize(
          includeIndexes: includeIndexes,
          includeLinks: includeLinks,
        ),
        projectResult: (bytes) => {'sizeBytes': bytes},
      );

  @override
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false}) =>
      _logger.dbTraceSync(
        source: _source,
        operation: 'getSizeSync',
        table: _name,
        run: () => _collection.getSizeSync(
          includeIndexes: includeIndexes,
          includeLinks: includeLinks,
        ),
        projectResult: (bytes) => {'sizeBytes': bytes},
      );

  // --- Import -------------------------------------------------------------

  @override
  Future<void> importJson(List<Map<String, dynamic>> json) => _logger.dbTrace(
        source: _source,
        operation: 'importJson',
        table: _name,
        run: () => _collection.importJson(json),
      );

  @override
  void importJsonSync(List<Map<String, dynamic>> json) => _logger.dbTraceSync(
        source: _source,
        operation: 'importJsonSync',
        table: _name,
        run: () => _collection.importJsonSync(json),
      );

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes) => _logger.dbTrace(
        source: _source,
        operation: 'importJsonRaw',
        table: _name,
        run: () => _collection.importJsonRaw(jsonBytes),
      );

  @override
  void importJsonRawSync(Uint8List jsonBytes) => _logger.dbTraceSync(
        source: _source,
        operation: 'importJsonRawSync',
        table: _name,
        run: () => _collection.importJsonRawSync(jsonBytes),
      );

  // --- Query Building -----------------------------------------------------

  @override
  QueryBuilder<T, T, QWhere> where({
    bool distinct = false,
    Sort sort = Sort.asc,
  }) =>
      _collection.where(distinct: distinct, sort: sort);

  @override
  QueryBuilder<T, T, QFilterCondition> filter() => _collection.filter();

  @override
  Query<R> buildQuery<R>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterOperation? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  }) =>
      _collection.buildQuery<R>(
        whereClauses: whereClauses,
        whereDistinct: whereDistinct,
        whereSort: whereSort,
        filter: filter,
        sortBy: sortBy,
        distinctBy: distinctBy,
        offset: offset,
        limit: limit,
        property: property,
      );

  // --- Watching -----------------------------------------------------------

  @override
  Stream<void> watchLazy({bool fireImmediately = false}) =>
      _collection.watchLazy(fireImmediately: fireImmediately);

  @override
  Stream<T?> watchObject(Id id, {bool fireImmediately = false}) =>
      _collection.watchObject(id, fireImmediately: fireImmediately);

  @override
  Stream<void> watchObjectLazy(Id id, {bool fireImmediately = false}) =>
      _collection.watchObjectLazy(id, fireImmediately: fireImmediately);

  // --- Testing & Verification ---------------------------------------------

  @override
  @visibleForTesting
  Future<void> verify(List<T> objects) => _logger.dbTrace(
        source: _source,
        operation: 'verify',
        table: _name,
        run: () => _collection.verify(objects),
      );

  @override
  @visibleForTesting
  Future<void> verifyLink(
    String linkName,
    List<int> sourceIds,
    List<int> targetIds,
  ) =>
      _logger.dbTrace(
        source: _source,
        operation: 'verifyLink',
        table: _name,
        run: () => _collection.verifyLink(linkName, sourceIds, targetIds),
      );
}
