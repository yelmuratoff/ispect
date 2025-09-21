import 'dart:js_interop';

import 'package:ispect/src/common/utils/logs_file/base/base_logs_file.dart';
import 'package:web/web.dart';

/// Web platform implementation for log file operations.
///
/// - Parameters: Browser Blob API for file simulation
/// - Return: Blob objects for web file operations
/// - Usage example: `final logsFile = WebLogsFile(); await logsFile.createFile(logs);`
/// - Edge case notes: Uses blob URLs for file identification, handles browser download limitations
class WebLogsFile extends BaseLogsFile {
  static final Map<Blob, String> _fileNames = <Blob, String>{};

  @override
  bool get supportsNativeFiles => false;

  @override
  Future<Blob> createFile(
    String logs, {
    String fileName = 'ispect_all_logs',
    String fileType = 'json',
  }) async {
    try {
      final fullFileName = _generateFileNameWithTimestamp(fileName, fileType);
      final blob = _createBlobFromLogs(logs);
      _storeFileNameMetadata(blob, fullFileName);

      return blob;
    } catch (e) {
      throw Exception('Failed to create web blob file: $e');
    }
  }

  /// Generates timestamped filename with proper sanitization
  String _generateFileNameWithTimestamp(String fileName, String fileType) {
    final timestamp = _generateTimestamp();
    final safeFileName = _sanitizeFileName(fileName);
    return '${safeFileName}_$timestamp.$fileType';
  }

  /// Creates timestamp string in YYYY-MM-DD_HH-mm-ss format
  String _generateTimestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}';
  }

  /// Sanitizes filename for web compatibility
  String _sanitizeFileName(String fileName) =>
      fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_');

  /// Creates Blob from log string using web API
  Blob _createBlobFromLogs(String logs) {
    final jsArray = [logs.toJS].toJS;
    return Blob(jsArray, BlobPropertyBag(type: 'text/plain'));
  }

  /// Stores filename metadata for later retrieval
  void _storeFileNameMetadata(Blob blob, String fileName) {
    _fileNames[blob] = fileName;
  }

  @override
  String getFilePath(Object file) {
    if (file is! Blob) {
      throw ArgumentError('Expected Blob instance, got ${file.runtimeType}');
    }
    return URL.createObjectURL(file);
  }

  @override
  Future<int> getFileSize(Object file) async {
    if (file is! Blob) {
      throw ArgumentError('Expected Blob instance, got ${file.runtimeType}');
    }
    return file.size;
  }

  @override
  Future<String> readAsString(Object file) async {
    if (file is! Blob) {
      throw ArgumentError('Expected Blob instance, got ${file.runtimeType}');
    }
    final jsString = await file.text().toDart;
    return jsString.toDart;
  }

  @override
  Future<void> deleteFile(Object file) async {
    if (file is! Blob) {
      throw ArgumentError('Expected Blob instance, got ${file.runtimeType}');
    }

    final url = URL.createObjectURL(file);
    URL.revokeObjectURL(url);
    _fileNames.remove(file);
  }

  @override
  Future<void> downloadFile(
    Object file, {
    String? fileName,
    String fileType = 'json',
  }) async {
    if (file is! Blob) {
      throw ArgumentError(
        'Expected Blob instance for web download, got ${file.runtimeType}',
      );
    }

    final finalFileName = _determineFinalFileName(file, fileName, fileType);
    final url = URL.createObjectURL(file);

    _triggerBrowserDownload(url, finalFileName);
    URL.revokeObjectURL(url);
  }

  /// Determines final filename for download
  String _determineFinalFileName(
    Blob blob,
    String? fileName,
    String fileType,
  ) {
    if (fileName != null) {
      return _processCustomFileName(fileName, fileType);
    }
    return _fileNames[blob] ?? 'ispect_logs.json';
  }

  /// Processes custom filename with timestamp if needed
  String _processCustomFileName(String fileName, String fileType) {
    if (fileName.contains('.')) {
      return fileName;
    }

    final timestamp = _generateTimestamp();
    return '${fileName}_$timestamp.$fileType';
  }

  /// Triggers browser download using anchor element
  void _triggerBrowserDownload(String url, String fileName) {
    final anchor = document.createElement('a') as HTMLAnchorElement
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    document.body!.appendChild(anchor);
    anchor.click();
    document.body!.removeChild(anchor);
  }

  /// Creates and immediately downloads a log file
  ///
  /// - Parameters: logs (content), fileName (base name)
  /// - Return: void (triggers browser download)
  /// - Usage example: `await WebLogsFile.createAndDownloadLogs(logs);`
  /// - Edge case notes: Creates temporary blob, handles direct download without DOM overhead
  static Future<void> createAndDownloadLogs(
    String logs, {
    String fileName = 'ispect_all_logs',
  }) async {
    final blob = _createDirectBlob(logs);
    final finalFileName = _createTimestampedFileName(fileName);
    final url = URL.createObjectURL(blob);

    _executeDirectDownload(url, finalFileName);
    URL.revokeObjectURL(url);
  }

  /// Creates blob directly for immediate download
  static Blob _createDirectBlob(String logs) {
    final jsArray = [logs.toJS].toJS;
    return Blob(jsArray, BlobPropertyBag(type: 'text/plain'));
  }

  /// Creates timestamped filename for direct download
  static String _createTimestampedFileName(String fileName) {
    final now = DateTime.now();
    final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}';
    return '${fileName}_$timestamp.json';
  }

  /// Executes direct download without DOM manipulation overhead
  static void _executeDirectDownload(String url, String fileName) {
    (document.createElement('a') as HTMLAnchorElement
          ..href = url
          ..download = fileName)
        .click();
  }
}
