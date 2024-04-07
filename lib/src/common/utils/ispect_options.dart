import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_controller.dart';
import 'package:talker_flutter/talker_flutter.dart';

final class ISpectOptions {
  final Talker talker;
  final ThemeMode themeMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final Locale locale;
  final ISpectController controller;
  final bool isInitialized;

  const ISpectOptions({
    required this.talker,
    required this.themeMode,
    required this.lightTheme,
    required this.darkTheme,
    required this.locale,
    required this.controller,
    this.isInitialized = false,
  });

  ISpectOptions copyWith({
    Talker? talker,
    ThemeMode? themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    Locale? locale,
    ISpectController? controller,
    bool? isInitialized,
  }) {
    return ISpectOptions(
      talker: talker ?? this.talker,
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      locale: locale ?? this.locale,
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
