import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ispect/src/common/utils/date_formatter.dart';
import 'package:ispect/src/common/utils/logs_file/base/base_logs_file.dart';
import 'package:ispect/src/core/platform/platform_directory.dart';
import 'package:ispect/src/core/res/ispect_callbacks.dart';
import 'package:ispectify/ispectify.dart' show generateTraceId;

/// Native platform implementation for log file operations.
///
/// **Security note:** Log files are stored as plain-text JSON. Avoid logging
/// PII or sensitive data via `ISpect.logger.*` methods, as it will be written
/// to disk without encryption.
///
/// - Parameters: Android, iOS, macOS, Windows, Linux support
/// - Return: File objects for native file system operations
/// - Usage example: `final logsFile = NativeLogsFile(); await logsFile.createFile(logs);`
/// - Edge case notes: Handles platform-specific directory selection and file system errors
class NativeLogsFile extends BaseLogsFile {
  static const String _persistentDirectoryPrefix = 'ispect_logs_';
  static const String _shareRootName = 'ispect_share';
  static const String _processDirectoryPrefix = 'process_';
  static const String _activeLeaseName = '.active-share';
  static final String _currentProcessDirectoryPrefix = 'process_${pid}_';

  /// How long share temp files are kept before startup or a later
  /// [createAndShareLogs] sweep removes them. Generous enough for platform
  /// share-sheet workflows to finish reading.
  static const Duration _shareRetention = Duration(hours: 1);
  static const Duration _shareLeaseTimeout = Duration(minutes: 2);
  static const Duration _shareLeaseHeartbeat = Duration(seconds: 30);

  /// Paths currently handed to a share callback.
  ///
  /// A concurrent stale-file sweep must not delete these files even when a
  /// recipient keeps the callback pending beyond [_shareRetention].
  static final Set<String> _inFlightSharePaths = <String>{};
  static final String _shareOwnerToken = '$pid-${generateTraceId()}';
  static Future<Directory>? _shareTempDirectory;
  static Timer? _shareLeaseTimer;
  static Future<void> _heartbeatFuture = Future<void>.value();
  static RandomAccessFile? _shareLeaseHandle;
  static String? _shareLeaseDirectoryPath;
  static String? _shareLeaseRecordValue;
  static int _shareLeaseVersion = 0;
  static int _shareLeaseGeneration = 0;
  static int _activeShareOperations = 0;
  static Future<void> _leaseSerial = Future<void>.value();
  static Future<void> _lifecycleSerial = Future<void>.value();

  @override
  bool get supportsNativeFiles => true;

  @override
  Future<File> createFile(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    try {
      final dir = await _getPlatformDirectory();
      final logsDir = await _ensureLogsDirectory(dir);
      final file = await _createLogFile(logsDir, fileName, fileType, logs);

      return file;
    } on FileSystemException catch (e, st) {
      Error.throwWithStackTrace(
        FileSystemException('Failed to create log file: ${e.message}', e.path),
        st,
      );
    }
  }

  /// Gets platform-appropriate directory for log storage.
  Future<Directory> _getPlatformDirectory() async {
    final result = await platformDirectoryProvider.logsBaseDirectory();
    if (result is! Directory) {
      throw StateError(
        'Expected dart:io Directory from logsBaseDirectory(). '
        'This method must not be called on web.',
      );
    }
    return result;
  }

  /// Creates an owner-private logs directory beneath the app support directory.
  Future<Directory> _ensureLogsDirectory(Directory parentDir) async {
    await _requireDirectoryEntity(parentDir, label: 'logs base directory');
    final canonicalParent = Directory(await parentDir.resolveSymbolicLinks());
    await _requireDirectoryEntity(
      canonicalParent,
      label: 'canonical logs base directory',
    );
    await _validatePrivateDirectoryPermissions(
      canonicalParent,
      label: 'canonical logs base directory',
      requireOwnerOnly: false,
    );

    final logsDir = await canonicalParent.createTemp(
      _persistentDirectoryPrefix,
    );
    try {
      await _requireDirectoryEntity(logsDir, label: 'logs directory');
      final canonicalLogsDir = Directory(await logsDir.resolveSymbolicLinks());
      if (!_isDirectChild(canonicalLogsDir.path, canonicalParent.path)) {
        throw FileSystemException(
          'Native logs directory escaped the platform directory.',
          logsDir.path,
        );
      }
      await _validatePrivateDirectoryPermissions(
        canonicalLogsDir,
        label: 'logs directory',
        requireOwnerOnly: true,
      );
      await _validatePrivateDirectoryPermissions(
        canonicalParent,
        label: 'canonical logs base directory',
        requireOwnerOnly: false,
      );
      return canonicalLogsDir;
    } catch (_) {
      try {
        await logsDir.delete();
      } catch (_) {
        // Cleanup is best-effort after rejecting a new private directory.
      }
      rethrow;
    }
  }

  /// Creates a uniquely named regular file without replacing an existing path.
  Future<File> _createLogFile(
    Directory logsDir,
    String fileName,
    String fileType,
    String logs,
  ) async {
    final timestamp = DateFormatter.nowAsFileTimestamp();
    final safeFileName = _sanitizeFileName(fileName);
    final safeFileType = _sanitizeFileType(fileType);
    final nonce =
        '${DateTime.now().microsecondsSinceEpoch}_${generateTraceId()}';
    final fullFileName = '${safeFileName}_${timestamp}_$nonce.$safeFileType';
    final file = File('${logsDir.path}/$fullFileName');

    RandomAccessFile? handle;
    try {
      await _requireDirectoryEntity(logsDir, label: 'logs directory');
      await file.create(exclusive: true);
      await _validateRegularFile(
        file,
        parent: logsDir,
        label: 'persistent log file',
      );
      await _makePersistentFileOwnerOnly(file);
      await _validatePersistentFilePermissions(file);
      handle = await file.open(mode: FileMode.writeOnlyAppend);
      await _validateRegularFile(
        file,
        parent: logsDir,
        label: 'persistent log file',
      );
      await _validatePersistentFilePermissions(file);
      await handle.truncate(0);
      await handle.setPosition(0);
      await handle.writeString(logs);
      await handle.flush();
      await _validateRegularFile(
        file,
        parent: logsDir,
        label: 'persistent log file',
      );
      await _validatePersistentFilePermissions(file);
    } catch (_) {
      try {
        await handle?.close();
      } catch (_) {
        // Cleanup is best-effort after a failed persistent-file write.
      }
      handle = null;
      await _bestEffortDelete(file);
      rethrow;
    } finally {
      try {
        await handle?.close();
      } catch (_) {
        // Cleanup is best-effort after a failed persistent-file write.
      }
    }
    return file;
  }

  /// Sanitizes filename for cross-platform compatibility.
  ///
  /// Strips directory separators to prevent path traversal, then removes
  /// any remaining non-alphanumeric characters except dashes, underscores,
  /// and dots.
  static String _sanitizeFileName(String fileName) {
    final baseName = fileName.split(RegExp(r'[/\\]')).last;
    return baseName.replaceAll(RegExp(r'[^\w\-_.]'), '_');
  }

  static String _sanitizeFileType(String fileType) =>
      fileType.replaceAll(RegExp(r'[^\w]'), '');

  @override
  String getFilePath(Object file) {
    if (file is! File) {
      throw ArgumentError('Expected File instance.');
    }
    return file.path;
  }

  @override
  Future<int> getFileSize(Object file) async {
    if (file is! File) {
      throw ArgumentError('Expected File instance.');
    }
    final stat = await file.stat();
    return stat.size;
  }

  @override
  Future<String> readAsString(Object file) async {
    if (file is! File) {
      throw ArgumentError('Expected File instance.');
    }
    return file.readAsString();
  }

  @override
  Future<void> deleteFile(Object file) async {
    if (file is! File) {
      throw ArgumentError('Expected File instance.');
    }

    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<String> saveToDevice(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    final file = await createFile(logs, fileName: fileName, fileType: fileType);
    return file.path;
  }

  @override
  Future<void> shareFile(
    Object file, {
    String? fileName,
    String fileType = 'json',
    ISpectShareCallback? onShare,
  }) async {
    if (file is! File) {
      throw ArgumentError('Expected File instance.');
    }

    if (onShare == null) {
      throw StateError(
        'Share callback is not provided. Supply an onShare callback via ISpectBuilder.',
      );
    }

    await onShare(
      ISpectShareRequest(
        filePaths: [file.path],
        text: 'ISpect Application Logs',
        subject: 'Application Logs - ${DateTime.now().toIso8601String()}',
      ),
    );
  }

  @override
  Future<void> createAndShareFile(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
    ISpectShareCallback? onShare,
  }) {
    if (onShare == null) {
      throw StateError(
        'Share callback is not provided. Supply an onShare callback via ISpectBuilder.',
      );
    }
    return createAndShareLogs(
      logs,
      onShare: onShare,
      fileName: fileName,
      fileType: fileType,
    );
  }

  /// Creates a temp log file and hands it to the platform share sheet.
  ///
  /// The file remains available for [_shareRetention] after success so share
  /// extensions can read it asynchronously. A delayed best-effort deletion,
  /// startup cleanup, and later-share sweeps bound its lifetime.
  ///
  /// On failure the just-created file is removed best-effort, since no share
  /// happened and the file is orphaned.
  static Future<void> createAndShareLogs(
    String logs, {
    required ISpectShareCallback onShare,
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    var leaseAcquired = false;
    File? file;
    try {
      await _beginShareOperation();
      leaseAcquired = true;
      await _sweepStaleShareFiles();
      file = await _createTemporaryFile(logs, fileName, fileType);
      _inFlightSharePaths.add(file.path);
      await _shareFile(file, onShare: onShare);
      _scheduleBestEffortDelete(file);
    } catch (_) {
      if (file != null) await _bestEffortDelete(file);
      rethrow;
    } finally {
      if (file != null) _inFlightSharePaths.remove(file.path);
      if (leaseAcquired) await _endShareOperation();
    }
  }

  /// Resolves the private process-local directory for share temp files.
  static Future<Directory> _shareTempDir() async {
    while (true) {
      var cached = _shareTempDirectory;
      if (cached == null) {
        cached = _createShareTempDir();
        _shareTempDirectory = cached;
      }

      final Directory directory;
      try {
        directory = await cached;
      } catch (_) {
        if (identical(_shareTempDirectory, cached)) {
          _shareTempDirectory = null;
        }
        rethrow;
      }
      if (await directory.exists()) {
        try {
          final root = await _shareRootDir();
          final validated = await _validateProcessDirectory(directory, root);
          await _ensureCurrentShareLease(validated);
          return validated;
        } catch (_) {
          if (identical(_shareTempDirectory, cached)) {
            _shareTempDirectory = null;
          }
          continue;
        }
      }

      if (identical(_shareTempDirectory, cached)) {
        _shareTempDirectory = null;
      }
      await _releaseCurrentShareLease();
    }
  }

  static Future<Directory> _createShareTempDir() async {
    final root = await _shareRootDir();
    final created = await root.createTemp(_currentProcessDirectoryPrefix);
    try {
      final directory = await _validateProcessDirectory(created, root);
      await _ensureCurrentShareLease(directory);
      return directory;
    } catch (_) {
      try {
        if (await FileSystemEntity.type(
              created.path,
              followLinks: false,
            ) ==
            FileSystemEntityType.directory) {
          await created.delete();
        }
      } catch (_) {
        // A concurrent sweeper may own the directory now.
      }
      rethrow;
    }
  }

  static Future<Directory> _shareRootDir() async {
    final cachePath = await platformDirectoryProvider.cacheDirectoryPath();
    final cache = Directory(cachePath);
    await _requireDirectoryEntity(cache, label: 'cache');
    final canonicalCache = Directory(await cache.resolveSymbolicLinks());
    await _requireDirectoryEntity(canonicalCache, label: 'canonical cache');

    final root = Directory(
      '${canonicalCache.path}${Platform.pathSeparator}$_shareRootName',
    );
    final initialType = await FileSystemEntity.type(
      root.path,
      followLinks: false,
    );
    if (initialType == FileSystemEntityType.notFound) {
      await root.create();
    } else if (initialType != FileSystemEntityType.directory) {
      throw FileSystemException(
        'Native share root must be a real directory.',
        root.path,
      );
    }
    await _requireDirectoryEntity(root, label: 'share root');

    final canonicalRoot = Directory(await root.resolveSymbolicLinks());
    if (!_isDirectChild(canonicalRoot.path, canonicalCache.path)) {
      throw FileSystemException(
        'Native share root escaped the app cache directory.',
        root.path,
      );
    }
    return canonicalRoot;
  }

  /// Creates temporary file for sharing
  static Future<File> _createTemporaryFile(
    String logs,
    String fileName,
    String fileType,
  ) async {
    final dir = await _shareTempDir();
    final root = await _shareRootDir();
    await _validateProcessDirectory(dir, root);
    final timestamp = DateFormatter.nowAsFileTimestamp();
    final safeFileName = _sanitizeFileName(fileName);
    final safeFileType = _sanitizeFileType(fileType);
    final nonce =
        '${DateTime.now().microsecondsSinceEpoch}_${generateTraceId()}';
    final fullFileName = '${safeFileName}_${timestamp}_$nonce.$safeFileType';
    final file = File('${dir.path}/$fullFileName');

    RandomAccessFile? handle;
    try {
      await file.create(exclusive: true);
      await _validateRegularFile(file, parent: dir, label: 'share file');
      handle = await file.open(mode: FileMode.writeOnlyAppend);
      await _validateRegularFile(file, parent: dir, label: 'share file');
      await handle.truncate(0);
      await handle.setPosition(0);
      await handle.writeString(logs);
      await handle.flush();
    } catch (_) {
      try {
        await handle?.close();
      } catch (_) {
        // Cleanup is best-effort after a failed temporary-file write.
      }
      handle = null;
      await _bestEffortDelete(file);
      rethrow;
    } finally {
      try {
        await handle?.close();
      } catch (_) {
        // Cleanup is best-effort after a failed temporary-file write.
      }
    }
    return file;
  }

  /// Shares file through system dialog
  static Future<void> _shareFile(
    File file, {
    required ISpectShareCallback onShare,
  }) async {
    await onShare(
      ISpectShareRequest(
        filePaths: [file.path],
        text: 'ISpect Application Logs',
        subject: 'Application Logs - ${DateTime.now().toIso8601String()}',
      ),
    );
  }

  /// Best-effort cleanup of share temp files older than [_shareRetention].
  ///
  /// Only randomized process directories under the app-private share root are
  /// inspected. A fresh lease protects another process with an active share;
  /// a crashed process's lease expires so later launches can remove its stale
  /// diagnostics.
  static Future<void> cleanupStaleShareFiles() =>
      _sweepStaleShareFiles(ignoreRootErrors: false);

  static Future<void> _sweepStaleShareFiles({
    bool ignoreRootErrors = true,
  }) =>
      _serializeLeaseAction<void>(() async {
        try {
          final root = await _shareRootDir();
          final currentDirectoryPath = _shareLeaseDirectoryPath;
          final now = DateTime.now();
          final cutoff = now.subtract(_shareRetention);
          await for (final entry in root.list(followLinks: false)) {
            final basename = _basename(entry.path);
            if (entry is! Directory ||
                !basename.startsWith(_processDirectoryPrefix)) {
              continue;
            }

            final Directory directory;
            try {
              directory = await _validateProcessDirectory(entry, root);
            } catch (_) {
              continue;
            }
            final isCurrent = directory.path == currentDirectoryPath;
            if (isCurrent) {
              await _sweepProcessDirectory(
                directory,
                cutoff: cutoff,
                protectInFlight: true,
              );
              continue;
            }
            // POSIX locks are process-scoped: opening a lease from another
            // isolate in this PID could release that isolate's active lock.
            if (basename.startsWith(_currentProcessDirectoryPrefix)) continue;
            await _sweepForeignProcessDirectory(
              directory,
              now: now,
              cutoff: cutoff,
            );
          }
        } catch (_) {
          if (!ignoreRootErrors) rethrow;
          // A share-triggered sweep is best-effort; never propagate.
        }
      });

  static Future<void> _sweepForeignProcessDirectory(
    Directory directory, {
    required DateTime now,
    required DateTime cutoff,
  }) async {
    final lease = _shareLeaseFile(directory);
    var createdLease = false;
    late final FileStat preLockStat;

    try {
      final leaseType = await FileSystemEntity.type(
        lease.path,
        followLinks: false,
      );
      if (leaseType == FileSystemEntityType.notFound) {
        final directoryStat = await directory.stat();
        final leaseLessCutoff = now.subtract(_shareLeaseTimeout);
        if (!directoryStat.modified.isBefore(leaseLessCutoff)) return;

        try {
          await lease.create(exclusive: true);
          createdLease = true;
        } on FileSystemException {
          if (await FileSystemEntity.type(
                lease.path,
                followLinks: false,
              ) ==
              FileSystemEntityType.notFound) {
            return;
          }
        }
      } else if (leaseType != FileSystemEntityType.file) {
        return;
      }
      await _validateRegularFile(
        lease,
        parent: directory,
        label: 'share lease',
      );
      preLockStat = await lease.stat();
    } catch (_) {
      return;
    }

    RandomAccessFile? handle;
    var sweepCompleted = false;
    try {
      handle = await lease.open(mode: FileMode.append);
      await _validateRegularFile(
        lease,
        parent: directory,
        label: 'share lease',
      );
      await handle.lock();

      final record = await _readLockedLease(handle);
      if (!createdLease) {
        final updatedAt = _leaseUpdatedAt(record) ?? preLockStat.modified;
        if (!updatedAt.isBefore(now.subtract(_shareLeaseTimeout))) {
          return;
        }
      }

      await _sweepProcessDirectory(
        directory,
        cutoff: cutoff,
        protectInFlight: false,
      );
      sweepCompleted = await _readLockedLease(handle) == record;
    } catch (_) {
      // Any lock or inspection failure leaves foreign artifacts intact.
    } finally {
      await _closeLockedLease(handle);
    }

    // Keep the tiny lease and process directory. Dart cannot atomically
    // revalidate and delete a locked file across POSIX and Windows, while
    // retaining this metadata avoids racing a newly active owner.
    if (!sweepCompleted) return;
  }

  static Future<void> _sweepProcessDirectory(
    Directory directory, {
    required DateTime cutoff,
    required bool protectInFlight,
  }) async {
    try {
      final root = await _shareRootDir();
      final validated = await _validateProcessDirectory(directory, root);
      await for (final entry in validated.list(followLinks: false)) {
        if (entry is! File ||
            _basename(entry.path) == _activeLeaseName ||
            (protectInFlight && _inFlightSharePaths.contains(entry.path))) {
          continue;
        }
        try {
          await _validateRegularFile(
            entry,
            parent: validated,
            label: 'share artifact',
          );
          final stat = await entry.stat();
          if (stat.modified.isBefore(cutoff)) await entry.delete();
        } catch (_) {
          // Per-file failure must not abort the sweep.
        }
      }
    } catch (_) {
      // A process may remove its directory while another process is sweeping.
    }
  }

  static Future<void> _beginShareOperation() =>
      _serializeLifecycleAction<void>(() async {
        _activeShareOperations++;
        if (_activeShareOperations > 1) return;
        try {
          await _startShareLease();
        } catch (_) {
          _activeShareOperations--;
          await _stopShareLease();
          rethrow;
        }
      });

  static Future<void> _endShareOperation() =>
      _serializeLifecycleAction<void>(() async {
        if (_activeShareOperations == 0) return;
        _activeShareOperations--;
        if (_activeShareOperations == 0) await _stopShareLease();
      });

  static Future<void> _startShareLease() async {
    final generation = ++_shareLeaseGeneration;
    await _shareTempDir();
    if (generation != _shareLeaseGeneration || _activeShareOperations == 0) {
      throw StateError('Native share lease startup was superseded.');
    }
    _shareLeaseTimer = Timer.periodic(_shareLeaseHeartbeat, (_) {
      _queueShareLeaseHeartbeat(generation);
    });
  }

  static void _queueShareLeaseHeartbeat(int generation) {
    final heartbeat = _heartbeatFuture.then(
      (_) => _refreshShareLease(generation),
    );
    _heartbeatFuture = heartbeat;
    unawaited(heartbeat);
  }

  static Future<void> _refreshShareLease(int generation) async {
    if (generation != _shareLeaseGeneration || _activeShareOperations == 0) {
      return;
    }
    try {
      await _serializeLeaseAction<void>(() async {
        if (generation != _shareLeaseGeneration ||
            _activeShareOperations == 0) {
          return;
        }
        final directoryPath = _shareLeaseDirectoryPath;
        if (directoryPath == null) return;
        await _refreshCurrentShareLease(Directory(directoryPath));
      });
    } catch (_) {
      // A failed heartbeat is retried at the next interval.
    }
  }

  static Future<void> _stopShareLease() async {
    _shareLeaseGeneration++;
    _shareLeaseTimer?.cancel();
    _shareLeaseTimer = null;
    await _heartbeatFuture;
    await _releaseCurrentShareLease();
  }

  static File _shareLeaseFile(Directory directory) => File(
        '${directory.path}${Platform.pathSeparator}$_activeLeaseName',
      );

  static Future<void> _ensureCurrentShareLease(Directory directory) =>
      _serializeLeaseAction<void>(
        () => _ensureCurrentShareLeaseUnlocked(directory),
      );

  static Future<void> _ensureCurrentShareLeaseUnlocked(
    Directory directory,
  ) async {
    final root = await _shareRootDir();
    final validatedDirectory = await _validateProcessDirectory(directory, root);
    final existingHandle = _shareLeaseHandle;
    if (existingHandle != null &&
        _shareLeaseDirectoryPath == validatedDirectory.path) {
      final expected = _shareLeaseRecordValue;
      if (expected != null &&
          await _readLockedLease(existingHandle) == expected) {
        return;
      }
      await _releaseCurrentShareLeaseUnlocked();
      throw StateError('The native share lease changed ownership.');
    }
    if (existingHandle != null) {
      await _releaseCurrentShareLeaseUnlocked();
    }

    final lease = _shareLeaseFile(validatedDirectory);
    final leaseType = await FileSystemEntity.type(
      lease.path,
      followLinks: false,
    );
    if (leaseType == FileSystemEntityType.notFound) {
      try {
        await lease.create(exclusive: true);
      } on FileSystemException {
        final racedType = await FileSystemEntity.type(
          lease.path,
          followLinks: false,
        );
        if (racedType != FileSystemEntityType.file) rethrow;
      }
    } else if (leaseType != FileSystemEntityType.file) {
      throw FileSystemException(
        'Native share lease must be a real file.',
        lease.path,
      );
    }
    await _validateRegularFile(
      lease,
      parent: validatedDirectory,
      label: 'share lease',
    );

    RandomAccessFile? handle;
    try {
      handle = await lease.open(mode: FileMode.append);
      await _validateRegularFile(
        lease,
        parent: validatedDirectory,
        label: 'share lease',
      );
      await handle.lock();

      final existing = await _readLockedLease(handle);
      if (existing.isNotEmpty && !_isOwnedLease(existing)) {
        throw StateError('The native share directory is already leased.');
      }

      final record = _leaseRecord(
        owner: _shareOwnerToken,
        version: ++_shareLeaseVersion,
      );
      await _writeLockedLease(handle, record);
      if (await _readLockedLease(handle) != record) {
        throw StateError('The native share lease path was replaced.');
      }

      _shareLeaseHandle = handle;
      _shareLeaseDirectoryPath = validatedDirectory.path;
      _shareLeaseRecordValue = record;
      handle = null;
    } catch (_) {
      await _closeLockedLease(handle);
      rethrow;
    }
  }

  static Future<void> _refreshCurrentShareLease(Directory directory) async {
    final handle = _shareLeaseHandle;
    final expected = _shareLeaseRecordValue;
    if (handle == null ||
        expected == null ||
        _shareLeaseDirectoryPath != directory.path ||
        await _readLockedLease(handle) != expected) {
      throw StateError('The native share lease is no longer owned.');
    }

    final record = _leaseRecord(
      owner: _shareOwnerToken,
      version: ++_shareLeaseVersion,
    );
    await _writeLockedLease(handle, record);
    if (await _readLockedLease(handle) != record) {
      throw StateError('The native share lease path was replaced.');
    }
    _shareLeaseRecordValue = record;
  }

  static Future<void> _releaseCurrentShareLease() =>
      _serializeLeaseAction<void>(
        _releaseCurrentShareLeaseUnlocked,
      );

  static Future<void> _releaseCurrentShareLeaseUnlocked() async {
    final handle = _shareLeaseHandle;
    _shareLeaseHandle = null;
    _shareLeaseDirectoryPath = null;
    _shareLeaseRecordValue = null;

    await _closeLockedLease(handle);
  }

  static String _leaseRecord({
    required String owner,
    required int version,
  }) =>
      'owner=$owner\n'
      'version=$version\n'
      'updated=${DateTime.now().toUtc().toIso8601String()}\n';

  static bool _isOwnedLease(String record) =>
      record.startsWith('owner=$_shareOwnerToken\n');

  static Future<void> _writeLockedLease(
    RandomAccessFile handle,
    String record,
  ) async {
    await handle.truncate(0);
    await handle.setPosition(0);
    await handle.writeString(record);
    await handle.flush();
  }

  static Future<String> _readLockedLease(RandomAccessFile handle) async {
    const maxLeaseBytes = 4096;
    final length = await handle.length();
    if (length > maxLeaseBytes) {
      throw const FormatException('Native share lease is too large.');
    }
    await handle.setPosition(0);
    final bytes = await handle.read(length);
    return utf8.decode(bytes, allowMalformed: true);
  }

  static DateTime? _leaseUpdatedAt(String record) {
    for (final line in const LineSplitter().convert(record)) {
      if (!line.startsWith('updated=')) continue;
      return DateTime.tryParse(line.substring('updated='.length))?.toUtc();
    }
    return null;
  }

  static Future<void> _closeLockedLease(RandomAccessFile? handle) async {
    if (handle == null) return;
    try {
      await handle.unlock();
    } catch (_) {
      // The file may already have been removed by external cleanup.
    }
    try {
      await handle.close();
    } catch (_) {
      // Closing an invalidated handle is best-effort.
    }
  }

  static Future<void> _requireDirectoryEntity(
    Directory directory, {
    required String label,
  }) async {
    final type = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (type != FileSystemEntityType.directory) {
      throw FileSystemException(
        'Native $label must be a real directory.',
        directory.path,
      );
    }
  }

  static Future<void> _validatePrivateDirectoryPermissions(
    Directory directory, {
    required String label,
    required bool requireOwnerOnly,
  }) async {
    if (Platform.isWindows) return;
    final stat = await directory.stat();
    const groupOrWorldPermissionBits = 0x3f;
    const groupOrWorldWriteBits = 0x12;
    final forbiddenBits =
        requireOwnerOnly ? groupOrWorldPermissionBits : groupOrWorldWriteBits;
    if (stat.type != FileSystemEntityType.directory ||
        stat.mode & forbiddenBits != 0) {
      throw FileSystemException(
        'Native $label has unsafe permissions.',
        directory.path,
      );
    }
  }

  static Future<void> _makePersistentFileOwnerOnly(File file) async {
    if (!Platform.isLinux && !Platform.isMacOS) return;
    try {
      final result = await Process.run('/bin/chmod', ['0600', file.path]);
      if (result.exitCode != 0) {
        throw FileSystemException(
          'Failed to restrict persistent log file permissions.',
          file.path,
        );
      }
    } on FileSystemException {
      rethrow;
    } catch (_) {
      throw FileSystemException(
        'Failed to restrict persistent log file permissions.',
        file.path,
      );
    }
  }

  static Future<void> _validatePersistentFilePermissions(File file) async {
    if (!Platform.isLinux && !Platform.isMacOS) return;
    final stat = await file.stat();
    const groupOrWorldPermissionBits = 0x3f;
    if (stat.type != FileSystemEntityType.file ||
        stat.mode & groupOrWorldPermissionBits != 0) {
      throw FileSystemException(
        'Native persistent log file has unsafe permissions.',
        file.path,
      );
    }
  }

  static Future<Directory> _validateProcessDirectory(
    Directory directory,
    Directory root,
  ) async {
    await _requireDirectoryEntity(directory, label: 'share process directory');
    final canonical = Directory(await directory.resolveSymbolicLinks());
    if (!_basename(canonical.path).startsWith(_processDirectoryPrefix) ||
        !_isDirectChild(canonical.path, root.path)) {
      throw FileSystemException(
        'Native share process directory escaped the share root.',
        directory.path,
      );
    }
    return canonical;
  }

  static Future<void> _validateRegularFile(
    File file, {
    required Directory parent,
    required String label,
  }) async {
    final type = await FileSystemEntity.type(
      file.path,
      followLinks: false,
    );
    if (type != FileSystemEntityType.file) {
      throw FileSystemException(
        'Native $label must be a real file.',
        file.path,
      );
    }

    final canonicalPath = await file.resolveSymbolicLinks();
    if (_normalizePath(canonicalPath) != _normalizePath(file.absolute.path) ||
        !_isDirectChild(canonicalPath, parent.path)) {
      throw FileSystemException(
        'Native $label escaped its expected directory.',
        file.path,
      );
    }
  }

  static bool _isDirectChild(String child, String parent) =>
      _normalizePath(Directory(child).parent.path) == _normalizePath(parent);

  static String _normalizePath(String path) {
    var normalized = path;
    while (normalized.length > 1 &&
        normalized.endsWith(Platform.pathSeparator) &&
        Directory(normalized).parent.path != normalized) {
      normalized = normalized.substring(
        0,
        normalized.length - Platform.pathSeparator.length,
      );
    }
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  static Future<T> _serializeLeaseAction<T>(
    Future<T> Function() action,
  ) {
    final previous = _leaseSerial;
    final released = Completer<void>();
    _leaseSerial = released.future;

    return (() async {
      await previous;
      try {
        return await action();
      } finally {
        released.complete();
      }
    })();
  }

  static Future<T> _serializeLifecycleAction<T>(
    Future<T> Function() action,
  ) {
    final previous = _lifecycleSerial;
    final released = Completer<void>();
    _lifecycleSerial = released.future;

    return (() async {
      await previous;
      try {
        return await action();
      } finally {
        released.complete();
      }
    })();
  }

  static String _basename(String path) =>
      path.split(Platform.pathSeparator).last;

  static Future<void> _bestEffortDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Cleanup is best-effort; OS will reclaim the temp directory.
    }
  }

  static void _scheduleBestEffortDelete(File file) {
    Timer(_shareRetention, () {
      unawaited(_bestEffortDelete(file));
    });
  }
}
