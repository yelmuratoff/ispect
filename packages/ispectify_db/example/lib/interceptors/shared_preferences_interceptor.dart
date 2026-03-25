/// Ready-to-copy interceptor for **shared_preferences**.
///
/// Wraps [SharedPreferences] with logging via `ispectify_db`.
///
/// ## Setup
/// ```dart
/// import 'package:shared_preferences/shared_preferences.dart';
///
/// final prefs = await SharedPreferences.getInstance();
/// final traced = ISpectSharedPreferences(delegate: prefs, logger: logger);
///
/// await traced.setString('theme', 'dark');
/// final theme = traced.getString('theme');
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [SharedPreferences] with `ispectify_db` logging.
///
/// Reads are synchronous (fire-and-forget via [db]).
/// Writes are async (traced via [dbTrace]).
final class ISpectSharedPreferences {
  const ISpectSharedPreferences({
    required SharedPreferences delegate,
    required ISpectLogger logger,
    String source = defaultSource,
  })  : _prefs = delegate,
        _logger = logger,
        _source = source;

  final SharedPreferences _prefs;
  final ISpectLogger _logger;
  final String _source;

  /// Default source identifier.
  static const defaultSource = 'shared_prefs';

  /// The underlying [SharedPreferences] instance.
  SharedPreferences get delegate => _prefs;

  // --- Reads (synchronous) ------------------------------------------------

  String? getString(String key) => _logRead(key, _prefs.getString(key));

  bool? getBool(String key) => _logRead(key, _prefs.getBool(key));

  int? getInt(String key) => _logRead(key, _prefs.getInt(key));

  double? getDouble(String key) => _logRead(key, _prefs.getDouble(key));

  List<String>? getStringList(String key) =>
      _logRead(key, _prefs.getStringList(key));

  bool containsKey(String key) {
    final result = _prefs.containsKey(key);
    _logger.db(
      source: _source,
      operation: 'lookup',
      key: key,
      success: true,
      cacheHit: result,
    );
    return result;
  }

  Set<String> getKeys() {
    final result = _prefs.getKeys();
    _logger.db(
      source: _source,
      operation: 'list',
      success: true,
      items: result.length,
    );
    return result;
  }

  // --- Writes (async) -----------------------------------------------------

  Future<bool> setString(String key, String value) =>
      _logWrite(key, () => _prefs.setString(key, value));

  // ignore: avoid_positional_boolean_parameters
  Future<bool> setBool(String key, bool value) =>
      _logWrite(key, () => _prefs.setBool(key, value));

  Future<bool> setInt(String key, int value) =>
      _logWrite(key, () => _prefs.setInt(key, value));

  Future<bool> setDouble(String key, double value) =>
      _logWrite(key, () => _prefs.setDouble(key, value));

  Future<bool> setStringList(String key, List<String> value) =>
      _logWrite(key, () => _prefs.setStringList(key, value));

  Future<bool> remove(String key) => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        key: key,
        run: () => _prefs.remove(key),
      );

  Future<bool> clear() => _logger.dbTrace(
        source: _source,
        operation: 'clear',
        run: _prefs.clear,
      );

  // --- Helpers -------------------------------------------------------------

  T? _logRead<T>(String key, T? result) {
    _logger.db(
      source: _source,
      operation: 'read',
      key: key,
      success: true,
      cacheHit: result != null,
    );
    return result;
  }

  Future<bool> _logWrite(String key, Future<bool> Function() action) =>
      _logger.dbTrace(
        source: _source,
        operation: 'write',
        key: key,
        run: action,
      );
}
