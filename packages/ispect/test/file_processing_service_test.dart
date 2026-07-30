import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_format.dart';
import 'package:ispect/src/features/log_viewer/services/file_processing_service.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  late FileProcessingService service;

  setUp(() {
    service = const FileProcessingService();
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

    test('rejects oversized JSON before decoding', () {
      final oversizedPrefix = '{"value":"'.padRight(
        JsonInputPreflight.maxCharacters,
        'x',
      );
      final content = '$oversizedPrefix"}';

      final result = service.processPastedContent(content);

      expect(result.success, false);
      expect(result.format, FileFormat.json);
      expect(result.error, contains('safe character limit'));
      expect(service.isValidJson(content), false);
    });

    test('rejects deeply nested JSON before decoding', () {
      final openings = List<String>.filled(
        JsonInputPreflight.maxNestingDepth + 1,
        '[',
      ).join();
      final closings = List<String>.filled(
        JsonInputPreflight.maxNestingDepth + 1,
        ']',
      ).join();
      final content = '$openings$closings';

      final result = service.processPastedContent(content);

      expect(result.success, false);
      expect(result.format, FileFormat.json);
      expect(result.error, contains('safe depth limit'));
      expect(service.isValidJson(content), false);
    });

    test('rejects wide JSON before decoding', () {
      final values = List<String>.filled(
        JsonInputPreflight.maxViewerNodes,
        'null',
      ).join(',');
      final content = '[$values]';

      final result = service.processPastedContent(content);

      expect(result.success, false);
      expect(result.format, FileFormat.json);
      expect(result.error, contains('safe node limit'));
      expect(service.isValidJson(content), false);
    });

    test('large JSON processing yields before completing', () async {
      final payload = List<String>.filled(300 * 1024, 'x').join();
      final content = '{"payload":"$payload"}';
      final completionOrder = <String>[];
      final queuedUiWork = Future<void>(
        () => completionOrder.add('ui'),
      );
      final operation = service.processPastedContentAsync(content).then(
        (result) {
          completionOrder.add('processed');
          return result;
        },
      );

      final result = await operation;
      await queuedUiWork;

      expect(result.success, true);
      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON');
      expect(completionOrder, const ['ui', 'processed']);
    });

    test('honors a local import character budget', () {
      final constrained = FileProcessingService(
        resourceLimits: DiagnosticResourceLimits.balanced.copyWith(
          maxImportCharacters: 16,
        ),
      );

      final result = constrained.processPastedContent(
        '{"value":"1234567890"}',
      );

      expect(result.success, false);
      expect(result.error, contains('16'));
    });

    test('rejects an invalid local scheduling policy', () {
      const invalid = FileProcessingService(
        processingPolicy: DiagnosticProcessingPolicy(
          backgroundProcessingThresholdBytes: 0,
        ),
      );

      expect(
        () => invalid.processPastedContentAsync('{}'),
        throwsArgumentError,
      );
    });
  });
}
