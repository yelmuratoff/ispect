import 'dart:ui';

class ISpectTheme {
  const ISpectTheme({
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightDividerColor,
    this.darkDividerColor,
  });

  final Color? lightBackgroundColor;
  final Color? darkBackgroundColor;

  final Color? lightDividerColor;
  final Color? darkDividerColor;

  ISpectTheme copyWith({
    Color? lightBackgroundColor,
    Color? darkBackgroundColor,
    Color? lightDividerColor,
    Color? darkDividerColor,
  }) =>
      ISpectTheme(
        lightBackgroundColor: lightBackgroundColor ?? this.lightBackgroundColor,
        darkBackgroundColor: darkBackgroundColor ?? this.darkBackgroundColor,
        lightDividerColor: lightDividerColor ?? this.lightDividerColor,
        darkDividerColor: darkDividerColor ?? this.darkDividerColor,
      );

  Color? backgroundColor({required bool isDark}) =>
      isDark ? darkBackgroundColor : lightBackgroundColor;

  Color? dividerColor({required bool isDark}) =>
      isDark ? darkDividerColor : lightDividerColor;
}
