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
