/// Ready-to-copy interceptor for **ObjectBox**.
///
/// Implements [Box] — drop-in replacement. Although [Box] is a concrete class,
/// it has no Dart 3 modifiers (`final`/`sealed`/`base`), so `implements` works.
///
/// ## Setup
/// ```dart
/// final store = await openStore();
/// final box = ISpectObjectBox<Task>(
///   delegate: store.box<Task>(),
///   logger: logger,
///   boxName: 'Task',
/// );
///
/// final id = box.put(Task(text: 'Buy milk'));
/// final task = box.get(id);
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:objectbox/objectbox.dart';

/// Wraps an ObjectBox [Box] with `ispectify_db` logging.
///
/// Implements the full [Box] interface — can be used anywhere `Box<T>` is
/// expected. CRUD operations are traced; query building ([query]) and
/// deprecated methods delegate without logging.
///
/// Access the underlying [Box] via [delegate] for internal ObjectBox APIs.
final class ISpectObjectBox<T> implements Box<T> {
  ISpectObjectBox({
    required Box<T> delegate,
    required ISpectLogger logger,
    required String boxName,
    String source = defaultSource,
    this.config = const ISpectDbConfig(),
  })  : _box = delegate,
        _logger = logger,
        _boxName = boxName,
        _source = source;

  final Box<T> _box;
  final ISpectLogger _logger;
  final String _boxName;
  final String _source;
  final ISpectDbConfig config;

  /// Default source identifier.
  static const defaultSource = 'objectbox';

  /// The underlying [Box] instance.
  Box<T> get delegate => _box;

  // --- Sync reads -----------------------------------------------------------

  @override
  T? get(int id) {
    final result = _box.get(id);
    _logger.db(
      source: _source,
      operation: 'get',
      table: _boxName,
      key: id.toString(),
      success: true,
      cacheHit: result != null,
      config: config,
      );
    return result;
  }

  @override
  List<T?> getMany(List<int> ids, {bool growableResult = false}) {
    final result = _box.getMany(ids, growableResult: growableResult);
    _logger.db(
      source: _source,
      operation: 'getMany',
      table: _boxName,
      success: true,
      meta: {'ids': ids.length},
      items: result.where((e) => e != null).length,
      config: config,
      );
    return result;
  }

  @override
  List<T> getAll() {
    final result = _box.getAll();
    _logger.db(
      source: _source,
      operation: 'getAll',
      table: _boxName,
      success: true,
      items: result.length,
      config: config,
      );
    return result;
  }

  // --- Async reads ----------------------------------------------------------

  @override
  Future<T?> getAsync(int id) => _logger.dbTrace(
        source: _source,
        operation: 'getAsync',
        table: _boxName,
        key: id.toString(),
        run: () => _box.getAsync(id),
        projectResult: (val) => val != null ? '1 object' : 'null',
        config: config,
      );

  @override
  Future<List<T?>> getManyAsync(List<int> ids, {bool growableResult = false}) =>
      _logger.dbTrace(
        source: _source,
        operation: 'getManyAsync',
        table: _boxName,
        meta: {'ids': ids.length},
        run: () => _box.getManyAsync(ids, growableResult: growableResult),
        projectResult: (items) => {
          'requested': ids.length,
          'found': items.where((e) => e != null).length,
        },
        config: config,
      );

  @override
  Future<List<T>> getAllAsync() => _logger.dbTrace(
        source: _source,
        operation: 'getAllAsync',
        table: _boxName,
        run: () => _box.getAllAsync(),
        projectResult: (items) => {'count': items.length},
        config: config,
      );

  // --- Sync writes ----------------------------------------------------------

  @override
  int put(T object, {PutMode mode = PutMode.put}) => _logger.dbTraceSync(
        source: _source,
        operation: 'put',
        table: _boxName,
        run: () => _box.put(object, mode: mode),
        projectResult: (id) => {'id': id},
        config: config,
      );

  @override
  List<int> putMany(List<T> objects, {PutMode mode = PutMode.put}) =>
      _logger.dbTraceSync(
        source: _source,
        operation: 'putMany',
        table: _boxName,
        meta: {'count': objects.length},
        run: () => _box.putMany(objects, mode: mode),
        projectResult: (ids) => {'inserted': ids.length},
        config: config,
      );

  // --- Async writes ---------------------------------------------------------

  @override
  Future<int> putAsync(T object, {PutMode mode = PutMode.put}) =>
      _logger.dbTrace(
        source: _source,
        operation: 'putAsync',
        table: _boxName,
        run: () => _box.putAsync(object, mode: mode),
        projectResult: (id) => {'id': id},
        config: config,
      );

  @override
  Future<T> putAndGetAsync(T object, {PutMode mode = PutMode.put}) =>
      _logger.dbTrace(
        source: _source,
        operation: 'putAndGetAsync',
        table: _boxName,
        run: () => _box.putAndGetAsync(object, mode: mode),
        projectResult: (obj) => '1 object',
        config: config,
      );

  @override
  Future<List<int>> putManyAsync(List<T> objects,
          {PutMode mode = PutMode.put}) =>
      _logger.dbTrace(
        source: _source,
        operation: 'putManyAsync',
        table: _boxName,
        meta: {'count': objects.length},
        run: () => _box.putManyAsync(objects, mode: mode),
        projectResult: (ids) => {'inserted': ids.length},
        config: config,
      );

  @override
  Future<List<T>> putAndGetManyAsync(List<T> objects,
          {PutMode mode = PutMode.put}) =>
      _logger.dbTrace(
        source: _source,
        operation: 'putAndGetManyAsync',
        table: _boxName,
        meta: {'count': objects.length},
        run: () => _box.putAndGetManyAsync(objects, mode: mode),
        projectResult: (items) => {'inserted': items.length},
        config: config,
      );

  @override
  int putQueued(T object, {PutMode mode = PutMode.put}) => _logger.dbTraceSync(
        source: _source,
        operation: 'putQueued',
        table: _boxName,
        run: () => _box.putQueued(object, mode: mode),
        projectResult: (id) => {'id': id},
        config: config,
      );

  @override
  @Deprecated('Use putAsync or putQueued instead.')
  Future<int> putQueuedAwaitResult(T object, {PutMode mode = PutMode.put}) =>
      // ignore: deprecated_member_use
      _box.putQueuedAwaitResult(object, mode: mode);

  // --- Sync deletes ---------------------------------------------------------

  @override
  bool remove(int id) => _logger.dbTraceSync(
        source: _source,
        operation: 'delete',
        table: _boxName,
        key: id.toString(),
        run: () => _box.remove(id),
        projectResult: (deleted) => {'deleted': deleted},
        config: config,
      );

  @override
  int removeMany(List<int> ids) => _logger.dbTraceSync(
        source: _source,
        operation: 'deleteMany',
        table: _boxName,
        meta: {'ids': ids.length},
        run: () => _box.removeMany(ids),
        projectResult: (count) => {'deleted': count},
        config: config,
      );

  @override
  int removeAll() => _logger.dbTraceSync(
        source: _source,
        operation: 'clear',
        table: _boxName,
        run: _box.removeAll,
        projectResult: (count) => {'cleared': count},
        config: config,
      );

  // --- Async deletes --------------------------------------------------------

  @override
  Future<bool> removeAsync(int id) => _logger.dbTrace(
        source: _source,
        operation: 'deleteAsync',
        table: _boxName,
        key: id.toString(),
        run: () => _box.removeAsync(id),
        projectResult: (deleted) => {'deleted': deleted},
        config: config,
      );

  @override
  Future<int> removeManyAsync(List<int> ids) => _logger.dbTrace(
        source: _source,
        operation: 'deleteManyAsync',
        table: _boxName,
        meta: {'ids': ids.length},
        run: () => _box.removeManyAsync(ids),
        projectResult: (count) => {'deleted': count},
        config: config,
      );

  @override
  Future<int> removeAllAsync() => _logger.dbTrace(
        source: _source,
        operation: 'clearAsync',
        table: _boxName,
        run: _box.removeAllAsync,
        projectResult: (count) => {'cleared': count},
        config: config,
      );

  // --- Aggregations ---------------------------------------------------------

  @override
  int count({int limit = 0}) {
    final result = _box.count(limit: limit);
    _logger.db(
      source: _source,
      operation: 'count',
      table: _boxName,
      success: true,
      items: result,
      config: config,
      );
    return result;
  }

  @override
  bool isEmpty() {
    final result = _box.isEmpty();
    _logger.db(
      source: _source,
      operation: 'lookup',
      table: _boxName,
      success: true,
      meta: {'isEmpty': result},
      config: config,
      );
    return result;
  }

  @override
  bool contains(int id) {
    final result = _box.contains(id);
    _logger.db(
      source: _source,
      operation: 'lookup',
      table: _boxName,
      key: id.toString(),
      success: true,
      cacheHit: result,
      config: config,
      );
    return result;
  }

  @override
  bool containsMany(List<int> ids) {
    final result = _box.containsMany(ids);
    _logger.db(
      source: _source,
      operation: 'lookup',
      table: _boxName,
      success: true,
      meta: {'ids': ids.length, 'allExist': result},
      config: config,
      );
    return result;
  }

  // --- Query building (passthrough) -----------------------------------------

  @override
  QueryBuilder<T> query([Condition<T>? qc]) => _box.query(qc);
}
