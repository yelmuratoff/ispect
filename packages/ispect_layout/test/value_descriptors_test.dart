import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/value_descriptors.dart';

void main() {
  test(
    'describes a mode color filter without accessing private SDK fields',
    () {
      expect(
        describeColorFilter(
          const ColorFilter.mode(Color(0xFF112233), BlendMode.srcIn),
        ),
        contains('srcIn'),
      );
    },
  );

  test(
    'describes image filters after validating the private-field contract',
    () {
      expect(
        describeImageFilter(ImageFilter.blur(sigmaX: 1, sigmaY: 2)),
        'blur(1.0, 2.0)',
      );
      expect(
        describeImageFilter(ImageFilter.dilate(radiusX: 3, radiusY: 4)),
        'dilate(3.0, 4.0)',
      );
    },
  );

  test('alignment preserves hundredths instead of inventing a tenth', () {
    expect(describeAlignment(const Alignment(0.25, -0.25)), '(0.25, -0.25)');
  });

  test('alignment honors an explicit precision override', () {
    expect(
      describeAlignment(const Alignment(0.25, -0.25), decimalPlaces: 1),
      '(0.3, -0.3)',
    );
  });
}
