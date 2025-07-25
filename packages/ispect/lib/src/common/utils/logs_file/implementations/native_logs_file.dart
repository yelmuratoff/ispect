import 'dart:io';

import 'package:ispect/src/common/utils/logs_file/base/base_logs_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native platform implementation for log file operations.
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

  /// Gets platform-appropriate directory for log storage
  Future<Directory> _getPlatformDirectory() async {
    if (Platform.isIOS || Platform.isMacOS) {
      return getApplicationDocumentsDirectory();
    }
    return getTemporaryDirectory();
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
    final timestamp = _generateTimestamp();
    final safeFileName = _sanitizeFileName(fileName);
    final fullFileName = '${safeFileName}_$timestamp.$fileType';
    final file = File('${logsDir.path}/$fullFileName');

    await file.writeAsString(logs, flush: true);
    return file;
  }

  /// Generates timestamp string for file naming
  String _generateTimestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}';
  }

  /// Sanitizes filename for cross-platform compatibility
  String _sanitizeFileName(String fileName) =>
      fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_');

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
  Future<void> downloadFile(
    Object file, {
    String? fileName,
    String fileType = 'json',
  }) async {
    if (file is! File) {
      throw ArgumentError('Expected File instance, got ${file.runtimeType}');
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
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
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    try {
      final file = await _createTemporaryFile(logs, fileName, fileType);
      await _shareFile(file);
    } catch (e) {
      throw Exception('Failed to create and share log file: $e');
    }
  }

  /// Creates temporary file for sharing
  static Future<File> _createTemporaryFile(
    String logs,
    String fileName,
    String fileType,
  ) async {
    final dir = await getTemporaryDirectory();
    final timestamp = _generateTimestampStatic();
    final safeFileName = fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_');
    final fullFileName = '${safeFileName}_$timestamp.$fileType';
    final file = File('${dir.path}/$fullFileName');

    await file.writeAsString(logs, flush: true);
    return file;
  }

  /// Shares file through system dialog
  static Future<void> _shareFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'ISpect Application Logs',
        subject: 'Application Logs - ${DateTime.now().toIso8601String()}',
      ),
    );
  }

  /// Static version of timestamp generator for static methods
  static String _generateTimestampStatic() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}';
  }
}
