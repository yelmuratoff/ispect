import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/group_button.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/logs_screen_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/logs_view_pipeline.dart';

void main() {
  late ISpectViewController view;
  late ScrollController scroll;
  late FocusNode focus;
  late GroupButtonController titles;
  late LogsScreenController screen;
  late LogsViewPipeline pipeline;

  setUp(() {
    view = ISpectViewController();
    scroll = ScrollController();
    focus = FocusNode();
    titles = GroupButtonController();
    screen = LogsScreenController(
      logsViewController: view,
      logsScrollController: scroll,
      searchFocusNode: focus,
      titleFiltersController: titles,
      onStateChanged: () {},
    );
    pipeline = LogsViewPipeline(screen: screen);
  });

  tearDown(() {
    screen.dispose();
    titles.dispose();
    focus.dispose();
    scroll.dispose();
    view.dispose();
  });

  ISpectLogData plain(
    String id, {
    String? message,
    String? key,
    LogLevel level = LogLevel.info,
  }) => ISpectLogData(
    message ?? 'message $id',
    id: id,
    key: key ?? ISpectLogType.info.key,
    logLevel: level,
  );

  List<ISpectLogData> transaction(int index) {
    final additionalData = <String, dynamic>{
      TraceKeys.category: TraceCategoryIds.network,
      TraceKeys.meta: <String, dynamic>{'requestId': 'request-$index'},
    };
    return [
      ISpectLogData(
        'request $index',
        id: 'REQUEST-$index',
        key: ISpectLogType.httpRequest.key,
        additionalData: additionalData,
      ),
      ISpectLogData(
        'response $index',
        id: 'RESPONSE-$index',
        key: ISpectLogType.httpResponse.key,
        additionalData: additionalData,
      ),
    ];
  }

  Iterable<String> ids(Iterable<ISpectLogData> logs) => logs.map((e) => e.id);

  test('flat list maps ids to rows and inverts them when the order flips', () {
    view.toggleGroupHttpLogs();
    final logs = [plain('A'), plain('B'), plain('C')];

    var state = pipeline.compute(logs);

    expect(state.grouped, isNull);
    expect(state.isReversed, isTrue);
    expect(state.idToVisualIndex, {'C': 0, 'B': 1, 'A': 2});

    view.toggleLogOrder();
    state = pipeline.compute(logs);

    expect(state.isReversed, isFalse);
    expect(state.idToVisualIndex, {'A': 0, 'B': 1, 'C': 2});
    expect(pipeline.visualIndexOf('C'), 2);
  });

  test('grouped list maps request and response ids to the same row', () {
    view.toggleLogOrder();
    final logs = [plain('A'), ...transaction(1)];

    final state = pipeline.compute(logs);

    expect(state.grouped, hasLength(2));
    expect(state.idToVisualIndex, {'A': 0, 'REQUEST-1': 1, 'RESPONSE-1': 1});
  });

  test('an unchanged snapshot reuses the visual index map', () {
    final logs = [plain('A'), plain('B')];

    final first = pipeline.compute(logs);
    final second = pipeline.compute(logs);

    expect(identical(first.idToVisualIndex, second.idToVisualIndex), isTrue);
  });

  test('a filter change rebuilds the visual index map', () {
    final logs = [
      plain('A'),
      plain('B', key: ISpectLogType.warning.key, level: LogLevel.warning),
    ];
    final before = pipeline.compute(logs);

    view.setOnlyLogTypeKey(ISpectLogType.warning.key);
    final after = pipeline.compute(logs);

    expect(identical(before.idToVisualIndex, after.idToVisualIndex), isFalse);
    expect(ids(after.filtered), ['B']);
    expect(after.idToVisualIndex, {'B': 0});
    expect(after.isFiltered, isTrue);
  });

  test('highlight mode keeps every entry and orders matches visually', () {
    view
      ..toggleGroupHttpLogs()
      ..searchByCorrelationId('needle');
    final logs = [
      plain('N1', message: 'needle one'),
      plain('O', message: 'other'),
      plain('N2', message: 'needle two'),
    ];

    final state = pipeline.compute(logs);

    expect(state.isHighlightMode, isTrue);
    expect(state.isFiltered, isFalse);
    expect(ids(state.filtered), ['N1', 'O', 'N2']);
    expect(ids(state.searchMatches!), ['N2', 'N1']);

    final again = pipeline.compute(logs);
    expect(identical(state.searchMatches, again.searchMatches), isTrue);
  });

  test('filter mode narrows the list to matches and reports no highlights', () {
    view
      ..toggleGroupHttpLogs()
      ..searchMode = SearchMode.filter
      ..searchByCorrelationId('needle');
    final logs = [
      plain('N1', message: 'needle one'),
      plain('O', message: 'other'),
      plain('N2', message: 'needle two'),
    ];

    final state = pipeline.compute(logs);

    expect(state.isHighlightMode, isFalse);
    expect(state.searchMatches, isNull);
    expect(ids(state.filtered), ['N1', 'N2']);
    expect(state.isFiltered, isTrue);
    expect(state.totalCount, 3);
  });

  test('level stats and type keys describe the raw snapshot', () {
    final logs = [
      plain('A'),
      plain('E', key: ISpectLogType.error.key, level: LogLevel.error),
      plain('W', key: ISpectLogType.warning.key, level: LogLevel.warning),
    ];
    view.setOnlyLogTypeKey(ISpectLogType.error.key);

    final state = pipeline.compute(logs);

    expect(state.levelStats, (errors: 1, warnings: 1));
    expect(state.logTypeKeys.counts[ISpectLogType.warning.key], 1);
    expect(ids(state.filtered), ['E']);
  });
}
