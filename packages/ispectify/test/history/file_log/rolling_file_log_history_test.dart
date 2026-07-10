import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  test('compile-time disabled constructor has no side effects', () async {
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
  });

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
