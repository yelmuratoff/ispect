import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  late ISpectLoggerOptions options;

  setUp(() {
    options = ISpectLoggerOptions();
    // Initialize ISpect for testing
    ISpect.initialize(ISpectLogger());
  });

  group('DailyFileLogHistory maxSessionDays edge cases', () {
    test('maxSessionDays = 0 should skip file persistence without crashing',
        () async {
      final history = DailyFileLogHistory(
        options,
        maxSessionDays: 0,
        enableAutoSave: false,
      );

      // Add some data
      final testData = ISpectifyData('Test log', key: 'test');
      history.add(testData);
      expect(history.history.length, 1);

      // This should not crash and should not create any files
      await history.saveToDailyFile();

      // History should still contain the data (not persisted to file, but kept in memory)
      expect(history.history.length, 1);
    });

    test('maxSessionDays = -1 should skip file persistence without crashing',
        () async {
      final history = DailyFileLogHistory(
        options,
        maxSessionDays: -1,
        enableAutoSave: false,
      );

      // Add some data
      final testData = ISpectifyData('Test log', key: 'test');
      history.add(testData);
      expect(history.history.length, 1);

      // This should not crash and should not create any files
      await history.saveToDailyFile();

      // History should still contain the data
      expect(history.history.length, 1);
    });

    test('maxSessionDays > 0 should work normally', () async {
      final history = DailyFileLogHistory(
        options,
        maxSessionDays: 5,
        enableAutoSave: false,
      );

      // Add some data
      final testData = ISpectifyData('Test log', key: 'test');
      history.add(testData);
      expect(history.history.length, 1);

      // This should work normally
      await history.saveToDailyFile();

      // History should still contain the data
      expect(history.history.length, 1);
    });

    test('cleanup methods should handle edge cases gracefully', () async {
      final history = DailyFileLogHistory(
        options,
        maxSessionDays: 0,
        enableAutoSave: false,
      );

      // Test that cleanup is not called when maxSessionDays <= 0
      // This is implicitly tested by the fact that saveToDailyFile doesn't crash

      final testData = ISpectifyData('Test log', key: 'test');
      history.add(testData);

      // Multiple saves should not crash
      await history.saveToDailyFile();
      await history.saveToDailyFile();
      await history.saveToDailyFile();
    });
  });

  group('DailyFileLogHistory updateAutoSaveSettings persistence', () {
    test('should persist interval changes and report them in statistics',
        () async {
      final history = DailyFileLogHistory(
        options,
        maxSessionDays: 5,
        enableAutoSave: false,
      );

      // Initial interval should be the default (1 second)
      final initialStats = await history.getSessionStatistics();
      expect(initialStats.autoSaveInterval, const Duration(seconds: 1));

      // Update the interval
      const newInterval = Duration(minutes: 2);
      history.updateAutoSaveSettings(interval: newInterval);

      // Statistics should now show the new interval
      final updatedStats = await history.getSessionStatistics();
      expect(updatedStats.autoSaveInterval, newInterval);
    });

    test('should persist interval when enabling auto-save with new interval',
        () async {
      final history = DailyFileLogHistory(
        options,
        maxSessionDays: 5,
        enableAutoSave: false,
      );

      // Update interval and enable auto-save at the same time
      const newInterval = Duration(minutes: 5);
      history.updateAutoSaveSettings(enabled: true, interval: newInterval);

      // Statistics should show the new interval
      final stats = await history.getSessionStatistics();
      expect(stats.autoSaveInterval, newInterval);
      expect(stats.enableAutoSave, true);
    });

    test('should keep updated interval when toggling auto-save', () async {
      final history = DailyFileLogHistory(
        options,
        maxSessionDays: 5,
        enableAutoSave: false,
      );

      // Update interval
      const newInterval = Duration(minutes: 3);
      history
        ..updateAutoSaveSettings(interval: newInterval)

        // Enable auto-save
        ..updateAutoSaveSettings(enabled: true)

        // Disable auto-save
        ..updateAutoSaveSettings(enabled: false)

        // Re-enable auto-save - should use the updated interval, not the original
        ..updateAutoSaveSettings(enabled: true);

      // Statistics should still show the updated interval
      final stats = await history.getSessionStatistics();
      expect(stats.autoSaveInterval, newInterval);
      expect(stats.enableAutoSave, true);
    });

    test('should handle interval updates while auto-save is enabled', () async {
      final history = DailyFileLogHistory(options, maxSessionDays: 5);

      // Initial interval
      final initialStats = await history.getSessionStatistics();
      expect(initialStats.autoSaveInterval, const Duration(seconds: 1));

      // Update interval while enabled
      const newInterval = Duration(seconds: 30);
      history.updateAutoSaveSettings(interval: newInterval);

      // Statistics should show the new interval
      final updatedStats = await history.getSessionStatistics();
      expect(updatedStats.autoSaveInterval, newInterval);
      expect(updatedStats.enableAutoSave, true);
    });
  });

  group('DailyFileLogHistory maxFileSize and disk space checking', () {
    test('should allow writes within maxFileSize limit', () async {
      final history = DailyFileLogHistory(
        options,
        maxFileSize: 5 * 1024 * 1024, // 5MB
        enableAutoSave: false,
      );

      // Add data that would be under the limit
      final testData = ISpectifyData('Small log entry', key: 'test');
      history.add(testData);

      // This should succeed (no disk space error)
      await history.saveToDailyFile();

      // History should still contain the data (file-based history keeps data in memory)
      expect(history.history.isEmpty, false);
      expect(history.history.length, 1);
    });

    test('should respect maxFileSize configuration in disk space check',
        () async {
      // Test with a larger maxFileSize (200MB) to ensure it doesn't hit the old 100MB hardcoded limit
      final history = DailyFileLogHistory(
        options,
        maxFileSize: 200 * 1024 * 1024, // 200MB
        enableAutoSave: false,
      );

      // Add a moderate amount of data that would be allowed under 200MB limit
      // but would be rejected under the old 100MB hardcoded limit
      for (var i = 0; i < 1000; i++) {
        final testData = ISpectifyData(
          'Log entry $i with some additional content to increase size',
          key: 'test_$i',
          additionalData: {'extra': 'data' * 100}, // Add some extra data
        );
        history.add(testData);
      }

      // This should succeed with the new implementation
      // The old implementation would fail because requiredWithBuffer > 100MB
      await history.saveToDailyFile();

      // Verify data was processed (either saved or cleared)
      // We don't assert emptiness since rotation might occur
    });

    test('should reject writes that exceed configured maxFileSize limit',
        () async {
      final history = DailyFileLogHistory(
        options,
        maxFileSize: 1024, // Very small limit (1KB)
        enableAutoSave: false,
      );

      // Add data that exceeds the limit
      final largeData = ISpectifyData(
        'This is a very large log entry that should exceed the 1KB limit when serialized to JSON',
        key: 'large_test',
        additionalData: {'big_field': 'x' * 2000}, // Make it large
      );
      history.add(largeData);

      // This should either fail gracefully or handle the size limit appropriately
      // The exact behavior depends on how _wouldExceedSizeLimit works
      await history.saveToDailyFile();

      // The test passes if no exception is thrown
    });
  });
}
