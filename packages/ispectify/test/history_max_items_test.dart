import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultISpectLoggerHistory maxHistoryItems edge cases', () {
    test('maxHistoryItems = 0 should disable history instead of crashing', () {
      final options = ISpectLoggerOptions(maxHistoryItems: 0);
      final history = DefaultISpectLoggerHistory(options);

      // This should not crash
      final testData = ISpectLogData('Test log', key: 'test');
      history.add(testData);

      // History should remain empty
      expect(history.history.length, 0);
    });

    test('maxHistoryItems = -1 should throw at runtime', () {
      expect(
        () => ISpectLoggerOptions(maxHistoryItems: -1),
        throwsArgumentError,
      );
    });

    test('negative console truncation should throw at runtime', () {
      expect(
        () => ISpectLoggerOptions(logTruncateLength: -1),
        throwsArgumentError,
      );
    });

    test('maxHistoryItems > 0 should work normally', () {
      final options = ISpectLoggerOptions(maxHistoryItems: 2);
      final history = DefaultISpectLoggerHistory(options)
        ..add(ISpectLogData('Log 1', key: 'test1'))
        ..add(ISpectLogData('Log 2', key: 'test2'));

      expect(history.history.length, 2);

      history.add(ISpectLogData('Log 3', key: 'test3'));
      expect(history.history.length, 2);
      expect(history.history.first.key, 'test2');
      expect(history.history.last.key, 'test3');
    });

    test('maxHistoryItems = 1 should keep only the latest item', () {
      final options = ISpectLoggerOptions(maxHistoryItems: 1);
      final history = DefaultISpectLoggerHistory(options)
        ..add(ISpectLogData('Log 1', key: 'test1'));

      expect(history.history.length, 1);
      expect(history.history.first.key, 'test1');

      history.add(ISpectLogData('Log 2', key: 'test2'));
      expect(history.history.length, 1);
      expect(history.history.first.key, 'test2');
    });
  });
}
