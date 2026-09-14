import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/render_tree_dump.dart';

void main() {
  testWidgets('dump lists every node with its type, size, and nesting', (
    tester,
  ) async {
    const rootKey = ValueKey('root');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Padding(
            key: rootKey,
            padding: EdgeInsets.all(10),
            child: SizedBox(width: 40, height: 20),
          ),
        ),
      ),
    );
    final root = tester.renderObject(find.byKey(rootKey));

    final dump = describeRenderTree(root);
    final lines = dump.trimRight().split('\n');

    expect(lines, hasLength(2));
    expect(lines[0], startsWith('RenderPadding#'));
    expect(lines[0], contains('size=60.0 × 40.0'));
    expect(lines[1], startsWith('  RenderConstrainedBox#'));
    expect(lines[1], contains('size=40.0 × 20.0'));
    expect(lines[1], contains('offset=(10.0, 10.0)'));
    expect(lines[1], contains('constraints=w0.0–780.0 h0.0–580.0'));
  });

  testWidgets('dump honours the requested precision', (tester) async {
    const key = ValueKey('box');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(key: key, width: 10.25, height: 5)),
      ),
    );
    final root = tester.renderObject(find.byKey(key));

    expect(
      describeRenderTree(root, decimalPlaces: 2),
      contains('10.25 × 5.00'),
    );
  });
}
