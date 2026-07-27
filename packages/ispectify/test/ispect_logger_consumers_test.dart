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
  List<ISpectLogData> get history =>
      List<ISpectLogData>.unmodifiable(entries);

  @override
  void add(ISpectLogData data) => entries.add(data);

  @override
  void clear() => entries.clear();

  @override
  void dispose() {}
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

  test('reports the active default history', () {
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);

    expect(logger.hasActiveConsumers, isTrue);
  });

  test('tracks stream subscriptions and observers', () async {
    final observer = const _Observer();
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

    logger.disable();
    expect(logger.hasActiveConsumers, isFalse);

    logger.enable();
    expect(logger.hasActiveConsumers, isTrue);

    await logger.dispose();
    expect(logger.hasActiveConsumers, isFalse);
  });
}
