// ignore_for_file: avoid_print

import 'package:ispectify/ispectify.dart';

/// Quick test to verify DailyFileLogHistory works correctly
Future<void> main() async {
  print('🧪 Testing DailyFileLogHistory...');

  // Create instance with automatic secure cache
  final dailyHistory = DailyFileLogHistory(
    ISpectifyOptions(
      maxHistoryItems: 100,
    ),
  );

  // Wait for initialization
  await Future<void>.delayed(const Duration(milliseconds: 100));

  print('📁 Cache directory: ${dailyHistory.sessionDirectory}');
  print('📊 Initial entries: ${dailyHistory.history.length}');

  // Add some test entries
  for (var i = 1; i <= 10; i++) {
    dailyHistory.add(
      ISpectifyData(
        'Test entry $i',
        time: DateTime.now(),
        logLevel: LogLevel.info,
        key: 'test',
      ),
    );
  }

  print('📊 After adding 10 entries: ${dailyHistory.history.length}');

  // Save manually
  await dailyHistory.saveToDailyFile();
  print('💾 Manual save completed');

  // Check available dates
  final dates = await dailyHistory.getAvailableLogDates();
  print('📅 Available dates: ${dates.length}');

  // Check file size
  final fileSize = await dailyHistory.getDateFileSize(DateTime.now());
  print("📁 Today's file size: $fileSize bytes");

  print('✅ Test completed successfully!');

  dailyHistory.dispose();
}
