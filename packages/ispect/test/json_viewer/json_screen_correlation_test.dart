import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('JsonScreen correlation chip', () {
    testWidgets('points back to the request after opening the response', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShell(
          JsonScreen(
            data: const {'key': 'http-request', 'message': 'GET /users'},
            correlatedLogData: const {
              'key': 'http-response',
              'message': '200 /users',
            },
            correlatedLogLabel: 'Response',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Response'));
      await tester.pumpAndSettle();

      expect(find.text('Request'), findsOneWidget);
      expect(find.text('Response'), findsNothing);
    });

    testWidgets('keeps a custom label when navigating back and forth', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShell(
          JsonScreen(
            data: const {'key': 'db-query', 'message': 'select'},
            correlatedLogData: const {'key': 'db-result', 'message': 'rows'},
            correlatedLogLabel: 'Related',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Related'));
      await tester.pumpAndSettle();

      expect(find.text('Related'), findsOneWidget);
    });
  });
}
