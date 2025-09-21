import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:ispect/ispect.dart';

import 'package:ispect/src/features/ispect/domain/models/file_format.dart';
import 'package:ispect/src/features/ispect/domain/models/file_processing_result.dart';

/// Service for handling file operations in log viewer
class FileProcessingService {
  /// Maximum file size in bytes (10MB)
  static const int _maxFileSize = 10 * 1024 * 1024;

  /// Supported file extensions
  static const List<String> _supportedExtensions = ['txt', 'json'];

  /// Pick and process files from device
  Future<FileProcessingResult> pickAndProcessFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        return FileProcessingResult.failure(
          fileName: 'Unknown',
          error: 'No files selected',
          format: FileFormat.text,
        );
      }

      final results = <FileProcessingResult>[];

      for (final file in result.files) {
        final processedResult = await _processPickedFile(file);
        results.add(processedResult);
      }

      return results.length == 1
          ? results.first
          : FileProcessingResult.failure(
              fileName: 'Multiple Files',
              error: 'Multiple files selected, please select one at a time',
              format: FileFormat.text,
            );
    } catch (e) {
      ISpect.logger.error('Error in file picker: $e');
      return FileProcessingResult.failure(
        fileName: 'Unknown',
        error: 'Error opening file picker: $e',
        format: FileFormat.text,
      );
    }
  }

  /// Process a single picked file
  Future<FileProcessingResult> _processPickedFile(PlatformFile file) async {
    // Validate file extension
    final fileName = file.name.toLowerCase();
    if (!_isValidExtension(fileName)) {
      return FileProcessingResult.failure(
        fileName: file.name,
        error: 'Unsupported file type',
        format: FileFormat.text,
      );
    }

    // Check file size
    if (file.size > _maxFileSize) {
      return FileProcessingResult.failure(
        fileName: file.name,
        error: 'File too large (max 10MB)',
        format: FileFormat.text,
      );
    }

    // Read file content
    final content = await _readFileContent(file);
    if (content == null) {
      return FileProcessingResult.failure(
        fileName: file.name,
        error: 'Empty or unreadable file',
        format: FileFormat.text,
      );
    }

    // Determine file type and display properties
    final fileInfo = _analyzeFileContent(content, fileName);

    return FileProcessingResult.success(
      content: content,
      displayName: fileInfo.displayName,
      mimeType: fileInfo.mimeType,
      fileName: file.name,
      format: fileInfo.mimeType == 'application/json'
          ? FileFormat.json
          : FileFormat.text,
    );
  }

  /// Read content from platform file
  Future<String?> _readFileContent(PlatformFile file) async {
    try {
      // Try bytes first (works for both web and mobile when available)
      if (file.bytes != null) {
        return utf8.decode(file.bytes!);
      }

      // Fallback to file path for mobile platforms
      if (file.path != null) {
        final fileHandle = File(file.path!);
        return await fileHandle.readAsString();
      }
    } catch (e) {
      ISpect.logger.error('Error reading file content: $e');
    }
    return null;
  }

  /// Process pasted content with auto-detected format
  FileProcessingResult processPastedContent(
    String content,
  ) {
    if (content.trim().isEmpty) {
      return FileProcessingResult.failure(
        fileName: 'Pasted Content',
        error: 'Content is empty',
        format: FileFormat.text,
      );
    }

    // Auto-detect format based on content
    final detectedFormat = _detectContentFormat(content);
    final fileInfo = _analyzeContentWithFormat(content, detectedFormat);

    return FileProcessingResult.success(
      content: content,
      displayName: fileInfo.displayName,
      mimeType: fileInfo.mimeType,
      fileName: 'Pasted Content',
      format: detectedFormat,
    );
  }

  /// Analyze file content and determine its properties
  ({String displayName, String mimeType}) _analyzeFileContent(
    String content,
    String fileName,
  ) {
    var displayName = 'Text';
    var mimeType = 'text/plain';

    if (fileName.endsWith('.json')) {
      displayName = 'JSON';
      mimeType = 'application/json';

      // Validate JSON structure (but don't fail if invalid)
      try {
        jsonDecode(content);
      } catch (e) {
        // Still process as JSON but it's invalid
        displayName = 'JSON (Invalid)';
      }
    } else {
      // For .txt files, try to detect if content is actually JSON
      if (_looksLikeJson(content)) {
        try {
          jsonDecode(content.trim());
          displayName = 'JSON (from .txt file)';
          mimeType = 'application/json';
        } catch (e) {
          // Keep as text file
        }
      }
    }

    return (displayName: displayName, mimeType: mimeType);
  }

  /// Analyze content with specified format
  ({String displayName, String mimeType}) _analyzeContentWithFormat(
    String content,
    FileFormat format,
  ) {
    // Set display name and MIME type based on format
    switch (format) {
      case FileFormat.json:
        // Validate JSON structure but keep JSON MIME regardless
        try {
          jsonDecode(content);
          return (displayName: 'JSON', mimeType: 'application/json');
        } catch (e) {
          return (displayName: 'JSON (Invalid)', mimeType: 'application/json');
        }
      case FileFormat.text:
        return (displayName: 'Text', mimeType: 'text/plain');
      case FileFormat.auto:
        // Should not occur as format should be detected before calling this method
        return (displayName: 'Text', mimeType: 'text/plain');
    }
  }

  /// Detect content format based on content analysis
  FileFormat _detectContentFormat(String content) {
    if (_looksLikeJson(content)) {
      try {
        jsonDecode(content.trim());
        return FileFormat.json;
      } catch (e) {
        // If it looks like JSON but fails to parse, still treat as JSON
        // This allows the UI to show it as invalid JSON
        return FileFormat.json;
      }
    }
    return FileFormat.text;
  }

  /// Check if content looks like JSON
  bool _looksLikeJson(String content) {
    final trimmedContent = content.trim();
    return (trimmedContent.startsWith('{') && trimmedContent.endsWith('}')) ||
        (trimmedContent.startsWith('[') && trimmedContent.endsWith(']'));
  }

  /// Check if file extension is valid
  bool _isValidExtension(String fileName) => _supportedExtensions
      .any((ext) => fileName.toLowerCase().endsWith('.$ext'));

  /// Validate JSON content
  bool isValidJson(String content) {
    try {
      jsonDecode(content);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get supported file extensions
  List<String> get supportedExtensions =>
      List.unmodifiable(_supportedExtensions);

  /// Get maximum file size in bytes
  int get maxFileSize => _maxFileSize;

  /// Get maximum file size in human readable format
  String get maxFileSizeFormatted => '${_maxFileSize ~/ (1024 * 1024)}MB';

  /// Process a file for testing purposes (bypasses file picker validation)
  @visibleForTesting
  Future<FileProcessingResult> processFileForTesting(PlatformFile file) async =>
      _processPickedFile(file);
}
