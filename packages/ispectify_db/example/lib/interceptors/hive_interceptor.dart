/// Ready-to-copy interceptor for **hive_ce** (Hive Community Edition) (typed boxes).
///
/// Implements the full [Box] interface — drop-in replacement.
///
/// ## Setup
/// ```dart
/// final box = await Hive.openBox<User>('users');
/// final traced = ISpectHiveBox<User>(delegate: box, logger: logger);
///
/// await traced.put('alice', User(name: 'Alice'));
/// final user = traced.get('alice');
/// ```
library;

import 'package:hive_ce/hive.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Wraps a Hive [Box] with `ispectify_db` logging.
///
/// Read operations ([get], [containsKey]) are logged as `db-query`.
/// Write operations ([put], [delete], [clear]) are logged as `db-result`.
/// Lifecycle/admin methods ([close], [compact], [flush]) delegate without logging.
final class ISpectHiveBox<E> implements Box<E> {
  const ISpectHiveBox({
    required Box<E> delegate,
    required ISpectLogger logger,
    String source = defaultSource,
  })  : _box = delegate,
        _logger = logger,
        _source = source;

  final Box<E> _box;
  final ISpectLogger _logger;
  final String _source;

  /// Default source identifier.
  static const defaultSource = 'hive';

  // --- Traced reads -------------------------------------------------------

  @override
  E? get(Object? key, {E? defaultValue}) {
    final result = _box.get(key, defaultValue: defaultValue);
    _logger.db(
      source: _source,
      operation: 'get',
      key: key.toString(),
      success: true,
      cacheHit: result != null,
      meta: {'box': _box.name},
    );
    return result;
  }

  @override
  E? getAt(int index) {
    final result = _box.getAt(index);
    _logger.db(
      source: _source,
      operation: 'get',
      key: 'index:$index',
      success: true,
      cacheHit: result != null,
      meta: {'box': _box.name},
    );
    return result;
  }

  @override
  bool containsKey(Object? key) {
    final result = _box.containsKey(key);
    _logger.db(
      source: _source,
      operation: 'lookup',
      key: key.toString(),
      success: true,
      cacheHit: result,
      meta: {'box': _box.name},
    );
    return result;
  }

  // --- Traced writes ------------------------------------------------------

  @override
  Future<void> put(Object? key, E value) => _logger.dbTrace(
        source: _source,
        operation: 'write',
        key: key.toString(),
        meta: {'box': _box.name},
        run: () => _box.put(key, value),
      );

  @override
  Future<void> putAt(int index, E value) => _logger.dbTrace(
        source: _source,
        operation: 'write',
        key: 'index:$index',
        meta: {'box': _box.name},
        run: () => _box.putAt(index, value),
      );

  @override
  Future<void> putAll(Map<Object?, E> entries) => _logger.dbTrace(
        source: _source,
        operation: 'write',
        meta: {'box': _box.name, 'entries': entries.length},
        run: () => _box.putAll(entries),
      );

  @override
  Future<int> add(E value) => _logger.dbTrace(
        source: _source,
        operation: 'insert',
        meta: {'box': _box.name},
        run: () => _box.add(value),
        projectResult: (key) => {'autoKey': key},
      );

  @override
  Future<Iterable<int>> addAll(Iterable<E> values) => _logger.dbTrace(
        source: _source,
        operation: 'insert',
        meta: {'box': _box.name, 'count': values.length},
        run: () => _box.addAll(values),
        projectResult: (keys) => {'inserted': keys.length},
      );

  @override
  Future<void> delete(Object? key) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        key: key.toString(),
        meta: {'box': _box.name},
        run: () => _box.delete(key),
      );

  @override
  Future<void> deleteAt(int index) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        key: 'index:$index',
        meta: {'box': _box.name},
        run: () => _box.deleteAt(index),
      );

  @override
  Future<void> deleteAll(Iterable<Object?> keys) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        meta: {'box': _box.name, 'keys': keys.length},
        run: () => _box.deleteAll(keys),
      );

  @override
  Future<int> clear() => _logger.dbTrace(
        source: _source,
        operation: 'clear',
        meta: {'box': _box.name},
        run: _box.clear,
        projectResult: (count) => {'cleared': count},
      );

  // --- Passthrough reads --------------------------------------------------

  @override
  String get name => _box.name;

  @override
  bool get isOpen => _box.isOpen;

  @override
  String? get path => _box.path;

  @override
  bool get lazy => _box.lazy;

  @override
  Iterable<Object?> get keys => _box.keys;

  @override
  Iterable<E> get values => _box.values;

  @override
  Iterable<E> valuesBetween({Object? startKey, Object? endKey}) =>
      _box.valuesBetween(startKey: startKey, endKey: endKey);

  @override
  int get length => _box.length;

  @override
  bool get isEmpty => _box.isEmpty;

  @override
  bool get isNotEmpty => _box.isNotEmpty;

  @override
  Object? keyAt(int index) => _box.keyAt(index);

  @override
  Map<Object?, E> toMap() => _box.toMap();

  // --- Passthrough lifecycle ----------------------------------------------

  @override
  Stream<BoxEvent> watch({Object? key}) => _box.watch(key: key);

  @override
  Future<void> compact() => _box.compact();

  @override
  Future<void> flush() => _box.flush();

  @override
  Future<void> close() => _box.close();

  @override
  Future<void> deleteFromDisk() => _box.deleteFromDisk();
}
