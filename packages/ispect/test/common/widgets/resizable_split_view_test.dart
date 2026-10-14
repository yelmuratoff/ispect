import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/widgets/resizable_split_view.dart';

import '../../helpers/pump_ispect.dart';

void main() {
  testWidgets('paints the idle divider with the supplied divider color', (
    tester,
  ) async {
    const dividerColor = Color(0xFFAA3366);
    await tester.pumpWidget(
      appShell(
        const ResizableSplitView(
          left: SizedBox.shrink(),
          right: SizedBox.shrink(),
          dividerColor: dividerColor,
        ),
      ),
    );

    final divider = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(ResizableSplitView),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((divider.decoration! as BoxDecoration).color, dividerColor);
  });
}
