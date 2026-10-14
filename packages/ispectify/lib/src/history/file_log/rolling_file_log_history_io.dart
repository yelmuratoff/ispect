import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/bounded_log_buffer.dart';
import 'package:ispectify/src/history/file_log/file_log_codec.dart';
import 'package:ispectify/src/history/file_log/file_log_layout.dart';
import 'package:ispectify/src/history/file_log/file_log_limits.dart';
import 'package:ispectify/src/history/file_log/managed_log_store.dart';
import 'package:ispectify/src/history/file_log/retention_executor.dart';
import 'package:ispectify/src/history/file_log/segment_reader.dart';
import 'package:ispectify/src/models/log_id.dart';
import 'package:ispectify/src/utils/bounded_json_decoder.dart';
import 'package:meta/meta.dart';

typedef _FileLogDiagnosticSink = void Function(
  String message, {
  Object? error,
  StackTrace? stackTrace,
});

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
          providerDirectoryRequiresOwnerOnlyProtection:
              _defaultProviderDirectoryRequiresOwnerOnlyProtection,
          diagnosticSink: null,
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
    bool? providerDirectoryRequiresOwnerOnlyProtection,
    void Function(
      String message, {
      Object? error,
      StackTrace? stackTrace,
    })? diagnosticSink,
  }) : this._(
          loggerOptions,
          directoryProvider: directoryProvider,
          options: options,
          redactor: redactor,
          enabled: kISpectEnabled,
          timerFactory: timerFactory,
          ioHook: ioHook,
          archiveCompressedByteLimit: archiveCompressedByteLimit,
          providerDirectoryRequiresOwnerOnlyProtection:
              providerDirectoryRequiresOwnerOnlyProtection ??
                  _defaultProviderDirectoryRequiresOwnerOnlyProtection,
          diagnosticSink: diagnosticSink,
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
    required bool providerDirectoryRequiresOwnerOnlyProtection,
    required _FileLogDiagnosticSink? diagnosticSink,
  })  : _store = ManagedLogStore(
          directoryProvider: directoryProvider,
          options: options,
          providerDirectoryRequiresOwnerOnlyProtection:
              providerDirectoryRequiresOwnerOnlyProtection,
          ioHook: ioHook,
        ),
        _options = options,
        _enabled = enabled,
        _loggerOptions = loggerOptions,
        _buffer = BoundedLogBuffer(loggerOptions),
        _codec = FileLogCodec(
          redactor: redactor,
          resourceLimits: loggerOptions.resourceLimits,
        ),
        _redactorOverride = redactor,
        _sessionId = LogId.generate(),
        _limits = FileLogLimits(options: options, loggerOptions: loggerOptions),
        _timerFactory = timerFactory ?? Timer.new,
        _archiveCompressedByteLimit = archiveCompressedByteLimit,
        _diagnosticSink = diagnosticSink ?? _developerDiagnosticSink,
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

  // iOS relies on its mandatory sandbox even when Library/Caches is 0755.
  static bool get _defaultProviderDirectoryRequiresOwnerOnlyProtection =>
      !Platform.isIOS;

  final ManagedLogStore _store;
  final FileLogHistoryOptions _options;
  final bool _enabled;
  final ISpectLoggerOptions _loggerOptions;
  final BoundedLogBuffer _buffer;
  final FileLogCodec _codec;
  final RedactionService? _redactorOverride;
  final String _sessionId;
  final FileLogLimits _limits;
  final Timer Function(Duration, void Function()) _timerFactory;
  final int? _archiveCompressedByteLimit;
  late final RetentionExecutor _retention = RetentionExecutor(
    store: _store,
    options: _options,
    archiveCompressedByteLimit: _archiveCompressedByteLimit,
  );
  late final SegmentReader _reader = SegmentReader(
    store: _store,
    codec: _codec,
    options: _options,
    loggerOptions: _loggerOptions,
    limits: _limits,
    sessionId: _sessionId,
    onError: _reportError,
  );
  final _FileLogDiagnosticSink _diagnosticSink;
  final LinkedHashMap<String, _PendingLog> _pending =
      LinkedHashMap<String, _PendingLog>();
  final LinkedHashMap<String, String> _sessionIdsByLogId =
      LinkedHashMap<String, String>();

  RedactionService get _redactor =>
      ISpectRedaction.resolveService(service: _redactorOverride);

  Future<void>? _initialization;
  Future<void> _operationChain = Future<void>.value();
  String? _resolvedTodaySessionPath;
  Timer? _autoSaveTimer;
  Duration _autoSaveInterval;
  bool _autoSaveEnabled;

  @override
  List<ISpectLogData> get history => _buffer.history;

  @override
  String get sessionDirectory => _store.sessionDirectory;

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
        captureMode: captured.captureMode,
        resourceLimits: captured.resourceLimits,
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
        captureMode: captured.captureMode,
        resourceLimits: captured.resourceLimits,
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
        captureMode: captured.captureMode,
        resourceLimits: captured.resourceLimits,
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
      await _serialized(_flushPending);
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
    final safeText = _safeDiagnosticText(safeError.toString());
    _diagnosticSink(
      '[ISpect] $safeText',
      error: safeError.cause,
      stackTrace: safeError.stackTrace,
    );
  }

  static void _developerDiagnosticSink(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'ispectify.file-history',
      error: error,
      stackTrace: stackTrace,
    );
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
      final prepared = LogExportOutput.replaceTruncatedPrefixes(
        LogExportOutput.boundJsonValue(
          value,
          resourceLimits: _loggerOptions.resourceLimits,
          preserveTypes: true,
          replaceOversizedStrings: true,
        ),
      );
      final bounded = LogExportOutput.boundJsonValue(
        _redactor.redactForExport(
          prepared,
          resourceLimits: _loggerOptions.resourceLimits,
        ),
        resourceLimits: _loggerOptions.resourceLimits,
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
        maxBytes: _loggerOptions.resourceLimits.maxCapturedValueBytes,
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
    return _serialized(_flushPending);
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    final previous = _operationChain;
    _operationChain = () async {
      await previous;
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }();
    return completer.future;
  }

  Future<T> _guardFileSystem<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on FileSystemException catch (error, stackTrace) {
      throw FileLogStorageException(
        operation: operation,
        path: _store.resolvedSessionDirectory,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _flushPending() async {
    if (_pending.isEmpty) return;
    final snapshot = LinkedHashMap<String, _PendingLog>.of(_pending);
    _pending.clear();
    try {
      await _ensureInitialized();
      final byDate = <String, List<_PendingLog>>{};
      for (final pending in snapshot.values) {
        (byDate[FileLogLayout.dateName(pending.time)] ??= []).add(pending);
      }
      for (final group in byDate.values) {
        await _appendRecords(group, snapshot);
      }
      await _retention.apply();
    } catch (error, stackTrace) {
      _restorePending(snapshot);
      if (error is FileLogHistoryException) rethrow;
      throw FileLogStorageException(
        operation: 'saveToDailyFile',
        path: _store.resolvedSessionDirectory,
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
        maxBytes: _limits.recordBytes,
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
    final historyImportLimit =
        _loggerOptions.maxHistoryItems > 0 ? _loggerOptions.maxHistoryItems : 1;
    final maxImportRecords =
        historyImportLimit < _loggerOptions.resourceLimits.maxImportEntries
            ? historyImportLimit
            : _loggerOptions.resourceLimits.maxImportEntries;
    final maxImportNodesByRecords =
        maxImportRecords * FileLogCodec.defaultMaxNodes + 1;
    final nodesBoundedByStorage =
        maxImportNodesByRecords < _options.maxTotalSize
            ? maxImportNodesByRecords
            : _options.maxTotalSize;
    final maxImportNodes =
        nodesBoundedByStorage < _loggerOptions.resourceLimits.maxImportNodes
            ? nodesBoundedByStorage
            : _loggerOptions.resourceLimits.maxImportNodes;
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
        : _loggerOptions.resourceLimits.maxCollectionItems;
    try {
      BoundedJsonDecoder.validateSource(
        jsonString,
        maxCharacters: _limits.importCharacters,
        maxEncodedBytes: _limits.importBytes,
        maxNodes: maxImportNodes,
        maxCollectionItems: _loggerOptions.resourceLimits.maxCollectionItems,
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
            maxCharacters: _limits.importCharacters,
            maxEncodedBytes: _limits.importBytes,
            maxDepth: _loggerOptions.resourceLimits.maxTraversalDepth,
            maxNodes: maxImportNodes,
            maxCollectionItems:
                _loggerOptions.resourceLimits.maxCollectionItems,
            maxRootCollectionItems: maxImportRecords,
          )
        : _decodeImportJsonLines(
            trimmed,
            maxImportRecords: maxImportRecords,
          );
    final importSessionId = LogId.generate();
    for (final log in logs) {
      final withoutSession = FileLogCodec.withoutSessionId(log);
      _add(
        ISpectRedaction.enabled
            ? _codec.roundTrip(
                withoutSession,
                sessionId: importSessionId,
                maxBytes: _limits.recordBytes,
              )
            : withoutSession,
        sessionId: importSessionId,
      );
    }
  }

  List<ISpectLogData> _decodeImportJsonLines(
    String input, {
    required int maxImportRecords,
  }) {
    final logs = <ISpectLogData>[];
    var lineStart = 0;
    for (var index = 0; index <= input.length; index++) {
      if (index != input.length && input.codeUnitAt(index) != 0x0A) continue;
      if (index - lineStart > _limits.recordBytes) {
        throw const FileLogLimitException(operation: 'importFromJson');
      }
      final rawLine = input.substring(lineStart, index);
      if (LogExportOutput.utf8Length(rawLine, limit: _limits.recordBytes) >
          _limits.recordBytes) {
        throw const FileLogLimitException(operation: 'importFromJson');
      }
      final line = rawLine.trim();
      lineStart = index + 1;
      if (line.isEmpty) continue;
      if (logs.length >= maxImportRecords) {
        throw const FileLogLimitException(operation: 'importFromJson');
      }
      logs.add(
        _codec.decodeLine(
          line,
          maxCharacters: _limits.recordBytes,
          maxEncodedBytes: _limits.recordBytes,
          maxDepth: _loggerOptions.resourceLimits.maxTraversalDepth,
          maxNodes: _loggerOptions.resourceLimits.maxImportNodes,
          maxCollectionItems: _loggerOptions.resourceLimits.maxCollectionItems,
        ),
      );
    }
    return logs;
  }

  @override
  Future<void> clearAllFileStorage() {
    if (!_enabled) return Future<void>.value();
    return _serialized(() async {
      await _ensureInitialized();
      for (final artifact in await _retention.scanArtifacts()) {
        await _retention.deleteArtifact(artifact);
      }
      await _retention.deleteEmptyDateDirectories();
    });
  }

  @override
  Future<void> clearDateStorage(DateTime date) {
    if (!_enabled) return Future<void>.value();
    return _serialized(
      () => _guardFileSystem('clearDateStorage', () => _clearDateStorage(date)),
    );
  }

  Future<void> _clearDateStorage(DateTime date) async {
    await _ensureInitialized();
    final directory = await _store.validatedDateDirectory(
      _store.dateDirectoryPath(date),
      operation: 'clearDateStorage',
      allowMissing: true,
    );
    final artifacts = directory == null
        ? const <File>[]
        : await _store.segmentFiles(
            directory,
            includeArchives: true,
            includeTemporary: true,
            operation: 'clearDateStorage',
          );
    final legacy = await _store.validatedLegacyFile(
      File(_store.legacyFilePath(date)),
      operation: 'clearDateStorage',
      allowMissing: true,
    );

    for (final artifact in artifacts) {
      await _store.deleteManagedFile(
        artifact,
        operation: 'clearDateStorage',
      );
    }
    if (legacy != null) {
      await _store.deleteManagedFile(
        legacy,
        operation: 'clearDateStorage',
      );
    }
    if (directory != null) {
      await _store.deleteDateDirectoryIfEmpty(
        directory,
        operation: 'clearDateStorage',
      );
    }
  }

  @override
  Future<List<DateTime>> getAvailableLogDates() {
    if (!_enabled) return Future<List<DateTime>>.value(const []);
    return _serialized(
      () => _guardFileSystem('getAvailableLogDates', _availableLogDates),
    );
  }

  Future<List<DateTime>> _availableLogDates() async {
    await _ensureInitialized();
    final dates = <DateTime>[];
    final root = await _store.validatedSessionDirectory(
      operation: 'getAvailableLogDates',
    );
    await for (final entity in root.list(followLinks: false)) {
      final name = FileLogLayout.basename(entity.path);
      if (FileLogLayout.dateNamePattern.hasMatch(name)) {
        if (entity is! Directory) {
          throw const FileLogAccessException(
            operation: 'getAvailableLogDates',
          );
        }
        final directory = await _store.validatedDateDirectory(
          entity.path,
          operation: 'getAvailableLogDates',
        );
        final artifacts = await _store.segmentFiles(
          directory!,
          includeArchives: true,
          operation: 'getAvailableLogDates',
        );
        if (artifacts.isNotEmpty) {
          final date = DateTime.tryParse(name);
          if (date != null) dates.add(date);
        }
      } else if (FileLogLayout.legacyNamePattern.hasMatch(name)) {
        if (entity is! File) {
          throw const FileLogAccessException(
            operation: 'getAvailableLogDates',
          );
        }
        await _store.validatedLegacyFile(
          entity,
          operation: 'getAvailableLogDates',
        );
        final date = FileLogLayout.legacyDate(name);
        if (date != null) dates.add(date);
      }
    }
    final uniqueDates = dates.toSet().toList()..sort();
    return uniqueDates;
  }

  @override
  Future<int> getDateFileSize(DateTime date) {
    if (!_enabled) return Future<int>.value(0);
    return _serialized(
      () => _guardFileSystem('getDateFileSize', () => _dateFileSize(date)),
    );
  }

  Future<int> _dateFileSize(DateTime date) async {
    await _ensureInitialized();
    var total = 0;
    final directory = await _store.validatedDateDirectory(
      _store.dateDirectoryPath(date),
      operation: 'getDateFileSize',
      allowMissing: true,
    );
    if (directory != null) {
      final artifacts = await _store.segmentFiles(
        directory,
        includeArchives: true,
        operation: 'getDateFileSize',
      );
      for (final artifact in artifacts) {
        total += await _store.managedFileLength(
          artifact,
          operation: 'getDateFileSize',
        );
      }
    }
    final legacy = await _store.validatedLegacyFile(
      File(_store.legacyFilePath(date)),
      operation: 'getDateFileSize',
      allowMissing: true,
    );
    if (legacy != null) {
      total += await _store.managedFileLength(
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
  Future<List<ISpectLogData>> getLogsByDate(DateTime date) {
    if (!_enabled) return Future<List<ISpectLogData>>.value(const []);
    return _serialized(() => _logsByDate(date));
  }

  Future<List<ISpectLogData>> _logsByDate(DateTime date) async {
    await _ensureInitialized();
    final files = <File>[];
    final directory = await _store.validatedDateDirectory(
      _store.dateDirectoryPath(date),
      operation: 'getLogsByDate',
      allowMissing: true,
    );
    if (directory != null) {
      files.addAll(
        await _store.segmentFiles(
          directory,
          includeArchives: true,
          operation: 'getLogsByDate',
        ),
      );
    }
    final legacy = await _store.validatedLegacyFile(
      File(_store.legacyFilePath(date)),
      operation: 'getLogsByDate',
      allowMissing: true,
    );
    if (legacy != null) files.add(legacy);
    return _reader.readFiles(files);
  }

  @override
  Future<String> getLogPathByDate(DateTime date) {
    if (!_enabled) return Future<String>.value('');
    return _serialized(() => _logPathByDate(date));
  }

  Future<String> _logPathByDate(DateTime date) async {
    await _ensureInitialized();
    final directory = await _store.validatedDateDirectory(
      _store.dateDirectoryPath(date),
      operation: 'getLogPathByDate',
      allowMissing: true,
    );
    if (directory != null &&
        (await _store.segmentFiles(
          directory,
          includeArchives: true,
          operation: 'getLogPathByDate',
        ))
            .isNotEmpty) {
      return directory.path;
    }
    final legacy = await _store.validatedLegacyFile(
      File(_store.legacyFilePath(date)),
      operation: 'getLogPathByDate',
      allowMissing: true,
    );
    return legacy?.path ?? '';
  }

  @override
  Future<List<ISpectLogData>> getLogsBySession(String sessionPath) {
    if (!_enabled) return Future<List<ISpectLogData>>.value(const []);
    return _serialized(() => _logsBySession(sessionPath));
  }

  Future<List<ISpectLogData>> _logsBySession(String sessionPath) async {
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
    final directory = await _store.validatedDateDirectory(
      path,
      operation: 'getLogsBySession',
    );
    return _reader.readDirectory(directory!);
  }

  Future<List<ISpectLogData>> _readValidatedFile(String path) async {
    final file = await _store.validatedHistoryFile(
      File(path),
      operation: 'getLogsBySession',
    );
    return _reader.readFiles([file!]);
  }

  Future<List<ISpectLogData>> _validateMissingSessionPath(String path) async {
    final hasTraversal =
        path.split(RegExp(r'[/\\]+')).any((segment) => segment == '..');
    if (!hasTraversal && FileLogLayout.isWithinRoot(path, sessionDirectory)) {
      return const <ISpectLogData>[];
    }
    throw const FileLogAccessException(operation: 'getLogsBySession');
  }

  @override
  Future<SessionStatistics> getSessionStatistics() =>
      _serialized(_sessionStatistics);

  Future<SessionStatistics> _sessionStatistics() async {
    final dates = _enabled
        ? await _guardFileSystem('getAvailableLogDates', _availableLogDates)
        : const <DateTime>[];
    var totalSize = 0;
    var totalEntries = 0;
    for (final date in dates) {
      totalSize += await _guardFileSystem(
        'getDateFileSize',
        () => _dateFileSize(date),
      );
      totalEntries += await _reader.countDateEntries(date);
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
      await _store.initialize();
      _resolvedTodaySessionPath = FileLogLayout.join(
        FileLogLayout.join(
          _store.sessionDirectory,
          FileLogLayout.dateName(DateTime.now()),
        ),
        FileLogLayout.segmentName(0),
      );
    } on FileLogHistoryException {
      rethrow;
    } catch (error, stackTrace) {
      throw FileLogStorageException(
        operation: 'initialize',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    try {
      await _retention.apply();
    } on FileLogHistoryException catch (error) {
      _reportError(error);
    } catch (error, stackTrace) {
      _reportError(
        FileLogStorageException(
          operation: 'initializeRetention',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> _appendRecords(
    List<_PendingLog> group,
    LinkedHashMap<String, _PendingLog> snapshot,
  ) async {
    _ActiveSegment? segment;
    _OpenAppend? acquired;
    final uncommitted = <String>[];
    try {
      for (final pending in group) {
        final List<int> bytes;
        try {
          bytes = _codec
              .encode(
                pending.log,
                sessionId: pending.sessionId,
                maxBytes: _limits.recordBytes,
              )
              .bytes;
        } on FileLogLimitException catch (error) {
          snapshot.remove(pending.id);
          _reportError(error);
          continue;
        }
        segment ??= await _resolveActiveSegment(pending.time);
        if (segment.length > 0 &&
            segment.length + bytes.length > _options.maxFileSize) {
          final full = acquired;
          acquired = null;
          if (full != null) {
            await _commitAppend(full);
            uncommitted
              ..forEach(snapshot.remove)
              ..clear();
          }
          segment.rotate(_store);
        }
        acquired ??= await _openAppend(segment);
        await acquired.handle.writeFrom(bytes);
        segment.length += bytes.length;
        uncommitted.add(pending.id);
      }
      final last = acquired;
      acquired = null;
      if (last != null) {
        await _commitAppend(last);
        uncommitted.forEach(snapshot.remove);
      }
    } catch (_) {
      final open = acquired;
      if (open != null) {
        try {
          await _rollBackAppend(open);
        } finally {
          await open.handle.close();
        }
      }
      rethrow;
    }
    if (segment != null &&
        FileLogLayout.dateName(group.first.time) ==
            FileLogLayout.dateName(DateTime.now())) {
      _resolvedTodaySessionPath = segment.file.path;
    }
  }

  Future<_ActiveSegment> _resolveActiveSegment(DateTime date) async {
    final directory = await _store.ensureDateDirectory(
      date,
      operation: 'appendRecord',
    );
    final artifacts = await _store.segmentFiles(
      directory,
      includeArchives: true,
      includeTemporary: true,
      operation: 'appendRecord',
    );
    final segments = artifacts
        .where(
          (file) =>
              FileLogLayout.dateArtifactKind(
                FileLogLayout.basename(file.path),
              ) ==
              ManagedFileKind.segment,
        )
        .toList(growable: false);
    var highestIndex = -1;
    for (final artifact in artifacts) {
      final index =
          FileLogLayout.segmentIndex(FileLogLayout.basename(artifact.path));
      if (index > highestIndex) highestIndex = index;
    }
    final candidate = segments.isEmpty
        ? _store.nextSegment(directory, highestIndex)
        : segments.last;
    final segment = _ActiveSegment(
      directory: directory,
      file: candidate,
      highestIndex: highestIndex,
    );
    if (await _repairIncompleteTail(candidate)) {
      segment.length = await _store.managedFileLength(
        candidate,
        operation: 'appendRecord',
        allowMissing: true,
      );
    } else {
      segment.rotate(_store);
    }
    return segment;
  }

  Future<_OpenAppend> _openAppend(_ActiveSegment segment) async {
    await _store.validatedDateArtifact(
      segment.file,
      directory: segment.directory,
      operation: 'appendRecord',
      allowMissing: true,
      allowedKinds: const {ManagedFileKind.segment},
    );
    final acquired = await _store.acquireAppendHandle(
      segment.file,
      operation: 'appendRecord',
      createIfMissing: true,
    );
    try {
      return _OpenAppend(acquired, await acquired.handle.length());
    } catch (_) {
      await acquired.handle.close();
      rethrow;
    }
  }

  Future<void> _commitAppend(_OpenAppend open) async {
    try {
      await open.handle.flush();
      await _store.validateWritablePath(
        open.acquired,
        operation: 'appendRecord',
      );
    } catch (_) {
      await _rollBackAppend(open);
      rethrow;
    } finally {
      await open.handle.close();
    }
  }

  Future<void> _rollBackAppend(_OpenAppend open) async {
    try {
      await open.handle.truncate(open.startLength);
      await open.handle.flush();
    } on FileSystemException catch (error, stackTrace) {
      _reportError(
        FileLogStorageException(
          operation: 'rollBackAppend',
          path: open.acquired.file.path,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<bool> _repairIncompleteTail(File file) async {
    final validated = await _store.validatedHistoryFile(
      file,
      operation: 'repairIncompleteTail',
      allowMissing: true,
      allowedKinds: const {ManagedFileKind.segment},
    );
    if (validated == null) return true;
    final acquired = await _store.acquireAppendHandle(
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
            await _store.validatedHistoryFile(
              validated,
              operation: 'repairIncompleteTail',
              allowedKinds: const {ManagedFileKind.segment},
            );
            await handle.truncate(start + index + 1);
            await handle.flush();
            await _store.validateWritablePath(
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
}

final class _OpenAppend {
  const _OpenAppend(this.acquired, this.startLength);

  final AcquiredWritableFile acquired;
  final int startLength;

  RandomAccessFile get handle => acquired.handle;
}

final class _ActiveSegment {
  _ActiveSegment({
    required this.directory,
    required this.file,
    required int highestIndex,
  }) : _highestIndex = _maxIndex(highestIndex, file);

  final Directory directory;
  File file;
  int length = 0;
  int _highestIndex;

  static int _maxIndex(int highestIndex, File file) {
    final index = FileLogLayout.segmentIndex(FileLogLayout.basename(file.path));
    return index > highestIndex ? index : highestIndex;
  }

  void rotate(ManagedLogStore store) {
    file = store.nextSegment(directory, _highestIndex);
    _highestIndex++;
    length = 0;
  }
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
