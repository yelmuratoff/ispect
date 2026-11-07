import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('icon-only log actions', () {
    Future<SemanticsNode> pumpAndRead(
      WidgetTester tester,
      Widget button,
    ) async {
      await tester.pumpWidget(appShell(Center(child: button)));
      return tester.getSemantics(find.bySemanticsLabel('Actions'));
    }

    testWidgets('a card action names itself once', (tester) async {
      final semantics = tester.ensureSemantics();
      final node = await pumpAndRead(
        tester,
        SquareIconButton(
          icon: Icons.more_horiz_rounded,
          color: Colors.grey,
          tooltip: 'Actions',
          onPressed: () {},
        ),
      );

      expect(node.label, 'Actions');
      expect(node.tooltip, isEmpty);
      semantics.dispose();
    });

    testWidgets('a transaction badge action names itself once', (tester) async {
      final semantics = tester.ensureSemantics();
      final node = await pumpAndRead(
        tester,
        SmallActionIcon(
          icon: Icons.more_horiz_rounded,
          color: Colors.grey,
          tooltip: 'Actions',
          onPressed: () {},
        ),
      );

      expect(node.label, 'Actions');
      expect(node.tooltip, isEmpty);
      semantics.dispose();
    });

    testWidgets('the visual tooltip still shows on long press', (tester) async {
      await tester.pumpWidget(
        appShell(
          Center(
            child: SquareIconButton(
              icon: Icons.more_horiz_rounded,
              color: Colors.grey,
              tooltip: 'Actions',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(SquareIconButton));
      await tester.pumpAndSettle();

      expect(find.text('Actions'), findsOneWidget);
    });
  });
}
