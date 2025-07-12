/// Example usage of the refactored DailyFileLogHistory
///
/// This demonstrates how to use the simplified constructor with automatic
/// secure cache directory and session management.
library;

// ignore_for_file: avoid_print

import 'package:ispectify/ispectify.dart';

void main() async {
  // ========================================
  // NEW SIMPLIFIED USAGE WITH SECURE CACHE
  // ========================================

  // Create history with automatic secure cache directory
  final history = DailyFileLogHistory(
    ISpectifyOptions(
      maxHistoryItems: 1000,
    ),
    // NO NEED TO SPECIFY DIRECTORY - it's automatically created in secure cache!
    autoSaveInterval: const Duration(seconds: 30), // Optional, defaults to 30s
  );

  // That's it! The history will:
  // 1. Automatically create secure cache directory
  // 2. Load today's logs on creation (async)
  // 3. Start auto-saving every 30 seconds
  // 4. Organize logs by date in files like: logs_2025-07-03.json
  // 5. Be cleared when user clears app cache
  // 6. Be secure and inaccessible to user directly

  // ========================================
  // SECURE CACHE DIRECTORY LOCATIONS
  // ========================================

  // The cache directory is automatically created in:
  // - macOS: ~/Library/Caches/ispectify/ispectify_logs/
  // - Windows: %LOCALAPPDATA%/ispectify/cache/ispectify_logs/
  // - Linux: ~/.cache/ispectify/ispectify_logs/
  // - Mobile: System temp directory with app-specific subfolder

  // Wait for initialization to complete before using
  await Future<void>.delayed(const Duration(milliseconds: 100));

  // ========================================
  // USAGE EXAMPLES
  // ========================================

  // Add logs - they will be automatically saved
  history.add(
    ISpectifyData(
      'Application started',
      time: DateTime.now(),
      logLevel: LogLevel.info,
    ),
  );

  // Get available log dates (waits for initialization)
  final availableDates = await history.getAvailableLogDates();
  print('Available log dates: $availableDates');

  // Load logs from a specific date
  await history.loadFromDate(DateTime(2025, 7, 2));

  // Export current history to JSON
  final jsonExport = await history.exportToJson();
  print('Exported ${jsonExport.length} characters');

  // Clear logs for a specific date
  await history.clearDateStorage(DateTime(2025, 7));

  // Get file size for a specific date
  final fileSize = await history.getDateFileSize(DateTime.now());
  print("Today's log file size: $fileSize bytes");

  // Check if today has any logs
  final hasTodayLogs = await history.hasTodaySession();
  print("Has today's logs: $hasTodayLogs");

  // Get secure cache directory path
  final cacheDir = history.sessionDirectory;
  print('Secure cache directory: $cacheDir');

  // ========================================
  // CLEANUP
  // ========================================

  // When you're done, dispose to clean up resources
  history.dispose();

  // ========================================
  // MIGRATION FROM OLD CODE
  // ========================================

  // OLD WAY (manual directory setup):
  // final history = DailyFileLogHistory(settings, '/path/to/logs');

  // NEW WAY (automatic secure cache):
  // final history = DailyFileLogHistory(settings);

  // Benefits:
  // ✅ No need to specify directory path
  // ✅ Secure cache directory automatically created
  // ✅ Cross-platform compatible
  // ✅ Cleared when user clears app cache
  // ✅ Inaccessible to user directly
  // ✅ Proper permissions handling
}
