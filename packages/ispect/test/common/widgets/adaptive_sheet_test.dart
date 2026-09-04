import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';

import '../../helpers/pump_ispect.dart';

void main() {
  const screenSize = Size(400, 800);

  Future<void> pumpAndOpen(WidgetTester tester, Widget content) async {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      appShell(
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showISpectSheet<void>(context, builder: (_, _) => content),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('showISpectSheet on a phone', () {
    testWidgets('sizes the sheet to short content', (tester) async {
      await pumpAndOpen(
        tester,
        const SizedBox(height: 200, child: Text('short')),
      );

      expect(find.text('short'), findsOneWidget);
      expect(tester.getSize(find.byType(BottomSheet)).height, 200);
    });

    testWidgets('caps tall content at 85% of the screen and scrolls it', (
      tester,
    ) async {
      await pumpAndOpen(
        tester,
        ListView(
          shrinkWrap: true,
          children: List.generate(
            40,
            (i) => SizedBox(height: 60, child: Text('row $i')),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        screenSize.height * 0.85,
      );
      expect(find.text('row 0'), findsOneWidget);
      expect(find.text('row 39'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('row 39'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('row 39'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
