import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/ispect/domain/models/file_format.dart';
import 'package:ispect/src/features/ispect/services/file_processing_service.dart';

void main() {
  late FileProcessingService service;

  setUp(() {
    service = FileProcessingService();
  });

  group('FileProcessingService', () {
    test('detects JSON map content', () {
      const content = '{"name":"test","value":123}';

      final result = service.processPastedContent(content);

      expect(result.success, true);
      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON');
      expect(result.mimeType, 'application/json');
      expect(result.content, content);
    });

    test('detects JSON array content', () {
      const content = '[{"name":"item1"},{"name":"item2"}]';

      final result = service.processPastedContent(content);

      expect(result.success, true);
      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON');
      expect(result.mimeType, 'application/json');
    });

    test('marks invalid JSON as JSON (Invalid)', () {
      const content = '{"name":"invalid",}';

      final result = service.processPastedContent(content);

      expect(result.success, true);
      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON (Invalid)');
      expect(result.mimeType, 'application/json');
    });

    test('treats plain text as text format', () {
      const content = 'This is plain text content.';

      final result = service.processPastedContent(content);

      expect(result.success, true);
      expect(result.format, FileFormat.text);
      expect(result.displayName, 'Text');
      expect(result.mimeType, 'text/plain');
      expect(result.content, content);
    });

    test('fails when content is empty', () {
      final result = service.processPastedContent('   ');

      expect(result.success, false);
      expect(result.error, 'Content is empty');
    });
  });
}
