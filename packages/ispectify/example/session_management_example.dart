// ignore_for_file: avoid_print

import 'package:ispectify/ispectify.dart';

/// Comprehensive example demonstrating advanced session management features
/// in DailyFileLogHistory.
///
/// This example showcases:
/// - Configurable session management with multiple cleanup strategies
/// - File size limits and automatic rotation
/// - Runtime configuration updates
/// - Session statistics monitoring
/// - Different cleanup strategies comparison
Future<void> main() async {
  print('🚀 Session Management Features Demo Started');

  // Example 1: Basic session management with custom configuration
  await _demonstrateBasicSessionManagement();

  // Example 2: Different cleanup strategies
  await _demonstrateCleanupStrategies();

  // Example 3: File size limits and rotation
  await _demonstrateFileSizeLimits();

  // Example 4: Runtime configuration updates
  await _demonstrateRuntimeUpdates();

  // Example 5: Session statistics monitoring
  await _demonstrateSessionStatistics();

  print('\n✅ Session Management Demo completed successfully!');
}

/// Demonstrates basic session management with custom configuration
Future<void> _demonstrateBasicSessionManagement() async {
  print('\n📋 1. Basic Session Management Configuration');

  // Create daily history with custom session management settings
  final dailyHistory = DailyFileLogHistory(
    ISpectifyOptions(maxHistoryItems: 1000),
    maxSessionDays: 7, // Keep logs for 7 days
    autoSaveInterval: const Duration(seconds: 10), // Save every 3 seconds
    maxFileSize: 2 * 1024 * 1024, // 2MB file size limit
  );

  await Future<void>.delayed(const Duration(milliseconds: 100));

  // Add some sample logs
  for (var i = 0; i < 50; i++) {
    dailyHistory.add(
      ISpectifyData(
        'Sample log entry $i',
        key: 'sample',
        additionalData: {'index': i, 'type': 'basic_demo'},
      ),
    );
  }

  await dailyHistory.saveToDailyFile();

  final stats = await dailyHistory.getSessionStatistics();
  print('📊 Configuration applied:');
  print('  • Max session days: ${stats.maxSessionDays}');
  print('  • Auto-save interval: ${stats.autoSaveInterval.inSeconds}s');
  print(
    '  • Max file size: ${(stats.maxFileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
  );
  print('  • Cleanup strategy: ${stats.cleanupStrategy.name}');
  print('  • Current entries: ${stats.totalEntries}');

  dailyHistory.dispose();
}

/// Demonstrates different cleanup strategies
Future<void> _demonstrateCleanupStrategies() async {
  print('\n🧹 2. Cleanup Strategies Comparison');

  final strategies = [
    SessionCleanupStrategy.deleteOldest,
    SessionCleanupStrategy.deleteBySize,
  ];

  for (final strategy in strategies) {
    print('\n🔄 Testing ${strategy.name} strategy:');

    final history = DailyFileLogHistory(
      ISpectifyOptions(maxHistoryItems: 100),
      maxSessionDays: 2, // Very low limit to trigger cleanup
      sessionCleanupStrategy: strategy,
      enableAutoSave: false, // Disable for controlled testing
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Add test entries
    for (var i = 0; i < 10; i++) {
      history.add(
        ISpectifyData(
          'Test entry for ${strategy.name} strategy',
          key: 'cleanup_test',
          additionalData: {'strategy': strategy.name, 'index': i},
        ),
      );
    }

    await history.saveToDailyFile();

    final stats = await history.getSessionStatistics();
    print(
      '  📊 Result: ${stats.totalDays} files, ${stats.totalEntries} entries',
    );

    history.dispose();
  }
}

/// Demonstrates file size limits and rotation
Future<void> _demonstrateFileSizeLimits() async {
  print('\n📁 3. File Size Limits and Rotation');

  // Create history with very small file size limit for demonstration
  final history = DailyFileLogHistory(
    ISpectifyOptions(maxHistoryItems: 1000),
    maxFileSize: 1024, // 1KB limit to trigger rotation quickly
    enableAutoSave: false,
  );

  await Future<void>.delayed(const Duration(milliseconds: 100));

  print('🔧 Adding large entries to trigger file rotation...');

  // Add entries with large data to exceed size limit
  for (var i = 0; i < 20; i++) {
    history.add(
      ISpectifyData(
        'Large entry with lots of data: ${'x' * 100}',
        key: 'size_test',
        additionalData: {
          'index': i,
          'largeData': 'x' * 200, // Make entries large
        },
      ),
    );
  }

  await history.saveToDailyFile();

  final stats = await history.getSessionStatistics();
  print('✅ File rotation handling completed');
  print('  📊 Total size: ${(stats.totalSize / 1024).toStringAsFixed(1)} KB');
  print('  📊 Total entries: ${stats.totalEntries}');

  history.dispose();
}

/// Demonstrates runtime configuration updates
Future<void> _demonstrateRuntimeUpdates() async {
  print('\n⚙️ 4. Runtime Configuration Updates');

  final history = DailyFileLogHistory(
    ISpectifyOptions(maxHistoryItems: 500),
    autoSaveInterval: const Duration(seconds: 5),
  );

  await Future<void>.delayed(const Duration(milliseconds: 100));

  // Show initial configuration
  final stats = await history.getSessionStatistics();
  print('📋 Initial configuration:');
  print('  • Auto-save: ${stats.enableAutoSave ? 'Enabled' : 'Disabled'}');
  print('  • Interval: ${stats.autoSaveInterval.inSeconds}s');

  // Update auto-save interval
  print('\n🔄 Updating auto-save interval to 10 seconds...');
  history.updateAutoSaveSettings(interval: const Duration(seconds: 10));
  print('✅ Interval updated');

  // Disable auto-save
  print('\n⏸️ Disabling auto-save...');
  history.updateAutoSaveSettings(enabled: false);
  print('✅ Auto-save disabled');

  // Re-enable with new interval
  print('\n▶️ Re-enabling auto-save with 2-second interval...');
  history.updateAutoSaveSettings(
    enabled: true,
    interval: const Duration(seconds: 2),
  );
  print('✅ Auto-save re-enabled');

  // Add some entries to test
  for (var i = 0; i < 5; i++) {
    history.add(
      ISpectifyData(
        'Runtime config test entry $i',
        key: 'runtime_test',
        additionalData: {'index': i},
      ),
    );
  }

  print(
    '📊 Added ${history.history.length} entries with updated configuration',
  );

  history.dispose();
}

/// Demonstrates session statistics monitoring
Future<void> _demonstrateSessionStatistics() async {
  print('\n📈 5. Session Statistics Monitoring');

  final history = DailyFileLogHistory(
    ISpectifyOptions(maxHistoryItems: 1000),
    enableAutoSave: false,
  );

  await Future<void>.delayed(const Duration(milliseconds: 100));

  // Add diverse types of log entries
  final logTypes = ['info', 'warning', 'error', 'debug', 'custom'];

  for (var i = 0; i < 100; i++) {
    final type = logTypes[i % logTypes.length];
    history.add(
      ISpectifyData(
        'Log entry $i of type $type',
        key: type,
        title: type.toUpperCase(),
        additionalData: {
          'index': i,
          'type': type,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  await history.saveToDailyFile();

  // Get comprehensive statistics
  final stats = await history.getSessionStatistics();

  print('📊 Comprehensive Session Statistics:');
  print(stats);

  // Count entries by type
  final typeCounts = <String, int>{};
  for (final entry in history.history) {
    final key = entry.key ?? 'unknown';
    typeCounts[key] = (typeCounts[key] ?? 0) + 1;
  }

  print('📋 Log type distribution:');
  for (final entry in typeCounts.entries) {
    print('  • ${entry.key}: ${entry.value} entries');
  }

  history.dispose();
}
