import 'dart:io';

import 'package:ispect/src/common/utils/logs_file/base_logs_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native platform implementation for log file operations.
///
/// Supports: Android, iOS, macOS, Windows, Linux
class NativeLogsFile extends BaseLogsFile {
  @override
  bool get supportsNativeFiles => true;

  @override
  Future<File> createFile(
    String logs, {
    String fileName = 'ispect_all_logs',
  }) async {
    try {
      // Get platform-appropriate directory
      final Directory dir;
      if (Platform.isIOS || Platform.isMacOS) {
        // Use documents directory for iOS/macOS for better persistence
        dir = await getApplicationDocumentsDirectory();
      } else {
        // Use temporary directory for other platforms
        dir = await getTemporaryDirectory();
      }

      // Create logs subdirectory
      final logsDir = Directory('${dir.path}/logs');
      await logsDir.create(recursive: true);

      // Create safe filename with timestamp
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-'
          '${now.minute.toString().padLeft(2, '0')}-'
          '${now.second.toString().padLeft(2, '0')}';

      // Sanitize filename for cross-platform compatibility
      final safeFileName = fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_');
      final fullFileName = '${safeFileName}_$timestamp.json';

      final filePath = '${logsDir.path}/$fullFileName';
      final file = File(filePath);

      // Write content with error handling
      await file.writeAsString(logs, flush: true);

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

  @override
  String getFilePath(Object file) {
    if (file is File) {
      return file.path;
    }
    throw ArgumentError('Expected File instance, got ${file.runtimeType}');
  }

  @override
  Future<int> getFileSize(Object file) async {
    if (file is File) {
      final stat = await file.stat();
      return stat.size;
    }
    throw ArgumentError('Expected File instance, got ${file.runtimeType}');
  }

  @override
  Future<String> readAsString(Object file) async {
    if (file is File) {
      return file.readAsString();
    }
    throw ArgumentError('Expected File instance, got ${file.runtimeType}');
  }

  @override
  Future<void> deleteFile(Object file) async {
    if (file is File) {
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }
    throw ArgumentError('Expected File instance, got ${file.runtimeType}');
  }

  @override
  Future<void> downloadFile(Object file, {String? fileName}) async {
    if (file is! File) {
      throw ArgumentError('Expected File instance, got ${file.runtimeType}');
    }

    try {
      // For native platforms, we share the file through the system share dialog
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

  /// Creates and immediately shares a log file.
  ///
  /// **Convenience method** for native platforms that creates a temporary file
  /// and opens the system share dialog.
  ///
  /// **Parameters:**
  /// - [logs]: The log content to share
  /// - [fileName]: Base name for the file (default: 'ispect_all_logs')
  static Future<void> createAndShareLogs(
    String logs, {
    String fileName = 'ispect_all_logs',
  }) async {
    try {
      // Create temporary file for sharing
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-'
          '${now.minute.toString().padLeft(2, '0')}-'
          '${now.second.toString().padLeft(2, '0')}';

      final safeFileName = fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_');
      final fullFileName = '${safeFileName}_$timestamp.json';
      final filePath = '${dir.path}/$fullFileName';

      final file = File(filePath);
      await file.writeAsString(logs, flush: true);

      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'ISpect Application Logs',
          subject: 'Application Logs - ${now.toIso8601String()}',
        ),
      );
    } catch (e) {
      throw Exception('Failed to create and share log file: $e');
    }
  }
}
