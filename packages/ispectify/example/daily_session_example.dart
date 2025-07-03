// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ispectify/ispectify.dart';

/// Advanced example demonstrating Daily Session History functionality
/// with automatic secure cache directory and cross-platform support.
///
/// This example showcases the new DailyFileLogHistory implementation that:
/// - Automatically creates secure cache directory (no manual setup needed)
/// - Uses platform-specific cache locations (cleared with app cache)
/// - Provides cross-platform compatibility
/// - Automatically loads today's session on initialization
Future<void> main() async {
  print('🚀 Daily Session History Demo Started');

  // Create daily file history with automatic secure cache directory
  final dailyHistory = DailyFileLogHistory(
    ISpectifyOptions(
      maxHistoryItems: 5000, // Higher limit for daily sessions
    ),
  );

  // Wait for secure directory initialization
  await Future<void>.delayed(const Duration(milliseconds: 100));

  // Get the automatically created secure session directory
  final sessionDir = dailyHistory.sessionDirectory;
  print('📁 Secure session directory: $sessionDir');

  // Create ISpectify instance with daily history
  final iSpectify = ISpectify(
    options: ISpectifyOptions(
      maxHistoryItems: 5000,
    ),
    history: dailyHistory,
  );

  // Note: DailyFileLogHistory automatically loads today's session during initialization
  print("📋 Checking today's session status...");
  final hasToday = await dailyHistory.hasTodaySession();
  if (hasToday) {
    print("✅ Today's session automatically loaded during initialization");
    print('📊 Current entries: ${dailyHistory.history.length}');
  } else {
    print('🆕 No existing session for today, starting fresh');
  }

  // Generate diverse log entries to simulate real app usage
  print('\n🔄 Generating sample logs...');

  // App startup logs
  iSpectify
    ..info('Application started successfully')
    ..debug('Environment: ${Platform.operatingSystem}');

  // User interaction logs
  for (var i = 1; i <= 5; i++) {
    iSpectify.logCustom(
      ISpectifyData(
        'User action $i completed',
        key: 'user_action',
        title: 'User Action',
        additionalData: {
          'actionId': 'action_$i',
          'timestamp': DateTime.now().toIso8601String(),
          'userId': 'user_123',
          'screen': 'home',
        },
      ),
    );

    // Simulate some processing time
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  // API call simulation
  for (var i = 1; i <= 3; i++) {
    iSpectify.logCustom(
      ISpectifyData(
        'API call to /api/data/$i',
        key: 'http-request',
        title: 'HTTP Request',
        additionalData: {
          'method': 'GET',
          'url': '/api/data/$i',
          'statusCode': 200,
          'responseTime': '${50 + i * 10}ms',
        },
      ),
    );
  }

  // Error simulation
  iSpectify
    ..error('Network timeout occurred')
    ..warning('Cache miss for user preferences')

    // Performance tracking
    ..logCustom(
      ISpectifyData(
        'Screen render performance',
        key: 'performance',
        title: 'Performance',
        additionalData: {
          'renderTime': '16.7ms',
          'frameDrops': 0,
          'memoryUsage': '45MB',
        },
      ),
    );

  print('✅ Generated ${dailyHistory.history.length} total log entries');

  // Manual save to demonstrate file operations
  print('\n💾 Performing manual save...');
  await dailyHistory.saveToDailyFile();
  print('✅ Session saved to daily file');

  // Show available log dates
  final availableDates = await dailyHistory.getAvailableLogDates();
  print('\n📅 Available log dates:');
  for (final date in availableDates) {
    final fileSize = await dailyHistory.getDateFileSize(date);
    final fileSizeKB = (fileSize / 1024).toStringAsFixed(1);
    print(
      '  • ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ($fileSizeKB KB)',
    );
  }

  // Export today's session to JSON
  print("\n📤 Exporting today's session...");
  final exportedJson = await dailyHistory.exportToJson();
  final exportFile = File('$sessionDir/exported_session.json');
  await exportFile.writeAsString(exportedJson);
  print('✅ Exported ${exportedJson.length} characters to ${exportFile.path}');

  // Demonstrate loading from different date (simulate loading yesterday's logs)
  print('\n⏮️  Simulating load from yesterday...');
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  // Create some mock data for yesterday
  final yesterdayFile = File(
    '$sessionDir/logs_${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}.json',
  );
  const mockYesterdayData = '''[
    {
      "key": "info",
      "message": "Previous day log entry",
      "time": "2024-01-01T10:00:00.000Z",
      "logLevel": 2,
      "title": "info",
      "pen": null,
      "additionalData": {"source": "yesterday"},
      "exception": null,
      "error": null,
      "stackTrace": null
    }
  ]''';
  await yesterdayFile.writeAsString(mockYesterdayData);

  // Clear current and load yesterday's data
  dailyHistory.clear();
  await dailyHistory.loadFromDate(yesterday);
  print('📊 Loaded ${dailyHistory.history.length} entries from yesterday');

  // Load today's data back
  await dailyHistory.loadTodayHistory();
  print('📊 Reloaded today: ${dailyHistory.history.length} entries');

  // Performance test with large dataset
  print('\n⚡ Performance test: Adding 1000 entries...');
  final startTime = DateTime.now();

  for (var i = 0; i < 1000; i++) {
    iSpectify.logCustom(
      ISpectifyData(
        'Performance test entry $i',
        key: 'perf_test',
        title: 'Performance Test',
        additionalData: {
          'iteration': i,
          'batch': i ~/ 100,
          'testData': 'x' * 50, // Some data to make entries larger
        },
      ),
    );

    // Yield control every 100 entries to prevent blocking
    if (i % 100 == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  final endTime = DateTime.now();
  final duration = endTime.difference(startTime);
  print('✅ Added 1000 entries in ${duration.inMilliseconds}ms');
  print('📊 Total entries now: ${dailyHistory.history.length}');

  // Save performance test results
  print('\n💾 Saving performance test results...');
  final perfStartTime = DateTime.now();
  await dailyHistory.saveToDailyFile();
  final perfEndTime = DateTime.now();
  final saveDuration = perfEndTime.difference(perfStartTime);
  print('✅ Saved in ${saveDuration.inMilliseconds}ms');

  // Display session statistics
  print('\n📈 Session Statistics:');
  final totalEntries = dailyHistory.history.length;
  final todayFileSize = await dailyHistory.getDateFileSize(DateTime.now());
  final fileSizeMB = (todayFileSize / (1024 * 1024)).toStringAsFixed(2);

  print('  • Total entries: $totalEntries');
  print('  • File size: $fileSizeMB MB');
  print('  • Average entry size: ${todayFileSize ~/ totalEntries} bytes');

  // Analyze log types
  final logTypes = <String, int>{};
  for (final entry in dailyHistory.history) {
    final key = entry.key ?? 'unknown';
    logTypes[key] = (logTypes[key] ?? 0) + 1;
  }

  print('  • Log type distribution:');
  for (final entry in logTypes.entries) {
    print('    - ${entry.key}: ${entry.value}');
  }

  // Cleanup demonstration
  print('\n🧹 Cleanup options demo:');
  print('  Available dates before cleanup: ${availableDates.length}');

  // Clean up old sessions (keep only today and yesterday)
  final allDates = await dailyHistory.getAvailableLogDates();
  final cutoffDate = DateTime.now().subtract(const Duration(days: 2));

  for (final date in allDates) {
    if (date.isBefore(cutoffDate)) {
      await dailyHistory.clearDateStorage(date);
      print(
        '  🗑️  Cleaned up logs for ${date.year}-${date.month}-${date.day}',
      );
    }
  }

  print('\n✅ Daily Session History Demo Completed!');
  print('📂 Session files remain in: $sessionDir');
  print('🔄 Auto-save will continue until app shutdown');

  // Cleanup
  await Future<void>.delayed(const Duration(seconds: 2));
  dailyHistory.dispose();
  print('🛑 History disposed, auto-save stopped');
}
