import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLogger additional data & pen', () {
    test('info stores additional data in history', () {
      final logger = ISpectLogger()
        ..info(
          'hello',
          additionalData: {'userId': 42},
        );

      final entry = logger.history.single;
      expect(entry.additionalData, isNotNull);
      expect(entry.additionalData!['userId'], 42);
    });

    test('additionalData is unmodifiable from consumers', () {
      final logger = ISpectLogger()
        ..debug(
          'immutable',
          additionalData: {'key': 'value'},
        );

      final entry = logger.history.single;

      expect(
        () => entry.additionalData!['key'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('custom pen propagates through convenience methods', () {
      final logger = ISpectLogger();
      final pen = AnsiPen()..green();

      logger.warning(
        'custom color',
        pen: pen,
      );

      final entry = logger.history.single;
      expect(entry.pen, same(pen));
    });
  });
}
