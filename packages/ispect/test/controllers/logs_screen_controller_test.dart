import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/logs_screen_controller.dart';

void main() {
  group('LogsScreenController', () {
    late ISpectViewController view;
    late ScrollController scroll;
    late FocusNode focus;
    late LogsScreenController screen;

    setUp(() {
      view = ISpectViewController();
      scroll = ScrollController();
      focus = FocusNode();
      screen = LogsScreenController(
        logsViewController: view,
        logsScrollController: scroll,
        searchFocusNode: focus,
        onStateChanged: () {},
      );
    });

    tearDown(() {
      screen.dispose();
      focus.dispose();
      scroll.dispose();
      view.dispose();
    });

    ISpectLogData log(String id, ISpectLogType type) =>
        ISpectLogData('message $id', id: id, key: type.key);

    Iterable<String> visibleIds(List<ISpectLogData> logs) {
      view.onDataChanged();
      return view.applyCurrentFilters(logs).map((log) => log.id);
    }

    test('a type that appears after hiding another stays visible', () {
      final before = [
        log('I', ISpectLogType.info),
        log('W', ISpectLogType.warning),
      ];
      screen.handleTypeFilter(ISpectLogType.info.key, LogTypeFilterAction.hide);

      final after = [...before, log('E', ISpectLogType.error)];

      expect(visibleIds(after), ['W', 'E']);
    });

    test('hiding the only present type hides its entries', () {
      final logs = [
        log('I1', ISpectLogType.info),
        log('I2', ISpectLogType.info),
      ];

      screen.handleTypeFilter(ISpectLogType.info.key, LogTypeFilterAction.hide);

      expect(visibleIds(logs), isEmpty);
    });

    test('show only narrows the list to that type', () {
      final logs = [
        log('I', ISpectLogType.info),
        log('W', ISpectLogType.warning),
      ];

      screen.handleTypeFilter(
        ISpectLogType.warning.key,
        LogTypeFilterAction.showOnly,
      );

      expect(visibleIds(logs), ['W']);
    });

    test('selecting a hidden type again shows it', () {
      final logs = [
        log('I', ISpectLogType.info),
        log('W', ISpectLogType.warning),
      ];
      screen.handleTypeFilter(ISpectLogType.info.key, LogTypeFilterAction.hide);

      view.handleLogTypeKeyFilterToggle(
        ISpectLogType.info.key,
        isSelected: true,
      );

      expect(visibleIds(logs), ['I', 'W']);
      expect(view.filter.logTypeKeys, isEmpty);
    });

    test('clearing all filters shows a hidden type again', () {
      final logs = [
        log('I', ISpectLogType.info),
        log('W', ISpectLogType.warning),
      ];
      screen.handleTypeFilter(ISpectLogType.info.key, LogTypeFilterAction.hide);

      view.clearAllFilters();

      expect(visibleIds(logs), ['I', 'W']);
    });

    test('column sorting follows a different input list', () {
      view.toggleSort(LogSortColumn.type);
      final first = [
        log('W', ISpectLogType.warning),
        log('I', ISpectLogType.info),
      ];
      final second = [
        log('E', ISpectLogType.error),
        log('D', ISpectLogType.debug),
      ];

      screen.applySortingIfNeeded(first);

      expect(screen.applySortingIfNeeded(second).map((e) => e.id), ['D', 'E']);
    });

    test('a narrow layout still records the latest log count', () {
      screen.checkForNewLogs(5, isDesktop: false, onMount: () {});

      expect(screen.lastLogCount, 5);
    });
  });
}
