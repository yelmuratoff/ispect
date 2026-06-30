import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('developerLogOutput', () {
    test('is usable as a LoggerOutput sink', () {
      expect(developerLogOutput, isA<LoggerOutput>());
    });

    test('writes without throwing for every metadata combination', () {
      expect(() => developerLogOutput('plain message'), returnsNormally);
      expect(
        () => developerLogOutput(
          'with error and stack',
          logLevel: LogLevel.error,
          error: StateError('boom'),
          stackTrace: StackTrace.current,
          time: DateTime(2024),
        ),
        returnsNormally,
      );
      expect(
        () => developerLogOutput('null level keeps default'),
        returnsNormally,
      );
    });

    test('drives ISpectBaseLogger with the boxed formatter', () {
      final logger = ISpectBaseLogger(
        settings: ConsoleSettings(formatter: const BoxedLogEntryFormatter()),
        output: developerLogOutput,
      );

      expect(
        () => logger
          ..info('boxed info')
          ..error('boxed error'),
        returnsNormally,
      );
    });
  });
}
