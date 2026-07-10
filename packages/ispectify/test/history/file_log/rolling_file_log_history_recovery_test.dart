import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  test('serializes concurrent saves without writing an ID twice', () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final initialization = Completer<void>();
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async {
        await initialization.future;
        return root.path;
      },
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    final date = DateTime(2026, 7, 10, 9);
    history.add(ISpectLogData('entry', id: 'A', time: date));

    final first = history.saveToDailyFile();
    final second = history.saveToDailyFile();
    initialization.complete();
    await Future.wait([first, second]);

    expect((await history.getLogsByDate(date)).map((log) => log.id), ['A']);
    expect(await _countJsonlLines(history, date), 1);
  });

  test('auto-save transitions replace the one pending timer', () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final timers = <_TestTimer>[];
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      timerFactory: (duration, callback) {
        final timer = _TestTimer(duration, callback);
        timers.add(timer);
        return timer;
      },
    );
    addTearDown(history.dispose);

    history.add(ISpectLogData('entry', id: 'A'));
    expect(timers, hasLength(1));
    expect(timers.single.duration, const Duration(seconds: 1));

    history.updateAutoSaveSettings(enabled: false);
    expect(timers.single.isActive, isFalse);
    history.updateAutoSaveSettings(interval: const Duration(seconds: 2));
    expect(timers, hasLength(1));
    history.updateAutoSaveSettings(enabled: true);
    expect(timers, hasLength(2));
    expect(timers.last.duration, const Duration(seconds: 2));

    final statistics = await history.getSessionStatistics();
    expect(statistics.enableAutoSave, isTrue);
    expect(statistics.autoSaveInterval, const Duration(seconds: 2));
  });

  test('imports original dates under a distinct shared import session',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    final firstDate = DateTime(2026, 7, 9, 9);
    final secondDate = DateTime(2026, 7, 10, 9);
    history.add(ISpectLogData('current', id: 'CURRENT', time: firstDate));

    await history.importFromJson(
      jsonEncode([
        ISpectLogData('first', id: 'A', time: firstDate).toJson(),
        ISpectLogData('second', id: 'B', time: secondDate).toJson(),
      ]),
    );
    await history.saveToDailyFile();

    expect(await history.getAvailableLogDates(), [
      DateTime(2026, 7, 9),
      DateTime(2026, 7, 10),
    ]);
    final records = await _readJsonlMaps(history, [firstDate, secondDate]);
    final sessions = <String, String>{
      for (final record in records)
        record['id']! as String: (record['additional-data']!
            as Map<String, dynamic>)[TraceKeys.sessionId]! as String,
    };
    expect(sessions['A'], sessions['B']);
    expect(sessions['A'], isNot(sessions['CURRENT']));
  });

  test('loading a date does not enqueue persisted entries again', () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final date = DateTime(2026, 7, 10, 9);
    final writer = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    )..add(ISpectLogData('entry', id: 'A', time: date));
    addTearDown(writer.dispose);
    await writer.saveToDailyFile();
    final loader = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(loader.dispose);

    await loader.loadFromDate(date);
    await loader.saveToDailyFile();

    expect(loader.history.map((log) => log.id), ['A']);
    expect(await _countJsonlLines(loader, date), 1);
  });

  test('repairs an incomplete tail before appending the next record', () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final date = DateTime(2026, 7, 10, 9);
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    )..add(ISpectLogData('first', id: 'A', time: date));
    addTearDown(history.dispose);
    await history.saveToDailyFile();
    final datePath = await history.getLogPathByDate(date);
    final segment = File('$datePath${Platform.pathSeparator}000000.jsonl');
    await segment.writeAsString('BROKEN_TAIL', mode: FileMode.append);

    history.add(ISpectLogData('second', id: 'B', time: date));
    await history.saveToDailyFile();

    expect(await segment.readAsString(), isNot(contains('BROKEN_TAIL')));
    expect(
      (await history.getLogsByDate(date)).map((log) => log.id),
      ['A', 'B'],
    );
  });

  test('restores a batch after a transient initialization failure', () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    var calls = 0;
    final date = DateTime(2026, 7, 10, 9);
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async {
        calls++;
        if (calls == 1) throw const FileSystemException('unavailable');
        return root.path;
      },
      options: const FileLogHistoryOptions(enableAutoSave: false),
    )..add(ISpectLogData('entry', id: 'A', time: date));
    addTearDown(history.dispose);

    await expectLater(
      history.saveToDailyFile(),
      throwsA(isA<FileLogStorageException>()),
    );
    await history.saveToDailyFile();

    expect((await history.getLogsByDate(date)).map((log) => log.id), ['A']);
    expect(calls, 2);
  });

  test('maxBatchItems replaces the trailing timer with an immediate flush',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final timers = <_TestTimer>[];
    final date = DateTime(2026, 7, 10, 9);
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        autoSaveInterval: Duration(hours: 1),
        maxBatchItems: 2,
      ),
      timerFactory: (duration, callback) {
        final timer = _TestTimer(duration, callback);
        timers.add(timer);
        return timer;
      },
    );
    addTearDown(history.dispose);

    history
      ..add(ISpectLogData('first', id: 'A', time: date))
      ..add(ISpectLogData('second', id: 'B', time: date));

    expect(timers, hasLength(2));
    expect(timers.first.isActive, isFalse);
    expect(timers.last.duration, Duration.zero);
    timers.last.fire();
    await history.saveToDailyFile();

    expect(
      (await history.getLogsByDate(date)).map((log) => log.id),
      ['A', 'B'],
    );
  });

  test('pending overflow reports bounded data loss without payload content',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    var unavailable = true;
    final errors = <FileLogHistoryException>[];
    final date = DateTime(2026, 7, 10, 9);
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false, maxHistoryItems: 2),
      directoryProvider: () async {
        if (unavailable) throw const FileSystemException('unavailable');
        return root.path;
      },
      options: FileLogHistoryOptions(
        enableAutoSave: false,
        onError: errors.add,
      ),
    )
      ..add(ISpectLogData('evicted-payload-marker', id: 'A', time: date))
      ..add(ISpectLogData('second', id: 'B', time: date));
    addTearDown(history.dispose);
    await expectLater(
      history.saveToDailyFile(),
      throwsA(isA<FileLogStorageException>()),
    );

    history.add(ISpectLogData('third', id: 'C', time: date));

    expect(errors, hasLength(1));
    expect(errors.single, isA<FileLogLimitException>());
    expect(errors.single.toString(), isNot(contains('evicted-payload-marker')));

    unavailable = false;
    await history.saveToDailyFile();
    expect(
      (await history.getLogsByDate(date)).map((log) => log.id),
      ['B', 'C'],
    );
  });

  test('restored failed batch stays within the pending limit', () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final providerStarted = Completer<void>();
    final releaseProvider = Completer<void>();
    final errors = <FileLogHistoryException>[];
    var unavailable = true;
    final date = DateTime(2026, 7, 10, 9);
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false, maxHistoryItems: 2),
      directoryProvider: () async {
        if (!providerStarted.isCompleted) providerStarted.complete();
        await releaseProvider.future;
        if (unavailable) throw const FileSystemException('unavailable');
        return root.path;
      },
      options: FileLogHistoryOptions(
        enableAutoSave: false,
        onError: errors.add,
      ),
    )
      ..add(ISpectLogData('first', id: 'A', time: date))
      ..add(ISpectLogData('second', id: 'B', time: date));
    addTearDown(history.dispose);

    final failedSave = history.saveToDailyFile();
    await providerStarted.future;
    history
      ..add(ISpectLogData('third', id: 'C', time: date))
      ..add(ISpectLogData('fourth', id: 'D', time: date));
    releaseProvider.complete();
    await expectLater(failedSave, throwsA(isA<FileLogStorageException>()));

    expect(errors.whereType<FileLogLimitException>(), hasLength(2));
    unavailable = false;
    await history.saveToDailyFile();
    expect(
      (await history.getLogsByDate(date)).map((log) => log.id),
      ['C', 'D'],
    );
  });

  test('export preserves an imported session ID', () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    await history.importFromJson(
      jsonEncode([
        ISpectLogData(
          'imported',
          id: 'A',
          additionalData: const {TraceKeys.sessionId: 'ORIGINAL-SESSION'},
        ).toJson(),
      ]),
    );

    final exported = jsonDecode(await history.exportToJson()) as List<dynamic>;
    final record = exported.single as Map<String, dynamic>;
    final additionalData = record['additional-data'] as Map<String, dynamic>;

    expect(additionalData[TraceKeys.sessionId], 'ORIGINAL-SESSION');
  });

  test('clear cancels the pending auto-save timer', () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    var providerCalls = 0;
    late _TestTimer timer;
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async {
        providerCalls++;
        return root.path;
      },
      timerFactory: (duration, callback) =>
          timer = _TestTimer(duration, callback),
    );
    addTearDown(history.dispose);

    history
      ..add(ISpectLogData('entry', id: 'A'))
      ..clear();
    timer.fire();
    await Future<void>.delayed(Duration.zero);

    expect(timer.isActive, isFalse);
    expect(providerCalls, 0);
  });

  test('skips malformed complete lines and ignores one incomplete tail',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final errors = <FileLogHistoryException>[];
    final date = DateTime(2026, 7, 10, 9);
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: FileLogHistoryOptions(
        enableAutoSave: false,
        onError: errors.add,
      ),
    )..add(ISpectLogData('entry', id: 'A', time: date));
    addTearDown(history.dispose);
    await history.saveToDailyFile();
    final datePath = await history.getLogPathByDate(date);
    final segment = File('$datePath${Platform.pathSeparator}000000.jsonl');
    await segment.writeAsString(
      'not-json\nincomplete-tail',
      mode: FileMode.append,
    );

    expect((await history.getLogsByDate(date)).map((log) => log.id), ['A']);
    expect(errors.whereType<FileLogFormatException>(), hasLength(1));
  });

  test('background auto-save reports failure and retains its batch', () async {
    final root = await Directory.systemTemp.createTemp('ispect-recovery-');
    addTearDown(() => root.delete(recursive: true));
    var unavailable = true;
    final reported = Completer<FileLogHistoryException>();
    late _TestTimer timer;
    final date = DateTime(2026, 7, 10, 9);
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async {
        if (unavailable) throw const FileSystemException('unavailable');
        return root.path;
      },
      options: FileLogHistoryOptions(
        onError: (error) {
          if (!reported.isCompleted) reported.complete(error);
        },
      ),
      timerFactory: (duration, callback) =>
          timer = _TestTimer(duration, callback),
    );
    addTearDown(history.dispose);
    history.add(ISpectLogData('entry', id: 'A', time: date));

    timer.fire();
    expect(await reported.future, isA<FileLogStorageException>());

    unavailable = false;
    await history.saveToDailyFile();
    expect((await history.getLogsByDate(date)).map((log) => log.id), ['A']);
  });
}

Future<int> _countJsonlLines(
  RollingFileLogHistory history,
  DateTime date,
) async {
  final path = await history.getLogPathByDate(date);
  var count = 0;
  await for (final entity in Directory(path).list()) {
    if (entity is File && entity.path.endsWith('.jsonl')) {
      count +=
          (await entity.readAsLines()).where((line) => line.isNotEmpty).length;
    }
  }
  return count;
}

Future<List<Map<String, dynamic>>> _readJsonlMaps(
  RollingFileLogHistory history,
  Iterable<DateTime> dates,
) async {
  final records = <Map<String, dynamic>>[];
  for (final date in dates) {
    final path = await history.getLogPathByDate(date);
    await for (final entity in Directory(path).list()) {
      if (entity is! File || !entity.path.endsWith('.jsonl')) continue;
      for (final line in await entity.readAsLines()) {
        if (line.isNotEmpty) {
          records.add(jsonDecode(line) as Map<String, dynamic>);
        }
      }
    }
  }
  return records;
}

final class _TestTimer implements Timer {
  _TestTimer(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;
  bool _isActive = true;
  int _tick = 0;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;

  @override
  void cancel() => _isActive = false;

  void fire() {
    if (!_isActive) return;
    _isActive = false;
    _tick++;
    _callback();
  }
}
