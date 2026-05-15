// ignore_for_file: type=lint
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/ispect/domain/models/models.dart';

/// Result of file processing operation
@immutable
sealed class FileProcessingResult {
  const FileProcessingResult({
    required this.fileName,
    required this.format,
  });

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
  }) = _SuccessFileProcessingResult;

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
          try {
            final decoded = jsonDecode(content);
            final data = switch (decoded) {
              Map<String, dynamic> map => map,
              List<Object?> list => {'data': list},
              _ => {'value': decoded},
            };
            if (!context.mounted) return;
            JsonScreen(data: data).push(context);
            return;
          } catch (_) {
            if (!context.mounted) return;
            JsonScreen(data: {'content': content}).push(context);
            return;
          }
        }
        if (!context.mounted) return;
        JsonScreen(data: {'content': content}).push(context);
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
  }) : super();

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
  int get hashCode => Object.hash(
        content,
        displayName,
        mimeType,
        fileName,
        format,
      );
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
