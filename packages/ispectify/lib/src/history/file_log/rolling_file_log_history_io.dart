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
import 'package:ispectify/src/utils/bounded_json_decoder.dart';
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
          ioHook: null,
          archiveCompressedByteLimit: null,
        );

  @visibleForTesting
  RollingFileLogHistory.testing(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    FileLogHistoryOptions options = const FileLogHistoryOptions(),
    RedactionService? redactor,
    Timer Function(Duration, void Function())? timerFactory,
    FutureOr<void> Function(File file, String operation)? ioHook,
    int? archiveCompressedByteLimit,
  }) : this._(
          loggerOptions,
          directoryProvider: directoryProvider,
          options: options,
          redactor: redactor,
          enabled: kISpectEnabled,
          timerFactory: timerFactory,
          ioHook: ioHook,
          archiveCompressedByteLimit: archiveCompressedByteLimit,
        );

  RollingFileLogHistory._(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    required FileLogHistoryOptions options,
    required RedactionService? redactor,
    required bool enabled,
    required Timer Function(Duration, void Function())? timerFactory,
    required FutureOr<void> Function(File file, String operation)? ioHook,
    required int? archiveCompressedByteLimit,
  })  : _directoryProvider = directoryProvider,
        _options = options,
        _enabled = enabled,
        _loggerOptions = loggerOptions,
        _buffer = BoundedLogBuffer(loggerOptions),
        _codec = FileLogCodec(redactor: redactor),
        _redactorOverride = redactor,
        _sessionId = LogId.generate(),
        _timerFactory = timerFactory ?? Timer.new,
        _ioHook = ioHook,
        _archiveCompressedByteLimit = archiveCompressedByteLimit,
        _autoSaveInterval = options.autoSaveInterval,
        _autoSaveEnabled = options.enableAutoSave {
    options.validate();
    if (archiveCompressedByteLimit != null && archiveCompressedByteLimit < 1) {
      throw ArgumentError.value(
        archiveCompressedByteLimit,
        'archiveCompressedByteLimit',
      );
    }
  }

  static final RegExp _segmentNamePattern = RegExp(r'^\d{6}\.jsonl$');
  static final RegExp _archiveNamePattern = RegExp(r'^\d{6}\.jsonl\.gz$');
  static final RegExp _temporaryArchiveNamePattern = RegExp(
    r'^\d{6}\.jsonl\.gz(?:\.[0-9A-HJKMNP-TV-Z]{26})?\.tmp$',
  );
  static final RegExp _dateNamePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _legacyNamePattern =
      RegExp(r'^logs_(\d{4}-\d{2}-\d{2})\.json$');
  static const int _ioChunkSize = 64 * 1024;

  final FileLogDirectoryProvider _directoryProvider;
  final FileLogHistoryOptions _options;
  final bool _enabled;
  final ISpectLoggerOptions _loggerOptions;
  final BoundedLogBuffer _buffer;
  final FileLogCodec _codec;
  final RedactionService? _redactorOverride;
  final String _sessionId;
  final Timer Function(Duration, void Function()) _timerFactory;
  final FutureOr<void> Function(File file, String operation)? _ioHook;
  final int? _archiveCompressedByteLimit;
  final LinkedHashMap<String, _PendingLog> _pending =
      LinkedHashMap<String, _PendingLog>();
  final LinkedHashMap<String, String> _sessionIdsByLogId =
      LinkedHashMap<String, String>();

  RedactionService get _redactor =>
      ISpectRedaction.resolveService(service: _redactorOverride);

  int get _managedArtifactLimit {
    // Every artifact created by this implementation contains at least one
    // bounded JSONL record. The small floor also leaves room for crash
    // temporaries without coupling durable storage to the in-memory history
    // setting.
    const conservativeMinimumArtifactBytes = 64;
    return _options.maxTotalSize ~/ conservativeMinimumArtifactBytes +
        _options.maxSessionDays * 2 +
        2;
  }

  Future<void>? _initialization;
  Future<void> _operationChain = Future<void>.value();
  String? _resolvedProviderDirectory;
  String? _canonicalProviderDirectory;
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
    if (!_enabled) return;
    final captured = captureISpectLogDataForEgress(data);
    final ISpectLogData storedData;
    if (data is ISpectLogError && captured.error != null) {
      storedData = ISpectLogError(
        captured.error!,
        message:
            captured.message is String ? captured.message! as String : null,
        id: captured.id,
        time: captured.time,
        key: captured.key,
        logLevel: captured.logLevel,
        pen: captured.pen,
        additionalData: captured.additionalData,
        stackTrace: captured.stackTrace,
      );
    } else if (data is ISpectLogException && captured.exception is Exception) {
      storedData = ISpectLogException(
        captured.exception! as Exception,
        message:
            captured.message is String ? captured.message! as String : null,
        id: captured.id,
        time: captured.time,
        key: captured.key,
        logLevel: captured.logLevel,
        pen: captured.pen,
        additionalData: captured.additionalData,
        stackTrace: captured.stackTrace,
      );
    } else {
      storedData = ISpectLogData(
        captured.message,
        id: captured.id,
        time: captured.time,
        key: captured.key,
        logLevel: captured.logLevel,
        pen: captured.pen,
        additionalData: captured.additionalData,
        exception: captured.exception,
        error: captured.error,
        stackTrace: captured.stackTrace,
      );
    }
    if (!_buffer.add(storedData)) return;
    final maxPending = _loggerOptions.maxHistoryItems;
    _sessionIdsByLogId[captured.id] = sessionId;
    while (_sessionIdsByLogId.length > maxPending) {
      _sessionIdsByLogId.remove(_sessionIdsByLogId.keys.first);
    }
    if (_pending.length >= maxPending && _pending.isNotEmpty) {
      _pending.remove(_pending.keys.first);
      _reportError(
        const FileLogLimitException(operation: 'pendingBufferOverflow'),
      );
    }
    _pending[captured.id] = _PendingLog(
      id: captured.id,
      time: captured.time,
      log: storedData,
      sessionId: sessionId,
    );
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
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _buffer.clear();
    _pending.clear();
    _sessionIdsByLogId.clear();
  }

  void _restorePending(LinkedHashMap<String, _PendingLog> failed) {
    final newer = LinkedHashMap<String, _PendingLog>.of(_pending);
    _pending
      ..clear()
      ..addAll(failed);
    for (final entry in newer.entries) {
      _pending.putIfAbsent(entry.key, () => entry.value);
    }
    while (_pending.length > _loggerOptions.maxHistoryItems) {
      _pending.remove(_pending.keys.first);
      _reportError(
        const FileLogLimitException(operation: 'pendingBufferOverflow'),
      );
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
    final safeError = _sanitizeError(error);
    final handler = _options.onError;
    if (handler != null) {
      try {
        handler(safeError);
        return;
      } catch (_) {
        // Fall through to the internal non-reentrant diagnostic sink.
      }
    }
    final safeText = _safeDiagnosticText(safeError);
    developer.log('[ISpect] $safeText', name: 'ispectify.file-history');
  }

  FileLogHistoryException _sanitizeError(FileLogHistoryException error) {
    if (!ISpectRedaction.enabled) return error;
    final path = error.path == null ? null : defaultPlaceholder;
    final cause = error.cause == null ? null : defaultPlaceholder;
    final stackTrace = error.stackTrace == null
        ? null
        : StackTrace.fromString(defaultPlaceholder);
    return switch (error) {
      FileLogStorageException() => FileLogStorageException(
          operation: error.operation,
          path: path,
          cause: cause,
          stackTrace: stackTrace,
        ),
      FileLogFormatException() => FileLogFormatException(
          operation: error.operation,
          path: path,
          cause: cause,
          stackTrace: stackTrace,
        ),
      FileLogAccessException() => FileLogAccessException(
          operation: error.operation,
          path: path,
          cause: cause,
          stackTrace: stackTrace,
        ),
      FileLogLimitException() => FileLogLimitException(
          operation: error.operation,
          path: path,
          cause: cause,
          stackTrace: stackTrace,
        ),
    };
  }

  String _safeDiagnosticText(Object value) {
    try {
      final bounded = LogExportOutput.boundJsonValue(
        _redactor.redactForExport(value),
        replaceOversizedStrings: true,
      );
      final text = switch (bounded) {
        null => defaultPlaceholder,
        final String text => text,
        final bool primitive => primitive.toString(),
        final num primitive => primitive.toString(),
        final Map<Object?, Object?> map => jsonEncode(map),
        final List<Object?> list => jsonEncode(list),
        _ => defaultPlaceholder,
      };
      return LogExportOutput.truncateUtf8(
        text,
        maxBytes: LogExportOutput.maxPreparedValueBytes,
      );
    } on Object {
      return defaultPlaceholder;
    }
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
    if (_pending.isEmpty) return;
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
        await _appendRecord(pending.time, encoded.bytes);
        snapshot.remove(pending.id);
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
    _sessionIdsByLogId.clear();
    for (final log in history) {
      final captured = captureISpectLogDataForEgress(log);
      final sessionId = captured.additionalData?[TraceKeys.sessionId];
      if (sessionId is String && sessionId.isNotEmpty) {
        _sessionIdsByLogId[captured.id] = sessionId;
      }
    }
  }

  @override
  Future<void> loadTodayHistory() => loadFromDate(DateTime.now());

  @override
  Future<String> exportToJson() async {
    if (!_enabled) return '[]';
    final output = StringBuffer('[');
    var encodedBytes = 1;
    var first = true;
    for (final log in history) {
      final captured = captureISpectLogDataForEgress(log);
      final storedSessionId = _sessionIdsByLogId[captured.id] ??
          captured.additionalData?[TraceKeys.sessionId];
      final encoded = _codec.encode(
        log,
        sessionId: storedSessionId is String && storedSessionId.isNotEmpty
            ? storedSessionId
            : _sessionId,
        maxBytes: _options.maxFileSize,
      );
      final recordLength =
          encoded.bytes.isNotEmpty && encoded.bytes.last == 0x0a
              ? encoded.bytes.length - 1
              : encoded.bytes.length;
      final nextSize = encodedBytes + (first ? 0 : 1) + recordLength + 1;
      if (nextSize > _options.maxTotalSize) {
        throw const FileLogLimitException(operation: 'exportToJson');
      }
      if (!first) output.write(',');
      output.write(utf8.decoder.convert(encoded.bytes, 0, recordLength));
      encodedBytes += (first ? 0 : 1) + recordLength;
      first = false;
    }
    output.write(']');
    return output.toString();
  }

  @override
  Future<void> importFromJson(String jsonString) async {
    if (!_enabled) return;
    final maxImportRecords =
        _loggerOptions.maxHistoryItems > 0 ? _loggerOptions.maxHistoryItems : 1;
    final maxImportNodesByRecords =
        maxImportRecords * FileLogCodec.defaultMaxNodes + 1;
    final maxImportNodes = maxImportNodesByRecords < _options.maxTotalSize
        ? maxImportNodesByRecords
        : _options.maxTotalSize;
    var firstNonWhitespace = -1;
    for (var index = 0; index < jsonString.length; index++) {
      final codeUnit = jsonString.codeUnitAt(index);
      if (codeUnit != 0x20 &&
          codeUnit != 0x09 &&
          codeUnit != 0x0a &&
          codeUnit != 0x0d) {
        firstNonWhitespace = codeUnit;
        break;
      }
    }
    final maxRootCollectionItems = firstNonWhitespace == 0x5b
        ? maxImportRecords
        : FileLogCodec.defaultMaxCollectionItems;
    try {
      BoundedJsonDecoder.validateSource(
        jsonString,
        maxCharacters: _options.maxTotalSize,
        maxEncodedBytes: _options.maxTotalSize,
        maxNodes: maxImportNodes,
        maxRootCollectionItems: maxRootCollectionItems,
      );
    } on BoundedJsonException catch (error, stackTrace) {
      if (error.isLimit) {
        throw FileLogLimitException(
          operation: 'importFromJson',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      throw FileLogFormatException(
        operation: 'importFromJson',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    final trimmed = jsonString.trim();
    if (trimmed.isEmpty) {
      throw const FileLogFormatException(operation: 'importFromJson');
    }

    final logs = trimmed.startsWith('[')
        ? _codec.decodeLegacyArray(
            trimmed,
            maxCharacters: _options.maxTotalSize,
            maxEncodedBytes: _options.maxTotalSize,
            maxNodes: maxImportNodes,
            maxRootCollectionItems: maxImportRecords,
          )
        : _decodeImportJsonLines(trimmed);
    final importSessionId = LogId.generate();
    for (final log in logs) {
      final withoutSession = _withoutUntrustedSessionId(log);
      _add(
        ISpectRedaction.enabled
            ? _sanitizeDecodedLog(
                withoutSession,
                sessionId: importSessionId,
              )
            : withoutSession,
        sessionId: importSessionId,
      );
    }
  }

  List<ISpectLogData> _decodeImportJsonLines(String input) {
    final logs = <ISpectLogData>[];
    var lineStart = 0;
    for (var index = 0; index <= input.length; index++) {
      if (index != input.length && input.codeUnitAt(index) != 0x0A) continue;
      final lineCharacters = index - lineStart;
      if (lineCharacters > _options.maxFileSize ||
          _utf8RangeExceeds(
            input,
            lineStart,
            index,
            _options.maxFileSize,
          )) {
        throw const FileLogLimitException(operation: 'importFromJson');
      }
      final line = input.substring(lineStart, index).trim();
      lineStart = index + 1;
      if (line.isEmpty) continue;
      if (logs.length >= _loggerOptions.maxHistoryItems) {
        throw const FileLogLimitException(operation: 'importFromJson');
      }
      logs.add(
        _codec.decodeLine(
          line,
          maxCharacters: _options.maxFileSize,
          maxEncodedBytes: _options.maxFileSize,
        ),
      );
    }
    return logs;
  }

  bool _utf8RangeExceeds(
    String input,
    int start,
    int end,
    int maxBytes,
  ) {
    var bytes = 0;
    for (var index = start; index < end; index++) {
      final codeUnit = input.codeUnitAt(index);
      if (codeUnit <= 0x7f) {
        bytes++;
      } else if (codeUnit <= 0x7ff) {
        bytes += 2;
      } else if (codeUnit >= 0xd800 &&
          codeUnit <= 0xdbff &&
          index + 1 < end &&
          input.codeUnitAt(index + 1) >= 0xdc00 &&
          input.codeUnitAt(index + 1) <= 0xdfff) {
        bytes += 4;
        index++;
      } else {
        bytes += 3;
      }
      if (bytes > maxBytes) return true;
    }
    return false;
  }

  ISpectLogData _withoutUntrustedSessionId(ISpectLogData data) {
    final captured = captureISpectLogDataForEgress(data);
    final additionalData = captured.additionalData;
    if (additionalData == null ||
        !additionalData.containsKey(TraceKeys.sessionId)) {
      return data;
    }
    return ISpectLogData(
      captured.message,
      id: captured.id,
      time: captured.time,
      key: captured.key,
      logLevel: captured.logLevel,
      pen: captured.pen,
      exception: captured.exception,
      error: captured.error,
      stackTrace: captured.stackTrace,
      additionalData: <String, dynamic>{
        for (final entry in additionalData.entries)
          if (entry.key != TraceKeys.sessionId) entry.key: entry.value,
      },
    );
  }

  ISpectLogData _sanitizeDecodedLog(
    ISpectLogData data, {
    required String sessionId,
  }) {
    final encoded = _codec.encode(
      data,
      sessionId: sessionId,
      maxBytes: _options.maxFileSize,
    );
    return _codec.decodeLine(
      utf8.decode(encoded.bytes),
      maxCharacters: _options.maxFileSize,
      maxEncodedBytes: _options.maxFileSize,
    );
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
    final directory = await _validatedDateDirectory(
      _dateDirectoryPath(date),
      operation: 'clearDateStorage',
      allowMissing: true,
    );
    final artifacts = directory == null
        ? const <File>[]
        : await _segmentFiles(
            directory,
            includeArchives: true,
            includeTemporary: true,
            operation: 'clearDateStorage',
          );
    final legacy = await _validatedLegacyFile(
      File(_legacyFilePath(date)),
      operation: 'clearDateStorage',
      allowMissing: true,
    );

    for (final artifact in artifacts) {
      await _deleteManagedFile(
        artifact,
        operation: 'clearDateStorage',
      );
    }
    if (legacy != null) {
      await _deleteManagedFile(
        legacy,
        operation: 'clearDateStorage',
      );
    }
    if (directory != null) {
      await _deleteDateDirectoryIfEmpty(
        directory,
        operation: 'clearDateStorage',
      );
    }
  }

  @override
  Future<List<DateTime>> getAvailableLogDates() async {
    if (!_enabled) return const [];
    await _ensureInitialized();
    final dates = <DateTime>[];
    final root = await _validatedSessionDirectory(
      operation: 'getAvailableLogDates',
    );
    await for (final entity in root.list(followLinks: false)) {
      final name = _basename(entity.path);
      if (_dateNamePattern.hasMatch(name)) {
        if (entity is! Directory) {
          throw const FileLogAccessException(
            operation: 'getAvailableLogDates',
          );
        }
        final directory = await _validatedDateDirectory(
          entity.path,
          operation: 'getAvailableLogDates',
        );
        final artifacts = await _segmentFiles(
          directory!,
          includeArchives: true,
          operation: 'getAvailableLogDates',
        );
        if (artifacts.isNotEmpty) {
          final date = DateTime.tryParse(name);
          if (date != null) dates.add(date);
        }
      } else if (_legacyNamePattern.hasMatch(name)) {
        if (entity is! File) {
          throw const FileLogAccessException(
            operation: 'getAvailableLogDates',
          );
        }
        await _validatedLegacyFile(
          entity,
          operation: 'getAvailableLogDates',
        );
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
    var total = 0;
    final directory = await _validatedDateDirectory(
      _dateDirectoryPath(date),
      operation: 'getDateFileSize',
      allowMissing: true,
    );
    if (directory != null) {
      final artifacts = await _segmentFiles(
        directory,
        includeArchives: true,
        operation: 'getDateFileSize',
      );
      for (final artifact in artifacts) {
        total += await _managedFileLength(
          artifact,
          operation: 'getDateFileSize',
        );
      }
    }
    final legacy = await _validatedLegacyFile(
      File(_legacyFilePath(date)),
      operation: 'getDateFileSize',
      allowMissing: true,
    );
    if (legacy != null) {
      total += await _managedFileLength(
        legacy,
        operation: 'getDateFileSize',
      );
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
    final files = <File>[];
    final directory = await _validatedDateDirectory(
      _dateDirectoryPath(date),
      operation: 'getLogsByDate',
      allowMissing: true,
    );
    if (directory != null) {
      files.addAll(
        await _segmentFiles(
          directory,
          includeArchives: true,
          operation: 'getLogsByDate',
        ),
      );
    }
    final legacy = await _validatedLegacyFile(
      File(_legacyFilePath(date)),
      operation: 'getLogsByDate',
      allowMissing: true,
    );
    if (legacy != null) files.add(legacy);
    return _readFiles(files);
  }

  @override
  Future<String> getLogPathByDate(DateTime date) async {
    if (!_enabled) return '';
    await _ensureInitialized();
    final directory = await _validatedDateDirectory(
      _dateDirectoryPath(date),
      operation: 'getLogPathByDate',
      allowMissing: true,
    );
    if (directory != null &&
        (await _segmentFiles(
          directory,
          includeArchives: true,
          operation: 'getLogPathByDate',
        ))
            .isNotEmpty) {
      return directory.path;
    }
    final legacy = await _validatedLegacyFile(
      File(_legacyFilePath(date)),
      operation: 'getLogPathByDate',
      allowMissing: true,
    );
    return legacy?.path ?? '';
  }

  @override
  Future<List<ISpectLogData>> getLogsBySession(String sessionPath) async {
    if (!_enabled) return const [];
    await _ensureInitialized();
    final type = await FileSystemEntity.type(
      sessionPath,
      followLinks: false,
    );
    return switch (type) {
      FileSystemEntityType.directory => _readValidatedDirectory(sessionPath),
      FileSystemEntityType.file => _readValidatedFile(sessionPath),
      FileSystemEntityType.link =>
        throw const FileLogAccessException(operation: 'getLogsBySession'),
      FileSystemEntityType.notFound => _validateMissingSessionPath(sessionPath),
      _ => throw const FileLogAccessException(
          operation: 'getLogsBySession',
        ),
    };
  }

  Future<List<ISpectLogData>> _readValidatedDirectory(String path) async {
    final directory = await _validatedDateDirectory(
      path,
      operation: 'getLogsBySession',
    );
    return _readDirectory(directory!);
  }

  Future<List<ISpectLogData>> _readValidatedFile(String path) async {
    final file = await _validatedHistoryFile(
      File(path),
      operation: 'getLogsBySession',
    );
    return _readFiles([file!]);
  }

  Future<List<ISpectLogData>> _validateMissingSessionPath(String path) async {
    final hasTraversal =
        path.split(RegExp(r'[/\\]+')).any((segment) => segment == '..');
    if (!hasTraversal && _isWithinRoot(path, sessionDirectory)) {
      return const <ISpectLogData>[];
    }
    throw const FileLogAccessException(operation: 'getLogsBySession');
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
      final providerPath = await _directoryProvider();
      if (await FileSystemEntity.type(
            providerPath,
            followLinks: false,
          ) !=
          FileSystemEntityType.directory) {
        throw const FileLogAccessException(operation: 'initialize');
      }
      final providerDirectory = Directory(providerPath);
      await _validatePrivateDirectoryPermissions(
        providerDirectory,
        operation: 'initialize',
        requireOwnerOnly: true,
      );
      _resolvedProviderDirectory = providerDirectory.path;
      _canonicalProviderDirectory =
          await providerDirectory.resolveSymbolicLinks();

      final directory = Directory(_join(providerDirectory.path, 'ispect_logs'));
      final initialType = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (initialType == FileSystemEntityType.link) {
        throw const FileLogAccessException(operation: 'initialize');
      }
      if (initialType == FileSystemEntityType.notFound) {
        await directory.create();
      }
      if (await FileSystemEntity.type(
            directory.path,
            followLinks: false,
          ) !=
          FileSystemEntityType.directory) {
        throw const FileLogAccessException(operation: 'initialize');
      }
      await _validatePrivateDirectoryPermissions(
        directory,
        operation: 'initialize',
      );
      _resolvedSessionDirectory = directory.path;
      _canonicalSessionDirectory = await directory.resolveSymbolicLinks();
      _resolvedTodaySessionPath = _join(
        _join(directory.path, _dateName(DateTime.now())),
        '000000.jsonl',
      );
      await _validatedSessionDirectory(operation: 'initialize');
      await _applyRetention();
    } on FileLogHistoryException {
      rethrow;
    } catch (error, stackTrace) {
      throw FileLogStorageException(
        operation: 'initialize',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _appendRecord(DateTime date, List<int> bytes) async {
    final directory = await _ensureDateDirectory(
      date,
      operation: 'appendRecord',
    );
    final artifacts = await _segmentFiles(
      directory,
      includeArchives: true,
      includeTemporary: true,
      operation: 'appendRecord',
    );
    final segments = artifacts
        .where(
          (file) =>
              _dateArtifactKind(_basename(file.path)) ==
              _ManagedFileKind.segment,
        )
        .toList(growable: false);
    var highestIndex = -1;
    for (final artifact in artifacts) {
      final index = int.parse(_basename(artifact.path).substring(0, 6));
      if (index > highestIndex) highestIndex = index;
    }
    var active = segments.isEmpty
        ? _nextSegment(directory, highestIndex)
        : segments.last;
    final tailIsAppendable = await _repairIncompleteTail(active);
    final currentLength = await _managedFileLength(
      active,
      operation: 'appendRecord',
      allowMissing: true,
    );
    if (!tailIsAppendable ||
        currentLength > 0 &&
            currentLength + bytes.length > _options.maxFileSize) {
      active = _nextSegment(directory, highestIndex);
    }
    await _validatedDateArtifact(
      active,
      directory: directory,
      operation: 'appendRecord',
      allowMissing: true,
      allowedKinds: const {_ManagedFileKind.segment},
    );
    final acquired = await _acquireAppendHandle(
      active,
      operation: 'appendRecord',
      createIfMissing: true,
    );
    try {
      await acquired.handle.writeFrom(bytes);
      await acquired.handle.flush();
      await _validateWritablePath(
        acquired,
        operation: 'appendRecord',
      );
    } finally {
      await acquired.handle.close();
    }
    if (_dateName(date) == _dateName(DateTime.now())) {
      _resolvedTodaySessionPath = active.path;
    }
  }

  File _nextSegment(Directory directory, int highestIndex) {
    if (highestIndex >= 999999) {
      throw const FileLogLimitException(operation: 'appendRecord');
    }
    final nextIndex = highestIndex + 1;
    return File(
      _join(
        directory.path,
        '${nextIndex.toString().padLeft(6, '0')}.jsonl',
      ),
    );
  }

  Future<bool> _repairIncompleteTail(File file) async {
    final validated = await _validatedHistoryFile(
      file,
      operation: 'repairIncompleteTail',
      allowMissing: true,
      allowedKinds: const {_ManagedFileKind.segment},
    );
    if (validated == null) return true;
    final acquired = await _acquireAppendHandle(
      validated,
      operation: 'repairIncompleteTail',
      createIfMissing: false,
    );
    final handle = acquired.handle;
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
            await _validatedHistoryFile(
              validated,
              operation: 'repairIncompleteTail',
              allowedKinds: const {_ManagedFileKind.segment},
            );
            await handle.truncate(start + index + 1);
            await handle.flush();
            await _validateWritablePath(
              acquired,
              operation: 'repairIncompleteTail',
            );
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

  Future<_AcquiredWritableFile> _acquireAppendHandle(
    File file, {
    required String operation,
    required bool createIfMissing,
  }) async {
    var validated = await _validatedHistoryFile(
      file,
      operation: operation,
      allowMissing: createIfMissing,
      allowedKinds: const {_ManagedFileKind.segment},
    );
    if (validated == null) {
      try {
        await file.create(exclusive: true);
      } on FileSystemException catch (_, stackTrace) {
        throw FileLogAccessException(
          operation: operation,
          stackTrace: stackTrace,
        );
      }
      validated = await _validatedHistoryFile(
        file,
        operation: operation,
        allowedKinds: const {_ManagedFileKind.segment},
      );
    }
    final before = _FileIdentity.fromStat(await validated!.stat());
    final hook = _ioHook;
    if (hook != null) await hook(validated, operation);
    final handle = await validated.open(mode: FileMode.append);
    try {
      final afterFile = await _validatedHistoryFile(
        validated,
        operation: operation,
        allowedKinds: const {_ManagedFileKind.segment},
      );
      final after = _FileIdentity.fromStat(await afterFile!.stat());
      if (before != after || await handle.length() != after.size) {
        throw FileLogAccessException(operation: operation);
      }
      return _AcquiredWritableFile(file: validated, handle: handle);
    } catch (_) {
      await handle.close();
      rethrow;
    }
  }

  Future<void> _validateWritablePath(
    _AcquiredWritableFile acquired, {
    required String operation,
  }) async {
    final validated = await _validatedHistoryFile(
      acquired.file,
      operation: operation,
      allowedKinds: const {_ManagedFileKind.segment},
    );
    if (await validated!.length() != await acquired.handle.length()) {
      throw FileLogAccessException(operation: operation);
    }
  }

  Future<List<File>> _segmentFiles(
    Directory directory, {
    bool includeArchives = false,
    bool includeTemporary = false,
    String operation = 'scanSegments',
  }) async {
    final files = <File>[];
    var managedArtifacts = 0;
    final validatedDirectory = await _validatedDateDirectory(
      directory.path,
      operation: operation,
    );
    await for (final entity in validatedDirectory!.list(followLinks: false)) {
      final name = _basename(entity.path);
      final kind = _dateArtifactKind(name);
      if (kind != null && ++managedArtifacts > _managedArtifactLimit) {
        throw FileLogLimitException(operation: operation);
      }
      final included = kind == _ManagedFileKind.segment ||
          includeArchives && kind == _ManagedFileKind.archive ||
          includeTemporary && kind == _ManagedFileKind.temporary;
      if (kind == null) continue;
      if (entity is! File) {
        throw FileLogAccessException(
          operation: operation,
        );
      }
      final file = await _validatedDateArtifact(
        entity,
        directory: validatedDirectory,
        operation: operation,
        allowedKinds: {kind},
      );
      if (included) files.add(file!);
    }
    files.sort((left, right) => left.path.compareTo(right.path));
    return files;
  }

  Future<List<ISpectLogData>> _readDirectory(Directory directory) async {
    final validated = await _validatedDateDirectory(
      directory.path,
      operation: 'readDirectory',
      allowMissing: true,
    );
    if (validated == null) return const [];
    return _readFiles(
      await _segmentFiles(
        validated,
        includeArchives: true,
        operation: 'readDirectory',
      ),
    );
  }

  Future<List<ISpectLogData>> _readFiles(Iterable<File> files) async {
    final byId = <String, ISpectLogData>{};
    var decodedBytes = 0;
    var inspectedRecords = 0;
    final orderedFiles = files.toList(growable: false);
    fileLoop:
    for (final file in orderedFiles.reversed) {
      final name = _basename(file.path);
      if (_legacyNamePattern.hasMatch(name)) {
        try {
          final legacyLength = await _managedFileLength(
            file,
            operation: 'readLegacy',
          );
          if (decodedBytes + legacyLength > _options.maxTotalSize) {
            _reportError(
              FileLogLimitException(
                operation: 'readTotalSize',
                path: file.path,
              ),
            );
            break;
          }
          decodedBytes += legacyLength;
          final input = await _readLegacyText(file);
          final legacyLogs = _codec.decodeLegacyArray(
            input,
            maxCharacters: _options.maxTotalSize,
            maxEncodedBytes: _options.maxTotalSize,
            maxNodes: _publicReadNodeLimit,
            maxRootCollectionItems: _publicReadRecordLimit,
          );
          for (final log in legacyLogs.reversed) {
            if (inspectedRecords >= _publicReadRecordLimit) {
              _reportError(
                const FileLogLimitException(operation: 'readRecordCount'),
              );
              break fileLoop;
            }
            inspectedRecords++;
            final safeLog = ISpectRedaction.enabled
                ? _sanitizeDecodedLog(
                    _withoutUntrustedSessionId(log),
                    sessionId: _sessionId,
                  )
                : log;
            final safeId = captureISpectLogDataForEgress(safeLog).id;
            byId.putIfAbsent(safeId, () => safeLog);
          }
        } on FileLogAccessException {
          rethrow;
        } on FileLogHistoryException catch (error) {
          _reportError(error);
        } catch (error, stackTrace) {
          _reportError(
            FileLogFormatException(
              operation: 'readLegacy',
              path: file.path,
              cause: error,
              stackTrace: stackTrace,
            ),
          );
        }
        continue;
      }

      List<int> bytes;
      try {
        bytes = await _readSegmentBytes(file);
      } on FileLogLimitException catch (error) {
        _reportError(error);
        continue;
      } on FileLogAccessException {
        rethrow;
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
      if (decodedBytes + bytes.length > _options.maxTotalSize) {
        _reportError(
          FileLogLimitException(
            operation: 'readTotalSize',
            path: file.path,
          ),
        );
        break;
      }
      decodedBytes += bytes.length;
      final completeLength =
          bytes.last == 0x0A ? bytes.length : bytes.lastIndexOf(0x0A) + 1;
      if (completeLength == 0) continue;
      String text;
      try {
        text = utf8.decoder.convert(bytes, 0, completeLength);
      } on FormatException catch (_, stackTrace) {
        _reportError(
          FileLogFormatException(
            operation: 'decodeSegmentUtf8',
            path: file.path,
            cause: const FormatException('Invalid file-log UTF-8'),
            stackTrace: stackTrace,
          ),
        );
        continue;
      }
      var lineEnd = text.length;
      for (var index = text.length - 1; index >= -1; index--) {
        if (index >= 0 && text.codeUnitAt(index) != 0x0a) continue;
        final lineStart = index + 1;
        if (lineStart == lineEnd) {
          lineEnd = index;
          continue;
        }
        if (inspectedRecords >= _publicReadRecordLimit) {
          _reportError(
            const FileLogLimitException(operation: 'readRecordCount'),
          );
          break fileLoop;
        }
        inspectedRecords++;
        final line = text.substring(lineStart, lineEnd);
        lineEnd = index;
        try {
          final log = _codec.decodeLine(
            line,
            maxCharacters: _options.maxFileSize,
            maxEncodedBytes: _options.maxFileSize,
          );
          final storedSessionId = captureISpectLogDataForEgress(
            log,
          ).additionalData?[TraceKeys.sessionId];
          final safeLog = ISpectRedaction.enabled
              ? _sanitizeDecodedLog(
                  log,
                  sessionId: storedSessionId is String &&
                          LogId.isValid(storedSessionId)
                      ? storedSessionId
                      : _sessionId,
                )
              : log;
          final safeId = captureISpectLogDataForEgress(safeLog).id;
          byId.putIfAbsent(safeId, () => safeLog);
        } on FileLogLimitException catch (error) {
          _reportError(error);
        } on FileLogAccessException {
          rethrow;
        } on FileLogFormatException catch (error) {
          _reportError(error);
        }
      }
    }
    final logs = byId.values.toList()
      ..sort((left, right) {
        final capturedLeft = captureISpectLogDataForEgress(left);
        final capturedRight = captureISpectLogDataForEgress(right);
        final byTime = capturedLeft.time.compareTo(capturedRight.time);
        return byTime != 0
            ? byTime
            : capturedLeft.id.compareTo(capturedRight.id);
      });
    return logs;
  }

  int get _publicReadRecordLimit {
    // `{"time":0}` is the smallest accepted record. This source-size-derived
    // bound therefore remains comprehensive for every valid stored record
    // while placing a finite ceiling on hostile newline-dense inputs.
    const minimumValidRecordBytes = 10;
    return _options.maxTotalSize ~/ minimumValidRecordBytes + 1;
  }

  int get _publicReadNodeLimit {
    final byRecords = _publicReadRecordLimit * FileLogCodec.defaultMaxNodes + 1;
    return byRecords < _options.maxTotalSize
        ? byRecords
        : _options.maxTotalSize;
  }

  Future<List<int>> _readSegmentBytes(File file) async {
    final kind = _dateArtifactKind(_basename(file.path));
    if (kind == _ManagedFileKind.segment) {
      return _readBoundedManagedFile(
        file,
        maxBytes: _options.maxFileSize,
        operation: 'readSegment',
        allowedKinds: const {_ManagedFileKind.segment},
      );
    }
    if (kind != _ManagedFileKind.archive) {
      throw const FileLogAccessException(operation: 'readSegment');
    }

    final compressedLimit = _gzipEncodedUpperBound(_options.maxFileSize);
    final acquired = await _acquireReadHandle(
      file,
      maxBytes: compressedLimit,
      operation: 'readCompressedSegment',
      allowedKinds: const {_ManagedFileKind.archive},
    );
    final builder = BytesBuilder(copy: false);
    try {
      final compressed = _boundedChunks(
        _readHandleChunks(acquired.handle),
        maxBytes: compressedLimit,
        operation: 'readCompressedSegment',
        path: file.path,
      );
      final decompressed = _boundedChunks(
        compressed.transform(gzip.decoder),
        maxBytes: _options.maxFileSize,
        operation: 'decompressSegment',
        path: file.path,
      );
      await decompressed.forEach(builder.add);
      await _validateFileIdentity(
        acquired.file,
        acquired.identity,
        operation: 'readCompressedSegment',
        allowedKinds: const {_ManagedFileKind.archive},
      );
      return builder.takeBytes();
    } finally {
      await acquired.handle.close();
    }
  }

  int _gzipEncodedUpperBound(int sourceBytes) =>
      sourceBytes +
      (sourceBytes >> 12) +
      (sourceBytes >> 14) +
      (sourceBytes >> 25) +
      64;

  Future<int> _countDateEntries(DateTime date) async {
    var count = 0;
    var decodedBytes = 0;
    final directory = await _validatedDateDirectory(
      _dateDirectoryPath(date),
      operation: 'countDateEntries',
      allowMissing: true,
    );
    if (directory != null) {
      final files = await _segmentFiles(
        directory,
        includeArchives: true,
        operation: 'countDateEntries',
      );
      for (final file in files) {
        final bytes = await _readSegmentBytes(file);
        decodedBytes += bytes.length;
        if (decodedBytes > _options.maxTotalSize) {
          throw FileLogLimitException(
            operation: 'countDateEntries',
            path: file.path,
          );
        }
        final completeLength = bytes.isNotEmpty && bytes.last == 0x0A
            ? bytes.length
            : bytes.lastIndexOf(0x0A) + 1;
        if (completeLength == 0) continue;
        final text = utf8.decoder.convert(bytes, 0, completeLength);
        var lineStart = 0;
        for (var index = 0; index <= text.length; index++) {
          if (index != text.length && text.codeUnitAt(index) != 0x0a) {
            continue;
          }
          if (index > lineStart) {
            count++;
            if (count > _publicReadRecordLimit) {
              throw const FileLogLimitException(
                operation: 'countDateEntries',
              );
            }
          }
          lineStart = index + 1;
        }
      }
    }
    final legacy = await _validatedLegacyFile(
      File(_legacyFilePath(date)),
      operation: 'countDateEntries',
      allowMissing: true,
    );
    if (legacy != null) {
      final legacyLength = await _managedFileLength(
        legacy,
        operation: 'countDateEntries',
      );
      if (decodedBytes + legacyLength > _options.maxTotalSize) {
        throw const FileLogLimitException(operation: 'countDateEntries');
      }
      count += _codec
          .decodeLegacyArray(
            await _readLegacyText(legacy),
            maxCharacters: _options.maxTotalSize,
            maxEncodedBytes: _options.maxTotalSize,
            maxNodes: _publicReadNodeLimit,
            maxRootCollectionItems: _publicReadRecordLimit,
          )
          .length;
      if (count > _publicReadRecordLimit) {
        throw const FileLogLimitException(operation: 'countDateEntries');
      }
    }
    return count;
  }

  bool _isWithinRoot(String path, String root) =>
      path == root || path.startsWith('$root${Platform.pathSeparator}');

  Future<Directory> _validatedProviderDirectory({
    required String operation,
  }) async {
    final path = _resolvedProviderDirectory;
    final canonicalPath = _canonicalProviderDirectory;
    if (path == null || canonicalPath == null) {
      throw FileLogAccessException(operation: operation);
    }
    if (await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw FileLogAccessException(operation: operation);
    }
    final directory = Directory(path);
    await _validatePrivateDirectoryPermissions(
      directory,
      operation: operation,
      requireOwnerOnly: true,
    );
    if (await directory.resolveSymbolicLinks() != canonicalPath) {
      throw FileLogAccessException(operation: operation);
    }
    return directory;
  }

  Future<Directory> _validatedSessionDirectory({
    required String operation,
  }) async {
    final provider = await _validatedProviderDirectory(operation: operation);
    final path = _resolvedSessionDirectory;
    final canonicalPath = _canonicalSessionDirectory;
    if (path == null ||
        canonicalPath == null ||
        path != _join(provider.path, 'ispect_logs')) {
      throw FileLogAccessException(operation: operation);
    }
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type != FileSystemEntityType.directory) {
      throw FileLogAccessException(operation: operation);
    }
    final directory = Directory(path);
    await _validatePrivateDirectoryPermissions(
      directory,
      operation: operation,
    );
    if (await directory.resolveSymbolicLinks() != canonicalPath) {
      throw FileLogAccessException(operation: operation);
    }
    return directory;
  }

  Future<Directory?> _validatedDateDirectory(
    String path, {
    required String operation,
    bool allowMissing = false,
  }) async {
    final root = await _validatedSessionDirectory(operation: operation);
    final name = _basename(path);
    if (!_dateNamePattern.hasMatch(name) || path != _join(root.path, name)) {
      throw FileLogAccessException(operation: operation);
    }

    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.notFound && allowMissing) return null;
    if (type != FileSystemEntityType.directory) {
      throw FileLogAccessException(operation: operation);
    }

    final directory = Directory(path);
    await _validatePrivateDirectoryPermissions(
      directory,
      operation: operation,
    );
    final canonicalRoot = _canonicalSessionDirectory!;
    final canonicalPath = await directory.resolveSymbolicLinks();
    if (canonicalPath != _join(canonicalRoot, name)) {
      throw FileLogAccessException(operation: operation);
    }
    return directory;
  }

  Future<void> _validatePrivateDirectoryPermissions(
    Directory directory, {
    required String operation,
    bool requireOwnerOnly = false,
  }) async {
    if (Platform.isWindows) return;
    final stat = await directory.stat();
    const groupOrWorldPermissionBits = 0x3f;
    const groupOrWorldWriteBits = 0x12;
    final forbiddenBits =
        requireOwnerOnly ? groupOrWorldPermissionBits : groupOrWorldWriteBits;
    if (stat.type != FileSystemEntityType.directory ||
        stat.mode & forbiddenBits != 0) {
      throw FileLogAccessException(operation: operation);
    }
  }

  Future<Directory> _ensureDateDirectory(
    DateTime date, {
    required String operation,
  }) async {
    final path = _dateDirectoryPath(date);
    var directory = await _validatedDateDirectory(
      path,
      operation: operation,
      allowMissing: true,
    );
    if (directory != null) return directory;

    await Directory(path).create();
    directory = await _validatedDateDirectory(
      path,
      operation: operation,
    );
    return directory!;
  }

  Future<File?> _validatedLegacyFile(
    File file, {
    required String operation,
    bool allowMissing = false,
  }) async {
    final root = await _validatedSessionDirectory(operation: operation);
    final name = _basename(file.path);
    if (!_legacyNamePattern.hasMatch(name) ||
        file.path != _join(root.path, name)) {
      throw FileLogAccessException(operation: operation);
    }

    final type = await FileSystemEntity.type(
      file.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound && allowMissing) return null;
    if (type != FileSystemEntityType.file) {
      throw FileLogAccessException(operation: operation);
    }
    final canonicalPath = await file.resolveSymbolicLinks();
    if (canonicalPath != _join(_canonicalSessionDirectory!, name)) {
      throw FileLogAccessException(operation: operation);
    }
    return file;
  }

  Future<File?> _validatedDateArtifact(
    File file, {
    required Directory directory,
    required String operation,
    required Set<_ManagedFileKind> allowedKinds,
    bool allowMissing = false,
  }) async {
    final validatedDirectory = await _validatedDateDirectory(
      directory.path,
      operation: operation,
    );
    final name = _basename(file.path);
    final kind = _dateArtifactKind(name);
    if (kind == null ||
        !allowedKinds.contains(kind) ||
        file.path != _join(validatedDirectory!.path, name)) {
      throw FileLogAccessException(operation: operation);
    }

    final type = await FileSystemEntity.type(
      file.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound && allowMissing) return null;
    if (type != FileSystemEntityType.file) {
      throw FileLogAccessException(operation: operation);
    }
    final canonicalDirectory =
        _join(_canonicalSessionDirectory!, _basename(directory.path));
    if (await file.resolveSymbolicLinks() != _join(canonicalDirectory, name)) {
      throw FileLogAccessException(operation: operation);
    }
    return file;
  }

  Future<File?> _validatedHistoryFile(
    File file, {
    required String operation,
    bool allowMissing = false,
    Set<_ManagedFileKind>? allowedKinds,
  }) {
    final name = _basename(file.path);
    if (_legacyNamePattern.hasMatch(name)) {
      if (allowedKinds != null &&
          !allowedKinds.contains(_ManagedFileKind.legacy)) {
        throw FileLogAccessException(operation: operation);
      }
      return _validatedLegacyFile(
        file,
        operation: operation,
        allowMissing: allowMissing,
      );
    }

    final kind = _dateArtifactKind(name);
    if (kind == null || allowedKinds != null && !allowedKinds.contains(kind)) {
      throw FileLogAccessException(operation: operation);
    }
    return _validatedDateArtifact(
      file,
      directory: file.parent,
      operation: operation,
      allowedKinds: {kind},
      allowMissing: allowMissing,
    );
  }

  Future<int> _managedFileLength(
    File file, {
    required String operation,
    bool allowMissing = false,
  }) async {
    final validated = await _validatedHistoryFile(
      file,
      operation: operation,
      allowMissing: allowMissing,
    );
    return validated == null ? 0 : validated.length();
  }

  Future<void> _deleteManagedFile(
    File file, {
    required String operation,
  }) async {
    final validated = await _validatedHistoryFile(
      file,
      operation: operation,
    );
    await validated!.delete();
  }

  Future<List<int>> _readBoundedManagedFile(
    File file, {
    required int maxBytes,
    required String operation,
    required Set<_ManagedFileKind> allowedKinds,
  }) async {
    final acquired = await _acquireReadHandle(
      file,
      maxBytes: maxBytes,
      operation: operation,
      allowedKinds: allowedKinds,
    );
    final builder = BytesBuilder(copy: false);
    try {
      await _boundedChunks(
        _readHandleChunks(acquired.handle),
        maxBytes: maxBytes,
        operation: operation,
        path: file.path,
      ).forEach(builder.add);
      await _validateFileIdentity(
        acquired.file,
        acquired.identity,
        operation: operation,
        allowedKinds: allowedKinds,
      );
      return builder.takeBytes();
    } finally {
      await acquired.handle.close();
    }
  }

  Future<_AcquiredReadFile> _acquireReadHandle(
    File file, {
    required int maxBytes,
    required String operation,
    required Set<_ManagedFileKind> allowedKinds,
  }) async {
    final validated = await _validatedHistoryFile(
      file,
      operation: operation,
      allowedKinds: allowedKinds,
    );
    final before = _FileIdentity.fromStat(await validated!.stat());
    if (before.size > maxBytes) {
      throw FileLogLimitException(operation: operation, path: file.path);
    }
    final hook = _ioHook;
    if (hook != null) await hook(validated, operation);

    final handle = await validated.open();
    try {
      final afterFile = await _validatedHistoryFile(
        validated,
        operation: operation,
        allowedKinds: allowedKinds,
      );
      final after = _FileIdentity.fromStat(await afterFile!.stat());
      final openedLength = await handle.length();
      if (before != after || openedLength != after.size) {
        throw FileLogAccessException(operation: operation);
      }
      if (openedLength > maxBytes) {
        throw FileLogLimitException(operation: operation, path: file.path);
      }
      return _AcquiredReadFile(
        file: validated,
        handle: handle,
        identity: after,
      );
    } catch (_) {
      await handle.close();
      rethrow;
    }
  }

  Stream<List<int>> _readHandleChunks(RandomAccessFile handle) async* {
    while (true) {
      final chunk = await handle.read(_ioChunkSize);
      if (chunk.isEmpty) return;
      yield chunk;
    }
  }

  Stream<List<int>> _boundedChunks(
    Stream<List<int>> chunks, {
    required int maxBytes,
    required String operation,
    required String path,
  }) async* {
    var total = 0;
    await for (final chunk in chunks) {
      total += chunk.length;
      if (total > maxBytes) {
        throw FileLogLimitException(
          operation: operation,
          path: path,
        );
      }
      yield chunk;
    }
  }

  Future<String> _readLegacyText(File file) async {
    final bytes = await _readBoundedManagedFile(
      file,
      maxBytes: _options.maxTotalSize,
      operation: 'readLegacy',
      allowedKinds: const {_ManagedFileKind.legacy},
    );
    try {
      return utf8.decode(bytes);
    } on FormatException catch (_, stackTrace) {
      throw FileLogFormatException(
        operation: 'decodeLegacyUtf8',
        path: file.path,
        cause: const FormatException('Invalid file-log UTF-8'),
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _deleteDateDirectoryIfEmpty(
    Directory directory, {
    required String operation,
  }) async {
    final validated = await _validatedDateDirectory(
      directory.path,
      operation: operation,
    );
    if (!await validated!.list(followLinks: false).isEmpty) return;
    final beforeDelete = await _validatedDateDirectory(
      directory.path,
      operation: operation,
    );
    await beforeDelete!.delete();
  }

  _ManagedFileKind? _dateArtifactKind(String name) {
    if (_segmentNamePattern.hasMatch(name)) {
      return _ManagedFileKind.segment;
    }
    if (_archiveNamePattern.hasMatch(name)) {
      return _ManagedFileKind.archive;
    }
    if (_temporaryArchiveNamePattern.hasMatch(name)) {
      return _ManagedFileKind.temporary;
    }
    return null;
  }

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
    var managedArtifacts = 0;
    var managedDates = 0;
    final root = await _validatedSessionDirectory(
      operation: 'scanArtifacts',
    );
    await for (final entity in root.list(followLinks: false)) {
      final name = _basename(entity.path);
      if (_dateNamePattern.hasMatch(name)) {
        if (++managedDates > _managedArtifactLimit) {
          throw const FileLogLimitException(operation: 'scanArtifacts');
        }
        if (entity is! Directory) {
          throw const FileLogAccessException(operation: 'scanArtifacts');
        }
        final directory = await _validatedDateDirectory(
          entity.path,
          operation: 'scanArtifacts',
        );
        final date = DateTime.tryParse(name);
        if (date == null) continue;
        final files = <File>[];
        await for (final child in directory!.list(followLinks: false)) {
          final kind = _dateArtifactKind(_basename(child.path));
          if (kind == null) continue;
          if (++managedArtifacts > _managedArtifactLimit) {
            throw const FileLogLimitException(operation: 'scanArtifacts');
          }
          if (child is! File) {
            throw const FileLogAccessException(operation: 'scanArtifacts');
          }
          final file = await _validatedDateArtifact(
            child,
            directory: directory,
            operation: 'scanArtifacts',
            allowedKinds: {kind},
          );
          files.add(file!);
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
              size: await _managedFileLength(
                file,
                operation: 'scanArtifacts',
              ),
              isActive: file.path == activePath,
              isArchive: isArchive,
              isTemporary: isTemporary,
              canArchive: isSegment,
            ),
          );
        }
      } else if (_legacyNamePattern.hasMatch(name)) {
        if (++managedArtifacts > _managedArtifactLimit) {
          throw const FileLogLimitException(operation: 'scanArtifacts');
        }
        if (entity is! File) {
          throw const FileLogAccessException(operation: 'scanArtifacts');
        }
        final legacy = await _validatedLegacyFile(
          entity,
          operation: 'scanArtifacts',
        );
        final legacyMatch = _legacyNamePattern.firstMatch(name);
        final legacyDate = DateTime.tryParse(legacyMatch?.group(1) ?? '');
        if (legacyDate != null) {
          artifacts.add(
            FileLogArtifact(
              path: legacy!.path,
              date: legacyDate,
              size: await _managedFileLength(
                legacy,
                operation: 'scanArtifacts',
              ),
              canArchive: false,
            ),
          );
        }
      }
    }
    return artifacts;
  }

  Future<void> _deleteArtifact(FileLogArtifact artifact) async {
    final type = await FileSystemEntity.type(
      artifact.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) return;
    await _deleteManagedFile(
      File(artifact.path),
      operation: 'deleteArtifact',
    );
  }

  Future<void> _archiveArtifact(FileLogArtifact artifact) async {
    final source = File(artifact.path);
    final target = File('${source.path}.gz');
    File? temporary;
    _AcquiredReadFile? acquiredSource;
    _AcquiredWritableFile? acquiredTemporary;
    var sourceClosed = false;
    var temporaryClosed = false;
    var renamed = false;
    try {
      final existingTarget = await _validatedHistoryFile(
        target,
        operation: 'archive',
        allowMissing: true,
        allowedKinds: const {_ManagedFileKind.archive},
      );
      if (existingTarget != null) {
        await _recoverCompletedArchive(source, existingTarget);
        return;
      }
      acquiredSource = await _acquireReadHandle(
        source,
        maxBytes: _options.maxFileSize,
        operation: 'archive',
        allowedKinds: const {_ManagedFileKind.segment},
      );
      acquiredTemporary = await _createArchiveTemporary(target);
      temporary = acquiredTemporary.file;
      final compressedLimit = _archiveCompressedByteLimit ??
          _gzipEncodedUpperBound(_options.maxFileSize);
      var compressedBytes = 0;
      final sourceChunks = _boundedChunks(
        _readHandleChunks(acquiredSource.handle),
        maxBytes: _options.maxFileSize,
        operation: 'archiveSource',
        path: source.path,
      );
      await for (final chunk in sourceChunks.transform(gzip.encoder)) {
        compressedBytes += chunk.length;
        if (compressedBytes > compressedLimit) {
          throw FileLogLimitException(
            operation: 'archiveCompressedOutput',
            path: source.path,
          );
        }
        await acquiredTemporary.handle.writeFrom(chunk);
      }
      await acquiredTemporary.handle.flush();
      final temporaryLength = await acquiredTemporary.handle.length();
      if (temporaryLength != compressedBytes) {
        throw const FileLogAccessException(operation: 'archive');
      }
      await _validatedHistoryFile(
        temporary,
        operation: 'archive',
        allowedKinds: const {_ManagedFileKind.temporary},
      );
      if (await temporary.length() != compressedBytes) {
        throw const FileLogAccessException(operation: 'archive');
      }
      await acquiredTemporary.handle.close();
      temporaryClosed = true;
      await acquiredSource.handle.close();
      sourceClosed = true;
      await _validateFileIdentity(
        acquiredSource.file,
        acquiredSource.identity,
        operation: 'archive',
        allowedKinds: const {_ManagedFileKind.segment},
      );
      final targetType = await FileSystemEntity.type(
        target.path,
        followLinks: false,
      );
      if (targetType != FileSystemEntityType.notFound) {
        throw const FileLogAccessException(operation: 'archive');
      }
      await temporary.rename(target.path);
      renamed = true;
      await _validatedHistoryFile(
        target,
        operation: 'archive',
        allowedKinds: const {_ManagedFileKind.archive},
      );
      await _deleteManagedFile(
        source,
        operation: 'archive',
      );
    } on FileLogHistoryException {
      rethrow;
    } catch (error, stackTrace) {
      throw FileLogStorageException(
        operation: 'archive',
        path: source.path,
        cause: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!temporaryClosed && acquiredTemporary != null) {
        await acquiredTemporary.handle.close();
      }
      if (!sourceClosed && acquiredSource != null) {
        await acquiredSource.handle.close();
      }
      if (!renamed &&
          temporary != null &&
          await FileSystemEntity.type(
                temporary.path,
                followLinks: false,
              ) ==
              FileSystemEntityType.file) {
        await _deleteManagedFile(temporary, operation: 'archiveCleanup');
      } else if (!renamed &&
          temporary != null &&
          await FileSystemEntity.type(
                temporary.path,
                followLinks: false,
              ) ==
              FileSystemEntityType.link) {
        // Delete the managed link itself; never resolve or follow it.
        await Link(temporary.path).delete();
      }
    }
  }

  Future<void> _recoverCompletedArchive(File source, File archive) async {
    final sourceBytes = await _readBoundedManagedFile(
      source,
      maxBytes: _options.maxFileSize,
      operation: 'archiveRecovery',
      allowedKinds: const {_ManagedFileKind.segment},
    );
    final archiveBytes = await _readSegmentBytes(archive);
    if (sourceBytes.length != archiveBytes.length) {
      throw const FileLogAccessException(operation: 'archiveRecovery');
    }
    for (var index = 0; index < sourceBytes.length; index++) {
      if (sourceBytes[index] != archiveBytes[index]) {
        throw const FileLogAccessException(operation: 'archiveRecovery');
      }
    }
    await _deleteManagedFile(source, operation: 'archiveRecovery');
  }

  Future<_AcquiredWritableFile> _createArchiveTemporary(File target) async {
    File? temporary;
    for (var attempt = 0; attempt < 8; attempt++) {
      final candidate = File('${target.path}.${LogId.generate()}.tmp');
      try {
        await candidate.create(exclusive: true);
        temporary = candidate;
        break;
      } on FileSystemException {
        if (await FileSystemEntity.type(
              candidate.path,
              followLinks: false,
            ) !=
            FileSystemEntityType.notFound) {
          continue;
        }
        rethrow;
      }
    }
    if (temporary == null) {
      throw const FileLogAccessException(operation: 'archiveTemporary');
    }

    RandomAccessFile? handle;
    try {
      final validated = await _validatedHistoryFile(
        temporary,
        operation: 'archiveTemporary',
        allowedKinds: const {_ManagedFileKind.temporary},
      );
      final before = _FileIdentity.fromStat(await validated!.stat());
      if (before.size != 0) {
        throw const FileLogAccessException(operation: 'archiveTemporary');
      }
      final hook = _ioHook;
      if (hook != null) await hook(validated, 'archiveTemporary');
      handle = await validated.open(mode: FileMode.writeOnlyAppend);
      final afterFile = await _validatedHistoryFile(
        validated,
        operation: 'archiveTemporary',
        allowedKinds: const {_ManagedFileKind.temporary},
      );
      final after = _FileIdentity.fromStat(await afterFile!.stat());
      if (before != after || await handle.length() != 0) {
        throw const FileLogAccessException(operation: 'archiveTemporary');
      }
      return _AcquiredWritableFile(file: validated, handle: handle);
    } catch (_) {
      if (handle != null) await handle.close();
      final temporaryType = await FileSystemEntity.type(
        temporary.path,
        followLinks: false,
      );
      if (temporaryType == FileSystemEntityType.file) {
        await _deleteManagedFile(
          temporary,
          operation: 'archiveTemporaryCleanup',
        );
      } else if (temporaryType == FileSystemEntityType.link) {
        await Link(temporary.path).delete();
      }
      rethrow;
    }
  }

  Future<void> _validateFileIdentity(
    File file,
    _FileIdentity expected, {
    required String operation,
    required Set<_ManagedFileKind> allowedKinds,
  }) async {
    final validated = await _validatedHistoryFile(
      file,
      operation: operation,
      allowedKinds: allowedKinds,
    );
    final current = _FileIdentity.fromStat(await validated!.stat());
    if (current != expected) {
      throw FileLogAccessException(operation: operation);
    }
  }

  Future<void> _deleteEmptyDateDirectories() async {
    final root = await _validatedSessionDirectory(
      operation: 'deleteEmptyDateDirectories',
    );
    final directories = <Directory>[];
    await for (final entity in root.list(followLinks: false)) {
      if (!_dateNamePattern.hasMatch(_basename(entity.path))) continue;
      if (entity is! Directory) {
        throw const FileLogAccessException(
          operation: 'deleteEmptyDateDirectories',
        );
      }
      final directory = await _validatedDateDirectory(
        entity.path,
        operation: 'deleteEmptyDateDirectories',
      );
      directories.add(directory!);
    }
    for (final directory in directories) {
      await _deleteDateDirectoryIfEmpty(
        directory,
        operation: 'deleteEmptyDateDirectories',
      );
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
  const _PendingLog({
    required this.id,
    required this.time,
    required this.log,
    required this.sessionId,
  });

  final String id;
  final DateTime time;
  final ISpectLogData log;
  final String sessionId;
}

final class _AcquiredReadFile {
  const _AcquiredReadFile({
    required this.file,
    required this.handle,
    required this.identity,
  });

  final File file;
  final RandomAccessFile handle;
  final _FileIdentity identity;
}

final class _AcquiredWritableFile {
  const _AcquiredWritableFile({
    required this.file,
    required this.handle,
  });

  final File file;
  final RandomAccessFile handle;
}

@immutable
final class _FileIdentity {
  const _FileIdentity({
    required this.size,
    required this.mode,
    required this.changed,
    required this.modified,
  });

  factory _FileIdentity.fromStat(FileStat stat) => _FileIdentity(
        size: stat.size,
        mode: stat.mode,
        changed: stat.changed,
        modified: stat.modified,
      );

  final int size;
  final int mode;
  final DateTime changed;
  final DateTime modified;

  @override
  bool operator ==(Object other) =>
      other is _FileIdentity &&
      other.size == size &&
      other.mode == mode &&
      other.changed == changed &&
      other.modified == modified;

  @override
  int get hashCode => Object.hash(size, mode, changed, modified);
}

enum _ManagedFileKind {
  segment,
  archive,
  temporary,
  legacy,
}
