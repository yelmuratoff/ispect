import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/file_type_info.dart';

const String _jsonMimeType = 'application/json';
const int _backgroundInspectionThreshold = 512 * 1024;

/// A loaded file classified by type; JSON content is validated but not kept
/// decoded, see [viewerContent].
final class FileInspection {
  const FileInspection({required this.type, this.jsonError});

  final FileTypeInfo type;

  /// Why the content does not parse when [type] is JSON.
  final FormatException? jsonError;

  /// Whether [type] is JSON.
  bool get isJson => type.mimeType == _jsonMimeType;
}

/// Detects the file type based on content and file name.
FileTypeInfo detectFileType(
  String content,
  String? fileName, {
  String defaultDisplayName = 'Text',
  String defaultMimeType = 'text/plain',
}) => inspectFileContent(
  content,
  fileName,
  defaultDisplayName: defaultDisplayName,
  defaultMimeType: defaultMimeType,
).type;

/// Classifies [content] like [detectFileType] and keeps any JSON parse error.
FileInspection inspectFileContent(
  String content,
  String? fileName, {
  String defaultDisplayName = 'Text',
  String defaultMimeType = 'text/plain',
}) {
  final trimmedContent = content.trim();
  final lowerFileName = fileName?.toLowerCase();
  final isJsonFile = lowerFileName?.endsWith('.json') ?? false;
  final looksStructured =
      (trimmedContent.startsWith('{') && trimmedContent.endsWith('}')) ||
      (trimmedContent.startsWith('[') && trimmedContent.endsWith(']'));
  final jsonError = looksStructured || isJsonFile ? _jsonError(content) : null;
  final isJsonContent = looksStructured && jsonError == null;

  final FileTypeInfo type;
  if (isJsonFile) {
    type = (displayName: 'JSON', mimeType: _jsonMimeType);
  } else if (lowerFileName?.endsWith('.txt') ?? false) {
    type = isJsonContent
        ? (displayName: 'JSON (from .txt file)', mimeType: _jsonMimeType)
        : (displayName: 'Text', mimeType: 'text/plain');
  } else if (isJsonContent) {
    type = (
      displayName: defaultDisplayName == 'HTML'
          ? 'JSON (from HTML format)'
          : 'JSON',
      mimeType: _jsonMimeType,
    );
  } else {
    type = (displayName: defaultDisplayName, mimeType: defaultMimeType);
  }

  if (type.mimeType != _jsonMimeType) {
    return FileInspection(type: type);
  }
  return FileInspection(type: type, jsonError: jsonError);
}

/// Wraps [content] already known to be of [type], validating it when JSON.
FileInspection inspectAs(String content, FileTypeInfo type) {
  if (type.mimeType != _jsonMimeType) {
    return FileInspection(type: type);
  }
  return FileInspection(type: type, jsonError: _jsonError(content));
}

/// The value the JSON viewer shows for [content]: decoded when [inspection]
/// is JSON, off the UI isolate for large content where isolates exist, and
/// the raw text otherwise.
///
/// Throws [FormatException] when JSON content does not parse.
Future<Object?> viewerContent(String content, FileInspection inspection) {
  if (!inspection.isJson) return Future.value(content);
  if (content.length < _backgroundInspectionThreshold) {
    return Future.value(_decodeJson(content));
  }
  return compute(_decodeJson, content);
}

/// [inspectFileContent] that moves large content off the UI isolate.
Future<FileInspection> inspectFileContentInBackground(
  String content,
  String? fileName, {
  String defaultDisplayName = 'Text',
  String defaultMimeType = 'text/plain',
}) {
  final request = (
    content: content,
    fileName: fileName,
    defaultDisplayName: defaultDisplayName,
    defaultMimeType: defaultMimeType,
  );
  if (content.length < _backgroundInspectionThreshold) {
    return Future.value(_inspectRequest(request));
  }
  return compute(_inspectRequest, request);
}

FileInspection _inspectRequest(
  ({
    String content,
    String? fileName,
    String defaultDisplayName,
    String defaultMimeType,
  })
  request,
) => inspectFileContent(
  request.content,
  request.fileName,
  defaultDisplayName: request.defaultDisplayName,
  defaultMimeType: request.defaultMimeType,
);

Object? _decodeJson(String content) => jsonDecode(content);

FormatException? _jsonError(String content) {
  try {
    jsonDecode(content);
    return null;
  } on FormatException catch (error) {
    return error;
  }
}
