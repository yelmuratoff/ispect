import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../core/models/models.dart';
import '../presentation/widgets/widgets.dart';

/// Handles different drop formats and processes them accordingly.
class DropFormatHandler {
  DropFormatHandler({
    required this.reader,
    required this.item,
    required this.onHandleFile,
    required this.onAddWidget,
  });

  final dynamic reader;
  final DropItem item;
  final void Function(dynamic file, String? displayName, String? mimeType)
  onHandleFile;
  final void Function(Widget widget) onAddWidget;

  Future<void> process() async {
    final formatHandlers = [
      () => _tryFormat(Formats.json, 'JSON', 'application/json'),
      () => _tryFormat(Formats.plainTextFile, null, null),
      () => _tryFormat(Formats.htmlFile, 'HTML', 'text/html'),
      () => _tryFileUri(),
    ];

    for (final handler in formatHandlers) {
      if (await handler()) return;
    }

    await _tryWebFormats() || await _tryMimeTypes() || await _tryPlainText();
  }

  Future<bool> _tryFormat(
    dynamic format,
    String? displayName,
    String? mimeType,
  ) async {
    if (reader.canProvide(format)) {
      reader.getFile(
        format,
        (file) {
          onHandleFile(file, displayName, mimeType);
        },
        onError: (error) {
          ISpect.logger.error('Error reading format: $error');
        },
      );
      return true;
    }
    return false;
  }

  Future<bool> _tryFileUri() async {
    if (reader.canProvide(Formats.fileUri)) {
      reader.getValue<Uri>(
        Formats.fileUri,
        (value) {
          if (value != null) {
            onAddWidget(FileUriWidget(fileUri: value));
            _tryReadExternalFile(value);
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading file URI: $error');
        },
      );
      return true;
    }
    return false;
  }

  Future<bool> _tryWebFormats() async {
    for (final format in item.platformFormats) {
      if (format.startsWith('web:') || format.contains('file')) {
        ISpect.logger.info('Trying web format: $format');
        _tryReadWebFormat(format);
        return true;
      }
    }
    return false;
  }

  Future<bool> _tryMimeTypes() async {
    for (final format in item.platformFormats) {
      if (format == 'application/json' ||
          format == 'text/plain' ||
          format == 'text/json') {
        ISpect.logger.info('Found MIME type: $format');
        _tryReadMimeTypeFormat(format);
        return true;
      }
    }
    return false;
  }

  Future<bool> _tryPlainText() async {
    if (reader.canProvide(Formats.plainText)) {
      reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null) {
            final mockFile = MockFile(
              content: value,
              fileName: 'dropped_text.txt',
            );
            onAddWidget(
              FileContentWidget(
                content: value,
                file: mockFile,
                displayName: 'Text',
                mimeType: 'text/plain',
              ),
            );
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading plain text: $error');
        },
      );
      return true;
    }
    return false;
  }

  void _tryReadExternalFile(Uri fileUri) {
    final fileName = fileUri.pathSegments.isNotEmpty
        ? fileUri.pathSegments.last
        : 'unknown';
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    if (extension != 'txt' && extension != 'json') {
      _showError(
        ExternalFileErrorWidget(
          fileName: fileName,
          error: 'Only .txt and .json files are supported',
        ),
      );
      return;
    }

    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) {
          onHandleFile(file, null, null);
        },
        onError: (error) {
          ISpect.logger.error('Could not read external file: $error');
          _showError(
            ExternalFileErrorWidget(
              fileName: fileName,
              error: 'Could not read file content',
            ),
          );
        },
      );
      return;
    }

    _showError(
      ExternalFileErrorWidget(
        fileName: fileName,
        error: 'File format not supported for content reading',
      ),
    );
  }

  void _tryReadWebFormat(String format) {
    ISpect.logger.info('Attempting to read web format: $format');

    if (reader.canProvide(Formats.json)) {
      reader.getFile(
        Formats.json,
        (file) => onHandleFile(file, 'JSON', 'application/json'),
        onError: (error) {
          ISpect.logger.error('Error reading web format as JSON: $error');
          _tryWebFormatAsPlainText(format);
        },
      );
      return;
    }

    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) => onHandleFile(file, null, null),
        onError: (error) {
          ISpect.logger.error('Error reading web format as text: $error');
          _showError(
            FormatErrorWidget(
              type: 'Web Format',
              format: format,
              error: 'Could not read as text file',
            ),
          );
        },
      );
      return;
    }

    _tryWebFormatAsPlainText(format);
  }

  void _tryReadMimeTypeFormat(String mimeType) {
    ISpect.logger.info('Attempting to read MIME type: $mimeType');

    if (mimeType == 'application/json' && reader.canProvide(Formats.json)) {
      reader.getFile(
        Formats.json,
        (file) => onHandleFile(file, 'JSON', 'application/json'),
        onError: (error) {
          ISpect.logger.error('Error reading JSON MIME type: $error');
          _tryReadAsPlainTextFile(mimeType);
        },
      );
      return;
    }

    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) => onHandleFile(file, null, null),
        onError: (error) {
          ISpect.logger.error('Error reading MIME type as file: $error');
          _showError(
            FormatErrorWidget(
              type: 'MIME Type',
              format: mimeType,
              error: 'Could not read file content',
            ),
          );
        },
      );
      return;
    }

    if (reader.canProvide(Formats.plainText)) {
      reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null) {
            final displayName = mimeType == 'application/json'
                ? 'JSON'
                : 'Text';
            final mockFile = MockFile(
              content: value,
              fileName:
                  'mime_content.${mimeType == 'application/json' ? 'json' : 'txt'}',
            );
            onAddWidget(
              FileContentWidget(
                content: value,
                file: mockFile,
                displayName: displayName,
                mimeType: mimeType,
              ),
            );
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading MIME type as text: $error');
          _showError(
            FormatErrorWidget(
              type: 'MIME Type',
              format: mimeType,
              error: 'Could not read text content',
            ),
          );
        },
      );
      return;
    }

    _showError(
      FormatErrorWidget(
        type: 'MIME Type',
        format: mimeType,
        error: 'MIME type not supported for reading',
      ),
    );
  }

  void _tryReadAsPlainTextFile(String mimeType) {
    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) => onHandleFile(file, null, null),
        onError: (error) {
          ISpect.logger.error('Error reading as plain text file: $error');
          _showError(
            FormatErrorWidget(
              type: 'MIME Type',
              format: mimeType,
              error: 'Could not read as text file',
            ),
          );
        },
      );
    } else {
      _showError(
        FormatErrorWidget(
          type: 'MIME Type',
          format: mimeType,
          error: 'Plain text file format not available',
        ),
      );
    }
  }

  void _tryWebFormatAsPlainText(String format) {
    if (reader.canProvide(Formats.plainText)) {
      reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null) {
            final mockFile = MockFile(
              content: value,
              fileName: 'web_format_content.txt',
            );
            onAddWidget(
              FileContentWidget(
                content: value,
                file: mockFile,
                displayName: 'Web Content',
                mimeType: 'text/plain',
              ),
            );
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading web format as plain text: $error');
          _showError(
            FormatErrorWidget(
              type: 'Web Format',
              format: format,
              error: 'Could not read as plain text',
            ),
          );
        },
      );
    } else {
      _showError(
        FormatErrorWidget(
          type: 'Web Format',
          format: format,
          error: 'Format not supported for content reading',
        ),
      );
    }
  }

  void _showError(Widget errorWidget) {
    onAddWidget(errorWidget);
  }
}
