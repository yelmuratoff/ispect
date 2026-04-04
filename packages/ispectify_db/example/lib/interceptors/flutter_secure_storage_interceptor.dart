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

// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Wraps [FlutterSecureStorage] with `ispectify_db` logging.
///
/// This class implements [FlutterSecureStorage], allowing it to be used
/// as a drop-in replacement anywhere `FlutterSecureStorage` is expected.
///
/// Redaction is **forced on** by default — values in secure storage
/// should never appear in logs. Override with `forceRedact: false`
/// if you explicitly need to see values during development.
final class ISpectSecureStorage implements FlutterSecureStorage {
  const ISpectSecureStorage({
    required FlutterSecureStorage delegate,
    required ISpectLogger logger,
    String source = defaultSource,
    this.forceRedact = true,
    this.config = const ISpectDbConfig(),
  })  : _storage = delegate,
        _logger = logger,
        _source = source;

  final FlutterSecureStorage _storage;
  final ISpectLogger _logger;
  final String _source;

  /// Whether values should be redacted in logs (defaults to true).
  final bool forceRedact;
  final ISpectDbConfig config;

  /// Default source identifier.
  static const defaultSource = 'secure_storage';

  /// The underlying [FlutterSecureStorage] instance.
  FlutterSecureStorage get delegate => _storage;

  @override
  AndroidOptions get aOptions => _storage.aOptions;

  @override
  IOSOptions get iOptions => _storage.iOptions;

  @override
  LinuxOptions get lOptions => _storage.lOptions;

  @override
  AppleOptions get mOptions => _storage.mOptions;

  @override
  WebOptions get webOptions => _storage.webOptions;

  @override
  WindowsOptions get wOptions => _storage.wOptions;

  @override
  Map<String, List<ValueChanged<String?>>> get getListeners =>
      _storage.getListeners;

  @override
  Future<bool?> isCupertinoProtectedDataAvailable() => _logger.dbTrace(
        source: _source,
        operation: 'isCupertinoProtectedDataAvailable',
        run: _storage.isCupertinoProtectedDataAvailable,
        config: config,
      );

  @override
  Stream<bool>? get onCupertinoProtectedDataAvailabilityChanged =>
      _storage.onCupertinoProtectedDataAvailabilityChanged;

  @override
  void registerListener({
    required String key,
    required ValueChanged<String?> listener,
  }) {
    _logger.dbTraceSync(
      source: _source,
      operation: 'registerListener',
      key: key,
      run: () => _storage.registerListener(key: key, listener: listener),
      config: config,
    );
  }

  @override
  void unregisterAllListeners() {
    _logger.dbTraceSync(
      source: _source,
      operation: 'unregisterAllListeners',
      run: _storage.unregisterAllListeners,
      config: config,
    );
  }

  @override
  void unregisterAllListenersForKey({required String key}) {
    _logger.dbTraceSync(
      source: _source,
      operation: 'unregisterAllListenersForKey',
      key: key,
      run: () => _storage.unregisterAllListenersForKey(key: key),
      config: config,
    );
  }

  @override
  void unregisterListener({
    required String key,
    required ValueChanged<String?> listener,
  }) {
    _logger.dbTraceSync(
      source: _source,
      operation: 'unregisterListener',
      key: key,
      run: () => _storage.unregisterListener(key: key, listener: listener),
      config: config,
    );
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'read',
        key: key,
        redact: forceRedact,
        run: () => _storage.read(
          key: key,
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
        projectResult: (val) => val != null ? '***' : null,
        config: config,
      );

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'write',
        key: key,
        redact: forceRedact,
        run: () => _storage.write(
          key: key,
          value: value,
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
        config: config,
      );

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'delete',
        key: key,
        run: () => _storage.delete(
          key: key,
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
        config: config,
      );

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'clear',
        run: () => _storage.deleteAll(
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
        config: config,
      );

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'list',
        redact: forceRedact,
        run: () => _storage.readAll(
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
        projectResult: (entries) => {'keys': entries.length},
        config: config,
      );

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) =>
      _logger.dbTrace(
        source: _source,
        operation: 'lookup',
        key: key,
        run: () => _storage.containsKey(
          key: key,
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
        projectResult: (exists) => {'exists': exists},
        config: config,
      );
}
