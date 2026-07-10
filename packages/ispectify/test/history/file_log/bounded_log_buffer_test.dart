import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/bounded_log_buffer.dart';
import 'package:test/test.dart';

void main() {
  test('deduplicates by ID and evicts FIFO with a bounded index', () {
    final buffer = BoundedLogBuffer(
      ISpectLoggerOptions(maxHistoryItems: 2),
    );
    final first = ISpectLogData('first', id: 'A');
    final duplicate = ISpectLogData('duplicate', id: 'A');
    final second = ISpectLogData('second', id: 'B');
    final third = ISpectLogData('third', id: 'C');

    expect(buffer.add(first), isTrue);
    expect(buffer.add(duplicate), isFalse);
    expect(buffer.add(second), isTrue);
    expect(buffer.add(third), isTrue);
    expect(buffer.history.map((log) => log.id), ['B', 'C']);
  });

  test('returns an unmodifiable cached history view', () {
    final buffer = BoundedLogBuffer(ISpectLoggerOptions())
      ..add(ISpectLogData('entry', id: 'A'));
    final first = buffer.history;

    expect(first.clear, throwsUnsupportedError);
    expect(identical(first, buffer.history), isTrue);

    expect(buffer.add(ISpectLogData('duplicate', id: 'A')), isFalse);
    expect(identical(first, buffer.history), isTrue);

    buffer.add(ISpectLogData('next', id: 'B'));
    expect(identical(first, buffer.history), isFalse);
  });

  test('rejects entries when history is disabled or has zero capacity', () {
    final disabled = BoundedLogBuffer(
      ISpectLoggerOptions(enabled: false),
    );
    final unused = BoundedLogBuffer(
      ISpectLoggerOptions(useHistory: false),
    );
    final zero = BoundedLogBuffer(
      ISpectLoggerOptions(maxHistoryItems: 0),
    );
    final entry = ISpectLogData('entry', id: 'A');

    expect(disabled.add(entry), isFalse);
    expect(unused.add(entry), isFalse);
    expect(zero.add(entry), isFalse);
    expect(disabled.history, isEmpty);
    expect(unused.history, isEmpty);
    expect(zero.history, isEmpty);
  });

  test('replaceAll resets membership and preserves bounded input order', () {
    final buffer = BoundedLogBuffer(
      ISpectLoggerOptions(maxHistoryItems: 2),
    )
      ..add(ISpectLogData('old', id: 'OLD'))
      ..replaceAll([
        ISpectLogData('first', id: 'A'),
        ISpectLogData('duplicate', id: 'A'),
        ISpectLogData('second', id: 'B'),
        ISpectLogData('third', id: 'C'),
      ]);

    expect(buffer.history.map((log) => log.id), ['B', 'C']);
    expect(buffer.add(ISpectLogData('old again', id: 'OLD')), isTrue);
    expect(buffer.history.map((log) => log.id), ['C', 'OLD']);
  });

  test('clear removes entries and membership', () {
    final buffer = BoundedLogBuffer(ISpectLoggerOptions())
      ..add(ISpectLogData('entry', id: 'A'))
      ..clear();

    expect(buffer.history, isEmpty);
    expect(buffer.add(ISpectLogData('entry again', id: 'A')), isTrue);
  });
}
