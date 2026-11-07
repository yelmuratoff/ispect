import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/empty_logs_widget.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('EmptyLogsWidget', () {
    testWidgets('an empty history invites waiting for logs, not filtering', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShell(const EmptyLogsWidget(reason: EmptyLogsReason.noLogs)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No logs yet'), findsOneWidget);
      expect(find.text('Logs appear here while the app runs'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsNothing);
      expect(find.text('Clear all filters'), findsNothing);
    });

    testWidgets('a filter with no matches offers to clear the filters', (
      tester,
    ) async {
      var clears = 0;
      await tester.pumpWidget(
        appShell(
          EmptyLogsWidget(
            reason: EmptyLogsReason.noMatches,
            onClearFilters: () => clears++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No matching logs'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);

      await tester.tap(find.text('Clear all filters'));
      await tester.pump();

      expect(clears, 1);
    });

    testWidgets('an empty sessions list explains where sessions come from', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShell(const EmptyLogsWidget(reason: EmptyLogsReason.noSessions)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No saved sessions'), findsOneWidget);
      expect(
        find.text('Sessions appear here once logs are saved to files'),
        findsOneWidget,
      );
      expect(find.text('Clear all filters'), findsNothing);
    });
  });
}
