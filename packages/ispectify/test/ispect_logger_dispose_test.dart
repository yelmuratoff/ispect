import 'dart:async';
import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLogger.dispose', () {
    test('stops emitting logs and reports disposed state', () async {
      final logger = ISpectLogger.testing();
      final received = <ISpectLogData>[];

      final subscription = logger.stream.listen(received.add);

      logger.info('before dispose');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(logger.isEnabled, isTrue);

      await logger.dispose();
      expect(logger.isDisposed, isTrue);
      expect(logger.isEnabled, isFalse);

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
      final logger = ISpectLogger.testing(options: options, history: history)
        ..logData(ISpectLogData('entry', id: 'A', time: date));

      await logger.dispose();

      expect((await history.getLogsByDate(date)).map((log) => log.id), ['A']);
    });

    test('concurrent calls join the same in-flight disposal', () async {
      final history = _DelayedFileLogHistory();
      addTearDown(history.unblock);
      final logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        history: history,
      );

      final first = logger.dispose();
      await history.started.future;
      var secondCompleted = false;
      final second = logger.dispose();
      unawaited(
        second.then((_) {
          secondCompleted = true;
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(secondCompleted, isFalse);
      expect(history.saveCalls, 1);

      history.release.complete();
      await Future.wait([first, second]);
      expect(secondCompleted, isTrue);
    });

    test('reentrant disposal joins the published operation', () async {
      late ISpectLogger logger;
      final history = _ReentrantLogHistory(() => logger.dispose());
      logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        history: history,
      );

      final disposal = logger.dispose();
      await disposal;

      expect(history.disposeCalls, 1);
      expect(identical(disposal, history.reentrantDisposal), isTrue);
    });

    test('file flush retains the policy active when disposal starts', () async {
      final initialService = RedactionService(
        sensitiveKeys: const {'initial'},
      );
      final nextService = RedactionService(
        sensitiveKeys: const {'next'},
      );
      ISpectRedaction.configure(service: initialService);
      addTearDown(ISpectRedaction.reset);
      final history = _DelayedFileLogHistory();
      addTearDown(history.unblock);
      final logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        history: history,
      );

      final disposal = logger.dispose();
      await history.started.future;
      ISpectRedaction.configure(enabled: false, service: nextService);
      history.release.complete();
      await disposal;

      expect(history.enabledDuringSave, isTrue);
      expect(history.serviceDuringSave, same(initialService));
    });

    test('disabled logger disposal performs no empty file-history I/O',
        () async {
      var directoryProviderCalls = 0;
      final options = ISpectLoggerOptions(
        enabled: false,
        useConsoleLogs: false,
      );
      final history = RollingFileLogHistory.testing(
        options,
        directoryProvider: () async {
          directoryProviderCalls++;
          throw StateError('disabled logger touched storage');
        },
        options: const FileLogHistoryOptions(enableAutoSave: false),
      );
      final logger = ISpectLogger.testing(
        options: options,
        history: history,
      );

      await logger.dispose();

      expect(directoryProviderCalls, 0);
    });

    test(
      'closes the stream when releasing history throws',
      () async {
        final error = StateError('history dispose failed');
        final logger = ISpectLogger.testing(
          history: _ThrowingLogHistory(error),
        );
        var streamDone = false;
        final subscription = logger.stream.listen(
          (_) {},
          onDone: () => streamDone = true,
        );

        Object? caughtError;
        StackTrace? caughtStackTrace;
        try {
          await logger.dispose();
        } catch (error, stackTrace) {
          caughtError = error;
          caughtStackTrace = stackTrace;
        }

        expect(caughtError, same(error));
        expect(
          caughtStackTrace.toString(),
          contains('_ThrowingLogHistory.dispose'),
        );
        expect(streamDone, isTrue);
        await subscription.cancel();
      },
    );
  });
}

final class _DelayedFileLogHistory implements FileLogHistory {
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  int saveCalls = 0;
  bool? enabledDuringSave;
  RedactionService? serviceDuringSave;

  void unblock() {
    if (!release.isCompleted) release.complete();
  }

  @override
  List<ISpectLogData> get history => const [];

  @override
  void add(ISpectLogData data) {}

  @override
  void clear() {}

  @override
  void dispose() {}

  @override
  Future<void> saveToDailyFile() async {
    saveCalls++;
    if (!started.isCompleted) started.complete();
    await release.future;
    enabledDuringSave = ISpectRedaction.enabled;
    serviceDuringSave = ISpectRedaction.service;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ThrowingLogHistory implements ILogHistory {
  const _ThrowingLogHistory(this.error);

  final Error error;

  @override
  List<ISpectLogData> get history => const [];

  @override
  void add(ISpectLogData data) {}

  @override
  void clear() {}

  @override
  void dispose() => throw error;
}

final class _ReentrantLogHistory implements ILogHistory {
  _ReentrantLogHistory(this._disposeLogger);

  final Future<void> Function() _disposeLogger;
  int disposeCalls = 0;
  Future<void>? reentrantDisposal;

  @override
  List<ISpectLogData> get history => const [];

  @override
  void add(ISpectLogData data) {}

  @override
  void clear() {}

  @override
  void dispose() {
    disposeCalls++;
    reentrantDisposal = _disposeLogger();
  }
}
