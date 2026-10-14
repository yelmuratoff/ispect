import 'dart:convert';

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

  group('inspectFileContent', () {
    test('classifies valid JSON content', () {
      final result = inspectFileContent('{"value": 1}', 'session.txt');

      expect(result.isJson, isTrue);
      expect(result.jsonError, isNull);
    });

    test('keeps the parse error of a malformed JSON file', () {
      final result = inspectFileContent('{not-json}', 'session.json');

      expect(result.isJson, isTrue);
      expect(result.jsonError, isA<FormatException>());
    });

    test('decodes nothing for plain text', () {
      final result = inspectFileContent('{not-json}', null);

      expect(result.isJson, isFalse);
      expect(result.jsonError, isNull);
    });
  });

  group('inspectAs', () {
    test('validates content declared as JSON', () {
      final result = inspectAs('[1, 2', (
        displayName: 'JSON',
        mimeType: 'application/json',
      ));

      expect(result.isJson, isTrue);
      expect(result.jsonError, isA<FormatException>());
    });

    test('leaves content declared as text unvalidated', () {
      final result = inspectAs('[1, 2', (
        displayName: 'Text',
        mimeType: 'text/plain',
      ));

      expect(result.isJson, isFalse);
      expect(result.jsonError, isNull);
    });
  });

  group('inspectFileContentInBackground', () {
    test('matches the synchronous inspection for large content', () async {
      final content = jsonEncode(List<int>.filled(300000, 7));

      final result = await inspectFileContentInBackground(content, 'big.json');

      expect(result.type, inspectFileContent(content, 'big.json').type);
      expect(result.jsonError, isNull);
    });
  });

  group('viewerContent', () {
    test('decodes JSON content when the viewer opens', () async {
      const inspection = FileInspection(
        type: (displayName: 'JSON', mimeType: 'application/json'),
      );

      expect(await viewerContent('{"value": 1}', inspection), {'value': 1});
    });

    test('decodes large JSON content off the UI isolate', () async {
      final content = jsonEncode(List<int>.filled(300000, 7));
      const inspection = FileInspection(
        type: (displayName: 'JSON', mimeType: 'application/json'),
      );

      expect(await viewerContent(content, inspection), hasLength(300000));
    });

    test('passes text content through undecoded', () async {
      const inspection = FileInspection(
        type: (displayName: 'Text', mimeType: 'text/plain'),
      );

      expect(await viewerContent('[1, 2]', inspection), '[1, 2]');
    });
  });
}
