import 'dart:convert';

import 'package:ispect/src/features/ispect/domain/models/file_format.dart';
import 'package:ispect/src/features/ispect/domain/models/file_processing_result.dart';

/// Service that normalizes and validates raw log content.
class FileProcessingService {
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

  /// Validate JSON content
  bool isValidJson(String content) {
    try {
      jsonDecode(content);
      return true;
    } catch (e) {
      return false;
    }
  }
}
