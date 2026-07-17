import 'package:flutter_test/flutter_test.dart';
import 'package:web_logs_viewer/src/core/utils/file_type_detector.dart';

void main() {
  group('detectFileType', () {
    test('detects valid JSON content in a text file', () {
      final result = detectFileType('{"value": 1}', 'session.txt');

      expect(result.displayName, 'JSON (from .txt file)');
      expect(result.mimeType, 'application/json');
    });

    test('does not classify malformed structured content as JSON', () {
      final result = detectFileType('{not-json}', null);

      expect(result.displayName, 'Text');
      expect(result.mimeType, 'text/plain');
    });

    test('keeps the explicit JSON file type for malformed content', () {
      final result = detectFileType('{not-json}', 'session.json');

      expect(result.displayName, 'JSON');
      expect(result.mimeType, 'application/json');
    });

    test('preserves the HTML source context for embedded JSON', () {
      final result = detectFileType(
        '[1, 2, 3]',
        null,
        defaultDisplayName: 'HTML',
        defaultMimeType: 'text/html',
      );

      expect(result.displayName, 'JSON (from HTML format)');
      expect(result.mimeType, 'application/json');
    });

    test('uses caller defaults for plain content', () {
      final result = detectFileType(
        'plain text',
        null,
        defaultDisplayName: 'Clipboard',
        defaultMimeType: 'text/plain',
      );

      expect(result.displayName, 'Clipboard');
      expect(result.mimeType, 'text/plain');
    });
  });
}
