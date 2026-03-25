/// Ready-to-copy interceptor for **isar_community** (Isar Community Edition).
///
/// Provides traced wrappers around [IsarCollection] operations.
/// Since Isar uses code generation and collections are tightly coupled
/// to the [Isar] instance, this interceptor is a **helper wrapper**.
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

import 'package:isar_community/isar.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Wraps an Isar [IsarCollection] with `ispectify_db` logging.
///
/// Each CRUD operation is traced with timing, key/count information,
/// and collection name. Call these methods inside `isar.writeTxn()` or
/// `isar.txn()` as you normally would.
final class ISpectIsarCollection<T> {
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

  /// Collection name.
  String get name => _name;

  // --- Reads --------------------------------------------------------------

  Future<T?> get(Id id) => _logger.dbTrace(
        source: _source,
        operation: 'get',
        table: _name,
        key: id.toString(),
        run: () => _collection.get(id),
        projectResult: (val) => val != null ? '1 object' : 'null',
      );

  Future<List<T?>> getAll(List<Id> ids) => _logger.dbTrace(
        source: _source,
        operation: 'get',
        table: _name,
        meta: {'ids': ids.length},
        run: () => _collection.getAll(ids),
        projectResult: (items) => {
          'requested': ids.length,
          'found': items.where((e) => e != null).length,
        },
      );

  // --- Writes -------------------------------------------------------------

  Future<Id> put(T object) => _logger.dbTrace(
        source: _source,
        operation: 'insert',
        table: _name,
        run: () => _collection.put(object),
        projectResult: (id) => {'id': id},
      );

  Future<List<Id>> putAll(List<T> objects) => _logger.dbTrace(
        source: _source,
        operation: 'insert',
        table: _name,
        run: () => _collection.putAll(objects),
        projectResult: (ids) => {'inserted': ids.length},
      );

  // --- Deletes ------------------------------------------------------------

  Future<bool> delete(Id id) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: _name,
        key: id.toString(),
        run: () => _collection.delete(id),
        projectResult: (deleted) => {'deleted': deleted},
      );

  Future<int> deleteAll(List<Id> ids) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: _name,
        meta: {'ids': ids.length},
        run: () => _collection.deleteAll(ids),
        projectResult: (count) => {'deleted': count},
      );

  Future<void> clear() => _logger.dbTrace(
        source: _source,
        operation: 'clear',
        table: _name,
        run: _collection.clear,
      );

  // --- Aggregations -------------------------------------------------------

  Future<int> count() => _logger.dbTrace(
        source: _source,
        operation: 'count',
        table: _name,
        run: _collection.count,
        projectResult: (n) => {'count': n},
      );

  Future<int> getSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'read',
        table: _name,
        run: () => _collection.getSize(
          includeIndexes: includeIndexes,
          includeLinks: includeLinks,
        ),
        projectResult: (bytes) => {'sizeBytes': bytes},
      );
}
