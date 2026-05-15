import 'dart:convert';

import 'package:ispect/src/features/ispect/domain/models/file_format.dart';
import 'package:ispect/src/features/ispect/domain/models/file_processing_result.dart';

/// Service that normalizes and validates raw log content.
///
/// This service follows SOLID principles by having a single responsibility:
/// processing and validating content format.
class FileProcessingService {
  const FileProcessingService();

  /// Process pasted content with auto-detected format
  FileProcessingResult processPastedContent(String content) {
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      return FileProcessingResult.failure(
        fileName: 'Pasted Content',
        error: 'Content is empty',
        format: FileFormat.text,
      );
    }

    // Auto-detect format based on content
    final detectedFormat = _detectContentFormat(trimmedContent);
    final fileInfo = _analyzeContentWithFormat(trimmedContent, detectedFormat);

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
  ) =>
      switch (format) {
        FileFormat.json => _analyzeJsonContent(content),
        FileFormat.text || FileFormat.auto => (
            displayName: 'Text',
            mimeType: 'text/plain',
          ),
      };

  /// Analyze JSON content and return appropriate metadata
  ({String displayName, String mimeType}) _analyzeJsonContent(String content) {
    final isValid = isValidJson(content);
    return (
      displayName: isValid ? 'JSON' : 'JSON (Invalid)',
      mimeType: 'application/json',
    );
  }

  /// Detect content format based on content analysis
  FileFormat _detectContentFormat(String content) =>
      _looksLikeJson(content) ? FileFormat.json : FileFormat.text;

  /// Check if content looks like JSON
  bool _looksLikeJson(String content) =>
      (content.startsWith('{') && content.endsWith('}')) ||
      (content.startsWith('[') && content.endsWith(']'));

  /// Validate JSON content
  bool isValidJson(String content) {
    try {
      jsonDecode(content);
      return true;
    } on FormatException {
      return false;
    }
  }
}
