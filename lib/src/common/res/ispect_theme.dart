import 'dart:ui';

class ISpectTheme {
  const ISpectTheme({
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightCardColor,
    this.darkCardColor,
    this.lightDividerColor,
    this.darkDividerColor,
  });

  final Color? lightBackgroundColor;
  final Color? darkBackgroundColor;

  final Color? lightCardColor;
  final Color? darkCardColor;

  final Color? lightDividerColor;
  final Color? darkDividerColor;

  ISpectTheme copyWith({
    Color? lightBackgroundColor,
    Color? darkBackgroundColor,
    Color? lightCardColor,
    Color? darkCardColor,
    Color? lightDividerColor,
    Color? darkDividerColor,
  }) =>
      ISpectTheme(
        lightBackgroundColor: lightBackgroundColor ?? this.lightBackgroundColor,
        darkBackgroundColor: darkBackgroundColor ?? this.darkBackgroundColor,
        lightCardColor: lightCardColor ?? this.lightCardColor,
        darkCardColor: darkCardColor ?? this.darkCardColor,
        lightDividerColor: lightDividerColor ?? this.lightDividerColor,
        darkDividerColor: darkDividerColor ?? this.darkDividerColor,
      );

  Color? backgroundColor({required bool isDark}) => isDark ? darkBackgroundColor : lightBackgroundColor;

  Color? cardColor({required bool isDark}) => isDark ? darkCardColor : lightCardColor;

  Color? dividerColor({required bool isDark}) => isDark ? darkDividerColor : lightDividerColor;
}
