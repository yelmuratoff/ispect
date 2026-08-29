import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/core/res/ispect_theme_data.dart';

void main() {
  testWidgets('scratch: themed component shapes', (tester) async {
    tester.view
      ..physicalSize = const Size(900, 620)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildISpectThemeData(dark: true),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 14,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 14,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(Icons.close_rounded),
                    ),
                    FilledButton(onPressed: () {}, child: const Text('Got it')),
                    OutlinedButton(onPressed: () {}, child: const Text('Text')),
                    const Chip(label: Text('2 info')),
                  ],
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Search')),
                    ButtonSegment(value: 1, label: Text('Filters')),
                  ],
                  selected: const {0},
                  onSelectionChanged: (_) {},
                ),
                const SizedBox(
                  width: 420,
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Share the log file'),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 420,
                  child: Dialog(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Tips'),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Reverse logs',
                  triggerMode: TooltipTriggerMode.tap,
                  child: const Icon(Icons.swap_vert),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Tooltip));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('scratch_t.png'),
    );
  });
}
