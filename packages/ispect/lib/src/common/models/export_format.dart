import 'package:flutter/material.dart';

/// Supported file formats for log export.
enum ExportFormat {
  json('JSON', 'json', Icons.data_object_rounded),
  text('Text', 'txt', Icons.text_snippet_outlined),
  markdown('Markdown', 'md', Icons.article_outlined),
  csv('CSV', 'csv', Icons.table_chart_outlined);

  const ExportFormat(this.label, this.extension, this.icon);

  final String label;
  final String extension;
  final IconData icon;
}

/// The kind of export action being performed.
///
/// Passed to [ExportContentBuilder] so callers can vary content
/// (e.g. full data for share/download, truncated for clipboard copy).
enum ExportAction { share, download, copy }

/// Builds the export content string for a given [format] and [action].
///
/// [redactKeys] is non-null when the user has opted to redact sensitive data.
typedef ExportContentBuilder = Future<String> Function(
  ExportFormat format, {
  required ExportAction action,
  Set<String>? redactKeys,
});
