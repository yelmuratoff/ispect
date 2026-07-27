import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _StoredCustomLog extends ISpectLogData {
  _StoredCustomLog(super.message, {super.additionalData});

  @override
  void notifyObserver(ISpectObserver observer) => observer.onException(this);
}

final class _RoutingObserver extends ISpectObserver {
  int errors = 0;
  int exceptions = 0;
  int logs = 0;

  @override
  void onError(ISpectLogData data) => errors++;

  @override
  void onException(ISpectLogData data) => exceptions++;

  @override
  void onLog(ISpectLogData data) => logs++;
}

void main() {
  test(
    'compile-time disabled constructor has no side effects',
    () async {
      final root = await Directory.systemTemp.createTemp('ispect-history-');
      addTearDown(() => root.delete(recursive: true));
      var providerCalls = 0;
      final history = RollingFileLogHistory(
        ISpectLoggerOptions(useConsoleLogs: false),
        directoryProvider: () async {
          providerCalls++;
          return root.path;
        },
      );

      await (history
            ..add(ISpectLogData('entry', id: 'A'))
            ..dispose())
          .saveToDailyFile();

      expect(providerCalls, 0);
      expect(await root.list().toList(), isEmpty);
    },
    skip: kISpectEnabled,
  );

  test('writes redacted unique records and reads the day in order', () async {
    final root = await Directory.systemTemp.createTemp('ispect-history-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    final later = ISpectLogData(
      'later',
      id: 'A',
      time: DateTime(2026, 7, 10, 10),
      additionalData: const {
        'authorization': 'Bearer persistence-secret',
      },
    );

    history
      ..add(later)
      ..add(ISpectLogData('duplicate', id: 'A', time: later.time))
      ..add(
        ISpectLogData(
          'earlier',
          id: 'B',
          time: DateTime(2026, 7, 10, 9),
        ),
      );

    expect(await root.list().toList(), isEmpty);

    await history.saveToDailyFile();

    final stored = await history.getLogsByDate(DateTime(2026, 7, 10));
    expect(stored.map((log) => log.id), ['B', 'A']);
    final datePath = await history.getLogPathByDate(DateTime(2026, 7, 10));
    final file = File('$datePath${Platform.pathSeparator}000000.jsonl');
    expect(await file.readAsString(), isNot(contains('persistence-secret')));
    expect(history.history.map((log) => log.id), ['A', 'B']);
  });

  test('live history retains built-in kinds and downgrades custom subtypes',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-history-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    final error = ISpectLogError(
      StateError('failure'),
      additionalData: const {TraceKeys.sessionId: 'UNTRUSTED-ERROR'},
    );
    final exception = ISpectLogException(
      const FormatException('failure'),
      additionalData: const {TraceKeys.sessionId: 'UNTRUSTED-EXCEPTION'},
    );
    final custom = _StoredCustomLog(
      'custom',
      additionalData: const {TraceKeys.sessionId: 'UNTRUSTED-CUSTOM'},
    );

    history
      ..add(error)
      ..add(exception)
      ..add(custom);

    expect(history.history[0], isNot(same(error)));
    expect(history.history[1], isNot(same(exception)));
    expect(history.history[2], isNot(same(custom)));
    expect(history.history[0], isA<ISpectLogError>());
    expect(history.history[1], isA<ISpectLogException>());
    expect(history.history[2], isA<ISpectLogData>());
    expect(history.history[2], isNot(isA<_StoredCustomLog>()));

    final observer = _RoutingObserver();
    for (final log in history.history) {
      log.notifyObserver(observer);
    }
    expect(observer.errors, 1);
    expect(observer.exceptions, 1);
    expect(observer.logs, 1);
    expect(await history.exportToJson(), isNot(contains('UNTRUSTED-')));
  });

  test('rotates before appending a complete line past the byte limit',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-history-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 300,
        maxTotalSize: 3000,
        enableAutoSave: false,
      ),
    );
    final date = DateTime(2026, 7, 10, 9);

    history
      ..add(ISpectLogData('a' * 80, id: 'A', time: date))
      ..add(ISpectLogData('b' * 80, id: 'B', time: date));
    await history.saveToDailyFile();

    final datePath = await history.getLogPathByDate(date);
    final files = await Directory(datePath)
        .list()
        .where((entity) => entity is File)
        .map((entity) => entity.path.split(Platform.pathSeparator).last)
        .toList();
    files.sort();

    expect(files, ['000000.jsonl', '000001.jsonl']);
    expect(
      (await history.getLogsByDate(date)).map((log) => log.id),
      ['A', 'B'],
    );
    for (final name in files) {
      final size =
          await File('$datePath${Platform.pathSeparator}$name').length();
      expect(size, lessThanOrEqualTo(300));
    }
  });
}
