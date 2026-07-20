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

  testWidgets(
    'search navigation scrolls to matches in grouped HTTP logs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(appShell(const _ViewerHarness()));
      await tester.pumpAndSettle();

      final logs = <ISpectLogData>[
        _plainLog('needle alpha', id: 'MATCH-ALPHA'),
        ..._httpTransactions(0, 40),
        _plainLog('needle beta', id: 'MATCH-BETA'),
        ..._httpTransactions(40, 80),
      ];
      final harness = tester.state<_ViewerHarnessState>(
        find.byType(_ViewerHarness),
      )..showLogs(logs);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'needle');
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pumpAndSettle();
      expect(harness.logsViewController.searchMatchCount, 2);
      expect(harness.logsViewController.focusedMatchPosition, 1);
      harness.rebuildViewer();
      await tester.pumpAndSettle();

      final nextMatchButton = find.descendant(
        of: find.byType(SearchBar),
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      );
      final previousMatchButton = find.descendant(
        of: find.byType(SearchBar),
        matching: find.byIcon(Icons.keyboard_arrow_up_rounded),
      );
      final nextIconButton = find.ancestor(
        of: nextMatchButton,
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(nextIconButton).onPressed, isNotNull);

      await tester.tap(nextIconButton);
      await tester.pumpAndSettle();

      expect(harness.logsViewController.focusedMatchId, 'MATCH-ALPHA');
      expect(harness.logsScrollController.offset, greaterThan(0));
      expect(find.text('needle alpha'), findsOneWidget);
      final alphaOffset = harness.logsScrollController.offset;

      await tester.tap(previousMatchButton);
      await tester.pumpAndSettle();

      expect(harness.logsViewController.focusedMatchId, 'MATCH-BETA');
      expect(harness.logsScrollController.offset, lessThan(alphaOffset));
      expect(find.text('needle beta'), findsOneWidget);
    },
  );
}

ISpectLogData _plainLog(String message, {required String id}) => ISpectLogData(
      message,
      id: id,
      key: ISpectLogType.info.key,
      logLevel: LogLevel.info,
    );

Iterable<ISpectLogData> _httpTransactions(int start, int end) sync* {
  for (var index = start; index < end; index++) {
    final requestId = 'request-$index';
    final additionalData = <String, dynamic>{
      TraceKeys.category: TraceCategoryIds.network,
      TraceKeys.meta: <String, dynamic>{'requestId': requestId},
    };
    yield ISpectLogData(
      'request $index',
      id: 'REQUEST-$index',
      key: ISpectLogType.httpRequest.key,
      additionalData: additionalData,
    );
    yield ISpectLogData(
      'response $index',
      id: 'RESPONSE-$index',
      key: ISpectLogType.httpResponse.key,
      additionalData: additionalData,
    );
  }
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

  ScrollController get logsScrollController => _logsScrollController;
  ISpectViewController get logsViewController => _logsViewController;

  void showLogs(List<ISpectLogData> logs) {
    setState(() => _logs = List<ISpectLogData>.unmodifiable(logs));
  }

  void rebuildViewer() => setState(() {});

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
