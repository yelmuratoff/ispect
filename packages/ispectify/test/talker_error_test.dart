import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectifyError', () {
    test('constructor sets correct values', () {
      final error = Error();
      final talkerError = ISpectifyError(
        error,
        message: 'Test Message',
        key: 'custom-key',
        logLevel: LogLevel.debug,
      );

      expect(talkerError.message, equals('Test Message'));
      expect(talkerError.error, equals(error));
      expect(talkerError.key, equals('custom-key'));
      expect(talkerError.logLevel, equals(LogLevel.debug));
    });

    test('generateTextMessage returns correct message format', () {
      final error = Error();
      final talkerError = ISpectifyError(
        error,
        message: 'Test Message',
        key: 'custom-key',
        logLevel: LogLevel.debug,
      );

      final generatedMessage = talkerError.generateTextMessage();
      expect(
        generatedMessage,
        equals(
          '${talkerError.displayTitleWithTime()}${talkerError.displayMessage}${talkerError.displayError}${talkerError.displayStackTrace}',
        ),
      );
    });
  });
}
