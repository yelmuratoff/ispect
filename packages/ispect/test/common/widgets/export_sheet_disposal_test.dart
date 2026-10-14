import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/navigation_flow/actions_sheet.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/share_all_logs_sheet.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/share_log_bottom_sheet.dart';

import '../../helpers/pump_ispect.dart';

void main() {
  group('export sheets', () {
    final sheets = <String, Future<void> Function(BuildContext)>{
      'share all logs': const ISpectShareAllLogsBottomSheet(logs: []).show,
      'share log': const ISpectShareLogBottomSheet(
        data: {},
        truncatedData: {},
      ).show,
      'navigation flow actions': const ISpectNavigationFlowActionsSheet(
        log: null,
        transition: null,
        items: [],
      ).show,
    };

    for (final MapEntry(key: name, value: show) in sheets.entries) {
      testWidgets('$name disposes its export controller once closed', (
        tester,
      ) async {
        await tester.pumpWidget(
          appShell(
            Builder(
              builder: (context) => TextButton(
                onPressed: () => show(context),
                child: const Text('open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final sheet = find.byType(ISpectExportSheet);
        final controller = tester.widget<ISpectExportSheet>(sheet).controller;

        Navigator.of(tester.element(sheet)).pop();
        await tester.pumpAndSettle();

        expect(() => controller.addListener(() {}), throwsFlutterError);
      });
    }
  });
}
