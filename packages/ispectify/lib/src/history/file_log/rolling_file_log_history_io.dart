import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/bounded_log_buffer.dart';
import 'package:ispectify/src/history/file_log/file_log_codec.dart';
import 'package:ispectify/src/models/log_id.dart';
import 'package:meta/meta.dart';

final class RollingFileLogHistory implements FileLogHistory {
  RollingFileLogHistory(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    FileLogHistoryOptions options = const FileLogHistoryOptions(),
    RedactionService? redactor,
  }) : this._(
          loggerOptions,
          directoryProvider: directoryProvider,
          options: options,
          redactor: redactor,
          enabled: kISpectEnabled,
        );

  @visibleForTesting
  RollingFileLogHistory.testing(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    FileLogHistoryOptions options = const FileLogHistoryOptions(),
    RedactionService? redactor,
  }) : this._(
          loggerOptions,
          directoryProvider: directoryProvider,
          options: options,
          redactor: redactor,
          enabled: true,
        );

  RollingFileLogHistory._(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    required FileLogHistoryOptions options,
    required RedactionService? redactor,
    required bool enabled,
  })  : _directoryProvider = directoryProvider,
        _options = options,
        _enabled = enabled,
        _buffer = BoundedLogBuffer(loggerOptions),
        _codec = FileLogCodec(redactor: redactor ?? RedactionService()),
        _sessionId = LogId.generate(),
        _autoSaveInterval = options.autoSaveInterval,
        _autoSaveEnabled = options.enableAutoSave {
    options.validate();
  }

  static final RegExp _segmentNamePattern = RegExp(r'^\d{6}\.jsonl$');
  static final RegExp _dateNamePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  final FileLogDirectoryProvider _directoryProvider;
  final FileLogHistoryOptions _options;
  final bool _enabled;
  final BoundedLogBuffer _buffer;
  final FileLogCodec _codec;
  final String _sessionId;
  final LinkedHashMap<String, _PendingLog> _pending =
      LinkedHashMap<String, _PendingLog>();

  Future<void>? _initialization;
  String? _resolvedSessionDirectory;
  String? _resolvedTodaySessionPath;
  Duration _autoSaveInterval;
  bool _autoSaveEnabled;

  @override
  List<ISpectLogData> get history => _buffer.history;

  @override
  String get sessionDirectory =>
      _resolvedSessionDirectory ??
      (throw StateError('File log history is not initialized'));

  @override
  String get todaySessionPath =>
      _resolvedTodaySessionPath ??
      (throw StateError('File log history is not initialized'));

  @override
  void add(ISpectLogData data) {
    if (!_enabled || !_buffer.add(data)) return;
    _pending[data.id] = _PendingLog(log: data, sessionId: _sessionId);
  }

  @override
  void clear() {
    _buffer.clear();
    _pending.clear();
  }

  @override
  void dispose() {}

  @override
  Future<void> saveToDailyFile() async {
    if (!_enabled) return;
    await _ensureInitialized();
    if (_pending.isEmpty) return;

    final snapshot = List<_PendingLog>.of(_pending.values);
    try {
      for (final pending in snapshot) {
        final encoded = _codec.encode(
          pending.log,
          sessionId: pending.sessionId,
          maxBytes: _options.maxFileSize,
        );
        await _appendRecord(pending.log.time, encoded.bytes);
      }
      for (final pending in snapshot) {
        _pending.remove(pending.log.id);
      }
    } on FileLogHistoryException {
      rethrow;
    } catch (error, stackTrace) {
      throw FileLogStorageException(
        operation: 'saveToDailyFile',
        path: _resolvedSessionDirectory,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> loadFromDate(DateTime date) async {
    if (!_enabled) return;
    _buffer.replaceAll(await getLogsByDate(date));
  }

  @override
  Future<void> loadTodayHistory() => loadFromDate(DateTime.now());

  @override
  Future<String> exportToJson() async {
    final records = <Object?>[];
    for (final log in history) {
      final encoded = _codec.encode(
        log,
        sessionId: _sessionId,
        maxBytes: _options.maxFileSize,
      );
      records.add(jsonDecode(utf8.decode(encoded.bytes).trim()));
    }
    return jsonEncode(records);
  }

  @override
  Future<void> importFromJson(String jsonString) async {
    _codec.decodeLegacyArray(jsonString).forEach(add);
  }

  @override
  Future<void> clearAllFileStorage() async {
    if (!_enabled) return;
    await _ensureInitialized();
    final directory = Directory(sessionDirectory);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    _initialization = null;
    _resolvedSessionDirectory = null;
    _resolvedTodaySessionPath = null;
  }

  @override
  Future<void> clearDateStorage(DateTime date) async {
    if (!_enabled) return;
    await _ensureInitialized();
    final directory = Directory(_dateDirectoryPath(date));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  @override
  Future<List<DateTime>> getAvailableLogDates() async {
    if (!_enabled) return const [];
    await _ensureInitialized();
    final dates = <DateTime>[];
    await for (final entity in Directory(sessionDirectory).list()) {
      if (entity is! Directory) continue;
      final name = _basename(entity.path);
      if (!_dateNamePattern.hasMatch(name)) continue;
      final date = DateTime.tryParse(name);
      if (date != null) dates.add(date);
    }
    dates.sort();
    return dates;
  }

  @override
  Future<int> getDateFileSize(DateTime date) async {
    if (!_enabled) return 0;
    await _ensureInitialized();
    final directory = Directory(_dateDirectoryPath(date));
    if (!await directory.exists()) return 0;

    var total = 0;
    await for (final entity in directory.list()) {
      if (entity is File &&
          _segmentNamePattern.hasMatch(_basename(entity.path))) {
        total += await entity.length();
      }
    }
    return total;
  }

  @override
  Future<bool> hasTodaySession() async =>
      await getLogPathByDate(DateTime.now()) != '';

  @override
  Future<List<ISpectLogData>> getLogsByDate(DateTime date) async {
    if (!_enabled) return const [];
    await _ensureInitialized();
    return _readDirectory(Directory(_dateDirectoryPath(date)));
  }

  @override
  Future<String> getLogPathByDate(DateTime date) async {
    if (!_enabled) return '';
    await _ensureInitialized();
    final directory = Directory(_dateDirectoryPath(date));
    return await directory.exists() ? directory.path : '';
  }

  @override
  Future<List<ISpectLogData>> getLogsBySession(String sessionPath) async {
    if (!_enabled) return const [];
    await _ensureInitialized();
    final type = await FileSystemEntity.type(sessionPath);
    return switch (type) {
      FileSystemEntityType.directory => _readDirectory(Directory(sessionPath)),
      FileSystemEntityType.file => _readFiles([File(sessionPath)]),
      _ => const <ISpectLogData>[],
    };
  }

  @override
  Future<SessionStatistics> getSessionStatistics() async {
    final dates = await getAvailableLogDates();
    var totalSize = 0;
    var totalEntries = 0;
    for (final date in dates) {
      totalSize += await getDateFileSize(date);
      totalEntries += (await getLogsByDate(date)).length;
    }
    return SessionStatistics(
      totalDays: dates.length,
      totalSize: totalSize,
      totalEntries: totalEntries,
      oldestDate: dates.firstOrNull,
      newestDate: dates.lastOrNull,
      maxSessionDays: _options.maxSessionDays,
      autoSaveInterval: _autoSaveInterval,
      enableAutoSave: _autoSaveEnabled,
      maxFileSize: _options.maxFileSize,
      cleanupStrategy: _options.cleanupStrategy,
      maxTotalSize: _options.maxTotalSize,
    );
  }

  @override
  void updateAutoSaveSettings({bool? enabled, Duration? interval}) {
    if (interval != null && interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval');
    }
    _autoSaveEnabled = enabled ?? _autoSaveEnabled;
    _autoSaveInterval = interval ?? _autoSaveInterval;
  }

  Future<void> _ensureInitialized() =>
      _initialization ??= _initializeDirectory();

  Future<void> _initializeDirectory() async {
    try {
      final root = await _directoryProvider();
      final directory = Directory(_join(root, 'ispect_logs'));
      await directory.create(recursive: true);
      _resolvedSessionDirectory = directory.path;
      _resolvedTodaySessionPath = _join(
        _join(directory.path, _dateName(DateTime.now())),
        '000000.jsonl',
      );
    } catch (error, stackTrace) {
      throw FileLogStorageException(
        operation: 'initialize',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _appendRecord(DateTime date, List<int> bytes) async {
    final directory = Directory(_dateDirectoryPath(date));
    await directory.create(recursive: true);
    final segments = await _segmentFiles(directory);
    var active = segments.isEmpty
        ? File(_join(directory.path, '000000.jsonl'))
        : segments.last;
    final currentLength = await active.exists() ? await active.length() : 0;
    if (currentLength > 0 &&
        currentLength + bytes.length > _options.maxFileSize) {
      final currentIndex = segments.isEmpty
          ? 0
          : int.parse(_basename(active.path).substring(0, 6));
      active = File(
        _join(
          directory.path,
          '${(currentIndex + 1).toString().padLeft(6, '0')}.jsonl',
        ),
      );
    }
    await active.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    if (_dateName(date) == _dateName(DateTime.now())) {
      _resolvedTodaySessionPath = active.path;
    }
  }

  Future<List<File>> _segmentFiles(Directory directory) async {
    final files = <File>[];
    await for (final entity in directory.list()) {
      if (entity is File &&
          _segmentNamePattern.hasMatch(_basename(entity.path))) {
        files.add(entity);
      }
    }
    files.sort((left, right) => left.path.compareTo(right.path));
    return files;
  }

  Future<List<ISpectLogData>> _readDirectory(Directory directory) async {
    if (!await directory.exists()) return const [];
    return _readFiles(await _segmentFiles(directory));
  }

  Future<List<ISpectLogData>> _readFiles(Iterable<File> files) async {
    final byId = <String, ISpectLogData>{};
    for (final file in files) {
      for (final line in await file.readAsLines()) {
        if (line.isEmpty) continue;
        final log = _codec.decodeLine(line);
        byId.putIfAbsent(log.id, () => log);
      }
    }
    final logs = byId.values.toList()
      ..sort((left, right) {
        final byTime = left.time.compareTo(right.time);
        return byTime != 0 ? byTime : left.id.compareTo(right.id);
      });
    return logs;
  }

  String _dateDirectoryPath(DateTime date) =>
      _join(sessionDirectory, _dateName(date));

  String _dateName(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _join(String parent, String child) =>
      parent.endsWith(Platform.pathSeparator)
          ? '$parent$child'
          : '$parent${Platform.pathSeparator}$child';

  String _basename(String path) => path.split(Platform.pathSeparator).last;
}

final class _PendingLog {
  const _PendingLog({required this.log, required this.sessionId});

  final ISpectLogData log;
  final String sessionId;
}
