/// Example: SharedPreferences interceptor with real package.
///
/// Requires Flutter context. Use in a Flutter app or test:
/// ```dart
/// SharedPreferences.setMockInitialValues({});
/// await sharedPreferencesExample();
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/shared_preferences_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> sharedPreferencesExample() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig();

  final realPrefs = await SharedPreferences.getInstance();
  final prefs = ISpectSharedPreferences(delegate: realPrefs, logger: logger);

  // Write
  await prefs.setString('theme', 'dark');
  await prefs.setBool('onboarding_done', true);
  await prefs.setInt('launch_count', 42);
  await prefs.setDouble('volume', 0.8);
  await prefs.setStringList('recent_searches', ['flutter', 'dart']);

  // Read
  logger
    ..info('Theme: ${prefs.getString('theme')}')
    ..info('Onboarding done: ${prefs.getBool('onboarding_done')}')
    ..info(
      'All keys: ${prefs.getKeys()}, has theme: ${prefs.containsKey('theme')}',
    );

  // Remove & clear
  await prefs.remove('recent_searches');
  await prefs.clear();
}
