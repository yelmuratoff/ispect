// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:ispect/src/features/snapshot/src/theme/feedback_theme.dart';
import 'package:ispect/src/features/snapshot/src/utilities/media_query_from_window.dart';

class FeedbackApp extends StatelessWidget {
  const FeedbackApp({
    required this.child,
    super.key,
    this.themeMode,
    this.theme,
    this.darkTheme,
    this.localizationsDelegates,
    this.localeOverride,
  });

  final Widget child;
  final ThemeMode? themeMode;
  final FeedbackThemeData? theme;
  final FeedbackThemeData? darkTheme;
  final List<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final Locale? localeOverride;

  FeedbackThemeData _buildThemeData(BuildContext context) {
    final mode = themeMode ?? ThemeMode.system;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final useDarkMode = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && brightness == Brightness.dark);
    FeedbackThemeData? themeData;

    if (useDarkMode && darkTheme != null) {
      themeData = darkTheme;
    } else if (useDarkMode && theme == null) {
      themeData = FeedbackThemeData.dark();
    }

    // ignore: join_return_with_assignment
    themeData ??= theme ?? FeedbackThemeData.light();

    return themeData;
  }

  @override
  Widget build(BuildContext context) {
    final themeWrapper = FeedbackTheme(
      data: _buildThemeData(context),
      child: child,
    );

    Widget mediaQueryWrapper;

    /// Don't replace existing MediaQuery widget if it exists.
    if (MediaQuery.maybeOf(context) == null) {
      mediaQueryWrapper = MediaQueryFromWindow(child: themeWrapper);
    } else {
      mediaQueryWrapper = themeWrapper;
    }

    return mediaQueryWrapper;
  }
}
