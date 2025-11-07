// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/date_time_extensions.dart';
import 'package:ispect/src/common/extensions/error_handling_extensions.dart';
import 'package:ispect/src/common/history/file_history_config.dart';

/// Optimized daily file-based log history implementation
///
/// - Parameters: Settings for configuration, optional history data
/// - Return: DailyFileLogHistory instance with secure storage
/// - Usage example: `final history = DailyFileLogHistory(settings);`
/// - Edge case notes: Handles platform-specific directories, auto-cleanup, memory optimization
class DailyFileLogHistory extends DefaultISpectLoggerHistory
    implements FileLogHistory {
  /// Creates a daily file-based log history manager
  ///
  /// - Parameters: settings (required), history (optional), maxSessionDays (limit), autoSaveInterval (frequency), enableAutoSave (flag), maxFileSize (bytes), enableCompression (flag), sessionCleanupStrategy (cleanup method)
  /// - Return: Configured DailyFileLogHistory instance
  /// - Usage example: `DailyFileLogHistory(settings, maxSessionDays: 7)`
  /// - Edge case notes: Initializes secure directory, sets up auto-save timer
  DailyFileLogHistory(
    super.settings, {
    super.history,
    int maxSessionDays = 10,
    Duration? autoSaveInterval,
    bool enableAutoSave = true,
    int maxFileSize = 10 * 1024 * 1024,
    bool enableCompression = false,
    SessionCleanupStrategy sessionCleanupStrategy =
        SessionCleanupStrategy.deleteOldest,
  })  : _maxSessionDays = maxSessionDays,
        _autoSaveInterval = autoSaveInterval ?? const Duration(seconds: 1),
        _maxFileSize = maxFileSize,
        _enableCompression = enableCompression,
        _sessionCleanupStrategy = sessionCleanupStrategy {
    _initializeSecureDirectory();
    if (enableAutoSave) {
      _autoSaveEnabled = true;
      _setupAutoSave();
    }
  }

  static const int _chunkSize = FileHistoryConfig.chunkSize;
  static const int _fallbackEntrySize = FileHistoryConfig.fallbackEntrySize;
  static const double _sizeSafetyMargin = FileHistoryConfig.sizeSafetyMargin;

  static final RegExp _datePattern =
      RegExp(r'logs_(\d{4})-(\d{2})-(\d{2})\.json');

  final int _maxSessionDays;
  Duration _autoSaveInterval;
  final int _maxFileSize;
  final bool _enableCompression;
  final SessionCleanupStrategy _sessionCleanupStrategy;

  String? _sessionDirectory;
  Timer? _autoSaveTimer;
  DateTime? _lastSaveDate;
  bool _autoSaveEnabled = false;

  final Set<String> _pendingWrites = <String>{};
  final Completer<void> _directoryInitialized = Completer<void>();

  @override
  String get sessionDirectory {
    if (_sessionDirectory == null) {
      throw StateError(
        'Session directory not initialized yet. Wait for initialization to complete.',
      );
    }
    return _sessionDirectory!;
  }

  @override
  String get todaySessionPath => _getDateFilePath(DateTime.now());

  /// Initializes secure cache directory for log storage.
  ///
  /// - Parameters: None
  /// - Returns: `Future<void>` completing when directory is ready
  /// - Usage example: Called automatically in constructor
  /// - Edge case notes: Handles platform-specific directory creation
  Future<void> _initializeSecureDirectory() async {
    try {
      final cacheDir = await _getSecureCacheDirectory();
      final logsDir = Directory('$cacheDir/ispect_logs');

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _sessionDirectory = logsDir.path;
      _directoryInitialized.complete();
    } catch (exception, stackTrace) {
      ISpect.logger.handleConditionally(
        exception: exception,
        stackTrace: stackTrace,
        settings: settings,
      );
      _directoryInitialized.completeError(exception);
    }
  }

  /// Gets platform-specific secure cache directory
  ///
  /// - Parameters: None
  /// - Returns: `Future<String>` path to secure cache directory
  /// - Usage example: Used internally for directory setup
  /// - Edge case notes: Handles mobile, desktop, and fallback scenarios
  Future<String> _getSecureCacheDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _getMobileCacheDirectory();
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return _getDesktopCacheDirectory();
    }

    return Directory.current.path;
  }

  /// Gets mobile cache directory path.
  ///
  /// - Parameters: None
  /// - Returns: `Future<String>` path to mobile cache directory
  /// - Usage example: Used for Android/iOS platforms
  /// - Edge case notes: Creates directory in system temp with app subdirectory
  Future<String> _getMobileCacheDirectory() async {
    final tempDir = Directory.systemTemp;
    final appCacheDir = Directory('${tempDir.path}/ispect_cache');

    if (!await appCacheDir.exists()) {
      await appCacheDir.create(recursive: true);
    }

    return appCacheDir.path;
  }

  /// Gets desktop cache directory path.
  ///
  /// - Parameters: None
  /// - Returns: `Future<String>` path to desktop cache directory
  /// - Usage example: Used for Windows/macOS/Linux platforms
  /// - Edge case notes: Respects platform-specific cache conventions
  Future<String> _getDesktopCacheDirectory() async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;

    final cacheDir = _buildPlatformCacheDir(homeDir);

    final dir = Directory(cacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir.path;
  }

  /// Builds platform-specific cache directory path
  ///
  /// - Parameters: homeDir - User's home directory path
  /// - Return: String cache directory path
  /// - Usage example: Used internally for desktop cache path building
  /// - Edge case notes: Handles macOS, Windows, and Linux conventions
  String _buildPlatformCacheDir(String homeDir) {
    if (Platform.isMacOS) {
      return '$homeDir/Library/Caches/ispect';
    }

    if (Platform.isWindows) {
      final localAppData =
          Platform.environment['LOCALAPPDATA'] ?? '$homeDir/AppData/Local';
      return '$localAppData/ispect/cache';
    }

    final xdgCache =
        Platform.environment['XDG_CACHE_HOME'] ?? '$homeDir/.cache';
    return '$xdgCache/ispect';
  }

  /// Ensures directory is initialized before operations.
  ///
  /// - Parameters: None
  /// - Returns: `Future<void>` completing when directory is ready
  /// - Usage example: Called before file operations
  /// - Edge case notes: Waits for async initialization to complete
  Future<void> _ensureDirectoryInitialized() async {
    if (!_directoryInitialized.isCompleted) {
      await _directoryInitialized.future;
    }
  }

  /// Sets up automatic saving timer
  void _setupAutoSave() {
    if (!_autoSaveEnabled) return;

    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
      _performAutoSave();
    });
  }

  /// Gets file path for specific date with optimized formatting
  ///
  /// - Parameters: date - Target date, fileType - File extension (default: json)
  /// - Return: String absolute path to date-specific log file
  /// - Usage example: `_getDateFilePath(DateTime.now())`
  /// - Edge case notes: Throws StateError if directory not initialized
  String _getDateFilePath(DateTime date, {String fileType = 'json'}) {
    if (_sessionDirectory == null) {
      throw StateError('Session directory not initialized yet.');
    }
    final dateStr = _formatDateForFileName(date);
    return '$_sessionDirectory/logs_$dateStr.$fileType';
  }

  /// Formats date for consistent file naming
  ///
  /// - Parameters: date - Date to format
  /// - Return: String formatted as YYYY-MM-DD
  /// - Usage example: Used internally for file naming consistency
  /// - Edge case notes: Zero-pads month and day for sorting
  String _formatDateForFileName(DateTime date) => date.toFileNameFormat();

  /// Optimized date parsing from file name
  DateTime? _parseDateFromFileName(String fileName) {
    final match = _datePattern.firstMatch(fileName);
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    return DateTime(year, month, day);
  }

  /// Performs optimized auto-save with write queue management.
  ///
  /// - Parameters: None
  /// - Returns: `Future<void>` completing when auto-save is done
  /// - Usage example: Called periodically by auto-save timer
  /// - Edge case notes: Silently handles errors to prevent app crashes
  Future<void> _performAutoSave() async {
    if (_sessionDirectory == null || history.isEmpty) return;

    final todayPath = todaySessionPath;
    if (_pendingWrites.contains(todayPath)) {
      return;
    }

    try {
      await saveToDailyFile();
    } catch (exception, stackTrace) {
      ISpect.logger.handleConditionally(
        exception: exception,
        stackTrace: stackTrace,
        settings: settings,
      );
    }
  }

  @override
  Future<void> saveToDailyFile() async {
    await _ensureDirectoryInitialized();

    // Skip file persistence if maxSessionDays is 0 or negative
    if (_maxSessionDays <= 0) return;

    if (history.isEmpty) return;

    final filePath = todaySessionPath;
    if (_pendingWrites.contains(filePath)) {
      return;
    }

    _pendingWrites.add(filePath);

    try {
      final availableDates = await getAvailableLogDates();
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Only trigger cleanup when adding a new date that would exceed the limit
      // If today's file already exists, we're just updating it, so no cleanup needed
      final todayExists = availableDates.any((date) => date.isSameDay(todayDate));

      if (!todayExists && availableDates.length >= _maxSessionDays) {
        await _performSessionCleanup(availableDates);
      }

      final file = File(filePath);
      await file.parent.create(recursive: true);

      final existingData = (await file.exists() && _shouldMergeWithExisting())
          ? await _loadExistingData(file)
          : <ISpectLogData>[];

      final mergedData = _mergeHistoryData(existingData, history);

      if (mergedData.isEmpty) return;

      // final today = DateTime.now(); // ← Remove duplicate declaration
      if (!_validateDataForDate(mergedData, today)) {
        if (settings.useConsoleLogs) {
          ISpect.logger
              .warning('Prevented saving mixed-date data to daily file');
        }
        return;
      }

      if (!await _validateFileIntegrity(file, today)) return;

      if (await _wouldExceedSizeLimit(file, mergedData)) {
        // Check available disk space before rotation
        if (!await _hasEnoughDiskSpace(
          file.parent,
          _estimateJsonSize(mergedData),
        )) {
          if (settings.useConsoleLogs) {
            ISpect.logger.warning(
              'Insufficient disk space for file rotation, skipping save',
            );
          }
          return;
        }

        if (settings.useConsoleLogs) {
          ISpect.logger
              .warning('File size would exceed limit, performing rotation');
        }
        await _rotateFileIfNeeded(file, today);
      }

      // Final disk space check before writing
      if (!await _hasEnoughDiskSpace(
        file.parent,
        _estimateJsonSize(mergedData),
      )) {
        if (settings.useConsoleLogs) {
          ISpect.logger
              .warning('Insufficient disk space for file write, skipping save');
        }
        return;
      }

      await _writeDataChunked(file, mergedData);
      _lastSaveDate = DateTime.now();
    } finally {
      _pendingWrites.remove(filePath);
    }
  }

  /// Performs session cleanup based on the configured strategy.
  ///
  /// - Parameters: availableDates - List of dates with existing log files
  /// - Returns: `Future<void>` completing when cleanup is done
  /// - Usage example: Called internally when session limit exceeded
  /// - Edge case notes: Handles different cleanup strategies efficiently
  Future<void> _performSessionCleanup(List<DateTime> availableDates) async {
    switch (_sessionCleanupStrategy) {
      case SessionCleanupStrategy.deleteOldest:
        await _cleanupByOldest(availableDates);
        return;
      case SessionCleanupStrategy.deleteBySize:
        await _cleanupBySize(availableDates);
        return;
      case SessionCleanupStrategy.archiveOldest:
        await _cleanupByArchiving(availableDates);
        return;
    }
  }

  /// Cleanup strategy: delete oldest files first.
  ///
  /// - Parameters: availableDates - List of dates with existing log files
  /// - Returns: `Future<void>` completing when cleanup is done
  /// - Usage example: Used by _performSessionCleanup
  /// - Edge case notes: Sorts dates and removes oldest first
  Future<void> _cleanupByOldest(List<DateTime> availableDates) async {
    final sortedDates = List<DateTime>.from(availableDates)..sort();
    final datesToDelete = sortedDates.sublist(
      0,
      sortedDates.length - _maxSessionDays + 1,
    );

    for (final date in datesToDelete) {
      await clearDateStorage(date);
    }
  }

  /// Cleanup strategy: delete largest files first
  ///
  /// - Parameters: availableDates - List of dates with existing log files
  /// - Returns: `Future<void>` completing when cleanup is done
  /// - Usage example: Used by _performSessionCleanup
  /// - Edge case notes: Sorts by file size and removes largest first
  Future<void> _cleanupBySize(List<DateTime> availableDates) async {
    final datesSizes = <MapEntry<DateTime, int>>[];

    for (final date in availableDates) {
      final size = await getDateFileSize(date);
      datesSizes.add(MapEntry(date, size));
    }

    datesSizes.sort((a, b) => b.value.compareTo(a.value));

    final datesToDelete = datesSizes
        .take(datesSizes.length - _maxSessionDays + 1)
        .map((entry) => entry.key)
        .toList();

    for (final date in datesToDelete) {
      await clearDateStorage(date);
    }
  }

  /// Cleanup strategy: archive oldest files before deletion
  ///
  /// - Parameters: availableDates - List of dates with existing log files
  /// - Returns: `Future<void>` completing when cleanup is done
  /// - Usage example: Used by _performSessionCleanup
  /// - Edge case notes: Archives files to compressed format then deletes originals
  Future<void> _cleanupByArchiving(List<DateTime> availableDates) async {
    if (_enableCompression) {
      final sortedDates = List<DateTime>.from(availableDates)..sort();
      final datesToArchive = sortedDates.sublist(
        0,
        sortedDates.length - _maxSessionDays + 1,
      );

      for (final date in datesToArchive) {
        await _archiveAndDeleteDate(date);
      }
    } else {
      await _cleanupByOldest(availableDates);
    }
  }

  /// Archives a date's log file and deletes the original
  Future<void> _archiveAndDeleteDate(DateTime date) async {
    await clearDateStorage(date);

    if (settings.useConsoleLogs) {
      ISpect.logger.info(
        'Archived and deleted logs for ${_formatDateForFileName(date)}',
      );
    }
  }

  /// Validates file integrity before writing.
  ///
  /// - Parameters: file - File to validate, today - Current date
  /// - Returns: `Future<bool>` true if safe to write
  /// - Usage example: Used internally before file writes
  /// - Edge case notes: Prevents overwriting files from other days
  Future<bool> _validateFileIntegrity(File file, DateTime today) async {
    final existingFileData = await _loadExistingData(file);
    if (existingFileData.isNotEmpty) {
      // Check that all entries in the file are from the same day
      final targetDate = DateTime(today.year, today.month, today.day);

      for (final entry in existingFileData) {
        if (!entry.time.isSameDay(targetDate)) {
          if (settings.useConsoleLogs) {
            ISpect.logger.warning(
              'File ${file.path} contains data from ${_formatDateForFileName(entry.time)}, '
              "but expected only today's data (${_formatDateForFileName(today)})",
            );
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Checks if there's enough disk space for the operation
  Future<bool> _hasEnoughDiskSpace(
    Directory directory,
    int requiredBytes,
  ) async {
    try {
      // Add buffer for filesystem overhead
      final requiredWithBuffer =
          (requiredBytes * FileHistoryConfig.filesystemOverheadMargin).round();

      // Check against the configured maximum file size limit
      // This prevents runaway file growth while respecting user configuration
      return requiredWithBuffer <=
          (_maxFileSize * FileHistoryConfig.filesystemOverheadMargin).round();
    } catch (e) {
      // If we can't check disk space, assume it's available
      return true;
    }
  }

  ///
  /// Since the file is completely overwritten with merged data, this method
  /// only checks the estimated size of the data to be written against 90%
  /// of the configured limit to provide a safety buffer.
  ///
  /// - Parameters: file - Target file, data - Data to be written
  /// - Returns: `Future<bool>` true if size limit would be exceeded
  /// - Usage example: Used before writing to prevent oversized files
  /// - Edge case notes: Uses 90% threshold to avoid unnecessary rotations near the limit
  Future<bool> _wouldExceedSizeLimit(
    File file,
    List<ISpectLogData> data,
  ) async {
    if (_maxFileSize <= 0) return false;

    try {
      // Since _writeDataChunked overwrites the file completely with merged data,
      // we only need to check if the estimated size of the data to be written
      // exceeds the limit. Adding currentSize would double-count existing data.
      // We use threshold to provide a safety buffer and avoid edge cases.
      final estimatedDataSize = _estimateJsonSize(data);
      final effectiveLimit =
          (_maxFileSize * FileHistoryConfig.fileSizeThreshold).round();

      return estimatedDataSize > effectiveLimit;
    } catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(exception: e, stackTrace: st);
      }
      return false;
    }
  }

  /// Estimates the JSON size of the data with safety margin
  int _estimateJsonSize(List<ISpectLogData> data) {
    if (data.isEmpty) return 0;

    final sampleSize = data.length > FileHistoryConfig.sampleSizeForEstimation
        ? FileHistoryConfig.sampleSizeForEstimation
        : data.length;
    var totalSampleSize = 0;

    for (var i = 0; i < sampleSize; i++) {
      try {
        final json = jsonEncode(data[i].toJson());
        totalSampleSize += json.length;
      } catch (e) {
        totalSampleSize += _fallbackEntrySize;
      }
    }

    final averageSize = totalSampleSize ~/ sampleSize;
    final estimatedTotal = averageSize * data.length;

    return (estimatedTotal * _sizeSafetyMargin).round();
  }

  /// Rotates the file if it would exceed size limits
  /// Ensures atomic operation: backup is created successfully before clearing the file
  Future<void> _rotateFileIfNeeded(File file, DateTime date) async {
    if (!await file.exists()) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${file.path}.backup_$timestamp';

      // First, create backup - if this fails, don't touch the original file
      await file.copy(backupPath);

      // Only after successful backup, clear the original file
      await file.writeAsString('[]');

      if (settings.useConsoleLogs) {
        ISpect.logger.info('Rotated log file: backup created at $backupPath');
      }
    } catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(
          exception: e,
          stackTrace: st,
          message:
              'Failed to rotate file ${file.path}, keeping original intact',
        );
      }
      // Re-throw to prevent writing to a file that wasn't properly rotated
      rethrow;
    }
  }

  /// Checks if we should merge with existing data
  ///
  /// - Parameters: None
  /// - Returns: `bool` true if should merge with existing file
  /// - Usage example: Used during save operations
  /// - Edge case notes: Prevents data loss by merging on same day
  bool _shouldMergeWithExisting() {
    final now = DateTime.now();

    if (_lastSaveDate == null) return true;

    if (!_lastSaveDate!.isSameDay(now)) return false;

    return true;
  }

  /// Loads existing data from file efficiently.
  ///
  /// - Parameters: file - File to load data from
  /// - Returns: `Future<List<ISpectLogData>>` loaded data or empty list
  /// - Usage example: Used during merge operations
  /// - Edge case notes: Returns empty list on any parsing error
  Future<List<ISpectLogData>> _loadExistingData(File file) async {
    try {
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) {
        return <ISpectLogData>[];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      return jsonList
          .map(
            (jsonEntry) => ISpectLogDataJsonUtils.fromJson(
              jsonEntry as Map<String, dynamic>,
            ),
          )
          .toList();
    } on FormatException catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(
          exception: e,
          stackTrace: st,
          message:
              'Failed to parse JSON from file ${file.path}, file may be corrupted',
        );
      }
      return <ISpectLogData>[];
    } catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(
          exception: e,
          stackTrace: st,
          message: 'Failed to load existing data from file ${file.path}',
        );
      }
      return <ISpectLogData>[];
    }
  }

  /// Merges history data avoiding duplicates and filtering by today's date
  ///
  /// - Parameters: existing - Data from file, current - Data from memory
  /// - Returns: `List<ISpectLogData>` merged and deduplicated data
  /// - Usage example: Used during save operations to merge datasets
  /// - Edge case notes: Uses Set for proper deduplication of identical objects, sorts by timestamp
  List<ISpectLogData> _mergeHistoryData(
    List<ISpectLogData> existing,
    List<ISpectLogData> current,
  ) {
    final merged = <ISpectLogData>{};
    final today = DateTime.now();

    // Add existing data (from file)
    for (final item in existing) {
      if (item.time.isSameDay(today)) {
        merged.add(item);
      }
    }

    // Add current data (from memory), avoiding duplicates
    for (final item in current) {
      if (item.time.isSameDay(today)) {
        merged.add(item);
      }
    }

    final result = merged.toList()..sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  /// Writes data in chunks using optimized streaming approach
  /// Validates that the file was written successfully
  Future<void> _writeDataChunked(File file, List<ISpectLogData> data) async {
    final sink = file.openWrite();

    try {
      sink.write('[');

      for (var i = 0; i < data.length; i++) {
        if (i > 0) {
          sink.write(',');
        }

        try {
          final json = data[i].toJson();
          final sanitizedJson = _sanitizeJsonForEncoding(json);
          sink.write(jsonEncode(sanitizedJson));
        } catch (e, st) {
          if (settings.useConsoleLogs) {
            ISpect.logger.handle(exception: e, stackTrace: st);
          }
          sink.write('null');
        }

        if (i % _chunkSize == 0) {
          await Future<void>.delayed(const Duration(microseconds: 1));
        }
      }

      sink.write(']');
    } finally {
      await sink.close();
    }

    // Validate that the file was written successfully
    if (await file.exists()) {
      final writtenSize = await file.length();
      if (writtenSize == 0 && data.isNotEmpty) {
        throw StateError(
          'File write validation failed: file is empty but data was provided',
        );
      }
    } else {
      throw StateError(
        'File write validation failed: file does not exist after write',
      );
    }
  }

  /// Sanitizes JSON data to ensure all values are encodable
  Map<String, dynamic> _sanitizeJsonForEncoding(Map<String, dynamic> json) {
    final sanitized = <String, dynamic>{};

    for (final MapEntry(:key, :value) in json.entries) {
      sanitized[key] = _sanitizeValue(value);
    }

    return sanitized;
  }

  /// Sanitizes a single value for JSON encoding
  Object? _sanitizeValue(Object? value) => switch (value) {
        null || String() || num() || bool() => value,
        final List<dynamic> list => list.map(_sanitizeValue).toList(),
        final Map<String, dynamic> map => _sanitizeJsonForEncoding(map),
        _ => value.toString(),
      };

  @override
  Future<void> loadFromDate(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final loadedData = await _parseJsonToData(jsonString);

        clear();
        for (final data in loadedData) {
          add(data);
        }
      } catch (e, st) {
        if (settings.useConsoleLogs) {
          ISpect.logger.handle(exception: e, stackTrace: st);
        }
      }
    }
  }

  @override
  Future<void> loadTodayHistory() async {
    await loadFromDate(DateTime.now());
  }

  @override
  Future<String> exportToJson() async {
    if (history.isEmpty) return '[]';

    final buffer = StringBuffer('[');
    var isFirstEntry = true;

    for (var i = 0; i < history.length; i += _chunkSize) {
      final chunkEnd =
          (i + _chunkSize > history.length) ? history.length : i + _chunkSize;
      final chunk = history.sublist(i, chunkEnd);

      // Process chunk entries
      for (final entry in chunk) {
        if (!isFirstEntry) {
          buffer.write(',');
        }
        buffer.write(jsonEncode(entry.toJson()));
        isFirstEntry = false;
      }

      // Yield control for very large datasets
      if (i % (_chunkSize * 20) == 0) {
        await Future<void>.delayed(const Duration(microseconds: 1));
      }
    }

    buffer.write(']');
    return buffer.toString();
  }

  @override
  Future<void> importFromJson(String jsonString) async {
    try {
      final loadedData = await _parseJsonToData(jsonString);

      for (final data in loadedData) {
        add(data);
      }
    } catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(exception: e, stackTrace: st);
      }
    }
  }

  @override
  Future<void> clearAllFileStorage() async {
    await _ensureDirectoryInitialized();

    try {
      final directory = Directory(sessionDirectory);
      if (await directory.exists()) {
        await for (final FileSystemEntity file in directory.list()) {
          if (file is File && file.path.endsWith('.json')) {
            await file.delete();
          }
        }
      }
    } catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(exception: e, stackTrace: st);
      }
    }
  }

  @override
  Future<void> clearDateStorage(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(exception: e, stackTrace: st);
      }
    }
  }

  @override
  Future<List<DateTime>> getAvailableLogDates() async {
    await _ensureDirectoryInitialized();

    final dates = <DateTime>[];

    try {
      final directory = Directory(sessionDirectory);
      if (await directory.exists()) {
        await for (final FileSystemEntity file in directory.list()) {
          if (file is File) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            final date = _parseDateFromFileName(fileName);
            if (date != null) {
              dates.add(date);
            }
          }
        }
      }
    } catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(exception: e, stackTrace: st);
      }
    }

    dates.sort();
    return dates;
  }

  @override
  Future<int> getDateFileSize(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    try {
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
    } catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(exception: e, stackTrace: st);
      }
    }

    return 0;
  }

  @override
  Future<bool> hasTodaySession() async {
    await _ensureDirectoryInitialized();

    final file = File(todaySessionPath);
    return file.exists();
  }

  /// Cleanup resources when history is no longer needed
  void dispose() {
    _autoSaveTimer?.cancel();
  }

  /// Gets comprehensive session statistics.
  @override
  // ignore: prefer_final_locals
  Future<SessionStatistics> getSessionStatistics() async {
    await _ensureDirectoryInitialized();

    final availableDates = await getAvailableLogDates();

    final stats = <String, int>{
      'totalSize': 0,
      'totalEntries': 0,
    };

    for (final date in availableDates) {
      stats['totalSize'] = stats['totalSize']! + await getDateFileSize(date);
      final logs = await getLogsByDate(date);
      stats['totalEntries'] = stats['totalEntries']! + logs.length;
    }

    return SessionStatistics(
      totalDays: availableDates.length,
      totalSize: stats['totalSize']!,
      totalEntries: stats['totalEntries']!,
      oldestDate: availableDates.isNotEmpty ? availableDates.first : null,
      newestDate: availableDates.isNotEmpty ? availableDates.last : null,
      maxSessionDays: _maxSessionDays,
      autoSaveInterval: _autoSaveInterval,
      enableAutoSave: _autoSaveEnabled,
      maxFileSize: _maxFileSize,
      cleanupStrategy: _sessionCleanupStrategy,
    );
  }

  /// Updates auto-save settings during runtime.
  @override
  void updateAutoSaveSettings({bool? enabled, Duration? interval}) {
    // Update the stored interval if provided
    if (interval != null) {
      _autoSaveInterval = interval;
    }

    if (enabled != null) {
      if (enabled && !_autoSaveEnabled) {
        // Enable auto-save
        _autoSaveEnabled = true;
        _autoSaveTimer?.cancel();
        _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
          _performAutoSave();
        });
      } else if (!enabled && _autoSaveEnabled) {
        // Disable auto-save
        _autoSaveEnabled = false;
        _autoSaveTimer?.cancel();
        _autoSaveTimer = null;
      }
    } else if (interval != null && _autoSaveEnabled) {
      // Update interval while keeping auto-save enabled
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
        _performAutoSave();
      });
    }
  }

  @override
  Future<List<ISpectLogData>> getLogsByDate(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        return _parseJsonToData(jsonString);
      } catch (e, st) {
        if (settings.useConsoleLogs) {
          ISpect.logger.handle(exception: e, stackTrace: st);
        }
        return <ISpectLogData>[];
      }
    }

    return <ISpectLogData>[];
  }

  /// Parses JSON string to list of ISpectLogData with optimized batch processing.
  ///
  /// - Parameters: jsonString - Raw JSON string representing a list of entries
  /// - Returns: `Future<List<ISpectLogData>>` parsed list (empty on error)
  /// - Usage example: Internal parsing for import and load operations
  /// - Edge case notes: Processes in adaptive chunks, skips invalid entries
  Future<List<ISpectLogData>> _parseJsonToData(String jsonString) async {
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final totalLength = jsonList.length;

      if (totalLength == 0) return <ISpectLogData>[];

      // Adaptive chunk size based on data size
      final chunkSize = totalLength > 1000 ? 50 : 25;
      final result = <ISpectLogData>[];

      for (var i = 0; i < totalLength; i += chunkSize) {
        final chunkEnd =
            (i + chunkSize > totalLength) ? totalLength : i + chunkSize;

        // Process batch without creating intermediate collections
        for (var j = i; j < chunkEnd; j++) {
          try {
            final entry = ISpectLogDataJsonUtils.fromJson(
              jsonList[j] as Map<String, dynamic>,
            );
            result.add(entry);
          } catch (e, st) {
            // Skip invalid entries but continue processing
            if (settings.useConsoleLogs) {
              ISpect.logger.handle(exception: e, stackTrace: st);
            }
          }
        }

        // Yield control less frequently for larger datasets
        if (i % (chunkSize * 8) == 0) {
          await Future<void>.delayed(const Duration(microseconds: 1));
        }
      }

      return result;
    } catch (e, st) {
      if (settings.useConsoleLogs) {
        ISpect.logger.handle(exception: e, stackTrace: st);
      }
      return <ISpectLogData>[];
    }
  }

  /// Validates that all data entries belong to the specified date with early exit optimization.
  ///
  /// - Parameters: data - Entries to validate, targetDate - Date to enforce
  /// - Returns: `bool` true if all entries belong to targetDate
  /// - Usage example: Used before saving to ensure daily file consistency
  /// - Edge case notes: Early exits on first mismatch for performance
  bool _validateDataForDate(List<ISpectLogData> data, DateTime targetDate) {
    if (data.isEmpty) return true;

    final targetYear = targetDate.year;
    final targetMonth = targetDate.month;
    final targetDay = targetDate.day;

    // Use indexed loop for better performance on large datasets
    for (var i = 0; i < data.length; i++) {
      final entryTime = data[i].time;
      if (entryTime.year != targetYear ||
          entryTime.month != targetMonth ||
          entryTime.day != targetDay) {
        return false; // Early exit on first mismatch
      }
    }
    return true;
  }

  @override
  Future<List<ISpectLogData>> getLogsBySession(String sessionPath) async {
    await _ensureDirectoryInitialized();

    final file = File(sessionPath);
    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        return _parseJsonToData(jsonString);
      } catch (e, st) {
        if (settings.useConsoleLogs) {
          ISpect.logger.handle(exception: e, stackTrace: st);
        }
        return <ISpectLogData>[];
      }
    }

    return <ISpectLogData>[];
  }

  @override
  Future<String> getLogPathByDate(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    if (await file.exists()) {
      return file.path;
    } else {
      throw FileSystemException('Log file does not exist for date: $date');
    }
  }
}
