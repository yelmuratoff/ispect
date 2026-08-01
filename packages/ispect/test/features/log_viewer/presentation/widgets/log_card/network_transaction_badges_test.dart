import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';

import '../../../../../helpers/pump_ispect.dart';

void main() {
  group('MethodBadge', () {
    const fallback = Color(0xFF4CAF50);

    Future<Color?> pumpBadgeColor(
      WidgetTester tester,
      String method, {
      Brightness brightness = Brightness.light,
    }) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MethodBadge(method: 'PLACEHOLDER', color: fallback),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: ThemeData(brightness: brightness),
            child: MethodBadge(method: method, color: fallback),
          ),
        ),
      );
      return tester.widget<Text>(find.text(method)).style?.color;
    }

    testWidgets('colors the badge by HTTP method', (tester) async {
      expect(
        await pumpBadgeColor(tester, 'POST'),
        JsonColors.methodColorFor('POST', Brightness.light),
      );
      expect(
        await pumpBadgeColor(tester, 'PUT'),
        JsonColors.methodColorFor('PUT', Brightness.light),
      );
      expect(
        await pumpBadgeColor(tester, 'DELETE'),
        JsonColors.methodColorFor('DELETE', Brightness.light),
      );
    });

    testWidgets('uses the lighter dark palette on dark theme', (tester) async {
      final color =
          await pumpBadgeColor(tester, 'DELETE', brightness: Brightness.dark);
      expect(color, JsonColors.methodColorFor('DELETE', Brightness.dark));
      expect(
        color,
        isNot(JsonColors.methodColorFor('DELETE', Brightness.light)),
      );
    });

    testWidgets('matches the method case-insensitively', (tester) async {
      expect(
        await pumpBadgeColor(tester, 'get'),
        JsonColors.methodColorFor('GET', Brightness.light),
      );
    });

    testWidgets('falls back to the provided color for unknown methods',
        (tester) async {
      expect(await pumpBadgeColor(tester, 'HTTP'), fallback);
    });
  });

  testWidgets('transaction action controls use visible Material ripples',
      (tester) async {
    await tester.pumpWidget(
      appShell(
        Row(
          children: [
            DetailChip(
              label: 'Request',
              color: Colors.green,
              onTap: () {},
            ),
            SmallActionIcon(
              icon: Icons.share_rounded,
              color: Colors.green,
              tooltip: 'Share',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    for (final control in [
      find.byType(DetailChip),
      find.byType(SmallActionIcon),
    ]) {
      expect(
        find.descendant(of: control, matching: find.byType(Material)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: control, matching: find.byType(InkWell)),
        findsOneWidget,
      );
    }
  });

  testWidgets('detail chip confines its ripple to the visual surface',
      (tester) async {
    await tester.pumpWidget(
      appShell(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: kMinInteractiveDimension,
            child: DetailChip(
              label: 'Request',
              color: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final control = find.byType(DetailChip);
    final inkWellFinder = find.descendant(
      of: control,
      matching: find.byType(InkWell),
    );
    final surfaceFinder = find.descendant(
      of: control,
      matching: find.byType(Ink),
    );
    final inkWell = tester.widget<InkWell>(inkWellFinder);
    final tapSize = tester.getSize(inkWellFinder);
    final surfaceSize = tester.getSize(surfaceFinder);
    final clipBounds =
        inkWell.customBorder!.getOuterPath(Offset.zero & tapSize).getBounds();

    expect(clipBounds.size, surfaceSize);
    expect(clipBounds.center, (Offset.zero & tapSize).center);
  });
}
