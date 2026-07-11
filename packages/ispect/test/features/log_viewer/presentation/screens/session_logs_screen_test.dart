import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/session_logs_screen.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_list_item.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/share_all_logs_sheet.dart';

import '../../../../helpers/pump_ispect.dart';

void main() {
  testWidgets(
    'independent logs use the same app bar and display defaults as live logs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        appShell(
          SessionLogsScreen(
            logs: [
              ISpectLogData(
                'persisted session entry',
                id: 'SESSION-LOG',
                key: ISpectLogType.info.key,
                logLevel: LogLevel.info,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ISpect'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(
        tester.widget<LogListItem>(find.byType(LogListItem)).isExpanded,
        isFalse,
      );
    },
  );

  testWidgets('clear history action clears the independent snapshot',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      appShell(
        SessionLogsScreen(
          logs: [
            ISpectLogData(
              'snapshot-only entry',
              id: 'SNAPSHOT-ONLY',
              key: ISpectLogType.info.key,
              logLevel: LogLevel.info,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('snapshot-only entry'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final clearHistory = find.text('Clear history');
    await tester.scrollUntilVisible(
      clearHistory,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(clearHistory);
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('snapshot-only entry'), findsNothing);
  });

  test('export content encodes the independent snapshot', () async {
    final content = await buildLogsExportContent(
      ExportFormat.text,
      logs: [
        ISpectLogData(
          'shared snapshot entry',
          id: 'SHARED-SNAPSHOT',
          key: ISpectLogType.info.key,
          logLevel: LogLevel.info,
        ),
      ],
    );

    expect(content, contains('shared snapshot entry'));
  });
}
