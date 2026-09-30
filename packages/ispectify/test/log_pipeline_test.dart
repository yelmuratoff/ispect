import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_pipeline.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ISpectRedaction.enabled = true);

  group('LogPipeline', () {
    late StreamController<ISpectLogData> streamController;
    late ISpectLoggerOptions options;
    late ISpectBaseLogger consoleLogger;
    late DefaultISpectLoggerHistory history;
    late LogPipeline pipeline;

    setUp(() {
      streamController = StreamController<ISpectLogData>.broadcast();
      options = ISpectLoggerOptions(useConsoleLogs: false);
      consoleLogger = ISpectBaseLogger();
      history = DefaultISpectLoggerHistory(options);
      pipeline = LogPipeline(
        streamController: streamController,
        options: options,
        consoleLogger: consoleLogger,
        history: history,
      );
    });

    tearDown(() async {
      if (!streamController.isClosed) {
        await streamController.close();
      }
    });

    test('_isDispatching guard rejects synchronous re-entry from history.add',
        () {
      // Re-entry is swallowed to prevent recursion and duplicate delivery.
      final reentrant = _ReentrantHistory();
      pipeline = LogPipeline(
        streamController: streamController,
        options: options,
        consoleLogger: consoleLogger,
        history: reentrant,
      );
      reentrant.pipeline = pipeline;

      pipeline.dispatch(ISpectLogData('first', key: 'first'));

      expect(reentrant.addedCount, 1);
      expect(reentrant.reentryAttempted, isTrue);
    });

    test('shouldProcess returns false when options.enabled = false', () {
      pipeline.update(options: options.copyWith(enabled: false));
      final data = ISpectLogData('ignored', key: 'ignored');
      expect(pipeline.shouldProcess(data), isFalse);
    });

    test('options.enabled = false keeps logs out of history and stream',
        () async {
      pipeline.update(options: options.copyWith(enabled: false));

      final received = <ISpectLogData>[];
      final sub = streamController.stream.listen(received.add);

      final data = ISpectLogData('disabled', key: 'disabled');
      if (pipeline.shouldProcess(data)) {
        pipeline.dispatch(data);
      }

      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty);
      expect(history.history, isEmpty);
      await sub.cancel();
    });

    test('update(filter: ...) changes filtering behavior', () {
      final filter = ISpectFilter(logTypeKeys: ['keep']);
      pipeline.update(filter: filter);

      expect(
        pipeline.shouldProcess(ISpectLogData('kept', key: 'keep')),
        isTrue,
      );
      expect(
        pipeline.shouldProcess(ISpectLogData('dropped', key: 'drop')),
        isFalse,
      );
    });

    test('clearFilter makes all logs pass', () {
      pipeline
        ..update(filter: ISpectFilter(logTypeKeys: ['only-this']))
        ..clearFilter();

      expect(
        pipeline.shouldProcess(ISpectLogData('any', key: 'any')),
        isTrue,
      );
      expect(
        pipeline.shouldProcess(ISpectLogData('other', key: 'other')),
        isTrue,
      );
    });

    test('dispatch does not throw StateError after stream is closed', () async {
      await streamController.close();

      pipeline.dispatch(ISpectLogData('after-close', key: 'after'));

      // History receives the log even after stream close.
      expect(history.history, hasLength(1));
      expect(history.history.single.key, 'after');
    });

    test('console output uses the formatter configured on ConsoleSettings', () {
      final captured = <String>[];
      final boxedLogger = ISpectBaseLogger(
        settings: ConsoleSettings(
          enableColors: false,
          formatter: const BoxedLogEntryFormatter(),
        ),
        output: (message, {logLevel, error, stackTrace, time}) =>
            captured.add(message),
      );
      LogPipeline(
        streamController: streamController,
        options: ISpectLoggerOptions(),
        consoleLogger: boxedLogger,
        history: history,
      ).dispatch(
        ISpectLogData('boxed me', key: 'info', logLevel: LogLevel.info),
      );

      expect(captured, hasLength(1));
      expect(captured.single, startsWith('┌'));
      expect(captured.single, contains('boxed me'));
    });

    test('dispatch swallows errors from history.add without crashing', () {
      pipeline = LogPipeline(
        streamController: streamController,
        options: options,
        consoleLogger: consoleLogger,
        history: _ThrowingHistory(),
      );

      // Must not throw.
      expect(
        () => pipeline.dispatch(ISpectLogData('bad', key: 'bad')),
        returnsNormally,
      );
    });

    test('custom histories receive sanitized bounded snapshots by default', () {
      const secret = 'CUSTOM-HISTORY-SECRET';
      final customHistory = _RecordingHistory();
      final logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        history: customHistory,
      );
      addTearDown(logger.dispose);

      logger.logData(
        ISpectLogData(
          'GET /private?token=$secret',
          additionalData: const {
            'authorization': 'Bearer CUSTOM-HISTORY-SECRET',
            'body': {'password': 'CUSTOM-HISTORY-SECRET'},
          },
        ),
      );

      expect(customHistory.history, hasLength(1));
      expect(
        customHistory.history.single.toJson().toString(),
        isNot(contains(secret)),
      );
      expect(
        customHistory.history.single.toJson().toString(),
        contains(defaultPlaceholder),
      );
    });

    test('explicit redaction opt-out keeps only bounded raw history data', () {
      ISpectRedaction.enabled = false;
      final customHistory = _RecordingHistory();
      final logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        history: customHistory,
      );
      addTearDown(logger.dispose);
      final oversized = 'CUSTOM-HISTORY-RAW-${'x' * (4 * 1024 * 1024)}';

      logger.logData(
        ISpectLogData(
          'token=ordinary-raw-value',
          additionalData: {'payload': oversized},
        ),
      );

      final entry = customHistory.history.single;
      final payload = entry.additionalData!['payload']! as String;
      expect(entry.messageForSerialization, contains('ordinary-raw-value'));
      expect(
        LogExportOutput.utf8Length(payload),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(payload, endsWith(LogExportOutput.truncatedMarker));
    });
  });
}

final class _RecordingHistory implements ILogHistory {
  final List<ISpectLogData> _history = <ISpectLogData>[];

  @override
  List<ISpectLogData> get history => List<ISpectLogData>.unmodifiable(_history);

  @override
  void add(ISpectLogData data) => _history.add(data);

  @override
  void clear() => _history.clear();

  @override
  void dispose() {}
}

class _ThrowingHistory implements ILogHistory {
  @override
  void add(ISpectLogData data) => throw StateError('history failure');

  @override
  void clear() {}

  @override
  void dispose() {}

  @override
  List<ISpectLogData> get history => const [];
}

class _ReentrantHistory implements ILogHistory {
  LogPipeline? pipeline;
  int addedCount = 0;
  bool reentryAttempted = false;

  @override
  void add(ISpectLogData data) {
    addedCount++;
    if (!reentryAttempted) {
      reentryAttempted = true;
      // This synchronous call must be swallowed by the _isDispatching guard,
      // otherwise addedCount would grow unboundedly.
      pipeline!.dispatch(ISpectLogData('inner', key: 'inner'));
    }
  }

  @override
  void clear() {}

  @override
  void dispose() {}

  @override
  List<ISpectLogData> get history => const [];
}
