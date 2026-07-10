import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
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
          timerFactory: null,
        );

  @visibleForTesting
  RollingFileLogHistory.testing(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    FileLogHistoryOptions options = const FileLogHistoryOptions(),
    RedactionService? redactor,
    Timer Function(Duration, void Function())? timerFactory,
  }) : this._(
          loggerOptions,
          directoryProvider: directoryProvider,
          options: options,
          redactor: redactor,
          enabled: true,
          timerFactory: timerFactory,
        );

  RollingFileLogHistory._(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    required FileLogHistoryOptions options,
    required RedactionService? redactor,
    required bool enabled,
    required Timer Function(Duration, void Function())? timerFactory,
  })  : _directoryProvider = directoryProvider,
        _options = options,
        _enabled = enabled,
        _loggerOptions = loggerOptions,
        _buffer = BoundedLogBuffer(loggerOptions),
        _codec = FileLogCodec(redactor: redactor ?? RedactionService()),
        _sessionId = LogId.generate(),
        _timerFactory = timerFactory ?? Timer.new,
        _autoSaveInterval = options.autoSaveInterval,
        _autoSaveEnabled = options.enableAutoSave {
    options.validate();
  }

  static final RegExp _segmentNamePattern = RegExp(r'^\d{6}\.jsonl$');
  static final RegExp _dateNamePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  final FileLogDirectoryProvider _directoryProvider;
  final FileLogHistoryOptions _options;
  final bool _enabled;
  final ISpectLoggerOptions _loggerOptions;
  final BoundedLogBuffer _buffer;
  final FileLogCodec _codec;
  final String _sessionId;
  final Timer Function(Duration, void Function()) _timerFactory;
  final LinkedHashMap<String, _PendingLog> _pending =
      LinkedHashMap<String, _PendingLog>();

  Future<void>? _initialization;
  Future<void> _operationChain = Future<void>.value();
  String? _resolvedSessionDirectory;
  String? _resolvedTodaySessionPath;
  Timer? _autoSaveTimer;
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
    _add(data, sessionId: _sessionId);
  }

  void _add(ISpectLogData data, {required String sessionId}) {
    if (!_enabled || !_buffer.add(data)) return;
    final maxPending = _loggerOptions.maxHistoryItems;
    if (_pending.length >= maxPending && _pending.isNotEmpty) {
      _pending.remove(_pending.keys.first);
      _reportError(
        const FileLogLimitException(operation: 'pendingBufferOverflow'),
      );
    }
    _pending[data.id] = _PendingLog(log: data, sessionId: sessionId);
    if (_autoSaveEnabled) {
      _scheduleAutoSave(
        _pending.length >= _options.maxBatchItems
            ? Duration.zero
            : _autoSaveInterval,
      );
    }
  }

  @override
  void clear() {
    _buffer.clear();
    _pending.clear();
  }

  void _restorePending(LinkedHashMap<String, _PendingLog> failed) {
    final newer = LinkedHashMap<String, _PendingLog>.of(_pending);
    _pending
      ..clear()
      ..addAll(failed);
    for (final entry in newer.entries) {
      _pending.putIfAbsent(entry.key, () => entry.value);
    }
  }

  void _scheduleAutoSave(Duration duration) {
    if (!_autoSaveEnabled || _pending.isEmpty) return;
    if (_autoSaveTimer?.isActive ?? false) {
      if (duration != Duration.zero) return;
      _autoSaveTimer!.cancel();
    }
    _autoSaveTimer = _timerFactory(duration, () {
      _autoSaveTimer = null;
      unawaited(_runBackgroundFlush());
    });
  }

  Future<void> _runBackgroundFlush() async {
    try {
      await _enqueueFlush();
    } on FileLogHistoryException catch (error) {
      _reportError(error);
    }
  }

  void _reportError(FileLogHistoryException error) {
    final handler = _options.onError;
    if (handler != null) {
      try {
        handler(error);
        return;
      } catch (_) {
        // Fall through to the internal non-reentrant diagnostic sink.
      }
    }
    developer.log('[ISpect] $error', name: 'ispectify.file-history');
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  @override
  Future<void> saveToDailyFile() {
    if (!_enabled) return Future<void>.value();
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    return _enqueueFlush();
  }

  Future<void> _enqueueFlush() {
    final completer = Completer<void>();
    final previous = _operationChain;
    _operationChain = () async {
      await previous;
      try {
        await _flushPending();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }();
    return completer.future;
  }

  Future<void> _flushPending() async {
    final snapshot = LinkedHashMap<String, _PendingLog>.of(_pending);
    _pending.clear();
    try {
      await _ensureInitialized();
      for (final pending in snapshot.values.toList(growable: false)) {
        final encoded = _codec.encode(
          pending.log,
          sessionId: pending.sessionId,
          maxBytes: _options.maxFileSize,
        );
        await _appendRecord(pending.log.time, encoded.bytes);
        snapshot.remove(pending.log.id);
      }
    } catch (error, stackTrace) {
      _restorePending(snapshot);
      if (error is FileLogHistoryException) rethrow;
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
    if (utf8.encode(jsonString).length > _options.maxTotalSize) {
      throw const FileLogLimitException(operation: 'importFromJson');
    }
    final trimmed = jsonString.trim();
    if (trimmed.isEmpty) {
      throw const FileLogFormatException(operation: 'importFromJson');
    }

    final logs = trimmed.startsWith('[')
        ? _codec.decodeLegacyArray(trimmed)
        : trimmed
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map(_codec.decodeLine)
            .toList(growable: false);
    final importSessionId = LogId.generate();
    for (final log in logs) {
      final storedSessionId = log.additionalData?[TraceKeys.sessionId];
      _add(
        log,
        sessionId: storedSessionId is String && storedSessionId.isNotEmpty
            ? storedSessionId
            : importSessionId,
      );
    }
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
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    if (_autoSaveEnabled && _pending.isNotEmpty) {
      _scheduleAutoSave(_autoSaveInterval);
    }
  }

  Future<void> _ensureInitialized() async {
    final existing = _initialization;
    if (existing != null) return existing;

    final initialization = _initializeDirectory();
    _initialization = initialization;
    try {
      await initialization;
    } catch (_) {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
      rethrow;
    }
  }

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
    final tailIsAppendable = await _repairIncompleteTail(active);
    final currentLength = await active.exists() ? await active.length() : 0;
    if (!tailIsAppendable ||
        currentLength > 0 &&
            currentLength + bytes.length > _options.maxFileSize) {
      active = _nextSegment(directory, active, segments.isNotEmpty);
    }
    await active.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    if (_dateName(date) == _dateName(DateTime.now())) {
      _resolvedTodaySessionPath = active.path;
    }
  }

  File _nextSegment(Directory directory, File active, bool hasSegments) {
    final currentIndex =
        hasSegments ? int.parse(_basename(active.path).substring(0, 6)) : 0;
    return File(
      _join(
        directory.path,
        '${(currentIndex + 1).toString().padLeft(6, '0')}.jsonl',
      ),
    );
  }

  Future<bool> _repairIncompleteTail(File file) async {
    if (!await file.exists()) return true;
    final handle = await file.open(mode: FileMode.append);
    try {
      final length = await handle.length();
      if (length == 0) return true;
      await handle.setPosition(length - 1);
      if (await handle.readByte() == 0x0A) return true;

      const chunkSize = 8192;
      var cursor = length;
      while (cursor > 0) {
        final start = cursor > chunkSize ? cursor - chunkSize : 0;
        await handle.setPosition(start);
        final chunk = await handle.read(cursor - start);
        for (var index = chunk.length - 1; index >= 0; index--) {
          if (chunk[index] == 0x0A) {
            await handle.truncate(start + index + 1);
            return true;
          }
        }
        cursor = start;
      }
      return false;
    } finally {
      await handle.close();
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
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      final completeLength =
          bytes.last == 0x0A ? bytes.length : bytes.lastIndexOf(0x0A) + 1;
      if (completeLength == 0) continue;
      final text = utf8.decode(
        bytes.sublist(0, completeLength),
        allowMalformed: true,
      );
      for (final line in const LineSplitter().convert(text)) {
        if (line.isEmpty) continue;
        try {
          final log = _codec.decodeLine(line);
          byId.putIfAbsent(log.id, () => log);
        } on FileLogFormatException catch (error) {
          _reportError(error);
        }
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
