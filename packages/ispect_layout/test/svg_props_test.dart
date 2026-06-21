import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';
import 'package:ispect_layout/src/widgets/components/svg_props.dart';

PropSpec? _propBySubtitle(List<PropSpec> props, String subtitle) {
  for (final p in props) {
    if (p.subtitle == subtitle) return p;
  }
  return null;
}

String? _textOf(Widget? child) {
  if (child is EllipsizedText) return child.value;
  if (child is Text) return child.data;
  return null;
}

void main() {
  group('svgProps', () {
    test('reads asset source, fit, and color filter', () {
      const svg = SvgPicture(
        bytesLoader: SvgAssetLoader('assets/logo.svg'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(Color(0xFF112233), BlendMode.srcIn),
      );

      final props = svgProps(svg);

      expect(
        _textOf(_propBySubtitle(props, 'source')?.child),
        'assets/logo.svg',
      );
      expect(_textOf(_propBySubtitle(props, 'fit')?.child), 'cover');
      expect(
        _textOf(_propBySubtitle(props, 'color filter')?.child),
        contains('mode'),
      );
    });

    test('prefixes packaged asset names', () {
      const svg = SvgPicture(
        bytesLoader: SvgAssetLoader('icons/x.svg', packageName: 'design'),
      );

      expect(
        _textOf(_propBySubtitle(svgProps(svg), 'source')?.child),
        'packages/design/icons/x.svg',
      );
    });

    test('reads network source', () {
      const svg = SvgPicture(bytesLoader: SvgNetworkLoader('https://x/y.svg'));

      expect(
        _textOf(_propBySubtitle(svgProps(svg), 'source')?.child),
        'https://x/y.svg',
      );
    });

    test('falls back to the loader type name for inline sources', () {
      const svg = SvgPicture(bytesLoader: SvgStringLoader());

      expect(
        _textOf(_propBySubtitle(svgProps(svg), 'source')?.child),
        'SvgStringLoader',
      );
    });

    test('returns no props for a widget without the SvgPicture shape', () {
      expect(svgProps(const SizedBox()), isEmpty);
    });
  });

  group('resolveSvgPicture', () {
    testWidgets('recovers an SvgPicture from the creator chain',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SvgPicture(
            bytesLoader: SvgAssetLoader('assets/logo.svg'),
            child: SizedBox(key: ValueKey('svg-leaf'), width: 24, height: 24),
          ),
        ),
      );

      final render = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('svg-leaf')),
      );
      final svg = resolveSvgPicture(render);

      expect(svg.runtimeType.toString(), 'SvgPicture');
    });

    testWidgets('returns null when no SvgPicture is in the chain',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(key: ValueKey('plain'), width: 10, height: 10),
        ),
      );

      final render = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('plain')),
      );

      expect(resolveSvgPicture(render), isNull);
    });
  });
}

/// Structural stand-in for flutter_svg's `SvgPicture`. [svgProps] and
/// [resolveSvgPicture] match by runtime type *name* and read fields by duck
/// typing — never by import — so a fake with the same name and field shape
/// exercises the real production code paths.
class SvgPicture extends StatelessWidget {
  const SvgPicture({
    super.key,
    this.bytesLoader,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.colorFilter,
    this.width,
    this.height,
    this.child = const SizedBox(),
  });

  final Object? bytesLoader;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final ColorFilter? colorFilter;
  final double? width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class SvgAssetLoader {
  const SvgAssetLoader(this.assetName, {this.packageName});

  final String assetName;
  final String? packageName;
}

class SvgNetworkLoader {
  const SvgNetworkLoader(this.url);

  final String url;
}

class SvgStringLoader {
  const SvgStringLoader();
}
