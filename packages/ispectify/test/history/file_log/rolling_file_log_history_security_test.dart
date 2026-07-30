import 'dart:convert';
import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/rolling_file_log_history_io.dart'
    as file_io;
import 'package:test/test.dart';

final class _HostileFileErrorOutput {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('HOSTILE_FILE_ERROR_FORMATTER');
  }
}

final class _HostileFileErrorRedactor extends RedactionService {
  _HostileFileErrorRedactor(this.output);

  final _HostileFileErrorOutput output;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      output;
}

final class _HostileRollingLogGetters extends ISpectLogData {
  _HostileRollingLogGetters()
      : super(
          'trusted-rolling-message',
          id: 'trusted-rolling-id',
          time: DateTime.utc(2026, 7, 10),
          key: 'trusted-rolling-key',
          logLevel: LogLevel.info,
          additionalData: const {
            TraceKeys.sessionId: 'ATTACKER_SESSION',
            'trusted': 'rolling-data',
          },
        );

  final List<int> _getterCalls = [0];

  int get getterCalls => _getterCalls.single;

  Never _forged() {
    _getterCalls[0]++;
    throw StateError('FORGED_ROLLING_GETTER_SECRET');
  }

  @override
  String get id => _forged();

  @override
  DateTime get time => _forged();

  @override
  String? get key => _forged();

  @override
  LogLevel? get logLevel => _forged();

  @override
  Map<String, dynamic>? get additionalData => _forged();

  @override
  Object? get exception => _forged();

  @override
  Error? get error => _forged();

  @override
  StackTrace? get stackTrace => _forged();

  @override
  Object? get messageForSerialization => _forged();
}

void main() {
  tearDown(() => ISpectRedaction.enabled = true);

  test('rejects a missing provider without creating it', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final missing = Directory(
      '${root.path}${Platform.pathSeparator}missing',
    );
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => missing.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);

    await expectLater(
      history.getAvailableLogDates(),
      throwsA(isA<FileLogAccessException>()),
    );
    expect(await missing.exists(), isFalse);
  });

  test('rejects a group- or world-accessible provider directory', () async {
    if (Platform.isWindows) {
      markTestSkipped('POSIX permission bits are unavailable on Windows');
      return;
    }
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final chmod = await Process.run('chmod', ['0755', root.path]);
    expect(chmod.exitCode, 0);
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);

    await expectLater(
      history.getAvailableLogDates(),
      throwsA(isA<FileLogAccessException>()),
    );
  });

  test('revalidates provider permissions after initialization', () async {
    if (Platform.isWindows) {
      markTestSkipped('POSIX permission bits are unavailable on Windows');
      return;
    }
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final chmod = await Process.run('chmod', ['0755', root.path]);
    expect(chmod.exitCode, 0);

    await expectLater(
      history.getAvailableLogDates(),
      throwsA(isA<FileLogAccessException>()),
    );
  });

  test('rejects a symbolic-link provider directory', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final target = Directory(
      '${root.path}${Platform.pathSeparator}target',
    );
    await target.create();
    final link = Link('${root.path}${Platform.pathSeparator}provider');
    try {
      await link.create(target.path);
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable on this platform');
      return;
    }
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => link.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);

    await expectLater(
      history.getAvailableLogDates(),
      throwsA(isA<FileLogAccessException>()),
    );
  });

  test('rejects a group- or world-writable managed directory', () async {
    if (Platform.isWindows) {
      markTestSkipped('POSIX permission bits are unavailable on Windows');
      return;
    }
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final managed = Directory(
      '${root.path}${Platform.pathSeparator}ispect_logs',
    );
    await managed.create();
    final chmod = await Process.run('chmod', ['0777', managed.path]);
    expect(chmod.exitCode, 0);
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);

    await expectLater(
      history.getAvailableLogDates(),
      throwsA(isA<FileLogAccessException>()),
    );
  });

  test('rejects a path outside the managed root', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final outside = File('${root.path}${Platform.pathSeparator}outside.jsonl');
    await outside.writeAsString('{}\n');
    final history = file_io.RollingFileLogHistory.testing(
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
    final history = file_io.RollingFileLogHistory.testing(
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
    final history = file_io.RollingFileLogHistory.testing(
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

  test('sanitizes imported records unless redaction is explicitly disabled',
      () async {
    const secret = 'RAW-IMPORT-SECRET';
    Future<file_io.RollingFileLogHistory> createHistory(String suffix) async {
      final root =
          await Directory.systemTemp.createTemp('ispect-import-$suffix-');
      addTearDown(() => root.delete(recursive: true));
      final history = file_io.RollingFileLogHistory.testing(
        ISpectLoggerOptions(useConsoleLogs: false),
        directoryProvider: () async => root.path,
        options: const FileLogHistoryOptions(enableAutoSave: false),
      );
      addTearDown(history.dispose);
      return history;
    }

    final rawRecord = jsonEncode([
      {
        'id': 'RAW',
        'time': DateTime(2026, 7, 10).toIso8601String(),
        'message': 'GET /private?token=$secret',
        'additional-data': {
          'authorization': 'Bearer $secret',
          TraceKeys.sessionId: 'ATTACKER-SESSION',
        },
      },
    ]);

    final protected = await createHistory('protected');
    await protected.importFromJson(rawRecord);
    expect(
      protected.history.single.toJson().toString(),
      isNot(contains(secret)),
    );
    expect(
      protected.history.single.additionalData?[TraceKeys.sessionId],
      isNot('ATTACKER-SESSION'),
    );

    ISpectRedaction.enabled = false;
    final optedOut = await createHistory('opted-out');
    await optedOut.importFromJson(rawRecord);
    expect(optedOut.history.single.message, contains(secret));
    expect(optedOut.history.single.additionalData.toString(), contains(secret));
    expect(
      optedOut.history.single.additionalData?[TraceKeys.sessionId],
      isNot('ATTACKER-SESSION'),
    );
  });

  test('does not retain malformed import source in the reported cause',
      () async {
    const marker = 'MALFORMED_IMPORT_INPUT_MARKER';
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);

    await expectLater(
      history.importFromJson('[{"message":"$marker"}'),
      throwsA(
        isA<FileLogFormatException>()
            .having(
              (error) => (error.cause as FormatException?)?.source,
              'cause source',
              isNull,
            )
            .having(
              (error) => '${error.cause}',
              'cause text',
              isNot(contains(marker)),
            ),
      ),
    );
  });

  test('rejects a managed child symlink before read or mutation', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final date = DateTime(2026, 7, 10, 9);
    final outside = File(
      '${root.path}${Platform.pathSeparator}outside-segment.jsonl',
    );
    const outsideContents = '{"id":"OUTSIDE"}\nINCOMPLETE_OUTSIDE_TAIL';
    await outside.writeAsString(outsideContents);
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
    final dateDirectory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}2026-07-10',
    );
    await dateDirectory.create();
    final link = Link(
      '${dateDirectory.path}${Platform.pathSeparator}000000.jsonl',
    );
    try {
      await link.create(outside.path);
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable on this platform');
      return;
    }

    await expectLater(
      history.getLogsByDate(date),
      throwsA(isA<FileLogAccessException>()),
    );
    await expectLater(
      history.getDateFileSize(date),
      throwsA(isA<FileLogAccessException>()),
    );
    history.add(ISpectLogData('new entry', id: 'NEW', time: date));
    await expectLater(
      history.saveToDailyFile(),
      throwsA(isA<FileLogAccessException>()),
    );
    await expectLater(
      history.clearDateStorage(date),
      throwsA(isA<FileLogAccessException>()),
    );
    await expectLater(
      history.clearAllFileStorage(),
      throwsA(isA<FileLogAccessException>()),
    );

    expect(await outside.exists(), isTrue);
    expect(await outside.readAsString(), outsideContents);
    expect(await File('${outside.path}.gz').exists(), isFalse);
  });

  test('rejects a linked closed segment before retention can archive it',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final currentDate = DateTime.now();
    final outside = File(
      '${root.path}${Platform.pathSeparator}outside-archive-source.jsonl',
    );
    const outsideContents = '{"id":"OUTSIDE_ARCHIVE_SOURCE"}\n';
    await outside.writeAsString(outsideContents);
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
    final oldDirectory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}2026-07-10',
    );
    await oldDirectory.create();
    final link = Link(
      '${oldDirectory.path}${Platform.pathSeparator}000000.jsonl',
    );
    try {
      await link.create(outside.path);
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable on this platform');
      return;
    }
    history.add(ISpectLogData('current', id: 'CURRENT', time: currentDate));

    await expectLater(
      history.saveToDailyFile(),
      throwsA(isA<FileLogAccessException>()),
    );

    expect(await outside.exists(), isTrue);
    expect(await outside.readAsString(), outsideContents);
    expect(await File('${outside.path}.gz').exists(), isFalse);
  });

  test('rejects a managed date-directory symlink before read or mutation',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final date = DateTime(2026, 7, 10, 9);
    final outsideDirectory = Directory(
      '${root.path}${Platform.pathSeparator}outside-date',
    );
    await outsideDirectory.create();
    final outside = File(
      '${outsideDirectory.path}${Platform.pathSeparator}000000.jsonl',
    );
    const outsideContents = '{"id":"OUTSIDE"}\nINCOMPLETE_OUTSIDE_TAIL';
    await outside.writeAsString(outsideContents);
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
    final link = Link(
      '${history.sessionDirectory}${Platform.pathSeparator}2026-07-10',
    );
    try {
      await link.create(outsideDirectory.path);
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable on this platform');
      return;
    }

    await expectLater(
      history.getAvailableLogDates(),
      throwsA(isA<FileLogAccessException>()),
    );
    await expectLater(
      history.getLogsByDate(date),
      throwsA(isA<FileLogAccessException>()),
    );
    history.add(ISpectLogData('new entry', id: 'NEW', time: date));
    await expectLater(
      history.saveToDailyFile(),
      throwsA(isA<FileLogAccessException>()),
    );
    await expectLater(
      history.clearDateStorage(date),
      throwsA(isA<FileLogAccessException>()),
    );

    expect(await outside.exists(), isTrue);
    expect(await outside.readAsString(), outsideContents);
    expect(await File('${outside.path}.gz').exists(), isFalse);
  });

  test('replaces an untrusted session ID on live logs before and after flush',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    final live = ISpectLogData(
      'live',
      id: 'LIVE',
      additionalData: const {
        TraceKeys.sessionId: 'ATTACKER_SESSION',
      },
    );
    history.add(live);

    expect(history.history.single, isNot(same(live)));
    expect(history.history.single.id, 'LIVE');
    expect(await history.exportToJson(), isNot(contains('ATTACKER_SESSION')));

    await history.saveToDailyFile();
    final persisted = await history.getLogsByDate(DateTime.now());
    expect(
      persisted.single.additionalData?[TraceKeys.sessionId],
      isNot('ATTACKER_SESSION'),
    );
    expect(await history.exportToJson(), isNot(contains('ATTACKER_SESSION')));
  });

  test('session scrubbing ignores hostile live-log getter overrides', () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    final live = _HostileRollingLogGetters();
    history.add(live);

    final exported = await history.exportToJson();
    await history.saveToDailyFile();
    final persisted = await history.getLogsByDate(DateTime.utc(2026, 7, 10));

    expect(exported, contains('trusted-rolling-message'));
    expect(exported, isNot(contains('ATTACKER_SESSION')));
    expect(exported, isNot(contains('FORGED_ROLLING_GETTER_SECRET')));
    expect(persisted, hasLength(1));
    expect(persisted.single.id, 'trusted-rolling-id');
    expect(live.getterCalls, 0);
  });

  test('replaces a tampered stored session ID before active-redaction reads',
      () async {
    const secret = 'Bearer STORED_SESSION_SECRET';
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final date = DateTime(2026, 7, 10);
    final dateDirectory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}2026-07-10',
    );
    await dateDirectory.create();
    final segment = File(
      '${dateDirectory.path}${Platform.pathSeparator}000000.jsonl',
    );
    await segment.writeAsString(
      '${jsonEncode({
            'id': 'TAMPERED',
            'time': date.toIso8601String(),
            'message': 'safe',
            'additional-data': {TraceKeys.sessionId: secret},
          })}\n',
    );

    final logs = await history.getLogsByDate(date);

    expect(logs, hasLength(1));
    final sessionId =
        logs.single.additionalData?[TraceKeys.sessionId] as String?;
    expect(sessionId, isNot(secret));
    expect(sessionId, isNot(contains('STORED_SESSION_SECRET')));
    expect(sessionId, hasLength(26));
  });

  test('file error reporting never formats custom redactor output', () async {
    final hostile = _HostileFileErrorOutput();
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
      redactor: _HostileFileErrorRedactor(hostile),
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final date = DateTime(2026, 7, 10);
    final dateDirectory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}2026-07-10',
    );
    await dateDirectory.create();
    await File(
      '${dateDirectory.path}${Platform.pathSeparator}000000.jsonl',
    ).writeAsString('{malformed-json}\n');

    await history.getLogsByDate(date);

    expect(hostile.toStringCalls, 0);
  });

  test('rejects a JSONL line before materializing maxFileSize plus one',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final history = RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 128,
        maxTotalSize: 1024,
        enableAutoSave: false,
      ),
    );
    addTearDown(history.dispose);
    final line = jsonEncode({
      'time': DateTime(2026, 7, 10).toIso8601String(),
      'message': 'x' * 129,
    });

    await expectLater(
      history.importFromJson(line),
      throwsA(isA<FileLogLimitException>()),
    );
  });

  test('rejects a segment swapped to a symlink immediately before read',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final outside = File('${root.path}${Platform.pathSeparator}outside-read');
    const outsideContents = 'outside-read-must-not-be-consumed';
    await outside.writeAsString(outsideContents);
    var swapped = false;
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
      ioHook: (file, operation) async {
        if (swapped || operation != 'readSegment') return;
        swapped = true;
        await file.rename('${file.path}.original');
        await Link(file.path).create(outside.path);
      },
    );
    addTearDown(history.dispose);
    final date = DateTime(2026, 7, 10, 9);
    history.add(ISpectLogData('entry', id: 'A', time: date));
    await history.saveToDailyFile();

    try {
      await expectLater(
        history.getLogsByDate(date),
        throwsA(isA<FileLogAccessException>()),
      );
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable on this platform');
    }
    expect(await outside.readAsString(), outsideContents);
  });

  test('rejects a segment swapped to a symlink immediately before append',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final outside = File('${root.path}${Platform.pathSeparator}outside-append');
    const outsideContents = 'outside-append-must-not-change';
    await outside.writeAsString(outsideContents);
    var swapped = false;
    var armed = false;
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(enableAutoSave: false),
      ioHook: (file, operation) async {
        if (!armed || swapped || operation != 'appendRecord') return;
        swapped = true;
        await file.rename('${file.path}.original');
        await Link(file.path).create(outside.path);
      },
    );
    addTearDown(history.dispose);
    final date = DateTime(2026, 7, 10, 9);
    history.add(ISpectLogData('first', id: 'A', time: date));
    await history.saveToDailyFile();
    armed = true;
    history.add(ISpectLogData('second', id: 'B', time: date));

    try {
      await expectLater(
        history.saveToDailyFile(),
        throwsA(isA<FileLogAccessException>()),
      );
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable on this platform');
    }
    expect(await outside.readAsString(), outsideContents);
  });

  test('exclusive archive temporary never writes through a raced symlink',
      () async {
    final root = await Directory.systemTemp.createTemp('ispect-security-');
    addTearDown(() => root.delete(recursive: true));
    final outside = File('${root.path}${Platform.pathSeparator}outside-temp');
    const outsideContents = 'outside-temp-must-not-change';
    await outside.writeAsString(outsideContents);
    var swapped = false;
    final history = file_io.RollingFileLogHistory.testing(
      ISpectLoggerOptions(useConsoleLogs: false),
      directoryProvider: () async => root.path,
      options: const FileLogHistoryOptions(
        maxFileSize: 512,
        maxTotalSize: 512,
        enableAutoSave: false,
        cleanupStrategy: SessionCleanupStrategy.archiveOldest,
      ),
      ioHook: (file, operation) async {
        if (swapped || operation != 'archiveTemporary') return;
        swapped = true;
        await file.delete();
        await Link(file.path).create(outside.path);
      },
    );
    addTearDown(history.dispose);
    await history.getAvailableLogDates();
    final oldDate = DateTime.now().subtract(const Duration(days: 1));
    final oldDirectory = Directory(
      '${history.sessionDirectory}${Platform.pathSeparator}'
      '${oldDate.toIso8601String().substring(0, 10)}',
    );
    await oldDirectory.create();
    final source =
        File('${oldDirectory.path}${Platform.pathSeparator}000000.jsonl');
    await source.writeAsBytes(List<int>.filled(400, 65));
    history.add(ISpectLogData('active', time: DateTime.now()));

    try {
      await expectLater(
        history.saveToDailyFile(),
        throwsA(isA<FileLogAccessException>()),
      );
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable on this platform');
    }
    expect(await outside.readAsString(), outsideContents);
    expect(await source.exists(), isTrue);
    expect(
      await oldDirectory
          .list()
          .where((entity) => entity.path.endsWith('.tmp'))
          .isEmpty,
      isTrue,
    );
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
