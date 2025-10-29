import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLogger clearHistory', () {
    test('clearHistory works when logging is disabled', () {
      final logger = ISpectLogger()

        // Add some logs to history
        ..info('Test log 1')
        ..error('Test log 2');
      expect(logger.history.length, 2);

      // Disable logging
      logger.disable();
      expect(logger.options.enabled, isFalse);

      // clearHistory should still work
      logger.clearHistory();
      expect(logger.history.length, 0);
    });

    test(
        'DefaultISpectLoggerHistory.clear() works regardless of useHistory setting',
        () {
      // Test with useHistory = false
      final optionsDisabled = ISpectLoggerOptions(useHistory: false);
      final historyDisabled = DefaultISpectLoggerHistory(optionsDisabled);

      // Add items to history using test method
      final testData = ISpectLogData('Test log', key: 'test');
      historyDisabled.addForTesting(testData);
      expect(historyDisabled.history.length, 1);

      // clear() should work even when useHistory is false
      historyDisabled.clear();
      expect(historyDisabled.history.length, 0);

      // Test with useHistory = true but enabled = false
      final optionsEnabledFalse = ISpectLoggerOptions(enabled: false);
      final historyEnabledFalse =
          DefaultISpectLoggerHistory(optionsEnabledFalse)
            ..addForTesting(testData);
      expect(historyEnabledFalse.history.length, 1);

      historyEnabledFalse.clear();
      expect(historyEnabledFalse.history.length, 0);
    });

    test('clearHistory preserves history functionality after re-enabling', () {
      final logger = ISpectLogger()

        // Add logs and disable
        ..info('Test log 1')
        ..disable();
      expect(logger.history.length, 1);

      // Clear while disabled
      logger.clearHistory();
      expect(logger.history.length, 0);

      // Re-enable and add new logs
      logger
        ..enable()
        ..info('Test log 2');
      expect(logger.history.length, 1);
    });
  });
}
