import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/performance/src/overlay.dart';

void main() {
  Widget wrap(Widget child) => Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: child,
        ),
      );

  const childKey = Key('child');
  const childText = 'app-content';
  const overlayLabel = 'Performance overlay';

  group('ISpectPerformanceOverlay', () {
    late SemanticsHandle semanticsHandle;

    setUp(() {
      semanticsHandle =
          TestWidgetsFlutterBinding.ensureInitialized().ensureSemantics();
    });

    tearDown(() {
      semanticsHandle.dispose();
    });

    testWidgets('returns the child unchanged when disabled', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ISpectPerformanceOverlay(
            enabled: false,
            child: Text(childText, key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.bySemanticsLabel(overlayLabel), findsNothing);
    });

    testWidgets('renders the overlay surface + freeze button when enabled',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const ISpectPerformanceOverlay(
            child: Text(childText, key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.bySemanticsLabel(overlayLabel), findsOneWidget);
    });

    testWidgets(
      'does not render freeze button when allowFreeze is false',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            const ISpectPerformanceOverlay(
              allowFreeze: false,
              child: Text(childText, key: childKey),
            ),
          ),
        );

        expect(find.byIcon(Icons.pause_rounded), findsNothing);
        expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
        expect(find.bySemanticsLabel(overlayLabel), findsOneWidget);
      },
    );

    testWidgets(
      'freeze button swaps to play icon after a tap',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            const ISpectPerformanceOverlay(
              child: Text(childText, key: childKey),
            ),
          ),
        );

        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

        await tester.tap(find.byIcon(Icons.pause_rounded));
        await tester.pump();

        expect(find.byIcon(Icons.pause_rounded), findsNothing);
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'exposes accessible button semantics for the freeze toggle',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            const ISpectPerformanceOverlay(
              child: Text(childText, key: childKey),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel('Pause performance overlay'),
          findsOneWidget,
        );

        await tester.tap(find.byIcon(Icons.pause_rounded));
        await tester.pump();

        expect(
          find.bySemanticsLabel('Resume performance overlay'),
          findsOneWidget,
        );
      },
    );

    testWidgets('compact mode uses the compact default height', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ISpectPerformanceOverlay(
            compact: true,
            child: Text(childText, key: childKey),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.bySemanticsLabel(overlayLabel), findsOneWidget);
      // Compact picks a tighter default height than the detailed layout.
      final detailedDefault = (16.0 + 10.0 * 1.15 * 3 + 18.0).round();
      final overlaySize = tester.getSize(find.bySemanticsLabel(overlayLabel));
      expect(overlaySize.height, lessThan(detailedDefault));
    });

    testWidgets('lets taps fall through to the underlying child',
        (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        wrap(
          ISpectPerformanceOverlay(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => tapCount++,
              child: const SizedBox.expand(child: Text(childText)),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(20, 580));
      expect(tapCount, 1);
    });
  });
}
