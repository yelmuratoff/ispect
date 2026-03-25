/// Ready-to-copy interceptor for **flutter_secure_storage**.
///
/// Wraps [FlutterSecureStorage] with logging via `ispectify_db`.
/// All values are **redacted by default** since secure storage
/// inherently holds sensitive data.
///
/// ## Setup
/// ```dart
/// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
///
/// const storage = FlutterSecureStorage();
/// final traced = ISpectSecureStorage(delegate: storage, logger: logger);
///
/// await traced.write(key: 'token', value: 'eyJhbGci...');
/// final token = await traced.read(key: 'token');
/// ```
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Wraps [FlutterSecureStorage] with `ispectify_db` logging.
///
/// Redaction is **forced on** by default — values in secure storage
/// should never appear in logs. Override with `forceRedact: false`
/// if you explicitly need to see values during development.
final class ISpectSecureStorage {
  const ISpectSecureStorage({
    required FlutterSecureStorage delegate,
    required ISpectLogger logger,
    String source = defaultSource,
    this.forceRedact = true,
  })  : _storage = delegate,
        _logger = logger,
        _source = source;

  final FlutterSecureStorage _storage;
  final ISpectLogger _logger;
  final String _source;
  final bool forceRedact;

  /// Default source identifier.
  static const defaultSource = 'secure_storage';

  /// The underlying [FlutterSecureStorage] instance.
  FlutterSecureStorage get delegate => _storage;

  Future<String?> read({required String key}) => _logger.dbTrace(
        source: _source,
        operation: 'read',
        key: key,
        redact: forceRedact,
        run: () => _storage.read(key: key),
        projectResult: (val) => val != null ? '***' : null,
      );

  Future<void> write({required String key, required String? value}) =>
      _logger.dbTrace(
        source: _source,
        operation: 'write',
        key: key,
        redact: forceRedact,
        run: () => _storage.write(key: key, value: value),
      );

  Future<void> delete({required String key}) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        key: key,
        run: () => _storage.delete(key: key),
      );

  Future<void> deleteAll() => _logger.dbTrace(
        source: _source,
        operation: 'clear',
        run: _storage.deleteAll,
      );

  Future<Map<String, String>> readAll() => _logger.dbTrace(
        source: _source,
        operation: 'list',
        redact: forceRedact,
        run: _storage.readAll,
        projectResult: (entries) => {'keys': entries.length},
      );

  Future<bool> containsKey({required String key}) => _logger.dbTrace(
        source: _source,
        operation: 'lookup',
        key: key,
        run: () => _storage.containsKey(key: key),
        projectResult: (exists) => {'exists': exists},
      );
}
