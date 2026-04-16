import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/empty_logs_widget.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('EmptyLogsWidget', () {
    testWidgets(
      'Given the widget is created, '
      'When it is pumped, '
      'Then it renders correctly',
      (tester) async {
        await tester.pumpWidget(appShell(const EmptyLogsWidget()));
        await tester.pumpAndSettle();

        expect(find.byType(EmptyLogsWidget), findsOneWidget);
      },
    );

    testWidgets(
      'Given the widget is rendered, '
      'When looking for the terminal icon, '
      'Then it shows terminal_rounded icon',
      (tester) async {
        await tester.pumpWidget(appShell(const EmptyLogsWidget()));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.terminal_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Given the widget is rendered, '
      'When looking for the search-off icon, '
      'Then it shows search_off_rounded icon',
      (tester) async {
        await tester.pumpWidget(appShell(const EmptyLogsWidget()));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Given the default English locale, '
      'When looking for the "not found" title, '
      'Then it shows localized not-found text',
      (tester) async {
        await tester.pumpWidget(appShell(const EmptyLogsWidget()));
        await tester.pumpAndSettle();

        expect(find.textContaining('Not'), findsOneWidget);
      },
    );

    testWidgets(
      'Given the default English locale, '
      'When looking for the hint text, '
      'Then it shows localized no-results hint',
      (tester) async {
        await tester.pumpWidget(appShell(const EmptyLogsWidget()));
        await tester.pumpAndSettle();

        // The hint text should be present below the title.
        expect(
          find.textContaining(
            RegExp('(filter|search|adjust|try)', caseSensitive: false),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
