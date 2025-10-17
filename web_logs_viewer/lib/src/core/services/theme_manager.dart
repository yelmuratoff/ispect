import 'package:flutter/material.dart';

class ThemeProvider extends StatefulWidget {
  final Widget child;

  const ThemeProvider({super.key, required this.child});

  @override
  State createState() => _ThemeProviderState();

  static ThemeMode themeMode(BuildContext context) {
    final inheritedTheme = context
        .dependOnInheritedWidgetOfExactType<InheritedTheme>();
    return inheritedTheme!.themeMode;
  }

  static void toggleTheme(BuildContext context) {
    final inheritedTheme = context
        .dependOnInheritedWidgetOfExactType<InheritedTheme>();
    inheritedTheme!.toggleTheme();
  }
}

class _ThemeProviderState extends State<ThemeProvider> {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedTheme(
      themeMode: _themeMode,
      toggleTheme: toggleTheme,
      child: widget.child,
    );
  }
}

class InheritedTheme extends InheritedWidget {
  final ThemeMode themeMode;
  final VoidCallback toggleTheme;

  const InheritedTheme({
    super.key,
    required this.themeMode,
    required this.toggleTheme,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedTheme oldWidget) =>
      oldWidget.themeMode != themeMode;
}
