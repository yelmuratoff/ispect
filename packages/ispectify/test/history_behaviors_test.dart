import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultISpectLoggerHistory behavior', () {
    test('N+1 adds evict FIFO head and preserve order', () {
      final options = ISpectLoggerOptions(maxHistoryItems: 3);
      final history = DefaultISpectLoggerHistory(options);

      for (var i = 0; i < 5; i++) {
        history.add(ISpectLogData('log-$i', key: 'k$i'));
      }

      expect(history.history, hasLength(3));
      expect(
        history.history.map((e) => e.key).toList(),
        ['k2', 'k3', 'k4'],
      );
    });

    test('add() invalidates the cached unmodifiable view', () {
      final options = ISpectLoggerOptions(maxHistoryItems: 5);
      final history = DefaultISpectLoggerHistory(options)
        ..add(ISpectLogData('one', key: 'a'));

      final firstView = history.history;
      expect(firstView, hasLength(1));

      history.add(ISpectLogData('two', key: 'b'));
      final secondView = history.history;

      expect(identical(firstView, secondView), isFalse);
      expect(secondView, hasLength(2));
    });

    test('clear() invalidates cache and empties history', () {
      final options = ISpectLoggerOptions(maxHistoryItems: 5);
      final history = DefaultISpectLoggerHistory(options)
        ..add(ISpectLogData('one', key: 'a'))
        ..add(ISpectLogData('two', key: 'b'));

      final snapshot = history.history;
      expect(snapshot, hasLength(2));

      history.clear();
      final afterClear = history.history;

      expect(afterClear, isEmpty);
      expect(identical(snapshot, afterClear), isFalse);
    });

    test('useHistory = false rejects add()', () {
      final options = ISpectLoggerOptions(useHistory: false);
      final history = DefaultISpectLoggerHistory(options)
        ..add(ISpectLogData('one', key: 'a'));

      expect(history.history, isEmpty);
    });

    test('enabled = false rejects add() even when useHistory is true', () {
      final options = ISpectLoggerOptions(enabled: false);
      final history = DefaultISpectLoggerHistory(options)
        ..add(ISpectLogData('one', key: 'a'));

      expect(history.history, isEmpty);
    });

    test('addForTesting bypasses useHistory guard', () {
      final options = ISpectLoggerOptions(useHistory: false);
      final history = DefaultISpectLoggerHistory(options)
        ..addForTesting(ISpectLogData('one', key: 'a'));

      expect(history.history, hasLength(1));
    });

    test('maxHistoryItems = 0 skips writes silently', () {
      final options = ISpectLoggerOptions(maxHistoryItems: 0);
      final history = DefaultISpectLoggerHistory(options)
        ..add(ISpectLogData('one', key: 'a'))
        ..add(ISpectLogData('two', key: 'b'));

      expect(history.history, isEmpty);
    });

    test('seed list is loaded into history via constructor', () {
      final options = ISpectLoggerOptions(maxHistoryItems: 5);
      final seeded = DefaultISpectLoggerHistory(
        options,
        history: [
          ISpectLogData('one', key: 'a'),
          ISpectLogData('two', key: 'b'),
        ],
      );

      expect(seeded.history.map((e) => e.key), ['a', 'b']);
    });

    test('returned view is unmodifiable', () {
      final options = ISpectLoggerOptions(maxHistoryItems: 5);
      final history = DefaultISpectLoggerHistory(options)
        ..add(ISpectLogData('one', key: 'a'));

      expect(
        () => history.history.add(ISpectLogData('two', key: 'b')),
        throwsUnsupportedError,
      );
    });
  });
}
