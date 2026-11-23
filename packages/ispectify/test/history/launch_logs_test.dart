import 'dart:convert';
import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

import '../helpers/private_temp_directory.dart';

const _launchA = '01JAAAAAAAAAAAAAAAAAAAAAAA';
const _launchB = '01JBBBBBBBBBBBBBBBBBBBBBBB';

ISpectLogData _log(
  String message, {
  required DateTime time,
  String? launchId,
  LogLevel? logLevel,
}) =>
    ISpectLogData(
      message,
      time: time,
      logLevel: logLevel,
      additionalData: launchId == null ? null : {TraceKeys.sessionId: launchId},
    );

void main() {
  group('LaunchLogs.groupByLaunch', () {
    test('returns no launches for no logs', () {
      expect(LaunchLogs.groupByLaunch(const []), isEmpty);
    });

    test('orders launches newest first and keeps entry order inside each', () {
      final logs = [
        _log('a1', time: DateTime(2026, 3, 2, 9), launchId: _launchA),
        _log('b1', time: DateTime(2026, 3, 2, 14), launchId: _launchB),
        _log('a2', time: DateTime(2026, 3, 2, 9, 30), launchId: _launchA),
        _log('b2', time: DateTime(2026, 3, 2, 15), launchId: _launchB),
      ];

      final launches = LaunchLogs.groupByLaunch(logs);

      expect(launches.map((l) => l.id), [_launchB, _launchA]);
      expect(launches.first.logs.map((l) => l.message), ['b1', 'b2']);
      expect(launches.last.logs.map((l) => l.message), ['a1', 'a2']);
    });

    test('spans the earliest to the latest entry of a launch', () {
      final launch = LaunchLogs.groupByLaunch([
        _log('late', time: DateTime(2026, 3, 2, 10), launchId: _launchA),
        _log('early', time: DateTime(2026, 3, 2, 8), launchId: _launchA),
        _log('middle', time: DateTime(2026, 3, 2, 9), launchId: _launchA),
      ]).single;

      expect(launch.startedAt, DateTime(2026, 3, 2, 8));
      expect(launch.endedAt, DateTime(2026, 3, 2, 10));
    });

    test('counts error entries per launch', () {
      final launches = LaunchLogs.groupByLaunch([
        _log('ok', time: DateTime(2026, 3, 2, 9), launchId: _launchA),
        _log(
          'failed',
          time: DateTime(2026, 3, 2, 9, 1),
          launchId: _launchA,
          logLevel: LogLevel.error,
        ),
        _log(
          'crashed',
          time: DateTime(2026, 3, 2, 9, 2),
          launchId: _launchA,
          logLevel: LogLevel.critical,
        ),
        _log('clean', time: DateTime(2026, 3, 2, 8), launchId: _launchB),
      ]);

      expect(
        {for (final launch in launches) launch.id: launch.errorCount},
        {_launchA: 2, _launchB: 0},
      );
    });

    test('puts entries without a launch ID last, under a null id', () {
      final launches = LaunchLogs.groupByLaunch([
        _log('legacy', time: DateTime(2026, 3, 2, 23)),
        _log('blank', time: DateTime(2026, 3, 2, 22), launchId: ''),
        _log('tracked', time: DateTime(2026, 3, 2, 8), launchId: _launchA),
      ]);

      expect(launches.map((l) => l.id), [_launchA, null]);
      expect(launches.last.logs.map((l) => l.message), ['legacy', 'blank']);
    });

    test('returns lists the caller cannot modify', () {
      final launches = LaunchLogs.groupByLaunch([
        _log('a', time: DateTime(2026, 3, 2), launchId: _launchA),
      ]);

      expect(() => launches.add(launches.single), throwsUnsupportedError);
      expect(
        () => launches.single.logs.add(launches.single.logs.single),
        throwsUnsupportedError,
      );
    });

    test(
      'groups logs read back from file history by the launch that wrote them',
      () async {
        final root = await createPrivateTempDirectory('ispect-launches-');
        addTearDown(() => root.delete(recursive: true));
        final day = DateTime(2026, 3, 2);
        final options = ISpectLoggerOptions(useConsoleLogs: false);
        Future<String> provider() async => root.path;

        final firstLaunch = RollingFileLogHistory.testing(
          options,
          directoryProvider: provider,
          options: const FileLogHistoryOptions(enableAutoSave: false),
        );
        addTearDown(firstLaunch.dispose);
        firstLaunch.add(ISpectLogData('first', time: DateTime(2026, 3, 2, 9)));
        await firstLaunch.saveToDailyFile();

        final secondLaunch = RollingFileLogHistory.testing(
          options,
          directoryProvider: provider,
          options: const FileLogHistoryOptions(enableAutoSave: false),
        );
        addTearDown(secondLaunch.dispose);
        secondLaunch
          ..add(ISpectLogData('second', time: DateTime(2026, 3, 2, 14)))
          ..add(
            ISpectLogData(
              'second failed',
              time: DateTime(2026, 3, 2, 14, 5),
              logLevel: LogLevel.error,
            ),
          );
        await secondLaunch.saveToDailyFile();

        final launches = LaunchLogs.groupByLaunch(
          await secondLaunch.getLogsByDate(day),
        );

        expect(launches, hasLength(2));
        expect(launches.every((l) => l.id != null), isTrue);
        expect(
          launches.map((l) => l.logs.map((log) => log.message).toList()),
          [
            ['second', 'second failed'],
            ['first'],
          ],
        );
        expect(launches.map((l) => l.errorCount), [1, 0]);
      },
      skip: !kISpectEnabled,
    );

    test(
      'keeps stored logs without a trusted launch ID out of the current launch',
      () async {
        final root = await createPrivateTempDirectory('ispect-launches-');
        addTearDown(() => root.delete(recursive: true));
        final day = DateTime(2026, 3, 2);
        final history = RollingFileLogHistory.testing(
          ISpectLoggerOptions(useConsoleLogs: false),
          directoryProvider: () async => root.path,
          options: const FileLogHistoryOptions(enableAutoSave: false),
        );
        addTearDown(history.dispose);
        history.add(ISpectLogData('current', time: DateTime(2026, 3, 2, 14)));
        await history.saveToDailyFile();

        final separator = Platform.pathSeparator;
        await File(
          '${history.sessionDirectory}${separator}logs_2026-03-02.json',
        ).writeAsString(
          jsonEncode([
            ISpectLogData('legacy', time: DateTime(2026, 3, 2, 8)).toJson(),
          ]),
        );
        final segment = File(
          '${history.sessionDirectory}${separator}2026-03-02$separator'
          '000001.jsonl',
        );
        await segment.writeAsString(
          '${jsonEncode({
                'id': 'TAMPERED',
                'time': DateTime(2026, 3, 2, 9).toIso8601String(),
                'message': 'tampered',
                'additional-data': {TraceKeys.sessionId: 'not-a-launch-id'},
              })}\n',
        );

        final launches = LaunchLogs.groupByLaunch(
          await history.getLogsByDate(day),
        );

        expect(launches, hasLength(2));
        expect(launches.first.logs.map((l) => l.message), ['current']);
        expect(launches.last.id, isNull);
        expect(
          launches.last.logs.map((l) => l.message),
          unorderedEquals(['legacy', 'tampered']),
        );
      },
      skip: !kISpectEnabled,
    );

    test('treats a malformed launch ID as unknown', () {
      final launches = LaunchLogs.groupByLaunch([
        _log('forged', time: DateTime(2026, 3, 2, 9), launchId: 'Bearer x'),
      ]);

      expect(launches.single.id, isNull);
    });
  });
}
