import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_pipeline.dart';
import 'package:test/test.dart';

void main() {
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
      // Simulate a custom history that tries to dispatch back into the
      // pipeline during its own add(). The guard must swallow the inner
      // call so we do not recurse or end up with a duplicated log.
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
  });
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
