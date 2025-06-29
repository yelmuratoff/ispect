import 'dart:developer';
import 'dart:io';

import 'package:ispectify/ispectify.dart';

/// Example demonstrating Session History functionality with file persistence.
Future<void> main() async {
  // Create session history with file support
  final sessionHistory = DefaultFileLogHistory(
    ISpectifyOptions(
      maxHistoryItems: 1000,
    ),
  );

  // Enable auto-save to application documents directory
  final documentsDir =
      Directory('/tmp/ispectify_sessions'); // For demo purposes
  await documentsDir.create(recursive: true);

  sessionHistory.enableAutoSave(
    documentsDir.path,
    interval: const Duration(seconds: 30),
  );

  // Create ISpectify instance with session history
  final iSpectify = ISpectify(
    options: ISpectifyOptions(
      maxHistoryItems: 1000,
    ),
    history: sessionHistory,
  )

    // Generate some test logs
    ..info('Session started')
    ..debug('Debug information')
    ..warning('Warning message')
    ..error('Error occurred')

    // Custom log
    ..logCustom(
      ISpectifyData(
        'Custom log entry',
        key: 'custom',
        title: 'Custom',
        additionalData: {
          'userId': 'user123',
          'sessionId': 'session456',
          'feature': 'payment',
        },
      ),
    );

  log('Generated ${iSpectify.history.length} log entries');

  // Manual save to specific file
  final sessionFile = File('${documentsDir.path}/manual_session.json');
  await sessionHistory.saveToFile(sessionFile.path);
  log('Session saved to: ${sessionFile.path}');

  // Export to JSON string
  final jsonString = await sessionHistory.exportToJson();
  log('JSON export length: ${jsonString.length} characters');

  // Clear current history
  sessionHistory.clear();
  log('History cleared. Current entries: ${iSpectify.history.length}');

  // Load from file
  await sessionHistory.loadFromFile(sessionFile.path);
  log('History loaded from file. Current entries: ${iSpectify.history.length}');

  // Import from JSON string
  sessionHistory.clear();
  await sessionHistory.importFromJson(jsonString);
  log('History imported from JSON. Current entries: ${iSpectify.history.length}');

  // Display loaded history
  log('\n--- Loaded Session History ---');
  for (var i = 0; i < iSpectify.history.length; i++) {
    final entry = iSpectify.history[i];
    log('[$i] ${entry.formattedTime} - ${entry.title}: ${entry.message}');
    if (entry.additionalData != null) {
      log('    Additional data: ${entry.additionalData}');
    }
  }

  // Cleanup
  sessionHistory.disableAutoSave();
  await sessionHistory.clearFileStorage();

  log('\nSession History demo completed!');
}
