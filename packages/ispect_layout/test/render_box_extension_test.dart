import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/inspector/render_box_extension.dart';

void main() {
  testWidgets('displaySize follows a FittedBox fill transform', (tester) async {
    const childKey = ValueKey('child');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(key: childKey, width: 100, height: 100),
            ),
          ),
        ),
      ),
    );

    final child = tester.renderObject<RenderBox>(find.byKey(childKey));

    expect(child.displaySize, const Size(200, 100));
  });
}
