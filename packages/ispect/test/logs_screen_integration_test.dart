// Widget integration test: HTTP log surfaces in the logs UI.
//
// `LogsScreen` reads `ISpect.logger` (a flag-gated global), which cannot be
// injected without the `ISPECT_ENABLED` compile flag. So this test targets
// `ISpectLogsBuilder` — the same widget `LogsScreen` uses internally to
// render log records. A network-style log emitted through the real
// `ISpectLogger` trace API must trigger a rebuild that renders the log
// entry in the widget tree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/builder/widget_builder.dart';

void main() {
  testWidgets(
    'HTTP request log surfaces in ISpectLogsBuilder after it is emitted',
    (tester) async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          home: Scaffold(
            body: ISpectLogsBuilder(
              logger: logger,
              // ignore: avoid_types_on_closure_parameters
              builder: (context, List<ISpectLogData> data) => ListView(
                children: [
                  if (data.isEmpty)
                    const Text('no-logs', key: Key('empty-marker'))
                  else
                    for (final log in data)
                      Text(
                        '${log.key ?? "log"}|'
                        '${log.additionalData?[TraceKeys.target] ?? ""}',
                        key: ValueKey(log),
                      ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before any log is emitted, the builder must render the empty marker.
      expect(find.byKey(const Key('empty-marker')), findsOneWidget);

      // Simulate what a network interceptor does on an outgoing request.
      logger.httpRequest(
        source: 'dio',
        operation: 'GET',
        target: 'https://api.test/users',
      );

      await tester.pumpAndSettle();

      // The empty marker must be gone, replaced by the logged request row.
      expect(find.byKey(const Key('empty-marker')), findsNothing);
      expect(find.textContaining('api.test/users'), findsOneWidget);
      expect(
        find.textContaining(ISpectLogType.httpRequest.key),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'builder rebuilds for every subsequent log emission',
    (tester) async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      var builderInvocations = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ISpectLogsBuilder(
              logger: logger,
              builder: (context, data) {
                builderInvocations++;
                return Text('count=${data.length}');
              },
            ),
          ),
        ),
      );
      final initialInvocations = builderInvocations;
      expect(find.text('count=0'), findsOneWidget);

      logger
        ..httpRequest(source: 'dio', operation: 'GET', target: '/a')
        ..httpResponse(source: 'dio', operation: 'GET', target: '/a');

      await tester.pumpAndSettle();

      expect(find.text('count=2'), findsOneWidget);
      expect(builderInvocations, greaterThan(initialInvocations));
    },
  );
}
