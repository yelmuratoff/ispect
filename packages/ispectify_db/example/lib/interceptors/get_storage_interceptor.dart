/// Ready-to-copy interceptor for **get_storage**.
///
/// Implements the full [GetStorage] interface — drop-in replacement.
///
/// ## Setup
/// ```dart
/// import 'package:get_storage/get_storage.dart';
///
/// await GetStorage.init();
/// final box = GetStorage();
/// final traced = ISpectGetStorage(delegate: box, logger: logger);
///
/// await traced.write('theme', 'dark');
/// final theme = traced.read<String>('theme');
/// ```
library;

import 'package:flutter/foundation.dart' show ValueSetter, VoidCallback;
import 'package:get/get_utils/src/queue/get_queue.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Wraps [GetStorage] with `ispectify_db` logging.
///
/// Implements [GetStorage], allowing it to be used as a drop-in replacement
/// anywhere `GetStorage` is expected.
///
/// Reads are synchronous (fire-and-forget via [db]).
/// Writes are async (traced via [dbTrace]).
/// Observation methods (`listen`, `listenKey`) and lifecycle fields
/// (`microtask`, `queue`, `initStorage`) are passed through.
final class ISpectGetStorage implements GetStorage {
  ISpectGetStorage({
    required GetStorage delegate,
    required ISpectLogger logger,
    String source = defaultSource,
    String? containerName,
    this.config = const ISpectDbConfig(),
  })  : _box = delegate,
        _logger = logger,
        _source = source,
        _containerName = containerName;

  final GetStorage _box;
  final ISpectLogger _logger;
  final String _source;
  final String? _containerName;
  final ISpectDbConfig config;

  /// Default source identifier.
  static const defaultSource = 'get_storage';

  /// The underlying [GetStorage] instance.
  GetStorage get delegate => _box;

  // --- Reads (synchronous) --------------------------------------------------

  @override
  T? read<T>(String key) => _logRead(key, _box.read<T>(key));

  @override
  bool hasData(String key) {
    final result = _box.hasData(key);
    _logger.db(
      source: _source,
      operation: 'lookup',
      table: _containerName,
      key: key,
      success: true,
      cacheHit: result,
      config: config,
    );
    return result;
  }

  @override
  T getKeys<T>() {
    final result = _box.getKeys<T>();
    if (result is Iterable) {
      _logger.db(
        source: _source,
        operation: 'list',
        table: _containerName,
        success: true,
        items: (result as Iterable<dynamic>).length,
        config: config,
      );
    }
    return result;
  }

  @override
  T getValues<T>() {
    final result = _box.getValues<T>();
    if (result is Iterable) {
      _logger.db(
        source: _source,
        operation: 'list',
        table: _containerName,
        success: true,
        items: (result as Iterable<dynamic>).length,
        meta: {'target': 'values'},
        config: config,
      );
    }
    return result;
  }

  // --- Writes (async) -------------------------------------------------------

  @override
  Future<void> write(String key, dynamic value) => _logger.dbTrace(
        source: _source,
        operation: 'write',
        table: _containerName,
        key: key,
        run: () => _box.write(key, value),
        config: config,
      );

  @override
  void writeInMemory(String key, dynamic value) {
    _box.writeInMemory(key, value);
    _logger.db(
      source: _source,
      operation: 'write',
      table: _containerName,
      key: key,
      success: true,
      meta: {'memoryOnly': true},
      config: config,
    );
  }

  @override
  Future<void> writeIfNull(String key, dynamic value) => _logger.dbTrace(
        source: _source,
        operation: 'write',
        table: _containerName,
        key: key,
        meta: {'ifNull': true},
        run: () => _box.writeIfNull(key, value),
        config: config,
      );

  // --- Deletes (async) ------------------------------------------------------

  @override
  Future<void> remove(String key) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: _containerName,
        key: key,
        run: () => _box.remove(key),
        config: config,
      );

  @override
  Future<void> erase() => _logger.dbTrace(
        source: _source,
        operation: 'clear',
        table: _containerName,
        run: _box.erase,
        config: config,
      );

  // --- Persistence (passthrough) --------------------------------------------

  @override
  Future<void> save() => _box.save();

  // --- Observation (passthrough) --------------------------------------------

  @override
  VoidCallback listen(VoidCallback value) => _box.listen(value);

  @override
  VoidCallback listenKey(String key, ValueSetter<dynamic> callback) =>
      _box.listenKey(key, callback);

  @override
  Map<String, dynamic> get changes => _box.changes;

  @override
  ValueStorage<Map<String, dynamic>> get listenable => _box.listenable;

  // --- Lifecycle (passthrough) ----------------------------------------------

  @override
  Microtask get microtask => _box.microtask;

  @override
  GetQueue get queue => _box.queue;

  @override
  set queue(GetQueue value) => _box.queue = value;

  @override
  Future<bool> get initStorage => _box.initStorage;

  @override
  set initStorage(Future<bool> value) => _box.initStorage = value;

  // --- Helpers ---------------------------------------------------------------

  T? _logRead<T>(String key, T? result) {
    _logger.db(
      source: _source,
      operation: 'read',
      table: _containerName,
      key: key,
      success: true,
      cacheHit: result != null,
      config: config,
    );
    return result;
  }
}
