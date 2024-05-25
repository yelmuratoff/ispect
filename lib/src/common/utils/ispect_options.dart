import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

final class ISpectOptions {
  final ThemeMode themeMode;
  final Locale locale;

  const ISpectOptions({
    required this.themeMode,
    required this.locale,
  });

  ISpectOptions copyWith({
    Talker? talker,
    ThemeMode? themeMode,
    Locale? locale,
    bool? isInitialized,
  }) =>
      ISpectOptions(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
      );
}
