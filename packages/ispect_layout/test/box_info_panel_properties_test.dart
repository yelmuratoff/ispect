import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/box_info_panel_widget.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';
import 'package:ispect_layout/src/widgets/inspector/box_info.dart';

Future<void> _pumpPanel(
  WidgetTester tester,
  RenderBox target,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: BoxInfoPanelWidget(
            boxInfo: BoxInfo(targetRenderBox: target),
            decimalPlaces: 2,
            maxRenderTreeClipboardCharacters: 1000,
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(BoxInfoPanelWidget));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('RenderEditable exposes its effective typography',
      (tester) async {
    const editableKey = ValueKey('editable');
    RenderEditable? editable;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Stack(
                children: [
                  const TextField(
                    key: editableKey,
                    style: TextStyle(fontSize: 15, letterSpacing: 0.25),
                  ),
                  if (editable != null)
                    SizedBox(
                      width: 600,
                      child: BoxInfoPanelWidget(
                        boxInfo: BoxInfo(targetRenderBox: editable),
                        decimalPlaces: 2,
                        maxRenderTreeClipboardCharacters: 1000,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    editable = tester.allRenderObjects.whereType<RenderEditable>().single;
    expect((editable.text! as TextSpan).style?.letterSpacing, 0.25);
    rebuild(() {});
    await tester.pump();

    final header = tester.widget<InkWell>(
      find
          .descendant(
            of: find.byType(BoxInfoPanelWidget),
            matching: find.byType(InkWell),
          )
          .first,
    );
    header.onTap!();
    await tester.pumpAndSettle();

    expect(find.text('LAYOUT'), findsOneWidget);
    expect(find.text('TYPOGRAPHY'), findsOneWidget);
    expect(find.text('0.25'), findsOneWidget);
  });

  testWidgets('directional radius is resolved with decoration text direction',
      (tester) async {
    const decoratedKey = ValueKey('decorated');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: DecoratedBox(
          key: decoratedKey,
          decoration: BoxDecoration(
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(4),
              topEnd: Radius.circular(8),
            ),
          ),
          child: SizedBox(width: 20, height: 20),
        ),
      ),
    );
    final decorated = tester.renderObject<RenderDecoratedBox>(
      find.byKey(decoratedKey),
    );

    await _pumpPanel(tester, decorated);

    final grid = tester.widget<BorderRadiusGrid>(
      find.byType(BorderRadiusGrid),
    );
    expect(grid.topLeft, const Radius.circular(8));
    expect(grid.topRight, const Radius.circular(4));
  });
}
