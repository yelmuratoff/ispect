import 'dart:convert';

/// Detects the file type based on content and file name.
({String displayName, String mimeType}) detectFileType(
  String content,
  String? fileName, {
  String defaultDisplayName = 'Text',
  String defaultMimeType = 'text/plain',
}) {
  final trimmedContent = content.trim();
  final isJsonContent = _isJsonContent(trimmedContent);

  if (fileName != null) {
    final lowerFileName = fileName.toLowerCase();
    if (lowerFileName.endsWith('.json')) {
      return (displayName: 'JSON', mimeType: 'application/json');
    }
    if (lowerFileName.endsWith('.txt')) {
      if (isJsonContent) {
        return (
          displayName: 'JSON (from .txt file)',
          mimeType: 'application/json',
        );
      }
      return (displayName: 'Text', mimeType: 'text/plain');
    }
  }

  if (isJsonContent) {
    final prefix = defaultDisplayName == 'HTML'
        ? 'JSON (from HTML format)'
        : 'JSON';
    return (displayName: prefix, mimeType: 'application/json');
  }

  return (displayName: defaultDisplayName, mimeType: defaultMimeType);
}

bool _isJsonContent(String trimmedContent) {
  if ((trimmedContent.startsWith('{') && trimmedContent.endsWith('}')) ||
      (trimmedContent.startsWith('[') && trimmedContent.endsWith(']'))) {
    try {
      jsonDecode(trimmedContent);
      return true;
    } catch (e) {
      return trimmedContent.startsWith('{') || trimmedContent.startsWith('[');
    }
  }
  return false;
}
