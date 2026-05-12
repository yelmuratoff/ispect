import 'package:ispect/src/core/res/ispect_callbacks.dart';

/// Abstract base class for cross-platform log file operations.
///
/// Provides a unified interface for creating and managing log files
/// across all Flutter platforms including Web.
abstract class BaseLogsFile {
  /// Creates a log file with the given content.
  ///
  /// **Parameters:**
  /// - [logs]: The log content to write
  /// - [fileName]: Base name for the file (default: 'ispect_all_logs')
  ///
  /// **Returns:** Platform-specific file representation
  Future<Object> createFile(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  });

  /// Gets the file path or identifier.
  ///
  /// **Returns:**
  /// - File path string for native platforms
  /// - Blob URL for Web platform
  String getFilePath(Object file);

  /// Gets the file size in bytes.
  Future<int> getFileSize(Object file);

  /// Reads the file content as string.
  Future<String> readAsString(Object file);

  /// Deletes the file.
  Future<void> deleteFile(Object file);

  /// Hands the log file to the platform's user-mediated transfer mechanism.
  ///
  /// **Platform-specific behavior:**
  /// - **Native**: opens the system share sheet via [onShare]
  /// - **Web**: triggers a browser download (the web equivalent of "share")
  ///
  /// **Parameters:**
  /// - [file]: The file object to share
  /// - [fileName]: Optional custom filename (defaults to file's original name)
  /// - [onShare]: Required on native, ignored on web
  Future<void> shareFile(
    Object file, {
    String? fileName,
    String fileType = 'json',
    ISpectShareCallback? onShare,
  });

  /// Creates and immediately shares a log file.
  ///
  /// **Convenience method** that combines [createFile] and [shareFile].
  Future<void> createAndShareFile(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
    ISpectShareCallback? onShare,
  }) async {
    final file = await createFile(logs, fileName: fileName, fileType: fileType);
    await shareFile(
      file,
      fileName: fileName,
      fileType: fileType,
      onShare: onShare,
    );
  }

  /// Saves logs to device storage without requiring a share callback.
  ///
  /// **Platform-specific behavior:**
  /// - **Web**: Triggers browser download
  /// - **Native**: Saves to the app's logs directory
  ///
  /// **Returns:** File path (native) or filename (web).
  Future<String> saveToDevice(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  });

  /// Checks if the platform supports native file operations.
  bool get supportsNativeFiles;
}
