/// Supported file formats for processing
enum FileFormat {
  /// Auto-detect format from content
  auto,

  /// JSON format
  json,

  /// Plain text format
  text;

  /// Get display name for the format
  String get displayName => switch (this) {
        FileFormat.auto => 'Auto-detect',
        FileFormat.json => 'JSON',
        FileFormat.text => 'Plain Text',
      };

  /// Get MIME type for the format
  String get mimeType => switch (this) {
        FileFormat.json => 'application/json',
        FileFormat.text => 'text/plain',
        FileFormat.auto => 'text/plain',
      };
}
