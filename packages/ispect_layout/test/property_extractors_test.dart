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
