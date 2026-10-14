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

  group('showISpectSheet builder context', () {
    Future<ModalRoute<Object?>?> openAndCaptureRoute(
      WidgetTester tester, {
      required Size size,
      bool fitContent = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      ModalRoute<Object?>? builderRoute;

      await tester.pumpWidget(
        appShell(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showISpectSheet<void>(
                context,
                fitContent: fitContent,
                builder: (sheetContext, _) {
                  builderRoute = ModalRoute.of(sheetContext);
                  return const Text('content');
                },
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return builderRoute;
    }

    testWidgets('is the sheet route context for a fitted phone sheet', (
      tester,
    ) async {
      final route = await openAndCaptureRoute(tester, size: screenSize);

      expect(route, isA<ModalBottomSheetRoute<void>>());
    });

    testWidgets('is the sheet route context for a draggable phone sheet', (
      tester,
    ) async {
      final route = await openAndCaptureRoute(
        tester,
        size: screenSize,
        fitContent: false,
      );

      expect(route, isA<ModalBottomSheetRoute<void>>());
    });

    testWidgets('is the dialog route context on larger screens', (
      tester,
    ) async {
      final route = await openAndCaptureRoute(
        tester,
        size: const Size(1200, 900),
      );

      expect(route, isA<DialogRoute<void>>());
    });
  });

  group('showISpectSheet after the caller unmounts', () {
    Future<void> rebuildWithoutCaller(
      WidgetTester tester, {
      required Size size,
      bool fitContent = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final showCaller = ValueNotifier(true);
      addTearDown(showCaller.dispose);
      var builds = 0;

      Widget home() => ValueListenableBuilder<bool>(
        valueListenable: showCaller,
        builder: (_, show, _) => show
            ? Builder(
                builder: (context) => TextButton(
                  onPressed: () => showISpectSheet<void>(
                    context,
                    fitContent: fitContent,
                    builder: (_, _) {
                      builds++;
                      return const Text('content');
                    },
                  ),
                  child: const Text('open'),
                ),
              )
            : const SizedBox(),
      );

      await tester.pumpWidget(appShell(home()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      showCaller.value = false;
      await tester.pump();
      final buildsBeforeRebuild = builds;

      await tester.pumpWidget(appShell(home(), locale: const Locale('en')));

      expect(tester.takeException(), isNull);
      expect(builds, greaterThan(buildsBeforeRebuild));
      expect(find.text('content'), findsOneWidget);
    }

    testWidgets('rebuilds a fitted phone sheet', (tester) async {
      await rebuildWithoutCaller(tester, size: screenSize);
    });

    testWidgets('rebuilds a draggable phone sheet', (tester) async {
      await rebuildWithoutCaller(tester, size: screenSize, fitContent: false);
    });

    testWidgets('rebuilds a dialog on larger screens', (tester) async {
      await rebuildWithoutCaller(tester, size: const Size(1200, 900));
    });
  });
}
