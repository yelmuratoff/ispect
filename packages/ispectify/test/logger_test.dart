import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/console_settings.dart';
import 'package:ispectify/src/logger/logger.dart';
import 'package:ispectify/src/logger/logger_io.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:test/test.dart';

void main() {
  test('default console colors follow stdout ANSI support', () {
    expect(ConsoleSettings().enableColors, stdout.supportsAnsiEscapes);
  });

  test('constructing a logger preserves the process ANSI setting', () {
    final original = ansiColorDisabled;
    try {
      ansiColorDisabled = true;

      ISpectBaseLogger();

      expect(ansiColorDisabled, isTrue);
    } finally {
      ansiColorDisabled = original;
    }
  });

  test('explicit console colors do not change the process ANSI setting', () {
    final original = ansiColorDisabled;
    final printed = <String>[];
    try {
      ansiColorDisabled = true;
      ISpectBaseLogger(
        settings: ConsoleSettings(enableColors: true),
        output: (message, {logLevel, error, stackTrace, time}) =>
            printed.add(message),
      ).info('colored message');

      expect(printed.single, contains('\x1B['));
      expect(ansiColorDisabled, isTrue);
    } finally {
      ansiColorDisabled = original;
    }
  });

  test('stdout emits a multi-line entry in one print call', () {
    final printed = <String>[];

    runZoned<void>(
      () => outputLog('first line\nsecond line'),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => printed.add(line),
      ),
    );

    expect(printed, ['first line\nsecond line']);
  });

  group('ISpectLoggerLogger', () {
    late List<String> loggedMessages;

    setUp(() {
      loggedMessages = [];
    });

    test('should log messages at or above the minimum level', () {
      ISpectBaseLogger(
        settings: ConsoleSettings(level: LogLevel.warning),
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
        settings: ConsoleSettings(level: LogLevel.warning),
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
        settings: ConsoleSettings(),
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
        settings: ConsoleSettings(level: LogLevel.critical, enabled: false),
        output: (message, {logLevel, error, stackTrace, time}) =>
            loggedMessages.add(message),
      )
        ..critical('Critical message')
        ..error('Error message');

      expect(loggedMessages, isEmpty);
    });

    test('should not log when logging is disabled', () {
      ISpectBaseLogger(
        settings: ConsoleSettings(enabled: false),
        output: (message, {logLevel, error, stackTrace, time}) =>
            loggedMessages.add(message),
      ).critical('Critical message');

      expect(loggedMessages, isEmpty);
    });

    test('should use default debug level when no level specified', () {
      ISpectBaseLogger(
        settings: ConsoleSettings(),
        output: (message, {logLevel, error, stackTrace, time}) =>
            loggedMessages.add(message),
      ).log('Default level message');

      expect(loggedMessages.length, 1);
      expect(loggedMessages[0], contains('Default level message'));
    });
  });
}
