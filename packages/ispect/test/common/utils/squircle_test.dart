import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

void main() {
  group('ISpectSquircle.border', () {
    test('keeps the logical radius as the corner radius', () {
      final border = ISpectSquircle.border(radius: 10);

      expect(border.borderRadius, const BorderRadius.all(Radius.circular(10)));
    });

    test('defaults to the card border radius when none is given', () {
      final border = ISpectSquircle.border();

      expect(
        border.borderRadius,
        const BorderRadius.all(
          Radius.circular(ISpectConstants.cardBorderRadius),
        ),
      );
    });

    test('applies the provided side', () {
      const side = BorderSide(color: Color(0xFF123456), width: 1.5);

      final border = ISpectSquircle.border(side: side);

      expect(border.side, side);
    });
  });

  group('ISpectSquircle.decoration', () {
    test('builds a ShapeDecoration with the squircle shape', () {
      final decoration = ISpectSquircle.decoration(
        color: const Color(0xFF222222),
        radius: 8,
      );

      final shape = decoration.shape as RoundedSuperellipseBorder;
      expect(decoration.color, const Color(0xFF222222));
      expect(shape.borderRadius, const BorderRadius.all(Radius.circular(8)));
    });

    test('passes shadows through to the ShapeDecoration', () {
      const shadows = [BoxShadow(blurRadius: 4)];

      final decoration = ISpectSquircle.decoration(shadows: shadows);

      expect(decoration.shadows, shadows);
    });
  });

  group('ISpectSquircle.inputBorder', () {
    test('carries the radius and reports as an outline border', () {
      final border = ISpectSquircle.inputBorder(radius: 10);

      expect(border.isOutline, isTrue);
      expect(border.borderRadius, const BorderRadius.all(Radius.circular(10)));
    });

    test('applies the side', () {
      const side = BorderSide(color: Color(0xFF112233), width: 1.2);

      final border = ISpectSquircle.inputBorder(side: side);

      expect(border.borderSide, side);
    });

    test('equal borders compare equal (drives InputDecoration equality)', () {
      expect(
        ISpectSquircle.inputBorder(radius: 8),
        ISpectSquircle.inputBorder(radius: 8),
      );
    });

    test('copyWith overrides only the given field', () {
      const side = BorderSide(color: Color(0xFFFF0000));

      final border = ISpectSquircle.inputBorder(
        radius: 10,
      ).copyWith(borderSide: side);

      expect(border.borderSide, side);
      expect(border.borderRadius, const BorderRadius.all(Radius.circular(10)));
    });
  });
}
