import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

class _SpyObserver implements ISpectifyObserver {
  const _SpyObserver();
  static int errorCount = 0;
  static int logCount = 0;

  @override
  void onError(ISpectifyData err) {
    errorCount++;
  }

  @override
  void onException(ISpectifyData err) {}

  @override
  void onLog(ISpectifyData log) {
    logCount++;
  }
}

void main() {
  setUp(() {
    _SpyObserver.errorCount = 0;
    _SpyObserver.logCount = 0;
  });

  test('logCustom routes error-level custom logs to onError', () async {
    final logger = ISpectify(observer: const _SpyObserver());

    // Subscribe before emitting to avoid missing broadcast events
    final future = logger.stream.take(2).toList();

    final httpErr = ISpectifyData(
      'HTTP failed',
      key: ISpectifyLogType.httpError.key,
      logLevel: LogLevel.error,
    );

    final normal = ISpectifyData('Hello', key: ISpectifyLogType.info.key);

    logger
      ..logCustom(httpErr)
      ..logCustom(normal);

    await future;

    expect(_SpyObserver.errorCount, 1);
    expect(_SpyObserver.logCount, 1);
  });
}
