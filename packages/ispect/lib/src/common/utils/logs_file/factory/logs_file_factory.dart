import 'package:ispect/src/common/utils/logs_file/base/base_logs_file.dart';
import 'package:ispect/src/common/utils/logs_file/factory/stub_factory.dart'
    if (dart.library.io) 'package:ispect/src/common/utils/logs_file/factory/native_factory.dart'
    if (dart.library.js_interop) 'package:ispect/src/common/utils/logs_file/factory/web_factory.dart';
import 'package:ispect/src/core/res/ispect_callbacks.dart';

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
  ///
  /// **Returns:** Platform-specific file representation:
  /// - [File] for native platforms
  /// - [Blob] for web platform
  static Future<Object> createLogsFile(
    String logs, {
    String fileName = 'ispect_all_logs',
  }) async {
    final handler = create();
    return handler.createFile(logs, fileName: fileName);
  }

  /// Saves logs to device without requiring a share callback.
  ///
  /// **Platform-specific behavior:**
  /// - **Web**: triggers browser download
  /// - **Native**: saves to the app's logs directory
  ///
  /// **Returns:** File path (native) or filename (web).
  static Future<String> saveToDevice(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    final handler = create();
    return handler.saveToDevice(
      logs,
      fileName: fileName,
      fileType: fileType,
    );
  }

  /// Creates a log file and hands it to the platform's share mechanism.
  ///
  /// **Platform-specific behavior:**
  /// - **Native**: opens the system share sheet via [onShare]
  /// - **Web**: triggers a browser download (web has no native share sheet)
  ///
  /// **Parameters:**
  /// - [logs]: The log content to share
  /// - [fileName]: Base name for the file (default: 'ispect_all_logs')
  /// - [onShare]: Required on native, ignored on web
  static Future<void> shareFile(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
    ISpectShareCallback? onShare,
  }) async {
    final handler = create();
    await handler.createAndShareFile(
      logs,
      fileName: fileName,
      fileType: fileType,
      onShare: onShare,
    );
  }
}
