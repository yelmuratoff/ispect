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
    } on FileSystemException catch (e) {
      throw FileSystemException(
        'Failed to create log file: ${e.message}',
        e.path,
      );
    } catch (e) {
      throw Exception('Unexpected error creating log file: $e');
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
    final safeFileType = fileType.replaceAll(RegExp(r'[^\w]'), '');
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
  String _sanitizeFileName(String fileName) {
    final baseName = fileName.split(RegExp(r'[/\\]')).last;
    return baseName.replaceAll(RegExp(r'[^\w\-_.]'), '_');
  }

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
  Future<void> downloadFile(
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

    try {
      await onShare(
        ISpectShareRequest(
          filePaths: [file.path],
          text: 'ISpect Application Logs',
          subject: 'Application Logs - ${DateTime.now().toIso8601String()}',
        ),
      );
    } catch (e) {
      throw Exception('Failed to share log file: $e');
    }
  }

  /// Creates and immediately shares a log file
  ///
  /// - Parameters: logs (content), fileName (base name), fileType (extension)
  /// - Return: void (shares file through system dialog)
  /// - Usage example: `await NativeLogsFile.createAndShareLogs(logs);`
  /// - Edge case notes: Creates temporary file, handles sharing errors
  static Future<void> createAndShareLogs(
    String logs, {
    required ISpectShareCallback onShare,
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    File? file;
    try {
      file = await _createTemporaryFile(logs, fileName, fileType);
      await _shareFile(file, onShare: onShare);
    } catch (e) {
      throw Exception('Failed to create and share log file: $e');
    } finally {
      try {
        if (file != null && await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best-effort cleanup; temp directory will be purged by the OS.
      }
    }
  }

  /// Creates temporary file for sharing
  static Future<File> _createTemporaryFile(
    String logs,
    String fileName,
    String fileType,
  ) async {
    final tempResult = await platformDirectoryProvider.tempDirectory();
    if (tempResult is! Directory) {
      throw StateError(
        'Expected dart:io Directory from tempDirectory(), '
        'got ${tempResult.runtimeType}. '
        'This method must not be called on web.',
      );
    }
    final dir = tempResult;
    final timestamp = DateFormatter.nowAsFileTimestamp();
    final safeFileName = fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_');
    final safeFileType = fileType.replaceAll(RegExp(r'[^\w]'), '');
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
}
