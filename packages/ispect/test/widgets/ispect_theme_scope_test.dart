import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/core/res/ispect_default_palette.dart';

void main() {
  group('ISpectThemeScope', () {
    Future<ThemeData> pumpAndReadTheme(
      WidgetTester tester, {
      required ISpectTheme theme,
      required ThemeData hostTheme,
    }) async {
      late ThemeData injected;
      await tester.pumpWidget(
        ISpectScopeController(
          model: ISpectScopeModel(isISpectEnabled: true, theme: theme),
          child: MaterialApp(
            theme: hostTheme,
            localizationsDelegates: ISpectLocalization.localizationDelegates,
            supportedLocales: ISpectLocalization.supportedLocales,
            home: Scaffold(
              body: ISpectThemeScope(
                child: Builder(
                  builder: (context) {
                    injected = Theme.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      return injected;
    }

    testWidgets('injects the owned dark theme by default over a light host',
        (tester) async {
      final injected = await pumpAndReadTheme(
        tester,
        theme: const ISpectTheme(),
        hostTheme: ThemeData.light(),
      );

      expect(injected.brightness, Brightness.dark);
      expect(
        injected.colorScheme.surface,
        ISpectDefaultPalette.background.dark,
      );
      expect(injected.colorScheme.primary, ISpectDefaultPalette.primary.dark);
    });

    testWidgets('renders the owned light variant when themeMode is light',
        (tester) async {
      final injected = await pumpAndReadTheme(
        tester,
        theme: const ISpectTheme(themeMode: ISpectThemeMode.light),
        hostTheme: ThemeData.dark(),
      );

      expect(injected.brightness, Brightness.light);
      expect(
        injected.colorScheme.surface,
        ISpectDefaultPalette.background.light,
      );
    });

    testWidgets('passes the host theme through when useHostColors is set',
        (tester) async {
      final host = ThemeData.light();
      final injected = await pumpAndReadTheme(
        tester,
        theme: const ISpectTheme(useHostColors: true),
        hostTheme: host,
      );

      expect(injected.brightness, Brightness.light);
      expect(injected.colorScheme.surface, host.colorScheme.surface);
    });
  });
}
