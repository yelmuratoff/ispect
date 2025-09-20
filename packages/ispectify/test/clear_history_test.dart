import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/history.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectify clearHistory', () {
    test('clearHistory works when logging is disabled', () {
      final logger = ISpectify();

      // Add some logs to history
      logger.info('Test log 1');
      logger.error('Test log 2');
      expect(logger.history.length, 2);

      // Disable logging
      logger.disable();
      expect(logger.options.enabled, isFalse);

      // clearHistory should still work
      logger.clearHistory();
      expect(logger.history.length, 0);
    });

    test(
        'DefaultISpectifyHistory.clear() works regardless of useHistory setting',
        () {
      // Test with useHistory = false
      final optionsDisabled = ISpectifyOptions(useHistory: false);
      final historyDisabled = DefaultISpectifyHistory(optionsDisabled);

      // Add items to history using test method
      final testData = ISpectifyData('Test log', key: 'test');
      historyDisabled.addForTesting(testData);
      expect(historyDisabled.history.length, 1);

      // clear() should work even when useHistory is false
      historyDisabled.clear();
      expect(historyDisabled.history.length, 0);

      // Test with useHistory = true but enabled = false
      final optionsEnabledFalse =
          ISpectifyOptions(useHistory: true, enabled: false);
      final historyEnabledFalse = DefaultISpectifyHistory(optionsEnabledFalse);

      historyEnabledFalse.addForTesting(testData);
      expect(historyEnabledFalse.history.length, 1);

      historyEnabledFalse.clear();
      expect(historyEnabledFalse.history.length, 0);
    });

    test('clearHistory preserves history functionality after re-enabling', () {
      final logger = ISpectify();

      // Add logs and disable
      logger.info('Test log 1');
      logger.disable();
      expect(logger.history.length, 1);

      // Clear while disabled
      logger.clearHistory();
      expect(logger.history.length, 0);

      // Re-enable and add new logs
      logger.enable();
      logger.info('Test log 2');
      expect(logger.history.length, 1);
    });
  });
}
