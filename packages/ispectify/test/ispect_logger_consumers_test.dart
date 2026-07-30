import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _Observer implements ISpectObserver {
  const _Observer();

  @override
  void onError(ISpectLogData data) {}

  @override
  void onException(ISpectLogData data) {}

  @override
  void onLog(ISpectLogData data) {}
}

final class _RecordingHistory implements ILogHistory {
  final List<ISpectLogData> entries = <ISpectLogData>[];

  @override
  List<ISpectLogData> get history => List<ISpectLogData>.unmodifiable(entries);

  @override
  void add(ISpectLogData data) => entries.add(data);

  @override
  void clear() => entries.clear();

  @override
  void dispose() {}
}

final class _CaptureTracker {
  int calls = 0;

  Object? toJson() {
    calls++;
    return const {'value': 'diagnostic'};
  }

  @override
  String toString() {
    calls++;
    return 'diagnostic';
  }
}

void main() {
  test('reports no consumers when the default fan-out is inactive', () {
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);

    expect(logger.hasActiveConsumers, isFalse);
  });

  test('does not capture caller objects when no consumer is active', () {
    final tracker = _CaptureTracker();
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);

    logger
      ..info(tracker)
      ..handle(exception: tracker)
      ..track(tracker, parameters: {'payload': tracker});

    expect(tracker.calls, 0);
  });

  test('reports the active default history', () {
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);

    expect(logger.hasActiveConsumers, isTrue);
  });

  test('uses injected default history settings as the dispatch contract', () {
    final history = DefaultISpectLoggerHistory(
      ISpectLoggerOptions(useConsoleLogs: false),
    );
    final logger = ISpectLogger.testing(
      history: history,
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);

    expect(logger.hasActiveConsumers, isTrue);
    logger.configure(logger: ISpectBaseLogger());
    expect(logger.logHistory, same(history));
    logger.info('retained by injected default history');
    expect(history.history, hasLength(1));
  });

  test('tracks stream subscriptions and observers', () async {
    const observer = _Observer();
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);

    final subscription = logger.stream.listen((_) {});
    expect(logger.hasActiveConsumers, isTrue);
    await subscription.cancel();
    expect(logger.hasActiveConsumers, isFalse);

    logger.addObserver(observer);
    expect(logger.hasActiveConsumers, isTrue);
    logger.removeObserver(observer);
    expect(logger.hasActiveConsumers, isFalse);
  });

  test('conservatively reports and dispatches to a custom history', () {
    final history = _RecordingHistory();
    final logger = ISpectLogger.testing(
      history: history,
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);

    expect(logger.hasActiveConsumers, isTrue);
    logger.info('retained by custom history');
    expect(history.entries, hasLength(1));
  });

  test('reports no consumers after runtime disablement or disposal', () async {
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );

    expect((logger..disable()).hasActiveConsumers, isFalse);
    expect((logger..enable()).hasActiveConsumers, isTrue);

    await logger.dispose();
    expect(logger.hasActiveConsumers, isFalse);
  });

  test('enabling a constructed-disabled logger activates default history', () {
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(
        enabled: false,
        useConsoleLogs: false,
      ),
    );
    addTearDown(logger.dispose);

    expect(logger.hasActiveConsumers, isFalse);

    logger
      ..enable()
      ..info('retained after enable');

    expect(logger.hasActiveConsumers, isTrue);
    expect(logger.history, hasLength(1));

    logger
      ..disable()
      ..info('ignored after disable');
    expect(logger.hasActiveConsumers, isFalse);
    expect(logger.history, hasLength(1));

    logger
      ..configure(
        options: logger.options.copyWith(
          enabled: true,
          useHistory: false,
        ),
      )
      ..info('ignored after history opt-out');
    expect(logger.hasActiveConsumers, isFalse);
    expect(logger.history, hasLength(1));
  });
}
