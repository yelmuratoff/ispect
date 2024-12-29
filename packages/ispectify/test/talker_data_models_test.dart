// ignore_for_file: unnecessary_type_check, leading_newlines_in_multiline_strings

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

const _testMessage = 'test message';
const _testTitle = 'test title';

void main() {
  group('ISpectiyData models', () {
    test('ISpectifyError', () async {
      final error = ISpectifyError(
        ArgumentError(),
        message: _testMessage,
        stackTrace: StackTrace.empty,
        title: _testTitle,
      );

      expect(error is ISpectiyData, true);
      expect(error is ISpectifyError, true);
      expect(error.message, _testMessage);
      expect(error.title, _testTitle);
      expect(error.time is DateTime, true);
      expect(error.error is ArgumentError, true);
      expect(error.stackTrace is StackTrace, true);

      final message = error.generateTextMessage();
      expect(
        message,
        '''[test title] | ${ISpectifyDateTimeFormatter(error.time).timeAndSeconds} | test message
Invalid argument(s)''',
      );
    });

    test('ISpectifyException', () async {
      final exception = ISpectifyException(
        Exception(),
        message: _testMessage,
        stackTrace: StackTrace.empty,
        title: _testTitle,
      );

      expect(exception is ISpectiyData, true);
      expect(exception is ISpectifyException, true);
      expect(exception.message, _testMessage);
      expect(exception.title, _testTitle);
      expect(exception.time is DateTime, true);
      expect(exception.exception is Exception, true);
      expect(exception.stackTrace is StackTrace, true);

      final message = exception.generateTextMessage();
      expect(
        message,
        '''[test title] | ${ISpectifyDateTimeFormatter(exception.time).timeAndSeconds} | test message
Exception''',
      );

      final exceptionWithStackTrace = ISpectifyException(
        Exception(),
        stackTrace: StackTrace.current,
      );

      final fmtStackTrace = exceptionWithStackTrace.displayStackTrace;
      expect(fmtStackTrace, isNotEmpty);
    });

    test('ISpectifyLog', () async {
      final log = ISpectifyLog(
        _testMessage,
        logLevel: LogLevel.debug,
        title: _testTitle,
      );

      expect(log is ISpectiyData, true);
      expect(log is ISpectifyLog, true);
      expect(log.message, _testMessage);
      expect(log.title, _testTitle);
      expect(log.time is DateTime, true);

      final message = log.generateTextMessage();
      expect(
        message,
        '''[test title] | ${ISpectifyDateTimeFormatter(log.time).timeAndSeconds} | test message''',
      );
    });
  });
}
