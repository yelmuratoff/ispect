import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

class _SpyObserver implements ISpectObserver {
  const _SpyObserver();
  static int errorCount = 0;
  static int exceptionCount = 0;
  static int logCount = 0;

  @override
  void onError(ISpectLogData err) {
    errorCount++;
  }

  @override
  void onException(ISpectLogData err) {
    exceptionCount++;
  }

  @override
  void onLog(ISpectLogData log) {
    logCount++;
  }
}

void main() {
  setUp(() {
    _SpyObserver.errorCount = 0;
    _SpyObserver.exceptionCount = 0;
    _SpyObserver.logCount = 0;
  });

  test('logCustom routes error-level custom logs to onError', () async {
    final logger = ISpectLogger(observer: const _SpyObserver());

    // Subscribe before emitting to avoid missing broadcast events
    final future = logger.stream.take(2).toList();

    final httpErr = ISpectLogData(
      'HTTP failed',
      key: ISpectLogType.httpError.key,
      logLevel: LogLevel.error,
    );

    final normal = ISpectLogData('Hello', key: ISpectLogType.info.key);

    logger
      ..logCustom(httpErr)
      ..logCustom(normal);

    await future;

    expect(_SpyObserver.errorCount, 1);
    expect(_SpyObserver.logCount, 1);
  });

  test('handle() calls observer methods only once per error/exception',
      () async {
    final logger = ISpectLogger(observer: const _SpyObserver());

    // Test Error handling
    final testError = ArgumentError('Test error');
    logger.handle(exception: testError);

    expect(
      _SpyObserver.errorCount,
      1,
      reason: 'onError should be called exactly once for Error',
    );
    expect(
      _SpyObserver.exceptionCount,
      0,
      reason: 'onException should not be called for Error',
    );

    // Reset counters
    _SpyObserver.errorCount = 0;
    _SpyObserver.exceptionCount = 0;

    // Test Exception handling
    const testException = FormatException('Test exception');
    logger.handle(exception: testException);

    expect(
      _SpyObserver.exceptionCount,
      1,
      reason: 'onException should be called exactly once for Exception',
    );
    expect(
      _SpyObserver.errorCount,
      0,
      reason: 'onError should not be called for Exception',
    );
  });
}
