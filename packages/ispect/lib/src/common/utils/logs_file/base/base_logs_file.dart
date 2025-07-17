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

  /// Downloads or shares the log file.
  ///
  /// **Platform-specific behavior:**
  /// - **Web**: Triggers browser download
  /// - **Native**: Opens share dialog
  ///
  /// **Parameters:**
  /// - [file]: The file object to download/share
  /// - [fileName]: Optional custom filename (defaults to file's original name)
  Future<void> downloadFile(
    Object file, {
    String? fileName,
    String fileType = 'json',
  });

  /// Creates and immediately downloads/shares a log file.
  ///
  /// **Convenience method** that combines [createFile] and [downloadFile].
  ///
  /// **Parameters:**
  /// - [logs]: The log content to write
  /// - [fileName]: Base name for the file (default: 'ispect_all_logs')
  Future<void> createAndDownloadFile(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    final file = await createFile(logs, fileName: fileName, fileType: fileType);
    await downloadFile(file, fileName: fileName, fileType: fileType);
  }

  /// Checks if the platform supports native file operations.
  bool get supportsNativeFiles;
}
