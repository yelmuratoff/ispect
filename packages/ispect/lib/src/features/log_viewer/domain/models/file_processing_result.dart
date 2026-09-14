// ignore_for_file: type=lint
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/log_viewer/domain/models/models.dart';

/// Result of file processing operation
@immutable
sealed class FileProcessingResult {
  const FileProcessingResult({required this.fileName, required this.format});

  /// Original file name
  final String fileName;

  /// Detected or specified file format
  final FileFormat format;

  /// Whether the operation was successful
  bool get success;

  /// Error message if operation failed (null for success)
  String? get error;

  /// The file content (empty for failure)
  String get content;

  /// Display name for the file (empty for failure)
  String get displayName;

  /// MIME type of the content (empty for failure)
  String get mimeType;

  /// Create a successful result
  factory FileProcessingResult.success({
    required String content,
    required String displayName,
    required String mimeType,
    required String fileName,
    required FileFormat format,
    Object? decodedJson,
    bool jsonDecodeAttempted = false,
    bool jsonDecodeSucceeded = false,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
    DiagnosticProcessingPolicy processingPolicy =
        DiagnosticProcessingPolicy.balanced,
  }) {
    resourceLimits.validate();
    processingPolicy.validate();
    return _SuccessFileProcessingResult(
      content: content,
      displayName: displayName,
      mimeType: mimeType,
      fileName: fileName,
      format: format,
      decodedJson: decodedJson,
      jsonDecodeAttempted: jsonDecodeAttempted,
      jsonDecodeSucceeded: jsonDecodeSucceeded,
      resourceLimits: resourceLimits,
      processingPolicy: processingPolicy,
    );
  }

  /// Create a failed result
  factory FileProcessingResult.failure({
    required String fileName,
    required String error,
    required FileFormat format,
  }) = _FailureFileProcessingResult;

  /// Navigate to appropriate screen to display the content.
  Future<void> action(BuildContext context) async {
    // Only meaningful for success results; callers already gate on success.
    switch (this) {
      case _SuccessFileProcessingResult(:final content, :final format):
        if (format == FileFormat.json) {
          final result = this as _SuccessFileProcessingResult;
          Object? decoded;
          if (result._jsonDecodeAttempted) {
            if (!result._jsonDecodeSucceeded) {
              if (!context.mounted) return;
              JsonScreen(
                data: {'content': content},
                resourceLimits: result._resourceLimits,
                processingPolicy: result._processingPolicy,
              ).push(context);
              return;
            }
            decoded = result._decodedJson;
          } else {
            try {
              decoded = JsonInputPreflight.decode(
                content,
                characterLimit: result._resourceLimits.maxImportCharacters,
                encodedByteLimit: result._resourceLimits.maxImportBytes,
                nestingDepthLimit: result._resourceLimits.maxTraversalDepth,
                approximateNodeLimit: result._resourceLimits.maxViewerNodes,
              );
            } on JsonInputLimitException {
              if (!context.mounted) return;
              JsonScreen(
                data: const {'content': JsonInputPreflight.rejectedContent},
                resourceLimits: result._resourceLimits,
                processingPolicy: result._processingPolicy,
              ).push(context);
              return;
            } on FormatException {
              if (!context.mounted) return;
              JsonScreen(
                data: {'content': content},
                resourceLimits: result._resourceLimits,
                processingPolicy: result._processingPolicy,
              ).push(context);
              return;
            }
          }

          final data = switch (decoded) {
            Map<String, dynamic> map => map,
            List<Object?> list => {'data': list},
            _ => {'value': decoded},
          };
          if (!context.mounted) return;
          JsonScreen(
            data: data,
            resourceLimits: result._resourceLimits,
            processingPolicy: result._processingPolicy,
          ).push(context);
          return;
        }
        if (!context.mounted) return;
        final result = this as _SuccessFileProcessingResult;
        JsonScreen(
          data: {'content': content},
          resourceLimits: result._resourceLimits,
          processingPolicy: result._processingPolicy,
        ).push(context);
        return;
      case _FailureFileProcessingResult():
        // No-op for failure; callers show error separately.
        return;
    }
  }

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

@immutable
final class _SuccessFileProcessingResult extends FileProcessingResult {
  const _SuccessFileProcessingResult({
    required this.content,
    required this.displayName,
    required this.mimeType,
    required super.fileName,
    required super.format,
    Object? decodedJson,
    bool jsonDecodeAttempted = false,
    bool jsonDecodeSucceeded = false,
    required DiagnosticResourceLimits resourceLimits,
    required DiagnosticProcessingPolicy processingPolicy,
  }) : _decodedJson = decodedJson,
       _jsonDecodeAttempted = jsonDecodeAttempted,
       _jsonDecodeSucceeded = jsonDecodeSucceeded,
       _resourceLimits = resourceLimits,
       _processingPolicy = processingPolicy,
       assert(!jsonDecodeSucceeded || jsonDecodeAttempted),
       super();

  final Object? _decodedJson;
  final bool _jsonDecodeAttempted;
  final bool _jsonDecodeSucceeded;
  final DiagnosticResourceLimits _resourceLimits;
  final DiagnosticProcessingPolicy _processingPolicy;

  @override
  bool get success => true;

  @override
  String? get error => null;

  @override
  final String content;

  @override
  final String displayName;

  @override
  final String mimeType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SuccessFileProcessingResult &&
        other.content == content &&
        other.displayName == displayName &&
        other.mimeType == mimeType &&
        other.fileName == fileName &&
        other.format == format;
  }

  @override
  int get hashCode =>
      Object.hash(content, displayName, mimeType, fileName, format);
}

@immutable
final class _FailureFileProcessingResult extends FileProcessingResult {
  const _FailureFileProcessingResult({
    required this.error,
    required super.fileName,
    required super.format,
  }) : super();

  @override
  bool get success => false;

  @override
  final String? error;

  @override
  String get content => '';

  @override
  String get displayName => '';

  @override
  String get mimeType => '';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _FailureFileProcessingResult &&
        other.error == error &&
        other.fileName == fileName &&
        other.format == format;
  }

  @override
  int get hashCode => Object.hash(error, fileName, format);
}
