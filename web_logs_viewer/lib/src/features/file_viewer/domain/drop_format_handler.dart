import 'package:ispect/ispect.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'drop_outcome.dart';

/// Reads one dropped item through the first format it can provide and reports
/// each result to [onOutcome].
class DropFormatHandler {
  DropFormatHandler({required this.item, required this.onOutcome});

  final DropItem item;
  final void Function(DropOutcome outcome) onOutcome;

  late final _reader = item.dataReader!;

  /// Reads [item]; does nothing when the item carries no data reader.
  Future<void> process() async {
    if (item.dataReader == null) return;

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

  void _readFile(
    FileFormat format, {
    String? displayName,
    String? mimeType,
    required void Function(Object error) onError,
  }) {
    _reader.getFile(
      format,
      (file) => onOutcome(
        DroppedFile(
          fileName: file.fileName,
          openStream: file.getStream,
          displayName: displayName,
          mimeType: mimeType,
        ),
      ),
      onError: onError,
    );
  }

  Future<bool> _tryFormat(
    FileFormat format,
    String? displayName,
    String? mimeType,
  ) async {
    if (_reader.canProvide(format)) {
      _readFile(
        format,
        displayName: displayName,
        mimeType: mimeType,
        onError: (error) {
          ISpect.logger.error('Error reading format: $error');
        },
      );
      return true;
    }
    return false;
  }

  Future<bool> _tryFileUri() async {
    if (_reader.canProvide(Formats.fileUri)) {
      _reader.getValue<Uri>(
        Formats.fileUri,
        (value) {
          if (value != null) {
            onOutcome(DroppedFileUri(value));
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
    if (_reader.canProvide(Formats.plainText)) {
      _reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null) {
            onOutcome(
              DroppedText(
                content: value,
                fileName: 'dropped_text.txt',
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
      onOutcome(
        ExternalFileFailure(
          fileName: fileName,
          error: 'Only .txt and .json files are supported',
        ),
      );
      return;
    }

    if (_reader.canProvide(Formats.plainTextFile)) {
      _readFile(
        Formats.plainTextFile,
        onError: (error) {
          ISpect.logger.error('Could not read external file: $error');
          onOutcome(
            ExternalFileFailure(
              fileName: fileName,
              error: 'Could not read file content',
            ),
          );
        },
      );
      return;
    }

    onOutcome(
      ExternalFileFailure(
        fileName: fileName,
        error: 'File format not supported for content reading',
      ),
    );
  }

  void _tryReadWebFormat(String format) {
    ISpect.logger.info('Attempting to read web format: $format');

    if (_reader.canProvide(Formats.json)) {
      _readFile(
        Formats.json,
        displayName: 'JSON',
        mimeType: 'application/json',
        onError: (error) {
          ISpect.logger.error('Error reading web format as JSON: $error');
          _tryWebFormatAsPlainText(format);
        },
      );
      return;
    }

    if (_reader.canProvide(Formats.plainTextFile)) {
      _readFile(
        Formats.plainTextFile,
        onError: (error) {
          ISpect.logger.error('Error reading web format as text: $error');
          onOutcome(
            DropFormatFailure(
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

    if (mimeType == 'application/json' && _reader.canProvide(Formats.json)) {
      _readFile(
        Formats.json,
        displayName: 'JSON',
        mimeType: 'application/json',
        onError: (error) {
          ISpect.logger.error('Error reading JSON MIME type: $error');
          _tryReadAsPlainTextFile(mimeType);
        },
      );
      return;
    }

    if (_reader.canProvide(Formats.plainTextFile)) {
      _readFile(
        Formats.plainTextFile,
        onError: (error) {
          ISpect.logger.error('Error reading MIME type as file: $error');
          onOutcome(
            DropFormatFailure(
              type: 'MIME Type',
              format: mimeType,
              error: 'Could not read file content',
            ),
          );
        },
      );
      return;
    }

    if (_reader.canProvide(Formats.plainText)) {
      _reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null) {
            final isJson = mimeType == 'application/json';
            onOutcome(
              DroppedText(
                content: value,
                fileName: 'mime_content.${isJson ? 'json' : 'txt'}',
                displayName: isJson ? 'JSON' : 'Text',
                mimeType: mimeType,
              ),
            );
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading MIME type as text: $error');
          onOutcome(
            DropFormatFailure(
              type: 'MIME Type',
              format: mimeType,
              error: 'Could not read text content',
            ),
          );
        },
      );
      return;
    }

    onOutcome(
      DropFormatFailure(
        type: 'MIME Type',
        format: mimeType,
        error: 'MIME type not supported for reading',
      ),
    );
  }

  void _tryReadAsPlainTextFile(String mimeType) {
    if (_reader.canProvide(Formats.plainTextFile)) {
      _readFile(
        Formats.plainTextFile,
        onError: (error) {
          ISpect.logger.error('Error reading as plain text file: $error');
          onOutcome(
            DropFormatFailure(
              type: 'MIME Type',
              format: mimeType,
              error: 'Could not read as text file',
            ),
          );
        },
      );
    } else {
      onOutcome(
        DropFormatFailure(
          type: 'MIME Type',
          format: mimeType,
          error: 'Plain text file format not available',
        ),
      );
    }
  }

  void _tryWebFormatAsPlainText(String format) {
    if (_reader.canProvide(Formats.plainText)) {
      _reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null) {
            onOutcome(
              DroppedText(
                content: value,
                fileName: 'web_format_content.txt',
                displayName: 'Web Content',
                mimeType: 'text/plain',
              ),
            );
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading web format as plain text: $error');
          onOutcome(
            DropFormatFailure(
              type: 'Web Format',
              format: format,
              error: 'Could not read as plain text',
            ),
          );
        },
      );
    } else {
      onOutcome(
        DropFormatFailure(
          type: 'Web Format',
          format: format,
          error: 'Format not supported for content reading',
        ),
      );
    }
  }
}
