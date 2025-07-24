import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/ispect/domain/models/models.dart';

/// Result of file processing operation
class FileProcessingResult {
  const FileProcessingResult({
    required this.success,
    required this.content,
    required this.displayName,
    required this.mimeType,
    required this.fileName,
    required this.format,
    this.error,
  });

  /// Create a successful result
  factory FileProcessingResult.success({
    required String content,
    required String displayName,
    required String mimeType,
    required String fileName,
    required FileFormat format,
  }) =>
      FileProcessingResult(
        success: true,
        content: content,
        displayName: displayName,
        mimeType: mimeType,
        fileName: fileName,
        format: format,
      );

  /// Create a failed result
  factory FileProcessingResult.failure({
    required String fileName,
    required String error,
    required FileFormat format,
  }) =>
      FileProcessingResult(
        success: false,
        content: '',
        displayName: '',
        mimeType: '',
        fileName: fileName,
        error: error,
        format: format,
      );

  /// Whether the operation was successful
  final bool success;

  /// The file content
  final String content;

  /// Display name for the file
  final String displayName;

  /// MIME type of the content
  final String mimeType;

  /// Original file name
  final String fileName;

  /// Error message if operation failed
  final String? error;

  final FileFormat format;

  Future<void> action(BuildContext context) async {
    if (format == FileFormat.json) {
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (!context.mounted) return;
      JsonScreen(data: data).push(context);
    } else {
      JsonScreen(data: {'content': content}).push(context);
    }
  }
}
