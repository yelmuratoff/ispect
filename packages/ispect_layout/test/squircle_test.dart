import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/squircle.dart';

void main() {
  group('InspectorSquircle', () {
    test('border scales the logical radius by the squircle scale factor', () {
      final border = InspectorSquircle.border(radius: 10);

      expect(
        border.borderRadius,
        const BorderRadius.all(Radius.circular(10 * InspectorSquircle.scale)),
      );
    });

    test('border applies the provided side', () {
      const side = BorderSide(color: Color(0xFF123456), width: 1.5);

      final border = InspectorSquircle.border(side: side);

      expect(border.side, side);
    });

    test('decoration builds a ShapeDecoration with a scaled squircle shape',
        () {
      final decoration = InspectorSquircle.decoration(
        color: const Color(0xFF222222),
        radius: 8,
      );

      final shape = decoration.shape as ContinuousRectangleBorder;
      expect(decoration.color, const Color(0xFF222222));
      expect(
        shape.borderRadius,
        const BorderRadius.all(Radius.circular(8 * InspectorSquircle.scale)),
      );
    });

    test('scale matches ISpect so the two packages stay visually in sync', () {
      // Guards the deliberate ISpectSquircle/InspectorSquircle duplication from
      // drifting apart — keep equal to ISpectSquircle.scale.
      expect(InspectorSquircle.scale, 2);
    });
  });
}
