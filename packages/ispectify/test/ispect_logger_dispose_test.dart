import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLogger.dispose', () {
    test('stops emitting logs and reports disposed state', () async {
      final logger = ISpectLogger();
      final received = <ISpectLogData>[];

      final subscription = logger.stream.listen(received.add);

      logger.info('before dispose');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));

      await logger.dispose();
      expect(logger.isDisposed, isTrue);

      // Any further logging should be ignored.
      logger.info('after dispose');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));

      await subscription.cancel();
    });

    test('flushes pending file history before releasing it', () async {
      final root = await Directory.systemTemp.createTemp('ispect-dispose-');
      addTearDown(() => root.delete(recursive: true));
      final date = DateTime(2026, 7, 10, 9);
      final options = ISpectLoggerOptions(useConsoleLogs: false);
      final history = RollingFileLogHistory.testing(
        options,
        directoryProvider: () async => root.path,
        options: const FileLogHistoryOptions(enableAutoSave: false),
      );
      final logger = ISpectLogger(options: options, history: history)
        ..logData(ISpectLogData('entry', id: 'A', time: date));

      await logger.dispose();

      expect((await history.getLogsByDate(date)).map((log) => log.id), ['A']);
    });
  });
}
