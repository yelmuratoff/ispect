import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/features/log_viewer/controllers/group_button.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_card.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_details.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_detail_view.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/logs_viewer_body.dart';

import '../../../../helpers/pump_ispect.dart';

void main() {
  for (final outcome in ['response', 'error', 'pending']) {
    testWidgets('desktop group selection opens HTTP $outcome details', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(appShell(const _ViewerHarness()));
      final logs = _httpTransactions(0, 1).toList();
      if (outcome == 'pending') {
        logs.removeLast();
      } else if (outcome == 'error') {
        logs[1] = ISpectLogData(
          'connection failed',
          id: 'ERROR-0',
          key: ISpectLogType.httpError.key,
          additionalData: logs.first.additionalData,
        );
      }
      final harness = tester.state<_ViewerHarnessState>(
        find.byType(_ViewerHarness),
      )..showLogs(logs);
      await tester.pumpAndSettle();
      final expectedId = outcome == 'pending'
          ? 'REQUEST-0'
          : outcome == 'error'
          ? 'ERROR-0'
          : 'RESPONSE-0';

      await tester.tap(find.text('/api/requests/0'));
      await tester.pumpAndSettle();
      expect(harness.logsViewController.activeData?.id, expectedId);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      final detailFinder = find.byType(LogDetailView);
      var detail = tester.widget<LogDetailView>(detailFinder);
      expect(detail.activeData.id, expectedId);
      if (outcome != 'pending') {
        expect(detail.correlatedLog?.id, 'REQUEST-0');
        await tester.tap(
          find.descendant(of: detailFinder, matching: find.text('Request')),
        );
        await tester.pumpAndSettle();
        detail = tester.widget<LogDetailView>(detailFinder);
        expect(detail.activeData.id, 'REQUEST-0');
        await tester.tap(
          find.descendant(of: detailFinder, matching: find.text('Response')),
        );
        await tester.pumpAndSettle();
        detail = tester.widget<LogDetailView>(detailFinder);
        expect(detail.activeData.id, expectedId);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('one mobile tap opens HTTP $outcome details', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(appShell(const _ViewerHarness()));
      final logs = _httpTransactions(0, 1).toList();
      if (outcome == 'pending') {
        logs.removeLast();
      } else if (outcome == 'error') {
        logs[1] = ISpectLogData(
          'connection failed',
          id: 'ERROR-0',
          key: ISpectLogType.httpError.key,
          additionalData: logs.first.additionalData,
        );
      }
      final harness = tester.state<_ViewerHarnessState>(
        find.byType(_ViewerHarness),
      )..showLogs(logs);
      await tester.pumpAndSettle();
      final scrollOffset = harness.logsScrollController.offset;

      await tester.tap(find.text('/api/requests/0'));
      await tester.pumpAndSettle();

      expect(find.byType(LogDetailView), findsOneWidget);
      var detail = tester.widget<LogDetailView>(find.byType(LogDetailView));
      expect(
        detail.activeData.id,
        outcome == 'pending'
            ? 'REQUEST-0'
            : outcome == 'error'
            ? 'ERROR-0'
            : 'RESPONSE-0',
      );
      if (outcome != 'pending') {
        expect(detail.correlatedLog?.id, 'REQUEST-0');
        await tester.tap(find.text('Request'));
        await tester.pumpAndSettle();
        detail = tester.widget<LogDetailView>(find.byType(LogDetailView));
        expect(detail.activeData.id, 'REQUEST-0');
        await tester.tap(find.text('Response'));
        await tester.pumpAndSettle();
        detail = tester.widget<LogDetailView>(find.byType(LogDetailView));
        expect(
          detail.activeData.id,
          outcome == 'error' ? 'ERROR-0' : 'RESPONSE-0',
        );
      }

      Navigator.of(tester.element(find.byType(LogDetailView))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(LogDetailView), findsNothing);
      expect(find.byType(NetworkTransactionCard), findsOneWidget);
      expect(find.byType(TransactionDetails), findsNothing);
      expect(harness.logsScrollController.offset, scrollOffset);
    });
  }

  testWidgets(
    'mobile HTTP disclosure opens and closes only the inline preview',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(appShell(const _ViewerHarness()));
      tester
          .state<_ViewerHarnessState>(find.byType(_ViewerHarness))
          .showLogs(_httpTransactions(0, 1).toList());
      await tester.pumpAndSettle();
      final card = find.byType(NetworkTransactionCard);

      await tester.tap(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LogDetailView), findsNothing);
      expect(find.text('Request'), findsWidgets);

      await tester.tap(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.keyboard_arrow_up_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Request'), findsNothing);
      expect(find.byType(LogDetailView), findsNothing);
    },
  );

  testWidgets('returning from mobile details preserves a scrolled search', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(appShell(const _ViewerHarness()));
    final harness = tester.state<_ViewerHarnessState>(
      find.byType(_ViewerHarness),
    )..showLogs(_httpTransactions(0, 20).toList());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'requests');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();
    harness.logsScrollController.jumpTo(
      harness.logsScrollController.position.maxScrollExtent,
    );
    await tester.pumpAndSettle();
    final offset = harness.logsScrollController.offset;
    final focusedMatchId = harness.logsViewController.focusedMatchId;
    expect(offset, greaterThan(0));

    await tester.tap(find.text('/api/requests/0'));
    await tester.pumpAndSettle();
    expect(find.byType(LogDetailView), findsOneWidget);
    Navigator.of(tester.element(find.byType(LogDetailView))).pop();
    await tester.pumpAndSettle();

    expect(harness.logsScrollController.offset, offset);
    expect(harness.logsViewController.searchController.text, 'requests');
    expect(harness.logsViewController.focusedMatchId, focusedMatchId);
    expect(find.text('/api/requests/0').hitTestable(), findsOneWidget);
  });

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

  testWidgets('search navigation scrolls to matches in grouped HTTP logs', (
    tester,
  ) async {
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
  });

  testWidgets(
    'opening log details preserves the focused search match and scroll offset',
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
      harness.rebuildViewer();
      await tester.pumpAndSettle();

      final nextMatchButton = find.descendant(
        of: find.byType(SearchBar),
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      );
      await tester.tap(nextMatchButton);
      await tester.pumpAndSettle();

      final focusedMatchId = harness.logsViewController.focusedMatchId;
      final focusedMatchPosition =
          harness.logsViewController.focusedMatchPosition;
      final scrollOffset = harness.logsScrollController.offset;
      expect(focusedMatchId, 'MATCH-ALPHA');
      expect(scrollOffset, greaterThan(0));

      harness.logsViewController.openLogDetail(logs.first);
      await tester.pumpAndSettle();

      expect(harness.logsViewController.searchController.text, 'needle');
      expect(harness.logsViewController.focusedMatchId, focusedMatchId);
      expect(
        harness.logsViewController.focusedMatchPosition,
        focusedMatchPosition,
      );
      expect(harness.logsScrollController.offset, scrollOffset);
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
      TraceKeys.operation: 'GET',
      TraceKeys.target: 'https://api.example.com/api/requests/$index',
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
