import 'package:ispect/src/common/utils/logs_file/base/base_logs_file.dart';
import 'package:ispect/src/common/utils/logs_file/factory/native_factory.dart'
    if (dart.library.js_interop) 'package:ispect/src/common/utils/logs_file/factory/web_factory.dart';

/// Factory class for creating platform-appropriate log file handlers.
///
/// Automatically selects the correct implementation based on the platform:
/// - **Native platforms** (Android, iOS, macOS, Windows, Linux): Uses file system
/// - **Web platform**: Uses browser Blob API
class LogsFileFactory {
  const LogsFileFactory._();

  /// Creates a platform-appropriate logs file handler.
  ///
  /// **Returns:**
  /// - Platform-specific implementation of [BaseLogsFile]
  static BaseLogsFile create() => createPlatformLogsFile();

  /// Convenience method to create a log file directly.
  ///
  /// **Parameters:**
  /// - [logs]: The log content to write
  /// - [fileName]: Base name for the file (default: 'ispect_all_logs')
  ///   /// **Returns:** Platform-specific file representation:
  /// - [File] for native platforms
  /// - [Blob] for web platform
  ///
  /// **Example:**
  /// ```dart
  /// // Works on all platforms
  /// final logFile = await LogsFileFactory.createLogsFile('My logs content');
  ///
  /// // Get file path/URL
  /// final handler = LogsFileFactory.create();
  /// final path = handler.getFilePath(logFile);
  /// print('Log file available at: $path');
  ///
  /// // For web, trigger download - check platform before casting
  /// if (kIsWeb) {
  ///   final webHandler = handler as dynamic;
  ///   if (webHandler.runtimeType.toString() == 'WebLogsFile') {
  ///     webHandler.downloadFile(logFile);
  ///   }
  /// }
  /// ```
  static Future<Object> createLogsFile(
    String logs, {
    String fileName = 'ispect_all_logs',
  }) async {
    final handler = create();
    return handler.createFile(logs, fileName: fileName);
  }

  /// Convenience method to directly download/share a log file.
  ///
  /// **Platform-specific behavior:**
  /// - **Web**: Triggers browser download
  /// - **Native**: Opens share dialog
  ///
  /// **Parameters:**
  /// - [logs]: The log content to download/share
  /// - [fileName]: Base name for the file (default: 'ispect_all_logs')
  ///
  /// **Example:**
  /// ```dart
  /// // Works on all platforms
  /// await LogsFileFactory.downloadFile('My logs content', fileName: 'my_logs');
  /// ```
  static Future<void> downloadFile(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    final handler = create();
    await handler.createAndDownloadFile(
      logs,
      fileName: fileName,
      fileType: fileType,
    );
  }
}
