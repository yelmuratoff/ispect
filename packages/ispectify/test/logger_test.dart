import 'package:ispectify/src/logger/logger.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/settings.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLoggerLogger', () {
    late List<String> loggedMessages;

    setUp(() {
      loggedMessages = [];
    });

    test('should log messages at or above the minimum level', () {
      ISpectBaseLogger(
        settings: LoggerSettings(level: LogLevel.warning),
        output: (message, {logLevel, error, stackTrace, time}) =>
            loggedMessages.add(message),
      )
        ..critical('Critical message')
        ..error('Error message')
        ..warning('Warning message')
        ..info('Info message')
        ..debug('Debug message')
        ..verbose('Verbose message');

      expect(loggedMessages.length, 3);
      expect(loggedMessages[0], contains('Critical message'));
      expect(loggedMessages[1], contains('Error message'));
      expect(loggedMessages[2], contains('Warning message'));
    });

    test('should not log messages below the minimum level', () {
      ISpectBaseLogger(
        settings: LoggerSettings(level: LogLevel.warning),
        output: (message, {logLevel, error, stackTrace, time}) =>
            loggedMessages.add(message),
      )
        ..info('Info message')
        ..debug('Debug message')
        ..verbose('Verbose message');

      expect(loggedMessages, isEmpty);
    });

    test('should log all messages when level is verbose', () {
      ISpectBaseLogger(
        settings: LoggerSettings(),
        output: (message, {logLevel, error, stackTrace, time}) =>
            loggedMessages.add(message),
      )
        ..critical('Critical message')
        ..error('Error message')
        ..warning('Warning message')
        ..info('Info message')
        ..debug('Debug message')
        ..verbose('Verbose message');

      expect(loggedMessages.length, 6);
    });

    test('should not log any messages when level is critical', () {
      ISpectBaseLogger(
        settings: LoggerSettings(level: LogLevel.critical, enable: false),
        output: (message, {logLevel, error, stackTrace, time}) =>
            loggedMessages.add(message),
      )
        ..critical('Critical message')
        ..error('Error message');

      expect(loggedMessages, isEmpty);
    });

    test('should not log when logging is disabled', () {
      ISpectBaseLogger(
        settings: LoggerSettings(enable: false),
        output: (message, {logLevel, error, stackTrace, time}) =>
            loggedMessages.add(message),
      ).critical('Critical message');

      expect(loggedMessages, isEmpty);
    });

    test('should use default debug level when no level specified', () {
      ISpectBaseLogger(
        settings: LoggerSettings(),
        output: (message, {logLevel, error, stackTrace, time}) =>
            loggedMessages.add(message),
      ).log('Default level message');

      expect(loggedMessages.length, 1);
      expect(loggedMessages[0], contains('Default level message'));
    });
  });
}
