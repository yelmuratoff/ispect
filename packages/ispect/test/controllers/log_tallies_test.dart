import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/log_tallies.dart';

ISpectLogData _log(String message, LogLevel level) =>
    ISpectLogData(message, key: level.name, logLevel: level);

void main() {
  group('LogHeaderTally', () {
    late LogHeaderTally tally;
    final everything = ISpectFilter();

    setUp(() => tally = LogHeaderTally());

    test('counts errors, criticals, and warnings', () {
      final logs = [
        _log('a', LogLevel.info),
        _log('b', LogLevel.error),
        _log('c', LogLevel.critical),
        _log('d', LogLevel.warning),
      ];

      expect(tally.update(logs, filter: everything), (
        total: 4,
        errors: 2,
        warnings: 1,
      ));
    });

    test('extends a previous count when entries were only appended', () {
      final first = [_log('a', LogLevel.error), _log('b', LogLevel.info)];
      final second = [...first, _log('c', LogLevel.warning)];

      expect(tally.update(first, filter: everything), (
        total: 2,
        errors: 1,
        warnings: 0,
      ));
      expect(tally.update(second, filter: everything), (
        total: 3,
        errors: 1,
        warnings: 1,
      ));
    });

    test('rescans when the oldest entries were evicted', () {
      final first = [_log('a', LogLevel.error), _log('b', LogLevel.info)];
      final second = [first[1], _log('c', LogLevel.warning)];

      tally.update(first, filter: everything);

      expect(tally.update(second, filter: everything), (
        total: 2,
        errors: 0,
        warnings: 1,
      ));
    });

    test('resets when the history is cleared', () {
      tally.update([_log('a', LogLevel.error)], filter: everything);

      expect(tally.update(const [], filter: everything), (
        total: 0,
        errors: 0,
        warnings: 0,
      ));
    });

    test('counts entries the severity bar treats as errors or warnings', () {
      final logs = [
        ISpectLogData(
          'failed trace',
          key: ISpectLogType.info.key,
          logLevel: LogLevel.info,
          additionalData: const {TraceKeys.success: false},
        ),
        ISpectLogData('http failure', key: ISpectLogType.httpError.key),
        ISpectLogData('warning key', key: ISpectLogType.warning.key),
        _log('plain', LogLevel.info),
      ];

      expect(tally.update(logs, filter: everything), (
        total: 4,
        errors: 2,
        warnings: 1,
      ));
    });

    test('counts only entries of the selected log types', () {
      final logs = [_log('a', LogLevel.error), _log('b', LogLevel.warning)];

      expect(
        tally.update(
          logs,
          filter: ISpectFilter(logTypeKeys: [LogLevel.warning.name]),
        ),
        (total: 1, errors: 0, warnings: 1),
      );
    });

    test('rescans when a log type is vetoed', () {
      final logs = [_log('a', LogLevel.error), _log('b', LogLevel.warning)];
      tally.update(logs, filter: everything);

      expect(
        tally.update(
          logs,
          filter: ISpectFilter(excludedLogTypeKeys: [LogLevel.error.name]),
        ),
        (total: 1, errors: 0, warnings: 1),
      );
    });

    test('ignores the search query', () {
      final logs = [_log('alpha', LogLevel.error), _log('beta', LogLevel.info)];

      expect(tally.update(logs, filter: ISpectFilter(searchQuery: 'beta')), (
        total: 2,
        errors: 1,
        warnings: 0,
      ));
    });
  });

  group('LogTypeKeyTally', () {
    late LogTypeKeyTally tally;

    setUp(() => tally = LogTypeKeyTally());

    ISpectLogData keyed(String key) => ISpectLogData(key, key: key);

    test('counts keys in first-seen order', () {
      final result = tally.update([
        keyed('b'),
        keyed('a'),
        keyed('b'),
      ], excludedKeys: const {});

      expect(result.unique, ['b', 'a']);
      expect(result.counts, {'b': 2, 'a': 1});
    });

    test('adds appended entries to the previous counts', () {
      final first = [keyed('a'), keyed('b')];
      final second = [...first, keyed('a'), keyed('c')];
      tally.update(first, excludedKeys: const {});

      final result = tally.update(second, excludedKeys: const {});

      expect(result.counts, {'a': 2, 'b': 1, 'c': 1});
      expect(result.unique, ['a', 'b', 'c']);
    });

    test('recounts after the oldest entries were evicted', () {
      final first = [keyed('a'), keyed('b')];
      final second = [first[1], keyed('c')];
      tally.update(first, excludedKeys: const {});

      final result = tally.update(second, excludedKeys: const {});

      expect(result.counts, {'b': 1, 'c': 1});
      expect(result.unique, ['b', 'c']);
    });

    test('empties after the history is cleared', () {
      tally.update([keyed('a')], excludedKeys: const {});

      final result = tally.update(const [], excludedKeys: const {});

      expect(result.counts, isEmpty);
      expect(result.unique, isEmpty);
    });

    test('returns the same result while the snapshot is unchanged', () {
      final logs = [keyed('a')];

      final first = tally.update(logs, excludedKeys: const {});

      expect(
        identical(tally.update(logs, excludedKeys: const {}), first),
        isTrue,
      );
    });

    test('recounts when the excluded keys change', () {
      final logs = [keyed('a'), keyed('b')];
      tally.update(logs, excludedKeys: const {});

      final result = tally.update(logs, excludedKeys: const {'a'});

      expect(result.counts, {'b': 1});
    });

    test('recounts when the caller mutates its excluded set in place', () {
      final logs = [keyed('a'), keyed('b')];
      final excluded = <String>{};
      tally.update(logs, excludedKeys: excluded);
      excluded.add('a');

      final result = tally.update(logs, excludedKeys: excluded);

      expect(result.counts, {'b': 1});
    });
  });
}
