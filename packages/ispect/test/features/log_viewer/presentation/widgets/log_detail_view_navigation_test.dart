import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_detail_view.dart';

void main() {
  testWidgets('selected transaction entry survives host rebuild', (
    tester,
  ) async {
    final revision = ValueNotifier(0);
    addTearDown(revision.dispose);
    final request = ISpectLogData(
      'request payload',
      key: ISpectLogType.httpRequest.key,
    );
    final response = ISpectLogData(
      'response payload',
      key: ISpectLogType.httpResponse.key,
    );
    await tester.pumpWidget(
      ISpectScopeController(
        model: ISpectScopeModel(isISpectEnabled: true),
        child: ValueListenableBuilder<int>(
          valueListenable: revision,
          builder: (context, value, child) => MaterialApp(
            title: 'Host $value',
            localizationsDelegates: ISpectLocalization.localizationDelegates,
            supportedLocales: ISpectLocalization.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => LogDetailView(
                    activeData: response,
                    correlatedLog: request,
                  ).push(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<LogDetailView>(find.byType(LogDetailView)).activeData,
      same(request),
    );
    final snapshot = tester.widget<JsonScreen>(find.byType(JsonScreen)).data;

    revision.value++;
    await tester.pumpAndSettle();

    expect(
      tester.widget<LogDetailView>(find.byType(LogDetailView)).activeData,
      same(request),
    );
    expect(
      tester.widget<JsonScreen>(find.byType(JsonScreen)).data,
      same(snapshot),
    );
    await tester.tap(find.text('Response'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<LogDetailView>(find.byType(LogDetailView)).activeData,
      same(response),
    );
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(LogDetailView), findsNothing);
  });
}
