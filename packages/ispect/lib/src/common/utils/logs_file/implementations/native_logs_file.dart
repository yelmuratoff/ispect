import 'dart:io';

import 'package:ispect/src/common/utils/date_formatter.dart';
import 'package:ispect/src/common/utils/logs_file/base/base_logs_file.dart';
import 'package:ispect/src/core/platform/platform_directory.dart';
import 'package:ispect/src/core/res/ispect_callbacks.dart';

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
  /// Subdirectory inside the platform temp dir for files created for sharing.
  ///
  /// Isolating share files in a dedicated folder lets us sweep stale entries
  /// on the next share without risking unrelated files in the temp root.
  static const String _shareSubdirName = 'ispect_share';

  /// How long share temp files are kept before the next [createAndShareLogs]
  /// sweeps them out. Generous enough for any platform share-sheet workflow
  /// (Android Intent recipients, iOS share extensions) to finish reading.
  static const Duration _shareRetention = Duration(hours: 1);

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
        'Expected dart:io Directory from logsBaseDirectory(), '
        'got ${result.runtimeType}. '
        'This method must not be called on web.',
      );
    }
    return result;
  }

  /// Ensures logs subdirectory exists
  Future<Directory> _ensureLogsDirectory(Directory parentDir) async {
    final logsDir = Directory('${parentDir.path}/logs');
    await logsDir.create(recursive: true);
    return logsDir;
  }

  /// Creates log file with sanitized name and timestamp
  Future<File> _createLogFile(
    Directory logsDir,
    String fileName,
    String fileType,
    String logs,
  ) async {
    final timestamp = DateFormatter.nowAsFileTimestamp();
    final safeFileName = _sanitizeFileName(fileName);
    final safeFileType = _sanitizeFileType(fileType);
    final fullFileName = '${safeFileName}_$timestamp.$safeFileType';
    final file = File('${logsDir.path}/$fullFileName');

    await file.writeAsString(logs, flush: true);
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
      throw ArgumentError('Expected File instance, got ${file.runtimeType}');
    }
    return file.path;
  }

  @override
  Future<int> getFileSize(Object file) async {
    if (file is! File) {
      throw ArgumentError('Expected File instance, got ${file.runtimeType}');
    }
    final stat = await file.stat();
    return stat.size;
  }

  @override
  Future<String> readAsString(Object file) async {
    if (file is! File) {
      throw ArgumentError('Expected File instance, got ${file.runtimeType}');
    }
    return file.readAsString();
  }

  @override
  Future<void> deleteFile(Object file) async {
    if (file is! File) {
      throw ArgumentError('Expected File instance, got ${file.runtimeType}');
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
      throw ArgumentError('Expected File instance, got ${file.runtimeType}');
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

  /// Creates a temp log file and hands it to the platform share sheet.
  ///
  /// The file is left behind on success — share sheets (Android Intents, iOS
  /// share extensions) can read it asynchronously after the callback resolves.
  /// Stale files from prior calls are swept here based on [_shareRetention],
  /// so the temp subdirectory does not grow unbounded.
  ///
  /// On failure the just-created file is removed best-effort, since no share
  /// happened and the file is orphaned.
  static Future<void> createAndShareLogs(
    String logs, {
    required ISpectShareCallback onShare,
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    await _sweepStaleShareFiles();

    final file = await _createTemporaryFile(logs, fileName, fileType);
    try {
      await _shareFile(file, onShare: onShare);
    } catch (_) {
      await _bestEffortDelete(file);
      rethrow;
    }
  }

  /// Resolves the dedicated subdirectory for share temp files.
  static Future<Directory> _shareTempDir() async {
    final tempResult = await platformDirectoryProvider.tempDirectory();
    if (tempResult is! Directory) {
      throw StateError(
        'Expected dart:io Directory from tempDirectory(), '
        'got ${tempResult.runtimeType}. '
        'This method must not be called on web.',
      );
    }
    final dir = Directory('${tempResult.path}/$_shareSubdirName');
    await dir.create(recursive: true);
    return dir;
  }

  /// Creates temporary file for sharing
  static Future<File> _createTemporaryFile(
    String logs,
    String fileName,
    String fileType,
  ) async {
    final dir = await _shareTempDir();
    final timestamp = DateFormatter.nowAsFileTimestamp();
    final safeFileName = _sanitizeFileName(fileName);
    final safeFileType = _sanitizeFileType(fileType);
    final fullFileName = '${safeFileName}_$timestamp.$safeFileType';
    final file = File('${dir.path}/$fullFileName');

    await file.writeAsString(logs, flush: true);
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
  /// Swallows individual file errors; the OS will eventually purge the temp
  /// directory anyway, so the sweep should never abort a share flow.
  static Future<void> _sweepStaleShareFiles() async {
    try {
      final dir = await _shareTempDir();
      final cutoff = DateTime.now().subtract(_shareRetention);
      await for (final entry in dir.list(followLinks: false)) {
        if (entry is! File) continue;
        try {
          final stat = await entry.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entry.delete();
          }
        } catch (_) {
          // Per-file failure must not abort the sweep.
        }
      }
    } catch (_) {
      // Sweep is best-effort; never propagate.
    }
  }

  static Future<void> _bestEffortDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Cleanup is best-effort; OS will reclaim the temp directory.
    }
  }
}
