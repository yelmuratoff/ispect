import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/bounded_log_buffer.dart';
import 'package:ispectify/src/history/file_log/file_log_codec.dart';
import 'package:ispectify/src/history/file_log/retention_planner.dart';
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
  static final RegExp _archiveNamePattern = RegExp(r'^\d{6}\.jsonl\.gz$');
  static final RegExp _dateNamePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _legacyNamePattern =
      RegExp(r'^logs_(\d{4}-\d{2}-\d{2})\.json$');

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
  String? _canonicalSessionDirectory;
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
      await _applyRetention();
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
    for (final artifact in await _scanArtifacts()) {
      await _deleteArtifact(artifact);
    }
    await _deleteEmptyDateDirectories();
  }

  @override
  Future<void> clearDateStorage(DateTime date) async {
    if (!_enabled) return;
    await _ensureInitialized();
    final directory = Directory(_dateDirectoryPath(date));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    final legacy = File(_legacyFilePath(date));
    if (await legacy.exists()) await legacy.delete();
  }

  @override
  Future<List<DateTime>> getAvailableLogDates() async {
    if (!_enabled) return const [];
    await _ensureInitialized();
    final dates = <DateTime>[];
    await for (final entity in Directory(sessionDirectory).list()) {
      final name = _basename(entity.path);
      if (entity is Directory && _dateNamePattern.hasMatch(name)) {
        final date = DateTime.tryParse(name);
        if (date != null) dates.add(date);
      } else if (entity is File) {
        final match = _legacyNamePattern.firstMatch(name);
        final date = DateTime.tryParse(match?.group(1) ?? '');
        if (date != null) dates.add(date);
      }
    }
    final uniqueDates = dates.toSet().toList()..sort();
    return uniqueDates;
  }

  @override
  Future<int> getDateFileSize(DateTime date) async {
    if (!_enabled) return 0;
    await _ensureInitialized();
    final directory = Directory(_dateDirectoryPath(date));
    var total = 0;
    if (await directory.exists()) {
      await for (final entity in directory.list()) {
        if (entity is File &&
            (_segmentNamePattern.hasMatch(_basename(entity.path)) ||
                _archiveNamePattern.hasMatch(_basename(entity.path)))) {
          total += await entity.length();
        }
      }
    }
    final legacy = File(_legacyFilePath(date));
    if (await legacy.exists()) total += await legacy.length();
    return total;
  }

  @override
  Future<bool> hasTodaySession() async =>
      await getLogPathByDate(DateTime.now()) != '';

  @override
  Future<List<ISpectLogData>> getLogsByDate(DateTime date) async {
    if (!_enabled) return const [];
    await _ensureInitialized();
    final files = <File>[];
    final directory = Directory(_dateDirectoryPath(date));
    if (await directory.exists()) {
      files.addAll(await _segmentFiles(directory, includeArchives: true));
    }
    final legacy = File(_legacyFilePath(date));
    if (await legacy.exists()) files.add(legacy);
    return _readFiles(files);
  }

  @override
  Future<String> getLogPathByDate(DateTime date) async {
    if (!_enabled) return '';
    await _ensureInitialized();
    final directory = Directory(_dateDirectoryPath(date));
    if (await directory.exists()) return directory.path;
    final legacy = File(_legacyFilePath(date));
    return await legacy.exists() ? legacy.path : '';
  }

  @override
  Future<List<ISpectLogData>> getLogsBySession(String sessionPath) async {
    if (!_enabled) return const [];
    await _ensureInitialized();
    await _assertManagedPath(sessionPath);
    final type = await FileSystemEntity.type(sessionPath);
    return switch (type) {
      FileSystemEntityType.directory
          when _isManagedDateDirectory(sessionPath) =>
        _readDirectory(Directory(sessionPath)),
      FileSystemEntityType.file when _isManagedHistoryFile(sessionPath) =>
        _readFiles([File(sessionPath)]),
      FileSystemEntityType.directory ||
      FileSystemEntityType.file =>
        throw const FileLogAccessException(operation: 'getLogsBySession'),
      _ => const <ISpectLogData>[],
    };
  }

  bool _isManagedDateDirectory(String path) =>
      _dateNamePattern.hasMatch(_basename(path)) &&
      Directory(path).parent.path == sessionDirectory;

  bool _isManagedHistoryFile(String path) {
    final name = _basename(path);
    if (_legacyNamePattern.hasMatch(name)) {
      return File(path).parent.path == sessionDirectory;
    }
    return (_segmentNamePattern.hasMatch(name) ||
            _archiveNamePattern.hasMatch(name)) &&
        _dateNamePattern.hasMatch(_basename(File(path).parent.path)) &&
        File(path).parent.parent.path == sessionDirectory;
  }

  @override
  Future<SessionStatistics> getSessionStatistics() async {
    final dates = await getAvailableLogDates();
    var totalSize = 0;
    var totalEntries = 0;
    for (final date in dates) {
      totalSize += await getDateFileSize(date);
      totalEntries += await _countDateEntries(date);
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
      _canonicalSessionDirectory = await directory.resolveSymbolicLinks();
      _resolvedTodaySessionPath = _join(
        _join(directory.path, _dateName(DateTime.now())),
        '000000.jsonl',
      );
      await _applyRetention();
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

  Future<List<File>> _segmentFiles(
    Directory directory, {
    bool includeArchives = false,
  }) async {
    final files = <File>[];
    await for (final entity in directory.list()) {
      final name = _basename(entity.path);
      if (entity is File &&
          (_segmentNamePattern.hasMatch(name) ||
              includeArchives && _archiveNamePattern.hasMatch(name))) {
        files.add(entity);
      }
    }
    files.sort((left, right) => left.path.compareTo(right.path));
    return files;
  }

  Future<List<ISpectLogData>> _readDirectory(Directory directory) async {
    if (!await directory.exists()) return const [];
    return _readFiles(await _segmentFiles(directory, includeArchives: true));
  }

  Future<List<ISpectLogData>> _readFiles(Iterable<File> files) async {
    final byId = <String, ISpectLogData>{};
    for (final file in files) {
      final name = _basename(file.path);
      if (_legacyNamePattern.hasMatch(name)) {
        final input = await file.readAsString();
        for (final log in _codec.decodeLegacyArray(input)) {
          byId.putIfAbsent(log.id, () => log);
        }
        continue;
      }

      List<int> bytes;
      try {
        bytes = await _readSegmentBytes(file);
      } catch (error, stackTrace) {
        _reportError(
          FileLogFormatException(
            operation: 'readSegment',
            path: file.path,
            cause: error,
            stackTrace: stackTrace,
          ),
        );
        continue;
      }
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

  Future<List<int>> _readSegmentBytes(File file) async {
    if (!file.path.endsWith('.gz')) return file.readAsBytes();
    final builder = BytesBuilder(copy: false);
    await file.openRead().transform(gzip.decoder).forEach(builder.add);
    return builder.takeBytes();
  }

  Future<int> _countDateEntries(DateTime date) async {
    var count = 0;
    final directory = Directory(_dateDirectoryPath(date));
    if (await directory.exists()) {
      final files = await _segmentFiles(directory, includeArchives: true);
      for (final file in files) {
        final bytes = await _readSegmentBytes(file);
        final completeLength = bytes.isNotEmpty && bytes.last == 0x0A
            ? bytes.length
            : bytes.lastIndexOf(0x0A) + 1;
        if (completeLength == 0) continue;
        count += const LineSplitter()
            .convert(
              utf8.decode(
                bytes.sublist(0, completeLength),
                allowMalformed: true,
              ),
            )
            .where((line) => line.isNotEmpty)
            .length;
      }
    }
    final legacy = File(_legacyFilePath(date));
    if (await legacy.exists()) {
      count += _codec.decodeLegacyArray(await legacy.readAsString()).length;
    }
    return count;
  }

  Future<void> _assertManagedPath(String candidatePath) async {
    final canonicalRoot = _canonicalSessionDirectory;
    if (canonicalRoot == null) {
      throw const FileLogAccessException(operation: 'getLogsBySession');
    }

    final type = await FileSystemEntity.type(candidatePath);
    if (type == FileSystemEntityType.notFound) {
      final hasTraversal = candidatePath
          .split(RegExp(r'[/\\]+'))
          .any((segment) => segment == '..');
      if (!hasTraversal && _isWithinRoot(candidatePath, sessionDirectory)) {
        return;
      }
      throw const FileLogAccessException(operation: 'getLogsBySession');
    }

    final canonicalCandidate = switch (type) {
      FileSystemEntityType.directory =>
        await Directory(candidatePath).resolveSymbolicLinks(),
      FileSystemEntityType.file =>
        await File(candidatePath).resolveSymbolicLinks(),
      FileSystemEntityType.link =>
        await Link(candidatePath).resolveSymbolicLinks(),
      _ => candidatePath,
    };
    if (!_isWithinRoot(canonicalCandidate, canonicalRoot)) {
      throw const FileLogAccessException(operation: 'getLogsBySession');
    }
  }

  bool _isWithinRoot(String path, String root) =>
      path == root || path.startsWith('$root${Platform.pathSeparator}');

  Future<void> _applyRetention() async {
    while (true) {
      final artifacts = await _scanArtifacts();
      final actions = RetentionPlanner(_options).plan(artifacts);
      if (actions.isEmpty) return;

      for (final action in actions) {
        switch (action) {
          case DeleteArtifact():
            await _deleteArtifact(action.artifact);
          case ArchiveArtifact():
            await _archiveArtifact(action.artifact);
        }
      }
      await _deleteEmptyDateDirectories();
    }
  }

  Future<List<FileLogArtifact>> _scanArtifacts() async {
    final artifacts = <FileLogArtifact>[];
    final root = Directory(sessionDirectory);
    await for (final entity in root.list()) {
      final name = _basename(entity.path);
      if (entity is Directory && _dateNamePattern.hasMatch(name)) {
        final date = DateTime.tryParse(name);
        if (date == null) continue;
        final files = <File>[];
        await for (final child in entity.list()) {
          if (child is File) files.add(child);
        }
        final liveSegments = files
            .where((file) => _segmentNamePattern.hasMatch(_basename(file.path)))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
        final activePath =
            name == _dateName(DateTime.now()) && liveSegments.isNotEmpty
                ? liveSegments.last.path
                : null;
        for (final file in files) {
          final fileName = _basename(file.path);
          final isSegment = _segmentNamePattern.hasMatch(fileName);
          final isArchive = _archiveNamePattern.hasMatch(fileName);
          final isTemporary = fileName.endsWith('.tmp');
          if (!isSegment && !isArchive && !isTemporary) continue;
          artifacts.add(
            FileLogArtifact(
              path: file.path,
              date: date,
              size: await file.length(),
              isActive: file.path == activePath,
              isArchive: isArchive,
              isTemporary: isTemporary,
              canArchive: isSegment,
            ),
          );
        }
      } else if (entity is File) {
        final legacyMatch = _legacyNamePattern.firstMatch(name);
        final legacyDate = DateTime.tryParse(legacyMatch?.group(1) ?? '');
        if (legacyDate != null) {
          artifacts.add(
            FileLogArtifact(
              path: entity.path,
              date: legacyDate,
              size: await entity.length(),
              canArchive: false,
            ),
          );
        } else if (name.endsWith('.tmp')) {
          artifacts.add(
            FileLogArtifact(
              path: entity.path,
              date: DateTime.fromMillisecondsSinceEpoch(0),
              size: await entity.length(),
              isTemporary: true,
              canArchive: false,
            ),
          );
        }
      }
    }
    return artifacts;
  }

  Future<void> _deleteArtifact(FileLogArtifact artifact) async {
    final file = File(artifact.path);
    if (await file.exists()) await file.delete();
  }

  Future<void> _archiveArtifact(FileLogArtifact artifact) async {
    final source = File(artifact.path);
    final target = File('${source.path}.gz');
    final temporary = File('${target.path}.tmp');
    var renamed = false;
    try {
      await source
          .openRead()
          .transform(gzip.encoder)
          .pipe(temporary.openWrite());
      await temporary.rename(target.path);
      renamed = true;
      await source.delete();
    } catch (error, stackTrace) {
      throw FileLogStorageException(
        operation: 'archive',
        path: source.path,
        cause: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!renamed && await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _deleteEmptyDateDirectories() async {
    await for (final entity in Directory(sessionDirectory).list()) {
      if (entity is! Directory ||
          !_dateNamePattern.hasMatch(_basename(entity.path))) {
        continue;
      }
      if (!await entity.list().isEmpty) continue;
      await entity.delete();
    }
  }

  String _dateDirectoryPath(DateTime date) =>
      _join(sessionDirectory, _dateName(date));

  String _legacyFilePath(DateTime date) =>
      _join(sessionDirectory, 'logs_${_dateName(date)}.json');

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
