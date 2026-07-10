import 'dart:convert';
import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  test('rejects a path outside the managed root', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final outside = File('${root.path}${Platform.pathSeparator}outside.jsonl');
    await outside.writeAsString('{}\n');
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);

    await expectLater(
      history.getLogsBySession(outside.path),
      throwsA(isA<FileLogAccessException>()),
    );
  });

  test('rejects a symlink that escapes the managed root', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final outside = File('${root.path}${Platform.pathSeparator}outside.jsonl');
    await outside.writeAsString('{}\n');
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final managedDate = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}2026-07-10',
    );
    await managedDate.create(recursive: true);
    final link =
        Link('${managedDate.path}${Platform.pathSeparator}000000.jsonl');
    try {
      await link.create(outside.path);
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable on this platform');
      return;
    }

    await expectLater(
      history.getLogsBySession(link.path),
      throwsA(isA<FileLogAccessException>()),
    );
  });

  test('rejects an unmanaged file even when it is inside the root', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final unmanaged = File(
      '${history.sessionDirectory}${Platform.pathSeparator}notes.txt',
    );
    await unmanaged.writeAsString('not history');

    await expectLater(
      history.getLogsBySession(unmanaged.path),
      throwsA(isA<FileLogAccessException>()),
    );
  });

  test('reads legacy arrays, merges segments, and deduplicates IDs', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final date = DateTime(2026, 7, 10, 9);
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    )..add(ISpectLogData('segment', id: 'A', time: date));
    addTearDown(history.dispose);
    await history.saveToDailyFile();
    final legacy = File(
      '${history.sessionDirectory}${Platform.pathSeparator}'
      'logs_2026-07-10.json',
    );
    await legacy.writeAsString(
      jsonEncode([
        ISpectLogData('duplicate', id: 'A', time: date).toJson(),
        ISpectLogData('legacy', id: 'B', time: date).toJson(),
      ]),
    );

    expect(
      (await history.getLogsByDate(date)).map((log) => log.id),
      ['A', 'B'],
    );
    expect(
      await history.getDateFileSize(date),
      await _ownedDateSize(history, date),
    );

    await history.clearDateStorage(date);
    expect(await legacy.exists(), isFalse);
    expect(await history.getLogPathByDate(date), isEmpty);
  });

  test('bounds imports before parsing and deduplicates accepted IDs', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 512,
        maxTotalSize: 512,
        enableAutoSave: false,
      ),
    );
    addTearDown(history.dispose);

    await expectLater(
      history.importFromJson('x' * 513),
      throwsA(isA<FileLogLimitException>()),
    );
    await expectLater(
      history.importFromJson('{}'),
      throwsA(isA<FileLogFormatException>()),
    );

    final duplicate = ISpectLogData('entry', id: 'A').toJson();
    await history.importFromJson(jsonEncode([duplicate, duplicate]));
    expect(history.history.map((log) => log.id), ['A']);
  });
}

Future<int> _ownedDateSize(
  RollingFileLogHistory history,
  DateTime date,
) async {
  final dateName = date.toIso8601String().substring(0, 10);
  final dateDirectory = Directory(
    '${history.sessionDirectory}${Platform.pathSeparator}$dateName',
  );
  var total = 0;
  if (await dateDirectory.exists()) {
    await for (final entity in dateDirectory.list()) {
      if (entity is File) total += await entity.length();
    }
  }
  final legacy = File(
    '${history.sessionDirectory}${Platform.pathSeparator}logs_$dateName.json',
  );
  if (await legacy.exists()) total += await legacy.length();
  return total;
}
