import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/property_extractors.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';

PropSpec? _prop(List<PropSpec> props, String subtitle) {
  for (final prop in props) {
    if (prop.subtitle == subtitle) return prop;
  }
  return null;
}

String? _text(PropSpec? prop) => switch (prop?.child) {
  Text(:final data) => data,
  _ => null,
};

void main() {
  test(
    'center-sliced decoration image reports Flutter default BoxFit.fill',
    () {
      final props = decorationProps(
        const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('nine-patch.png'),
            centerSlice: Rect.fromLTWH(2, 2, 4, 4),
          ),
        ),
      );

      expect(_text(_prop(props, 'bg fit')), 'fill');
    },
  );

  test('BorderDirectional exposes its active semantic sides', () {
    final props = decorationProps(
      const BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: Color(0xFF112233), width: 2),
          end: BorderSide(color: Color(0xFF445566), width: 3),
        ),
      ),
    );

    expect(_prop(props, 'border start'), isNotNull);
    expect(_prop(props, 'border end'), isNotNull);
  });

  test('Flex exposes spacing, direction, baseline, and clipping', () {
    final props = flexProps(
      RenderFlex(
        spacing: 2.25,
        textDirection: TextDirection.rtl,
        textBaseline: TextBaseline.ideographic,
        clipBehavior: Clip.hardEdge,
      ),
      decimalPlaces: 2,
    );

    expect(_text(_prop(props, 'spacing')), '2.25');
    expect(_text(_prop(props, 'text direction')), 'rtl');
    expect(_text(_prop(props, 'text baseline')), 'ideographic');
    expect(_text(_prop(props, 'clip behavior')), 'hardEdge');
  });

  test('Wrap exposes cross-axis and directional properties', () {
    final props = wrapProps(
      RenderWrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        textDirection: TextDirection.rtl,
        verticalDirection: VerticalDirection.up,
        clipBehavior: Clip.antiAlias,
      ),
      decimalPlaces: 2,
    );

    expect(_text(_prop(props, 'cross axis')), 'end');
    expect(_text(_prop(props, 'text direction')), 'rtl');
    expect(_text(_prop(props, 'vertical dir')), 'up');
    expect(_text(_prop(props, 'clip behavior')), 'antiAlias');
  });

  test('selected Flex child exposes its flex parent data', () {
    final child = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(
        width: 10,
        height: 10,
      ),
    );
    RenderFlex(children: [child]);
    final parentData = child.parentData! as FlexParentData
      ..flex = 2
      ..fit = FlexFit.tight;

    final props = parentDataProps(child, decimalPlaces: 2);

    expect(parentData.flex, 2);
    expect(_text(_prop(props, 'flex')), '2');
    expect(_text(_prop(props, 'flex fit')), 'tight');
  });

  test('selected Stack child exposes its positioned parent data', () {
    final child = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(
        width: 10,
        height: 10,
      ),
    );
    RenderStack(children: [child], textDirection: TextDirection.ltr);
    final parentData = child.parentData! as StackParentData
      ..left = 4.25
      ..top = 8.5;

    final props = parentDataProps(child, decimalPlaces: 2);

    expect(parentData.left, 4.25);
    expect(_text(_prop(props, 'left')), '4.25');
    expect(_text(_prop(props, 'top')), '8.50');
  });

  test('FittedBox exposes non-default clipping', () {
    final props = fittedBoxProps(RenderFittedBox(clipBehavior: Clip.antiAlias));

    expect(_text(_prop(props, 'clip behavior')), 'antiAlias');
  });

  test('PhysicalModel exposes non-default clipping', () {
    final props = physicalModelProps(
      RenderPhysicalModel(
        shape: BoxShape.rectangle,
        color: Colors.white,
        shadowColor: Colors.black,
        clipBehavior: Clip.antiAlias,
      ),
    );

    expect(_text(_prop(props, 'clip behavior')), 'antiAlias');
  });

  testWidgets('ClipRRect resolves directional radii with its text direction', (
    tester,
  ) async {
    const key = ValueKey('clip-rrect');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: ClipRRect(
          key: key,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(4),
            topEnd: Radius.circular(8),
          ),
          child: SizedBox(width: 20, height: 20),
        ),
      ),
    );
    final render = tester.renderObject<RenderClipRRect>(find.byKey(key));

    final grid = _prop(clipRRectProps(render), 'radius')?.child;

    expect(grid, isA<BorderRadiusGrid>());
    expect((grid! as BorderRadiusGrid).topLeft, const Radius.circular(8));
    expect((grid as BorderRadiusGrid).topRight, const Radius.circular(4));
  });

  testWidgets('ClipRSuperellipse exposes directional radii and clipping', (
    tester,
  ) async {
    const key = ValueKey('clip-superellipse');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: ClipRSuperellipse(
          key: key,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(4),
            topEnd: Radius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: SizedBox(width: 20, height: 20),
        ),
      ),
    );
    final render = tester.renderObject<RenderClipRSuperellipse>(
      find.byKey(key),
    );

    final props = typeProps(render);
    final grid = _prop(props, 'radius')?.child;

    expect(hasTypeProps(render), isTrue);
    expect(grid, isA<BorderRadiusGrid>());
    expect((grid! as BorderRadiusGrid).topLeft, const Radius.circular(8));
    expect(_text(_prop(props, 'clip behavior')), 'hardEdge');
  });

  testWidgets('Padding exposes its resolved insets', (tester) async {
    const key = ValueKey('padding');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          key: key,
          padding: EdgeInsetsDirectional.only(start: 4, end: 8, top: 2),
          child: SizedBox(width: 20, height: 20),
        ),
      ),
    );
    final render = tester.renderObject<RenderPadding>(find.byKey(key));

    final props = typeProps(render);

    expect(_text(_prop(props, 'padding')), 'L:8.0 T:2.0 R:4.0 B:0.0');
  });

  test('uniform and symmetric padding collapse to short forms', () {
    expect(
      _text(
        _prop(
          paddingProps(RenderPadding(padding: EdgeInsets.all(6))),
          'padding',
        ),
      ),
      '6.0',
    );
    expect(
      _text(
        _prop(
          paddingProps(
            RenderPadding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          ),
          'padding',
        ),
      ),
      'h:6.0 v:2.0',
    );
  });

  test('ConstrainedBox exposes its additional constraints', () {
    final props = typeProps(
      RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(
          minWidth: 10,
          maxWidth: 40,
          minHeight: 20,
          maxHeight: 20,
        ),
      ),
    );

    expect(_text(_prop(props, 'width')), '10.0–40.0');
    expect(_text(_prop(props, 'height')), '=20.0');
  });

  test('expanding constraints render as infinity instead of a number', () {
    final props = constrainedBoxProps(
      RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.expand(),
      ),
    );

    expect(_text(_prop(props, 'width')), '=∞');
  });

  test('Align exposes alignment and size factors', () {
    final props = typeProps(
      RenderPositionedBox(
        alignment: Alignment.bottomRight,
        widthFactor: 2,
        textDirection: TextDirection.ltr,
      ),
    );

    expect(
      (_prop(props, 'alignment')?.child as EllipsizedText?)?.value,
      'bottomRight',
    );
    expect(_text(_prop(props, 'width factor')), '2.0');
    expect(_prop(props, 'height factor'), isNull);
  });

  test('ShapeDecoration exposes color, shape, radius, and shadows', () {
    final props = shapeDecorationProps(
      const ShapeDecoration(
        color: Color(0xFF112233),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        shadows: [BoxShadow(blurRadius: 4)],
      ),
    );

    expect(_prop(props, 'color'), isNotNull);
    expect(_text(_prop(props, 'shape')), 'RoundedRectangleBorder');
    expect(_text(_prop(props, 'border radius')), '6.0');
    expect(_prop(props, 'shadows'), isNotNull);
  });

  test('BackdropFilter exposes its filter and disabled state', () {
    final props = backdropFilterProps(
      RenderBackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 3),
        enabled: false,
      ),
    );

    expect(
      (_prop(props, 'filter')?.child as EllipsizedText?)?.value,
      'blur(2.0, 3.0)',
    );
    expect(_text(_prop(props, 'enabled')), 'off');
  });

  test('BackdropFilter built with a filter config still reports it', () {
    final props = backdropFilterProps(_ConfigBackedBackdropFilter());

    expect(
      (_prop(props, 'filter')?.child as EllipsizedText?)?.value,
      startsWith('blur(2.0, 3.0'),
    );
  });

  testWidgets('aligned rotation does not fabricate a translation', (
    tester,
  ) async {
    const transformKey = ValueKey('transform');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Transform.rotate(
            key: transformKey,
            angle: 1.5707963267948966,
            child: SizedBox(width: 100, height: 50),
          ),
        ),
      ),
    );

    final render = tester.renderObject<RenderTransform>(
      find.byKey(transformKey),
    );
    final props = transformProps(render, decimalPlaces: 2);

    expect(_prop(props, 'translate'), isNull);
    expect(_text(_prop(props, 'rotation°')), '90.00');
  });

  testWidgets('skew transform is shown as a matrix instead of being omitted', (
    tester,
  ) async {
    const transformKey = ValueKey('skew-transform');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Transform(
          key: transformKey,
          transform: Matrix4.skewX(0.5),
          child: const SizedBox(width: 100, height: 50),
        ),
      ),
    );
    final render = tester.renderObject<RenderTransform>(
      find.byKey(transformKey),
    );
    final props = transformProps(render, decimalPlaces: 2);

    expect(_prop(props, 'matrix'), isNotNull);
    expect(_prop(props, 'scale'), isNull);
    expect(_prop(props, 'rotation°'), isNull);
  });
}

/// Mimics Flutter 3.40+, where `filter` throws for a render object built
/// with `filterConfig`. On SDKs that predate `filterConfig` the getter is
/// served through [noSuchMethod] with a config shaped like Flutter's blur
/// config, so the fallback path runs on every supported Flutter.
class _ConfigBackedBackdropFilter extends RenderBackdropFilter {
  _ConfigBackedBackdropFilter()
    : super(filter: ImageFilter.blur(sigmaX: 2, sigmaY: 3));

  @override
  ImageFilter get filter => throw AssertionError('built with filterConfig');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      invocation.memberName == #filterConfig
      ? const _BlurConfig()
      : super.noSuchMethod(invocation);
}

class _BlurConfig {
  const _BlurConfig();
  double get sigmaX => 2;
  double get sigmaY => 3;
  TileMode get tileMode => TileMode.clamp;
  bool get bounded => false;
}
