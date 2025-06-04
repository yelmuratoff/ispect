import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/logs_file/logs_file.dart';

void main() {
  group('LogsFileFactory', () {
    test('creates platform-appropriate handler', () {
      final handler = LogsFileFactory.create();
      expect(handler, isA<BaseLogsFile>());

      // The specific type depends on platform but should always extend BaseLogsFile
      expect(handler.supportsNativeFiles, isA<bool>());
    });

    test('can create log files', () async {
      const testContent = 'Test log content\nLine 2\nLine 3';
      const fileName = 'test_logs';

      final logFile = await LogsFileFactory.createLogsFile(
        testContent,
        fileName: fileName,
      );

      expect(logFile, isNotNull);

      final handler = LogsFileFactory.create();
      final filePath = handler.getFilePath(logFile);
      expect(filePath, isA<String>());
      expect(filePath.isNotEmpty, isTrue);

      // Verify file size
      final size = await handler.getFileSize(logFile);
      expect(size, greaterThan(0));
      expect(size, equals(testContent.length));

      // Verify content
      final readContent = await handler.readAsString(logFile);
      expect(readContent, equals(testContent));

      // Clean up
      await handler.deleteFile(logFile);
    });
  });
}
