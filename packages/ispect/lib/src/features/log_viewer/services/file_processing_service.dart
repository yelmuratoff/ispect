import 'package:flutter/foundation.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_format.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_processing_result.dart';

const int _backgroundProcessingThreshold = 256 * 1024;

FileProcessingResult _processPastedContentInBackground(String content) =>
    const FileProcessingService().processPastedContent(content);

/// Service that normalizes and validates raw log content.
///
/// This service follows SOLID principles by having a single responsibility:
/// processing and validating content format.
class FileProcessingService {
  const FileProcessingService();

  /// Moves large content validation and decoding off the UI isolate on native
  /// platforms. Web yields before using its single-isolate implementation.
  Future<FileProcessingResult> processPastedContentAsync(String content) {
    if (content.length > JsonInputPreflight.maxCharacters ||
        content.length < _backgroundProcessingThreshold) {
      return Future<FileProcessingResult>.value(
        processPastedContent(content),
      );
    }
    if (kIsWeb) {
      return Future<FileProcessingResult>(
        () => processPastedContent(content),
      );
    }
    return compute(
      _processPastedContentInBackground,
      content,
      debugLabel: 'ISpect JSON import',
    );
  }

  /// Process pasted content with auto-detected format
  FileProcessingResult processPastedContent(String content) {
    try {
      JsonInputPreflight.validateCharacterSize(content);
    } on JsonInputLimitException catch (error) {
      return FileProcessingResult.failure(
        fileName: 'Pasted Content',
        error: error.message,
        format: FileFormat.json,
      );
    }

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      return FileProcessingResult.failure(
        fileName: 'Pasted Content',
        error: 'Content is empty',
        format: FileFormat.text,
      );
    }

    final detectedFormat = _detectContentFormat(trimmedContent);
    if (detectedFormat == FileFormat.json) {
      return _processJsonContent(content, trimmedContent);
    }

    return FileProcessingResult.success(
      content: content,
      displayName: 'Text',
      mimeType: 'text/plain',
      fileName: 'Pasted Content',
      format: detectedFormat,
    );
  }

  FileProcessingResult _processJsonContent(
    String originalContent,
    String trimmedContent,
  ) {
    try {
      final decodedJson = _decodeForViewer(trimmedContent);
      return FileProcessingResult.success(
        content: originalContent,
        displayName: 'JSON',
        mimeType: 'application/json',
        fileName: 'Pasted Content',
        format: FileFormat.json,
        decodedJson: decodedJson,
        jsonDecodeAttempted: true,
        jsonDecodeSucceeded: true,
      );
    } on JsonInputLimitException catch (error) {
      return FileProcessingResult.failure(
        fileName: 'Pasted Content',
        error: error.message,
        format: FileFormat.json,
      );
    } on FormatException {
      return FileProcessingResult.success(
        content: originalContent,
        displayName: 'JSON (Invalid)',
        mimeType: 'application/json',
        fileName: 'Pasted Content',
        format: FileFormat.json,
        jsonDecodeAttempted: true,
      );
    }
  }

  static Object? _decodeForViewer(String content) => JsonInputPreflight.decode(
        content,
        approximateNodeLimit: JsonInputPreflight.maxViewerNodes,
      );

  /// Validate JSON content
  bool isValidJson(String content) {
    try {
      _decodeForViewer(content);
      return true;
    } on FormatException {
      return false;
    }
  }

  FileFormat _detectContentFormat(String content) =>
      _looksLikeJson(content) ? FileFormat.json : FileFormat.text;

  bool _looksLikeJson(String content) =>
      (content.startsWith('{') && content.endsWith('}')) ||
      (content.startsWith('[') && content.endsWith(']'));
}
