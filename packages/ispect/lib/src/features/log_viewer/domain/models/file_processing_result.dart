import 'package:ispect/src/features/log_viewer/domain/models/file_format.dart';
import 'package:ispectify/ispectify.dart';
import 'package:meta/meta.dart';

enum FileProcessingError { emptyContent, exceedsSafeLimits }

/// Result of file processing operation
@immutable
sealed class FileProcessingResult {
  const FileProcessingResult({required this.fileName, required this.format});

  /// Original file name
  final String fileName;

  /// Detected or specified file format
  final FileFormat format;
}

@immutable
final class FileProcessingSuccess extends FileProcessingResult {
  FileProcessingSuccess({
    required this.content,
    required this.displayName,
    required this.mimeType,
    required super.fileName,
    required super.format,
    required this.resourceLimits,
    required this.processingPolicy,
    this.decodedJson,
    this.hasDecodedJson = false,
  }) {
    resourceLimits.validate();
    processingPolicy.validate();
  }

  final String content;

  final String displayName;

  final String mimeType;

  final Object? decodedJson;

  final bool hasDecodedJson;

  final DiagnosticResourceLimits resourceLimits;

  final DiagnosticProcessingPolicy processingPolicy;

  Map<String, dynamic> get viewerData {
    if (!hasDecodedJson) return {'content': content};
    return switch (decodedJson) {
      final Map<String, dynamic> map => map,
      final List<Object?> list => {'data': list},
      final value => {'value': value},
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileProcessingSuccess &&
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
final class FileProcessingFailure extends FileProcessingResult {
  const FileProcessingFailure({
    required this.error,
    required super.fileName,
    required super.format,
  });

  final FileProcessingError error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileProcessingFailure &&
        other.error == error &&
        other.fileName == fileName &&
        other.format == format;
  }

  @override
  int get hashCode => Object.hash(error, fileName, format);
}
