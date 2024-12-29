import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectifyException', () {
    test('constructor sets correct values', () {
      final exception = Exception('Test Exception');
      final talkerException = ISpectifyException(
        exception,
        message: 'Test Message',
        key: 'custom-key',
        logLevel: LogLevel.debug,
      );

      expect(talkerException.message, equals('Test Message'));
      expect(talkerException.exception, equals(exception));
      expect(talkerException.key, equals('custom-key'));
      expect(talkerException.logLevel, equals(LogLevel.debug));
    });

    test('generateTextMessage returns correct message format', () {
      final exception = Exception('Test Exception');
      final talkerException = ISpectifyException(
        exception,
        message: 'Test Message',
        key: 'custom-key',
        logLevel: LogLevel.debug,
      );

      final generatedMessage = talkerException.generateTextMessage();
      expect(
        generatedMessage,
        equals(
          '${talkerException.displayTitleWithTime()}${talkerException.displayMessage}${talkerException.displayException}${talkerException.displayStackTrace}',
        ),
      );
    });
  });
}
