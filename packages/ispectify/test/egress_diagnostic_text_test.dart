import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

ISpectLogger _logger() => ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false, maxHistoryItems: 10),
    );

void main() {
  setUp(() {
    ISpectRedaction.reset();
    ISpectRedaction.configure(service: RedactionService());
  });

  tearDown(ISpectRedaction.reset);

  group('egress diagnostic text', () {
    test('retains the error description', () {
      final logger = _logger();
      addTearDown(logger.dispose);

      logger.handle(
        exception: StateError('checkout total mismatch'),
        stackTrace: StackTrace.current,
        message: 'order submit failed',
      );

      final entry = logger.history.single;
      expect(entry.errorText, contains('checkout total mismatch'));
      expect(entry.textMessage, contains('order submit failed'));
    });

    test('retains the exception description', () {
      final logger = _logger();
      addTearDown(logger.dispose);

      logger.handle(
        exception: const FormatException('unexpected character at offset 4'),
        message: 'payload parse failed',
      );

      final entry = logger.history.single;
      expect(entry.exceptionText, contains('unexpected character at offset 4'));
    });

    test('retains the stack trace frames', () {
      final logger = _logger();
      addTearDown(logger.dispose);

      logger.handle(
        exception: StateError('boom'),
        stackTrace: StackTrace.fromString('#0 someFrame (file.dart:1:2)'),
      );

      final entry = logger.history.single;
      expect(entry.stackTraceText, contains('someFrame'));
      expect(
        entry.stackTraceText,
        isNot(contains(JsonValueNormalizer.unprintableValue)),
      );
    });

    test('still redacts a credential inside the error description', () {
      final logger = _logger();
      addTearDown(logger.dispose);

      logger.handle(
        exception: StateError('Bearer aaaabbbbccccddddeeeeffff00001111'),
      );

      final entry = logger.history.single;
      expect(entry.errorText, isNot(contains('aaaabbbbccccddddeeeeffff')));
      expect(entry.errorText, contains('[REDACTED]'));
    });
  });
}
