import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/core/res/ispect_theme_data.dart';

ShapeBorder? _shapeOf(WidgetStateProperty<OutlinedBorder?>? property) =>
    property?.resolve({});

void main() {
  group('buildISpectThemeData', () {
    final theme = buildISpectThemeData(dark: true);

    test('every button shape is a squircle', () {
      expect(
        _shapeOf(theme.filledButtonTheme.style?.shape),
        isA<RoundedSuperellipseBorder>(),
      );
      expect(
        _shapeOf(theme.elevatedButtonTheme.style?.shape),
        isA<RoundedSuperellipseBorder>(),
      );
      expect(
        _shapeOf(theme.textButtonTheme.style?.shape),
        isA<RoundedSuperellipseBorder>(),
      );
      expect(
        _shapeOf(theme.outlinedButtonTheme.style?.shape),
        isA<RoundedSuperellipseBorder>(),
      );
      expect(
        _shapeOf(theme.iconButtonTheme.style?.shape),
        isA<RoundedSuperellipseBorder>(),
      );
      expect(
        _shapeOf(theme.segmentedButtonTheme.style?.shape),
        isA<RoundedSuperellipseBorder>(),
      );
    });

    test('every surface shape is a squircle', () {
      expect(theme.cardTheme.shape, isA<RoundedSuperellipseBorder>());
      expect(theme.dialogTheme.shape, isA<RoundedSuperellipseBorder>());
      expect(theme.bottomSheetTheme.shape, isA<RoundedSuperellipseBorder>());
      expect(theme.popupMenuTheme.shape, isA<RoundedSuperellipseBorder>());
      expect(theme.snackBarTheme.shape, isA<RoundedSuperellipseBorder>());
      expect(theme.listTileTheme.shape, isA<RoundedSuperellipseBorder>());
      expect(theme.chipTheme.shape, isA<RoundedSuperellipseBorder>());
      expect(theme.expansionTileTheme.shape, isA<RoundedSuperellipseBorder>());
      expect(
        _shapeOf(theme.menuTheme.style?.shape),
        isA<RoundedSuperellipseBorder>(),
      );
    });

    test('the tooltip is a squircle rather than Material default', () {
      final decoration = theme.tooltipTheme.decoration! as ShapeDecoration;

      expect(decoration.shape, isA<RoundedSuperellipseBorder>());
    });

    test('the light variant carries the same shapes', () {
      final light = buildISpectThemeData(dark: false);

      expect(light.cardTheme.shape, theme.cardTheme.shape);
      expect(light.dialogTheme.shape, theme.dialogTheme.shape);
      expect(
        _shapeOf(light.iconButtonTheme.style?.shape),
        _shapeOf(theme.iconButtonTheme.style?.shape),
      );
    });
  });
}
