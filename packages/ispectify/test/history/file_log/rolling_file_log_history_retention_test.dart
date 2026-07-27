import 'dart:io';
import 'dart:math';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/file_log_codec.dart';
import 'package:ispectify/src/history/file_log/rolling_file_log_history_io.dart'
    as file_io;
import 'package:test/test.dart';

void main() {
  test('keeps only the newest configured number of dates', () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final history = file_io.RollingFileLogHistory.testing(
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
    final history = file_io.RollingFileLogHistory.testing(
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
    final oldMessageA =
        List<String>.generate(300, (index) => 'alpha-$index').join(',');
    final oldMessageB =
        List<String>.generate(300, (index) => 'bravo-$index').join(',');
    final laterMessage =
        List<String>.generate(550, (index) => 'charlie-$index').join(',');
    final oldBytes = <int>[
      ...codec
          .encode(
            ISpectLogData(oldMessageA, id: 'A', time: oldDate),
            sessionId: 'IMPORT-SESSION',
            maxBytes: 4096,
          )
          .bytes,
      ...codec
          .encode(
            ISpectLogData(oldMessageB, id: 'B', time: oldDate),
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
    final laterBytes = codec
        .encode(
          ISpectLogData(laterMessage, id: 'LATER', time: oldDate),
          sessionId: 'IMPORT-SESSION',
          maxBytes: 4096,
        )
        .bytes;
    final maxFileSize =
        max(oldBytes.length, max(activeBytes.length, laterBytes.length));
    final maxTotalSize = maxFileSize;
    expect(oldBytes.length + activeBytes.length, greaterThan(maxTotalSize));
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

    history.add(
      ISpectLogData(laterMessage, id: 'LATER', time: oldDate),
    );
    await history.saveToDailyFile();

    final laterSegment = File(
      '${oldDirectory.path}${Platform.pathSeparator}000001.jsonl',
    );
    expect(laterSegment.existsSync(), isTrue);
    expect(
      (await history.getLogsByDate(oldDate)).map((log) => log.id),
      ['LATER'],
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

  test('many flushes are not capped by the in-memory history setting',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final date = DateTime(2026, 7, 10, 9);
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false, maxHistoryItems: 1),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 256,
        maxTotalSize: 4096,
        enableAutoSave: false,
      ),
    );
    addTearDown(history.dispose);
    for (var index = 0; index < 12; index++) {
      history.add(ISpectLogData('entry-$index', id: 'ID-$index', time: date));
      await history.saveToDailyFile();
    }

    final directory = Directory(await history.getLogPathByDate(date));
    final segments = await directory
        .list()
        .where((entity) => entity.path.endsWith('.jsonl'))
        .toList();
    expect(segments.length, greaterThan(9));
    expect(await history.getLogsByDate(date), hasLength(12));
  });

  test('archive rejects an oversized source and leaves it recoverable',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 512,
        maxTotalSize: 512,
        enableAutoSave: false,
        cleanupStrategy: SessionCleanupStrategy.archiveOldest,
      ),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final oldDate = DateTime.now().subtract(const Duration(days: 1));
    final directory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}'
      '${oldDate.toIso8601String().substring(0, 10)}',
    );
    await directory.create();
    final source =
        File('${directory.path}${Platform.pathSeparator}000000.jsonl');
    await source.writeAsBytes(List<int>.filled(513, 65));
    history.add(ISpectLogData('active', time: DateTime.now()));

    await expectLater(
      history.saveToDailyFile(),
      throwsA(isA<FileLogLimitException>()),
    );
    expect(await source.exists(), isTrue);
    expect(await File('${source.path}.gz').exists(), isFalse);
  });

  test('archive bounds compressed output and cleans its temporary', () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 512,
        maxTotalSize: 512,
        enableAutoSave: false,
        cleanupStrategy: SessionCleanupStrategy.archiveOldest,
      ),
      archiveCompressedByteLimit: 16,
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final oldDate = DateTime.now().subtract(const Duration(days: 1));
    final directory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}'
      '${oldDate.toIso8601String().substring(0, 10)}',
    );
    await directory.create();
    final source =
        File('${directory.path}${Platform.pathSeparator}000000.jsonl');
    await source.writeAsBytes(List<int>.filled(400, 65));
    history.add(ISpectLogData('active', time: DateTime.now()));

    await expectLater(
      history.saveToDailyFile(),
      throwsA(isA<FileLogLimitException>()),
    );
    expect(await source.exists(), isTrue);
    expect(await File('${source.path}.gz').exists(), isFalse);
    expect(
      await directory
          .list()
          .where((entity) => entity.path.endsWith('.tmp'))
          .isEmpty,
      isTrue,
    );
  });

  test('archives incompressible input near the configured upper boundary',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    const maxFileSize = 64 * 1024;
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: maxFileSize,
        maxTotalSize: maxFileSize,
        enableAutoSave: false,
        cleanupStrategy: SessionCleanupStrategy.archiveOldest,
      ),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final oldDate = DateTime.now().subtract(const Duration(days: 1));
    final directory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}'
      '${oldDate.toIso8601String().substring(0, 10)}',
    );
    await directory.create();
    final source =
        File('${directory.path}${Platform.pathSeparator}000000.jsonl');
    final random = Random(7);
    await source.writeAsBytes(
      List<int>.generate(maxFileSize - 64, (_) => random.nextInt(256)),
    );
    history.add(ISpectLogData('active', time: DateTime.now()));

    await history.saveToDailyFile();

    expect(await source.exists(), isFalse);
  });

  test('recovers a completed archive left beside its source', () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 512,
        maxTotalSize: 512,
        enableAutoSave: false,
        cleanupStrategy: SessionCleanupStrategy.archiveOldest,
      ),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final oldDate = DateTime.now().subtract(const Duration(days: 1));
    final directory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}'
      '${oldDate.toIso8601String().substring(0, 10)}',
    );
    await directory.create();
    final source =
        File('${directory.path}${Platform.pathSeparator}000000.jsonl');
    final bytes = List<int>.filled(400, 65);
    await source.writeAsBytes(bytes);
    final archive = File('${source.path}.gz');
    await archive.writeAsBytes(gzip.encode(bytes));
    history.add(ISpectLogData('active', time: DateTime.now()));

    await history.saveToDailyFile();

    expect(await source.exists(), isFalse);
    expect(await archive.exists(), isTrue);
  });

  test('retention cleans legacy predictable archive temporaries', () async {
    final root = await Directory.systemTemp.createTemp('ispect-retention-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final date = DateTime(2026, 7, 10, 9);
    final directory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}2026-07-10',
    );
    await directory.create();
    final legacyTemporary = File(
      '${directory.path}${Platform.pathSeparator}000000.jsonl.gz.tmp',
    );
    await legacyTemporary.writeAsBytes(const [1, 2, 3]);
    history.add(ISpectLogData('entry', time: date));

    await history.saveToDailyFile();

    expect(await legacyTemporary.exists(), isFalse);
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
