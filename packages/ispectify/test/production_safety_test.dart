import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _ProductionObserver extends ISpectObserver {
  int calls = 0;

  @override
  void onLog(ISpectLogData data) {
    calls++;
  }
}

void main() {
  test(
    'direct logger remains disabled when ISPECT_ENABLED is omitted',
    () {
      expect(kISpectEnabled, isFalse);

      final logger = ISpectLogger(
        options: ISpectLoggerOptions(
          useConsoleLogs: false,
        ),
      );
      addTearDown(logger.dispose);

      final observer = _ProductionObserver();
      logger
        ..addObserver(observer)
        ..configure(options: ISpectLoggerOptions())
        ..enable()
        ..info(
          'synthetic production diagnostic',
          additionalData: const {'token': 'synthetic-secret'},
        )
        ..good('synthetic good diagnostic')
        ..track('synthetic analytics diagnostic')
        ..print('synthetic print diagnostic')
        ..route('synthetic route diagnostic')
        ..provider('synthetic provider diagnostic')
        ..handle(exception: Exception('synthetic exception'));

      expect(logger.options.enabled, isFalse);
      expect(logger.history, isEmpty);
      expect(logger.hasObservers, isFalse);
      expect(observer.calls, 0);
    },
    skip: kISpectEnabled
        ? 'This regression exercises a build without ISPECT_ENABLED.'
        : false,
  );

  test(
    'testing and fake loggers cannot bypass the compile-time gate',
    () {
      expect(kISpectEnabled, isFalse);

      final testing = ISpectLogger.testing();
      final fake = FakeISpectLogger();
      addTearDown(testing.dispose);
      addTearDown(fake.dispose);

      testing.info('testing-secret');
      fake.info('fake-secret');

      expect(testing.options.enabled, isFalse);
      expect(testing.history, isEmpty);
      expect(fake.options.enabled, isFalse);
      expect(fake.traces, isEmpty);
    },
    skip: kISpectEnabled
        ? 'This regression exercises a build without ISPECT_ENABLED.'
        : false,
  );

  test(
    'direct history APIs cannot bypass the compile-time gate',
    () async {
      expect(kISpectEnabled, isFalse);

      final memoryHistory = DefaultISpectLoggerHistory(
        ISpectLoggerOptions(),
        history: [ISpectLogData('seeded-secret')],
      )
        ..add(ISpectLogData('direct-secret'))
        ..addForTesting(ISpectLogData('testing-secret'));

      expect(memoryHistory.history, isEmpty);

      final root = await Directory.systemTemp.createTemp(
        'ispect-disabled-history-',
      );
      addTearDown(() => root.delete(recursive: true));
      var providerCalls = 0;
      final fileHistory = RollingFileLogHistory.testing(
        ISpectLoggerOptions(),
        directoryProvider: () async {
          providerCalls++;
          return root.path;
        },
        options: const FileLogHistoryOptions(enableAutoSave: false),
      );
      addTearDown(fileHistory.dispose);

      fileHistory.add(ISpectLogData('persistence-secret'));
      await fileHistory.saveToDailyFile();
      await fileHistory.importFromJson('{malformed-production-secret');

      expect(fileHistory.history, isEmpty);
      expect(await fileHistory.exportToJson(), '[]');
      expect(providerCalls, 0);
      expect(await root.list().toList(), isEmpty);
    },
    skip: kISpectEnabled
        ? 'This regression exercises a build without ISPECT_ENABLED.'
        : false,
  );
}
