/// Example: SharedPreferences interceptor with real package.
///
/// Requires Flutter context. Use in a Flutter app or test:
/// ```dart
/// SharedPreferences.setMockInitialValues({});
/// await sharedPreferencesExample();
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db_example/interceptors/shared_preferences_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> sharedPreferencesExample() async {
  final logger = ISpectLogger();

  final realPrefs = await SharedPreferences.getInstance();
  final prefs = ISpectSharedPreferences(delegate: realPrefs, logger: logger);

  // Write user preferences
  await prefs.setString('user_theme', 'dark');
  await prefs.setBool('user_onboarding_done', true);

  // Write feature flags
  await prefs.setBool('flag_new_ui', true);
  await prefs.setDouble('analytics_sample_rate', 0.5);

  // Write app state
  await prefs.setInt('app_launch_count', 42);
  await prefs.setStringList('app_recent_searches', ['flutter', 'dart']);

  // Read
  logger.info(
    'All keys: ${prefs.getKeys()}, has theme: ${prefs.containsKey('user_theme')}',
  );

  // Remove & clear
  await prefs.remove('app_recent_searches');
  await prefs.clear();
}
