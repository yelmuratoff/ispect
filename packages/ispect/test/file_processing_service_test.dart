import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_format.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_processing_result.dart';
import 'package:ispect/src/features/log_viewer/services/file_processing_service.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  late FileProcessingService service;

  setUp(() {
    service = const FileProcessingService();
  });

  FileProcessingSuccess expectSuccess(FileProcessingResult result) {
    expect(result, isA<FileProcessingSuccess>());
    return result as FileProcessingSuccess;
  }

  FileProcessingError? errorOf(FileProcessingResult result) => switch (result) {
    FileProcessingFailure(:final error) => error,
    FileProcessingSuccess() => null,
  };

  group('FileProcessingService', () {
    test('detects JSON map content', () {
      const content = '{"name":"test","value":123}';

      final result = expectSuccess(service.processPastedContent(content));

      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON');
      expect(result.mimeType, 'application/json');
      expect(result.content, content);
      expect(result.viewerData, {'name': 'test', 'value': 123});
    });

    test('detects JSON array content', () {
      const content = '[{"name":"item1"},{"name":"item2"}]';

      final result = expectSuccess(service.processPastedContent(content));

      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON');
      expect(result.mimeType, 'application/json');
      expect(result.viewerData['data'], hasLength(2));
    });

    test('marks invalid JSON as JSON (Invalid)', () {
      const content = '{"name":"invalid",}';

      final result = expectSuccess(service.processPastedContent(content));

      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON (Invalid)');
      expect(result.mimeType, 'application/json');
      expect(result.viewerData, {'content': content});
    });

    test('treats plain text as text format', () {
      const content = 'This is plain text content.';

      final result = expectSuccess(service.processPastedContent(content));

      expect(result.format, FileFormat.text);
      expect(result.displayName, 'Text');
      expect(result.mimeType, 'text/plain');
      expect(result.content, content);
      expect(result.viewerData, {'content': content});
    });

    test('fails with an empty-content error for whitespace', () {
      final result = service.processPastedContent('   ');

      expect(errorOf(result), FileProcessingError.emptyContent);
    });

    test('rejects oversized JSON before decoding', () {
      final oversizedPrefix = '{"value":"'.padRight(
        JsonInputPreflight.maxCharacters,
        'x',
      );
      final content = '$oversizedPrefix"}';

      final result = service.processPastedContent(content);

      expect(errorOf(result), FileProcessingError.exceedsSafeLimits);
      expect(result.format, FileFormat.json);
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

      expect(errorOf(result), FileProcessingError.exceedsSafeLimits);
      expect(result.format, FileFormat.json);
      expect(service.isValidJson(content), false);
    });

    test('rejects wide JSON before decoding', () {
      final values = List<String>.filled(
        JsonInputPreflight.maxViewerNodes,
        'null',
      ).join(',');
      final content = '[$values]';

      final result = service.processPastedContent(content);

      expect(errorOf(result), FileProcessingError.exceedsSafeLimits);
      expect(result.format, FileFormat.json);
      expect(service.isValidJson(content), false);
    });

    test('large JSON processing yields before completing', () async {
      final payload = List<String>.filled(300 * 1024, 'x').join();
      final content = '{"payload":"$payload"}';
      final completionOrder = <String>[];
      final queuedUiWork = Future<void>(() => completionOrder.add('ui'));
      final operation = service.processPastedContentAsync(content).then((
        result,
      ) {
        completionOrder.add('processed');
        return result;
      });

      final result = expectSuccess(await operation);
      await queuedUiWork;

      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON');
      expect(completionOrder, const ['ui', 'processed']);
    });

    test(
      'keeps the local scheduling policy on background processing',
      () async {
        const policy = DiagnosticProcessingPolicy(
          backgroundProcessingThresholdBytes: 1024,
        );
        const local = FileProcessingService(processingPolicy: policy);
        final content = '{"payload":"${'x' * 4096}"}';

        final result = expectSuccess(
          await local.processPastedContentAsync(content),
        );

        expect(
          result.processingPolicy.backgroundProcessingThresholdBytes,
          1024,
        );
      },
    );

    test('rejects content above a local import character budget', () {
      final constrained = FileProcessingService(
        resourceLimits: DiagnosticResourceLimits.balanced.copyWith(
          maxImportCharacters: 16,
        ),
      );

      final result = constrained.processPastedContent('{"value":"1234567890"}');

      expect(errorOf(result), FileProcessingError.exceedsSafeLimits);
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

  group('FileProcessingSuccess.viewerData', () {
    FileProcessingSuccess decoded(Object? value) => FileProcessingSuccess(
      content: '',
      displayName: 'JSON',
      mimeType: 'application/json',
      fileName: 'test.json',
      format: FileFormat.json,
      decodedJson: value,
      hasDecodedJson: true,
      resourceLimits: DiagnosticResourceLimits.balanced,
      processingPolicy: DiagnosticProcessingPolicy.balanced,
    );

    test('shows a decoded object as the root', () {
      expect(decoded(<String, dynamic>{'a': 1}).viewerData, {'a': 1});
    });

    test('wraps a decoded list under data', () {
      expect(decoded(<Object?>[1, 2]).viewerData, {
        'data': [1, 2],
      });
    });

    test('wraps a decoded scalar under value', () {
      expect(decoded(123).viewerData, {'value': 123});
    });
  });
}
