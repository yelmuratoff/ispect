import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('ISpectLogsScreen', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      ISpect.initialize(logger);
    });
    tearDown(ISpect.dispose);

    testWidgets('shows entries added to the logger after it opens', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      await tester.pumpWidget(appShell(const ISpectLogsScreen(title: 'App')));
      await tester.pumpAndSettle();
      expect(find.textContaining('order sync failed'), findsNothing);

      logger.logData(
        ISpectLogData('order sync failed', logLevel: LogLevel.error),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('order sync failed'), findsWidgets);
      expect(find.text('App'), findsOneWidget);
    });

    testWidgets('offers no back button when there is nothing to go back to', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      await tester.pumpWidget(appShell(const ISpectLogsScreen()));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('offers a back button when opened over another screen', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      await tester.pumpWidget(appShell(const SizedBox()));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const ISpectLogsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Back'), findsOneWidget);
    });
  });
}
