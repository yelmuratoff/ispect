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

  group('ISpectPerformanceOverlay', () {
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
    });

    testWidgets('renders header + freeze button when enabled', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ISpectPerformanceOverlay(
            child: Text(childText, key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.textContaining('Hz'), findsOneWidget);
      expect(find.textContaining('FPS'), findsOneWidget);
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
      },
    );

    testWidgets(
      'freeze button swaps to play icon after a tap and shows PAUSED',
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
        expect(find.textContaining('PAUSED'), findsOneWidget);
      },
    );

    testWidgets(
      'exposes accessible button semantics for the freeze toggle',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
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
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('compact mode renders a single-line summary', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ISpectPerformanceOverlay(
            compact: true,
            child: Text(childText, key: childKey),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.textContaining('jank'), findsOneWidget);
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
