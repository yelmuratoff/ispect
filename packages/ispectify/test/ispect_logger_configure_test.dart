import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLogger.configure', () {
    test('updates filter for subsequent logs', () {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(
          useConsoleLogs: false,
        ),
      )..info('should be stored');
      expect(logger.history.length, 1);

      logger
        ..configure(
          filter: ISpectFilter(titles: const ['never-match']),
        )
        ..info('blocked');
      expect(logger.history.length, 1);
    });

    test('updates logger instance used for console output', () {
      final captured = <String>[];
      final firstLogger = ISpectBaseLogger(
        output: (msg, {logLevel, error, stackTrace, time}) => captured.add(msg),
      );

      final sut = ISpectLogger(
        logger: firstLogger,
        options: ISpectLoggerOptions(useHistory: false),
      )..info('initial');
      expect(captured.single, contains('initial'));

      final replacementCaptured = <String>[];
      final replacementLogger = ISpectBaseLogger(
        output: (msg, {logLevel, error, stackTrace, time}) =>
            replacementCaptured.add(msg),
      );

      sut
        ..configure(logger: replacementLogger)
        ..info('after replace');
      expect(replacementCaptured.single, contains('after replace'));
      expect(
        captured.length,
        1,
        reason: 'original logger should not receive new log',
      );
    });
  });
}
