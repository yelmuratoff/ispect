import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

void main() {
  group('ISpectScopeModel.theme', () {
    late List<String?> printed;
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      printed = [];
      originalDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message);
    });

    tearDown(() => debugPrint = originalDebugPrint);

    const customIcon = Icons.cloud;
    const theme = ISpectTheme(logIcons: {'custom-key': customIcon});
    const incompleteTheme = ISpectTheme(
      customLogTypes: [ISpectLogType('firebase-read')],
    );

    test('constructor merges default type icons under custom icons', () {
      final model = ISpectScopeModel(theme: theme);
      addTearDown(model.dispose);

      expect(model.theme.logIcons['custom-key'], customIcon);
      for (final entry in ISpectConstants.typeIcons.entries) {
        expect(model.theme.logIcons[entry.key], entry.value);
      }
    });

    test('setter stores the theme merged with default type icons', () {
      final model = ISpectScopeModel();
      addTearDown(model.dispose);

      model.theme = theme;

      expect(model.theme, isNot(same(theme)));
      expect(model.theme.logIcons['custom-key'], customIcon);
      for (final entry in ISpectConstants.typeIcons.entries) {
        expect(model.theme.logIcons[entry.key], entry.value);
      }
    });

    test('setter notifies only when the merged theme changes', () {
      final model = ISpectScopeModel(theme: theme);
      addTearDown(model.dispose);
      var notifications = 0;
      model
        ..addListener(() => notifications++)
        ..theme = theme;

      expect(notifications, 0);

      model.theme = const ISpectTheme(themeMode: ISpectThemeMode.light);

      expect(notifications, 1);
    });

    test('constructor and setter both report theme validation warnings', () {
      final model = ISpectScopeModel(theme: incompleteTheme);
      addTearDown(model.dispose);
      final constructorWarnings = printed.toList();
      printed.clear();

      model.theme = incompleteTheme;

      expect(constructorWarnings, isNotEmpty);
      expect(printed, constructorWarnings);
      expect(printed.first, startsWith('[ISpect] '));
    });
  });
}
