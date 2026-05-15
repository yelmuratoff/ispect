import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/sorting_controller.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  late SortingController controller;
  late bool isReversed;

  setUp(() {
    isReversed = false;
    controller = SortingController(isLogOrderReversed: () => isReversed);
  });

  tearDown(() => controller.dispose());

  group('defaults', () {
    test('starts with time column descending', () {
      expect(controller.sortColumn, LogSortColumn.time);
      expect(controller.sortDirection, LogSortDirection.descending);
    });
  });

  group('toggleSort', () {
    test('switching column resets to ascending', () {
      controller.toggleSort(LogSortColumn.type);
      expect(controller.sortColumn, LogSortColumn.type);
      expect(controller.sortDirection, LogSortDirection.ascending);
    });

    test('toggling same column flips direction', () {
      controller
        ..toggleSort(LogSortColumn.type)
        ..toggleSort(LogSortColumn.type);
      expect(controller.sortDirection, LogSortDirection.descending);
    });
  });

  group('applySorting', () {
    final a = ISpectLogData('alpha', key: 'aaa');
    final b = ISpectLogData('bravo', key: 'bbb');
    final c = ISpectLogData('charlie', key: 'ccc');

    test('time column is a passthrough (chronological order is preserved)', () {
      final entries = [c, a, b];
      expect(controller.applySorting(entries), entries);
    });

    test('type column sorts ascending by key', () {
      controller.toggleSort(LogSortColumn.type);
      final result = controller.applySorting([c, a, b]);
      expect(result.map((e) => e.key).toList(), ['aaa', 'bbb', 'ccc']);
    });

    test('type column toggled twice sorts descending by key', () {
      controller
        ..toggleSort(LogSortColumn.type)
        ..toggleSort(LogSortColumn.type);
      final result = controller.applySorting([a, b, c]);
      expect(result.map((e) => e.key).toList(), ['ccc', 'bbb', 'aaa']);
    });

    test('message column sorts ascending by text', () {
      controller.toggleSort(LogSortColumn.message);
      final result = controller.applySorting([c, a, b]);
      expect(
        result.map((e) => e.message).toList(),
        ['alpha', 'bravo', 'charlie'],
      );
    });
  });

  group('getLogEntryAtIndex', () {
    final a = ISpectLogData('a');
    final b = ISpectLogData('b');
    final c = ISpectLogData('c');

    test('returns natural index when not reversed', () {
      final result = controller.getLogEntryAtIndex([a, b, c], 1);
      expect(result?.entry.message, 'b');
      expect(result?.actualIndex, 1);
    });

    test('returns reversed index when isLogOrderReversed is true', () {
      isReversed = true;
      final result = controller.getLogEntryAtIndex([a, b, c], 0);
      expect(result?.entry.message, 'c');
      expect(result?.actualIndex, 2);
    });

    test('returns null when index is out of range', () {
      expect(controller.getLogEntryAtIndex([a], 5), isNull);
      expect(controller.getLogEntryAtIndex([a], -1), isNull);
    });
  });
}
