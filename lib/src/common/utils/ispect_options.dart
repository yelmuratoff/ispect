import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

final class ISpectOptions {
  Talker talker;
  ThemeMode themeMode;
  ThemeData lightTheme;
  ThemeData darkTheme;
  Locale locale;

  ISpectOptions({
    required this.talker,
    required this.themeMode,
    required this.lightTheme,
    required this.darkTheme,
    required this.locale,
  });

  ISpectOptions copyWith({
    Talker? talker,
    ThemeMode? themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    Locale? locale,
    bool? isInitialized,
  }) {
    return ISpectOptions(
      talker: talker ?? this.talker,
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      locale: locale ?? this.locale,
    );
  }
}
