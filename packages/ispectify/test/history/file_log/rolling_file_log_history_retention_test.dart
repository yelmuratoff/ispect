import 'dart:io';
import 'dart:math';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/file_log_codec.dart';
import 'package:test/test.dart';

void main() {
  test('keeps only the newest configured number of dates', () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 512,
        maxTotalSize: 16 * 1024,
        enableAutoSave: false,
      ),
    );
    addTearDown(history.dispose);
    for (var day = 3; day <= 10; day++) {
      history.add(
        ISpectLogData(
          'day-$day',
          id: 'ID-$day',
          time: DateTime(2026, 7, day, 9),
        ),
      );
    }

    await history.saveToDailyFile();

    expect(await history.getAvailableLogDates(), [
      for (var day = 4; day <= 10; day++) DateTime(2026, 7, day),
    ]);
  });

  test('deleteBySize uses age to break equal-size ties', () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 300,
        maxTotalSize: 600,
        enableAutoSave: false,
        cleanupStrategy: SessionCleanupStrategy.deleteBySize,
      ),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final oldLarge = await _writeSizedSegment(
      history.sessionDirectory,
      currentDate.subtract(const Duration(days: 2)),
      size: 300,
    );
    final newLarge = await _writeSizedSegment(
      history.sessionDirectory,
      currentDate.subtract(const Duration(days: 1)),
      size: 300,
    );
    await _writeSizedSegment(
      history.sessionDirectory,
      currentDate.subtract(const Duration(days: 3)),
      size: 20,
    );

    history.add(
      ISpectLogData('active', id: 'ACTIVE', time: currentDate),
    );
    await history.saveToDailyFile();

    expect(await oldLarge.exists(), isFalse);
    expect(await newLarge.exists(), isTrue);
    expect(await history.hasTodaySession(), isTrue);
  });

  test('archiveOldest gzip-compresses a closed segment and reads it back',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final codec = FileLogCodec(redactor: RedactionService());
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final oldDate = currentDate.subtract(const Duration(days: 1));
    final oldBytes = <int>[
      ...codec
          .encode(
            ISpectLogData('a' * 80, id: 'A', time: oldDate),
            sessionId: 'IMPORT-SESSION',
            maxBytes: 4096,
          )
          .bytes,
      ...codec
          .encode(
            ISpectLogData('b' * 80, id: 'B', time: oldDate),
            sessionId: 'IMPORT-SESSION',
            maxBytes: 4096,
          )
          .bytes,
    ];
    final activeBytes = codec
        .encode(
          ISpectLogData(
            'active',
            id: 'ACTIVE',
            time: currentDate,
          ),
          sessionId: '0' * 26,
          maxBytes: 4096,
        )
        .bytes;
    final maxFileSize = max(oldBytes.length, activeBytes.length);
    final maxTotalSize = max(
      maxFileSize,
      gzip.encode(oldBytes).length + activeBytes.length + 16,
    );
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: FileLogHistoryOptions(
        maxFileSize: maxFileSize,
        maxTotalSize: maxTotalSize,
        enableAutoSave: false,
        cleanupStrategy: SessionCleanupStrategy.archiveOldest,
      ),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final oldDirectory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}'
      '${oldDate.toIso8601String().substring(0, 10)}',
    );
    await oldDirectory.create(recursive: true);
    final source = File(
      '${oldDirectory.path}${Platform.pathSeparator}000000.jsonl',
    );
    await source.writeAsBytes(oldBytes);

    history.add(
      ISpectLogData('active', id: 'ACTIVE', time: currentDate),
    );
    await history.saveToDailyFile();

    final archive = File('${source.path}.gz');
    expect(await source.exists(), isFalse);
    expect(await archive.exists(), isTrue);
    expect(await history.getDateFileSize(oldDate), await archive.length());
    expect(
      (await history.getSessionStatistics()).totalSize,
      lessThanOrEqualTo(maxTotalSize),
    );
    expect(
      (await history.getLogsByDate(oldDate)).map((log) => log.id),
      ['A', 'B'],
    );
  });

  test('statistics include configured bounds, archives, and entries', () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxSessionDays: 3,
        maxFileSize: 512,
        maxTotalSize: 4096,
        autoSaveInterval: Duration(seconds: 3),
        enableAutoSave: false,
      ),
    )..add(
        ISpectLogData(
          'entry',
          id: 'A',
          time: DateTime(2026, 7, 10, 9),
        ),
      );
    addTearDown(history.dispose);
    await history.saveToDailyFile();

    final statistics = await history.getSessionStatistics();

    expect(statistics.totalDays, 1);
    expect(statistics.totalEntries, 1);
    expect(statistics.totalSize, greaterThan(0));
    expect(statistics.maxSessionDays, 3);
    expect(statistics.maxFileSize, 512);
    expect(statistics.maxTotalSize, 4096);
    expect(statistics.autoSaveInterval, const Duration(seconds: 3));
    expect(statistics.enableAutoSave, isFalse);
  });

  test('clearAllFileStorage preserves siblings of the managed root', () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final sibling = File('${root.path}${Platform.pathSeparator}keep.txt');
    await sibling.writeAsString('keep');
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    )..add(ISpectLogData('entry', id: 'A'));
    addTearDown(history.dispose);
    await history.saveToDailyFile();
    final unmanaged = File(
      '${history.sessionDirectory}${Platform.pathSeparator}notes.txt',
    );
    await unmanaged.writeAsString('keep');

    await history.clearAllFileStorage();

    expect(await sibling.exists(), isTrue);
    expect(await unmanaged.exists(), isTrue);
  });

  test('ignores date directories without managed history artifacts', () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final date = DateTime(2026, 7, 10);
    final directory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}2026-07-10',
    );
    await directory.create();
    await File('${directory.path}${Platform.pathSeparator}notes.txt')
        .writeAsString('unmanaged');

    expect(await history.getAvailableLogDates(), isEmpty);
    expect(await history.getLogPathByDate(date), isEmpty);
  });
}

Future<File> _writeSizedSegment(
  String sessionDirectory,
  DateTime date, {
  required int size,
}) async {
  final directory = Directory(
    '$sessionDirectory${Platform.pathSeparator}'
    '${date.toIso8601String().substring(0, 10)}',
  );
  await directory.create(recursive: true);
  final file = File('${directory.path}${Platform.pathSeparator}000000.jsonl');
  await file.writeAsString('x' * size);
  return file;
}
