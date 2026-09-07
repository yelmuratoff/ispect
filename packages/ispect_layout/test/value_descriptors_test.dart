import 'dart:typed_data';
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

  test('image filters describe structurally, independent of toString', () {
    expect(
      describeImageFilter(
        ImageFilter.blur(sigmaX: 1, sigmaY: 2, tileMode: TileMode.mirror),
      ),
      'blur(1.0, 2.0, mirror)',
    );
    expect(
      describeImageFilter(
        ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          inner: ImageFilter.dilate(radiusX: 2, radiusY: 2),
        ),
      ),
      'compose(dilate(2.0, 2.0) → blur(1.0, 1.0))',
    );
    expect(
      describeImageFilter(
        ImageFilter.matrix(_identity4x4, filterQuality: FilterQuality.high),
      ),
      'matrix([1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, '
      '0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0], high)',
    );
  });

  group('describeImageFilterConfig', () {
    test('delegates to a directly wrapped image filter', () {
      expect(
        describeImageFilterConfig(
          _DirectConfig(ImageFilter.blur(sigmaX: 1, sigmaY: 2)),
        ),
        'blur(1.0, 2.0)',
      );
    });

    test('describes a blur config with tile mode and bounds', () {
      expect(
        describeImageFilterConfig(
          const _BlurConfig(sigmaX: 2, sigmaY: 3, bounded: true),
        ),
        'blur(2.0, 3.0, clamp, bounded)',
      );
    });

    test('describes a compose config recursively', () {
      expect(
        describeImageFilterConfig(
          const _ComposeConfig(
            outer: _BlurConfig(sigmaX: 1, sigmaY: 1),
            inner: _BlurConfig(sigmaX: 4, sigmaY: 4),
          ),
        ),
        'compose(blur(4.0, 4.0, clamp) → blur(1.0, 1.0, clamp))',
      );
    });

    test('falls back to the type name for an unknown shape', () {
      expect(describeImageFilterConfig(const Object()), 'Object');
    });
  });

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

final Float64List _identity4x4 = Float64List(16)
  ..[0] = 1
  ..[5] = 1
  ..[10] = 1
  ..[15] = 1;

/// Stand-ins shaped like Flutter 3.40's private `ImageFilterConfig`
/// subclasses; [describeImageFilterConfig] reads them by duck typing.
class _DirectConfig {
  const _DirectConfig(this.filter);
  final ImageFilter filter;
}

class _BlurConfig {
  const _BlurConfig({
    required this.sigmaX,
    required this.sigmaY,
    this.bounded = false,
  });

  final double sigmaX;
  final double sigmaY;
  final bool bounded;
  TileMode get tileMode => TileMode.clamp;
}

class _ComposeConfig {
  const _ComposeConfig({required this.outer, required this.inner});
  final Object outer;
  final Object inner;
}
