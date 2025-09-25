import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/ispect/domain/models/file_format.dart';
import 'package:ispect/src/features/ispect/services/file_processing_service.dart';

void main() {
  late FileProcessingService service;

  setUp(() {
    service = FileProcessingService();
    // Initialize ISpect with a basic logger for testing
    ISpect.initialize(ISpectify());
  });

  group('FileProcessingService JSON detection in .txt files', () {
    test('should detect JSON content in .txt file and set format to JSON',
        () async {
      // Create a mock .txt file with JSON content
      const jsonContent = '{"name": "test", "value": 123}';
      final mockFile = _createMockFile('test_data.txt', jsonContent);

      // Process the file
      final result = await service.processFileForTesting(mockFile);

      // Verify the result
      expect(result.success, true);
      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON (from .txt file)');
      expect(result.mimeType, 'application/json');
      expect(result.content, jsonContent);
    });

    test('should detect JSON array content in .txt file and set format to JSON',
        () async {
      // Create a mock .txt file with JSON array content
      const jsonContent = '[{"name": "item1"}, {"name": "item2"}]';
      final mockFile = _createMockFile('array_data.txt', jsonContent);

      // Process the file
      final result = await service.processFileForTesting(mockFile);

      // Verify the result
      expect(result.success, true);
      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON (from .txt file)');
      expect(result.mimeType, 'application/json');
      expect(result.content, jsonContent);
    });

    test(
        'should keep format as text for actual .txt files with non-JSON content',
        () async {
      // Create a mock .txt file with plain text content
      const textContent = 'This is just plain text content.';
      final mockFile = _createMockFile('plain_text.txt', textContent);

      // Process the file
      final result = await service.processFileForTesting(mockFile);

      // Verify the result
      expect(result.success, true);
      expect(result.format, FileFormat.text);
      expect(result.displayName, 'Text');
      expect(result.mimeType, 'text/plain');
      expect(result.content, textContent);
    });

    test('should detect .json files correctly', () async {
      // Create a mock .json file
      const jsonContent = '{"type": "json", "valid": true}';
      final mockFile = _createMockFile('data.json', jsonContent);

      // Process the file
      final result = await service.processFileForTesting(mockFile);

      // Verify the result
      expect(result.success, true);
      expect(result.format, FileFormat.json);
      expect(result.displayName, 'JSON');
      expect(result.mimeType, 'application/json');
      expect(result.content, jsonContent);
    });

    test('should handle invalid JSON in .txt file as text', () async {
      // Create a mock .txt file with invalid JSON content
      const invalidJsonContent = '{"name": "test", "value": }'; // Missing value
      final mockFile = _createMockFile('invalid_data.txt', invalidJsonContent);

      // Process the file
      final result = await service.processFileForTesting(mockFile);

      // Verify the result - should be treated as text since JSON parsing fails
      expect(result.success, true);
      expect(result.format, FileFormat.text);
      expect(result.displayName, 'Text');
      expect(result.mimeType, 'text/plain');
      expect(result.content, invalidJsonContent);
    });
  });
}

/// Helper function to create a mock PlatformFile for testing
PlatformFile _createMockFile(String fileName, String content) {
  final bytes = Uint8List.fromList(content.codeUnits);
  return PlatformFile(
    name: fileName,
    size: bytes.length,
    bytes: bytes,
    // Don't set path for web testing
  );
}
