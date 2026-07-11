import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/features/log_viewer/controllers/group_button.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/logs_viewer_body.dart';

import '../../../../helpers/pump_ispect.dart';

void main() {
  testWidgets(
    'renders logs when an independent snapshot arrives after the empty state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(appShell(const _ViewerHarness()));
      await tester.pumpAndSettle();

      tester.state<_ViewerHarnessState>(find.byType(_ViewerHarness)).showLogs([
        ISpectLogData(
          'persisted session entry',
          id: 'SESSION-LOG',
          key: ISpectLogType.info.key,
          logLevel: LogLevel.info,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.textContaining('persisted session entry'), findsOneWidget);
    },
  );
}

final class _ViewerHarness extends StatefulWidget {
  const _ViewerHarness();

  @override
  State<_ViewerHarness> createState() => _ViewerHarnessState();
}

final class _ViewerHarnessState extends State<_ViewerHarness> {
  final _titleFiltersController = GroupButtonController();
  final _searchFocusNode = FocusNode();
  final _logsScrollController = ScrollController();
  final _logsViewController = ISpectViewController();
  List<ISpectLogData> _logs = const [];

  void showLogs(List<ISpectLogData> logs) {
    setState(() => _logs = List<ISpectLogData>.unmodifiable(logs));
  }

  @override
  void dispose() {
    _titleFiltersController.dispose();
    _searchFocusNode.dispose();
    _logsScrollController.dispose();
    _logsViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ISpectThemeScope(
        child: Builder(
          builder: (context) => LogsViewerBody(
            logsData: _logs,
            controller: _logsViewController,
            iSpectTheme: ISpect.read(context),
            titleFiltersController: _titleFiltersController,
            searchFocusNode: _searchFocusNode,
            logsScrollController: _logsScrollController,
          ),
        ),
      );
}
