import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('JsonScreen log title', () {
    testWidgets('shows the time and level under the title', (tester) async {
      await tester.pumpWidget(
        appShell(
          JsonScreen(
            data: const {
              'key': 'riverpod-update',
              'message': 'flaky-future AsyncLoading -> AsyncError',
              'time': '2026-10-31T12:34:56.789',
              'log-level': '3',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12:34:56.789 · INFO'), findsOneWidget);
    });

    testWidgets('keeps the message only in the tree', (tester) async {
      const message = 'flaky-future AsyncLoading -> AsyncError';
      await tester.pumpWidget(
        appShell(
          JsonScreen(
            data: const {'key': 'riverpod-update', 'message': message},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(message, findRichText: true), findsOneWidget);
    });

    testWidgets('omits the level when it repeats the log type', (tester) async {
      await tester.pumpWidget(
        appShell(
          JsonScreen(
            data: const {
              'key': 'error',
              'message': 'Checkout failed',
              'time': '2026-10-31T12:34:56.789',
              'log-level': '1',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12:34:56.789'), findsOneWidget);
    });

    testWidgets('plain JSON keeps the plain viewer title', (tester) async {
      await tester.pumpWidget(appShell(JsonScreen(data: const {'total': 3})));
      await tester.pumpAndSettle();

      expect(find.text('JSON Viewer'), findsOneWidget);
    });
  });

  testWidgets('one toggle collapses and expands the whole tree', (
    tester,
  ) async {
    await tester.pumpWidget(
      appShell(
        JsonScreen(
          data: const {
            'key': 'riverpod-update',
            'additional-data': {'provider': 'flaky-future'},
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final nested = find.text('flaky-future', findRichText: true);

    expect(nested, findsOneWidget);

    await tester.tap(find.byTooltip('Collapse logs'));
    await tester.pumpAndSettle();

    expect(nested, findsNothing);
    expect(find.byTooltip('Expand logs'), findsOneWidget);

    await tester.tap(find.byTooltip('Expand logs'));
    await tester.pumpAndSettle();

    expect(nested, findsOneWidget);
  });

  testWidgets('collapsing a node by hand turns the toggle into Expand', (
    tester,
  ) async {
    await tester.pumpWidget(
      appShell(
        JsonScreen(
          data: const {
            'key': 'riverpod-update',
            'additional-data': {'provider': 'flaky-future'},
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('additional-data', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.text('flaky-future', findRichText: true), findsNothing);
    expect(find.byTooltip('Expand logs'), findsOneWidget);
  });

  group('export from the viewer', () {
    testWidgets('a log exports without a host callback as one log', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShell(
          JsonScreen(data: const {'key': 'info', 'message': 'App started'}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Export logs'));
      await tester.pumpAndSettle();

      expect(find.byType(ISpectExportSheet), findsOneWidget);
      expect(find.text('Download log file'), findsOneWidget);
      expect(find.text('1 log'), findsOneWidget);
    });

    testWidgets('plain JSON is not labelled as one log', (tester) async {
      await tester.pumpWidget(
        appShell(
          JsonScreen(
            data: const {
              'data': [
                {'key': 'info'},
                {'key': 'error'},
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Export logs'));
      await tester.pumpAndSettle();

      expect(find.byType(ISpectExportSheet), findsOneWidget);
      expect(find.text('1 log'), findsNothing);
    });

    testWidgets('a host share callback names the button Share', (tester) async {
      await tester.pumpWidget(
        appShell(
          JsonScreen(data: const {'key': 'info', 'message': 'App started'}),
          options: ISpectOptions(onShare: (_) async {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Share log file'), findsOneWidget);
      expect(find.byTooltip('Export logs'), findsNothing);
    });
  });
}
