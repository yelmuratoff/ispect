import 'dart:js_interop';

import 'package:ispect/src/common/utils/logs_file/base_logs_file.dart';
import 'package:web/web.dart';

/// Web platform implementation for log file operations.
///
/// Uses browser Blob API to simulate file operations.
class WebLogsFile extends BaseLogsFile {
  // Store filename metadata separately
  static final Map<String, String> _fileNames = <String, String>{};

  @override
  bool get supportsNativeFiles => false;

  @override
  Future<Blob> createFile(
    String logs, {
    String fileName = 'ispect_all_logs',
  }) async {
    try {
      // Create safe filename with timestamp
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-'
          '${now.minute.toString().padLeft(2, '0')}-'
          '${now.second.toString().padLeft(2, '0')}';

      // Sanitize filename for web compatibility
      final safeFileName = fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_');
      final fullFileName = '${safeFileName}_$timestamp.json';

      // Create blob with proper MIME type using the new web API
      final jsArray = [logs.toJS].toJS;
      final blob = Blob(jsArray, BlobPropertyBag(type: 'text/plain'));

      // Store filename in our metadata map using blob URL as key
      final blobUrl = URL.createObjectURL(blob);
      _fileNames[blobUrl] = fullFileName;

      return blob;
    } catch (e) {
      throw Exception('Failed to create web blob file: $e');
    }
  }

  @override
  String getFilePath(Object file) {
    if (file is Blob) {
      // Return blob URL for web using the new web API
      return URL.createObjectURL(file);
    }
    throw ArgumentError('Expected Blob instance, got ${file.runtimeType}');
  }

  @override
  Future<int> getFileSize(Object file) async {
    if (file is Blob) {
      return file.size;
    }
    throw ArgumentError('Expected Blob instance, got ${file.runtimeType}');
  }

  @override
  Future<String> readAsString(Object file) async {
    if (file is Blob) {
      // Use the modern web API to read the blob as text
      final jsString = await file.text().toDart;
      return jsString.toDart;
    }
    throw ArgumentError('Expected Blob instance, got ${file.runtimeType}');
  }

  @override
  Future<void> deleteFile(Object file) async {
    if (file is Blob) {
      // Revoke blob URL to free memory using the new web API
      final url = URL.createObjectURL(file);
      URL.revokeObjectURL(url);
      // Remove from our filename metadata
      _fileNames.remove(url);
      return;
    }
    throw ArgumentError('Expected Blob instance, got ${file.runtimeType}');
  }

  @override
  Future<void> downloadFile(Object file, {String? fileName}) async {
    if (file is! Blob) {
      throw ArgumentError(
        'Expected Blob instance for web download, got ${file.runtimeType}',
      );
    }

    final blob = file;
    final url = URL.createObjectURL(blob);

    // Determine filename: custom > metadata > default
    final String finalFileName;
    if (fileName != null) {
      // Add timestamp if custom filename doesn't have extension
      final hasExtension = fileName.contains('.');
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-'
          '${now.minute.toString().padLeft(2, '0')}-'
          '${now.second.toString().padLeft(2, '0')}';

      finalFileName = hasExtension ? fileName : '${fileName}_$timestamp.json';
    } else {
      finalFileName = _fileNames[url] ?? 'ispect_logs.json';
    }

    final anchor = document.createElement('a') as HTMLAnchorElement
      ..href = url
      ..download = finalFileName;
    anchor.style.display = 'none';

    document.body!.appendChild(anchor);
    anchor.click();
    document.body!.removeChild(anchor);

    // Clean up
    URL.revokeObjectURL(url);
  }

  /// Creates and immediately downloads a log file.
  ///
  /// **Convenience method** for web platforms that creates a temporary blob
  /// and triggers download without storing the file.
  ///
  /// **Parameters:**
  /// - [logs]: The log content to download
  /// - [fileName]: Base name for the file (default: 'ispect_all_logs')
  static Future<void> createAndDownloadLogs(
    String logs, {
    String fileName = 'ispect_all_logs',
  }) async {
    // Create blob directly for immediate download
    final jsArray = [logs.toJS].toJS;
    final blob = Blob(jsArray, BlobPropertyBag(type: 'text/plain'));

    // Add timestamp to filename
    final now = DateTime.now();
    final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}';

    final finalFileName = '${fileName}_$timestamp.json';
    final url = URL.createObjectURL(blob);

    document.createElement('a') as HTMLAnchorElement
      ..href = url
      ..download = finalFileName
      ..click();

    URL.revokeObjectURL(url);
  }
}
