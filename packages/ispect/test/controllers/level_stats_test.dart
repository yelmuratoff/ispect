import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';

ISpectLogData _log(String message, LogLevel level) =>
    ISpectLogData(message, key: level.name, logLevel: level);

void main() {
  group('ISpectViewController.getLevelStats', () {
    late ISpectViewController controller;

    setUp(() => controller = ISpectViewController());
    tearDown(() => controller.dispose());

    test('counts errors, criticals, and warnings', () {
      final logs = [
        _log('a', LogLevel.info),
        _log('b', LogLevel.error),
        _log('c', LogLevel.critical),
        _log('d', LogLevel.warning),
      ];

      expect(controller.getLevelStats(logs), (errors: 2, warnings: 1));
    });

    test('extends a previous count when entries were only appended', () {
      final first = [_log('a', LogLevel.error), _log('b', LogLevel.info)];
      final second = [...first, _log('c', LogLevel.warning)];

      expect(controller.getLevelStats(first), (errors: 1, warnings: 0));
      expect(controller.getLevelStats(second), (errors: 1, warnings: 1));
    });

    test('rescans when the oldest entries were evicted', () {
      final first = [_log('a', LogLevel.error), _log('b', LogLevel.info)];
      final second = [first[1], _log('c', LogLevel.warning)];

      expect(controller.getLevelStats(first), (errors: 1, warnings: 0));
      expect(controller.getLevelStats(second), (errors: 0, warnings: 1));
    });

    test('rescans after an excluded log type changes the filter', () {
      final logs = [_log('a', LogLevel.error), _log('b', LogLevel.warning)];

      expect(controller.getLevelStats(logs), (errors: 1, warnings: 1));

      controller.updateSettings(
        controller.settings.copyWith(disabledLogTypes: {LogLevel.error.name}),
      );

      expect(controller.getLevelStats(logs), (errors: 0, warnings: 1));
    });
  });
}
