import 'package:flutter/foundation.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_format.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_processing_result.dart';

FileProcessingResult _processPastedContentInBackground(
  ({String content, DiagnosticResourceLimits resourceLimits}) input,
) => FileProcessingService(
  resourceLimits: input.resourceLimits,
).processPastedContent(input.content);

/// Service that normalizes and validates raw log content.
///
/// This service follows SOLID principles by having a single responsibility:
/// processing and validating content format.
class FileProcessingService {
  const FileProcessingService({this.resourceLimits, this.processingPolicy});

  final DiagnosticResourceLimits? resourceLimits;
  final DiagnosticProcessingPolicy? processingPolicy;

  /// Moves large content validation and decoding off the UI isolate on native
  /// platforms. Web yields before using its single-isolate implementation.
  Future<FileProcessingResult> processPastedContentAsync(String content) {
    final limits = _resourceLimits;
    final scheduling = _processingPolicy;
    if (content.length > limits.maxImportCharacters ||
        content.length < scheduling.backgroundProcessingThresholdBytes) {
      return Future<FileProcessingResult>.value(processPastedContent(content));
    }
    if (kIsWeb) {
      return Future<FileProcessingResult>(() => processPastedContent(content));
    }
    return compute(_processPastedContentInBackground, (
      content: content,
      resourceLimits: limits,
    ), debugLabel: 'ISpect JSON import');
  }

  /// Process pasted content with auto-detected format
  FileProcessingResult processPastedContent(String content) {
    final limits = _resourceLimits;
    try {
      JsonInputPreflight.validateCharacterSize(
        content,
        characterLimit: limits.maxImportCharacters,
      );
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
      resourceLimits: limits,
      processingPolicy: _processingPolicy,
    );
  }

  FileProcessingResult _processJsonContent(
    String originalContent,
    String trimmedContent,
  ) {
    try {
      final decodedJson = _decodeForViewer(trimmedContent, _resourceLimits);
      return FileProcessingResult.success(
        content: originalContent,
        displayName: 'JSON',
        mimeType: 'application/json',
        fileName: 'Pasted Content',
        format: FileFormat.json,
        decodedJson: decodedJson,
        jsonDecodeAttempted: true,
        jsonDecodeSucceeded: true,
        resourceLimits: _resourceLimits,
        processingPolicy: _processingPolicy,
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
        resourceLimits: _resourceLimits,
        processingPolicy: _processingPolicy,
      );
    }
  }

  static Object? _decodeForViewer(
    String content,
    DiagnosticResourceLimits resourceLimits,
  ) => JsonInputPreflight.decode(
    content,
    characterLimit: resourceLimits.maxImportCharacters,
    encodedByteLimit: resourceLimits.maxImportBytes,
    nestingDepthLimit: resourceLimits.maxTraversalDepth,
    approximateNodeLimit: resourceLimits.maxViewerNodes,
  );

  /// Validate JSON content
  bool isValidJson(String content) {
    try {
      _decodeForViewer(content, _resourceLimits);
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

  DiagnosticResourceLimits get _resourceLimits {
    final limits =
        (resourceLimits ??
              ISpect.loggerIfInitialized?.options.resourceLimits ??
              DiagnosticResourceLimits.balanced)
          ..validate();
    return limits;
  }

  DiagnosticProcessingPolicy get _processingPolicy {
    final policy =
        (processingPolicy ??
              ISpect.loggerIfInitialized?.options.processingPolicy ??
              DiagnosticProcessingPolicy.balanced)
          ..validate();
    return policy;
  }
}
