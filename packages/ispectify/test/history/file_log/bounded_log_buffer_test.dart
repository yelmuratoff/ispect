import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/bounded_log_buffer.dart';
import 'package:test/test.dart';

final class _HostileBufferedLogGetters extends ISpectLogData {
  _HostileBufferedLogGetters(String id) : super('trusted', id: id);

  final List<int> _getterCalls = [0];

  int get getterCalls => _getterCalls.single;

  @override
  String get id {
    _getterCalls[0]++;
    throw StateError('FORGED_BUFFER_ID');
  }
}

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

  test('deduplication and eviction ignore hostile ID getter overrides', () {
    final buffer = BoundedLogBuffer(
      ISpectLoggerOptions(maxHistoryItems: 1),
    );
    final first = _HostileBufferedLogGetters('A');
    final duplicate = _HostileBufferedLogGetters('A');
    final second = _HostileBufferedLogGetters('B');

    expect(buffer.add(first), isTrue);
    expect(buffer.add(duplicate), isFalse);
    expect(buffer.add(second), isTrue);
    expect(buffer.history, hasLength(1));
    expect(identical(buffer.history.single, second), isTrue);
    expect(first.getterCalls, 0);
    expect(duplicate.getterCalls, 0);
    expect(second.getterCalls, 0);
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
