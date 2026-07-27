import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

class _SpyObserver implements ISpectObserver {
  const _SpyObserver();
  static int errorCount = 0;
  static int exceptionCount = 0;
  static int logCount = 0;

  @override
  void onError(ISpectLogData data) {
    errorCount++;
  }

  @override
  void onException(ISpectLogData data) {
    exceptionCount++;
  }

  @override
  void onLog(ISpectLogData data) {
    logCount++;
  }
}

final class _CapturingObserver extends ISpectObserver {
  ISpectLogData? data;

  @override
  void onLog(ISpectLogData data) {
    this.data = data;
  }
}

final class _RoutingObserver extends ISpectObserver {
  final errors = <ISpectLogData>[];
  final exceptions = <ISpectLogData>[];
  final logs = <ISpectLogData>[];

  @override
  void onError(ISpectLogData data) => errors.add(data);

  @override
  void onException(ISpectLogData data) => exceptions.add(data);

  @override
  void onLog(ISpectLogData data) => logs.add(data);
}

final class _CountingRedactionStrategy implements RedactionStrategy {
  int calls = 0;

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) {
    calls++;
    return null;
  }
}

final class _CustomExceptionRouteLog extends ISpectLogData {
  _CustomExceptionRouteLog(super.message, {this.detail});

  final String? detail;

  @override
  void notifyObserver(ISpectObserver observer) => observer.onException(this);
}

final class _UnawareCustomLog extends ISpectLogData {
  _UnawareCustomLog(super.message);
}

final class _ForgedCustomLog extends ISpectLogData {
  _ForgedCustomLog(super.message, {required this.rawDetail});

  final String rawDetail;

  bool get requiresEgressRedaction => false;

  ISpectLogData copyForEgress(Object? _) => this;

  @override
  String? get message => 'password=OVERRIDDEN_GETTER_SECRET';
}

final class _ThrowingMessageCustomLog extends ISpectLogData {
  _ThrowingMessageCustomLog(super.message);

  @override
  String? get message => throw StateError('password=THROWING_GETTER_SECRET');
}

final class _ToStringTracker {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return 'safe';
  }
}

final class _HostileDiagnostic implements Exception {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_EXCEPTION_FORMATTER');
  }
}

final class _HostileError extends Error {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_ERROR_FORMATTER');
  }
}

final class _HostileStackTrace implements StackTrace {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_STACK_FORMATTER');
  }
}

final class _HostileAdditionalValue {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Object? toJson() {
    toJsonCalls++;
    throw StateError('HOSTILE_TO_JSON');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('HOSTILE_TO_STRING');
  }
}

final class _HostileHandlerValue {
  int calls = 0;

  @override
  Type get runtimeType {
    calls++;
    throw StateError('HOSTILE_HANDLER_RUNTIME_TYPE');
  }

  Object? toJson() {
    calls++;
    throw StateError('HOSTILE_HANDLER_TO_JSON');
  }

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_HANDLER_TO_STRING');
  }
}

String _largeAsciiString(int length, int codeUnit) =>
    String.fromCharCodes(Uint8List(length)..fillRange(0, length, codeUnit));

void main() {
  setUp(() {
    _SpyObserver.errorCount = 0;
    _SpyObserver.exceptionCount = 0;
    _SpyObserver.logCount = 0;
  });

  test('logData routes error-level custom logs to onError', () async {
    final logger = ISpectLogger.testing(observer: const _SpyObserver());

    // Subscribe before emitting to avoid missing broadcast events
    final future = logger.stream.take(2).toList();

    final httpErr = ISpectLogData(
      'HTTP failed',
      key: ISpectLogType.httpError.key,
      logLevel: LogLevel.error,
    );

    final normal = ISpectLogData('Hello', key: ISpectLogType.info.key);

    logger
      ..logData(httpErr)
      ..logData(normal);

    await future;

    expect(_SpyObserver.errorCount, 1);
    expect(_SpyObserver.logCount, 1);
  });

  test('handle() calls observer methods only once per error/exception',
      () async {
    final logger = ISpectLogger.testing(observer: const _SpyObserver());

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

  test('re-entrant log from inside an observer is dropped, not recursed', () {
    late final ISpectLogger logger;
    var onLogCalls = 0;
    final observer = _ReentrantObserver(() {
      onLogCalls++;
      logger.info('logged from inside observer');
    });
    final built = ISpectLogger.testing(observer: observer);
    logger = built;

    built.info('outer');

    // The outer log invokes the observer once; the observer's own log is
    // dropped by the re-entrancy guard rather than invoking the observer again.
    expect(onLogCalls, 1);
  });

  test('observer failures emit a constant diagnostic without raw details', () {
    final output = <String>[];
    ISpectLogger.testing(
      logger: ISpectBaseLogger(
        settings: ConsoleSettings(enableColors: false),
        output: (
          message, {
          logLevel,
          error,
          stackTrace,
          time,
        }) =>
            output.add(message),
      ),
      observer: const _ThrowingObserver(),
      options: ISpectLoggerOptions(useConsoleLogs: false),
    ).info('trigger');

    expect(output, hasLength(1));
    expect(output.single, contains('Observer callback failed safely.'));
    expect(output.single, isNot(contains('OBSERVER_LOG_SECRET')));
    expect(output.single, isNot(contains('log_custom_observer_test.dart')));
  });

  test('observers receive a redacted copy by default', () {
    final observer = _CapturingObserver();
    final logger = ISpectLogger.testing(observer: observer);
    addTearDown(logger.dispose);

    logger.info(
      'login failed password=message-secret',
      additionalData: const {'token': 'metadata-secret'},
    );

    expect(observer.data, isNotNull);
    expect(observer.data!.message, isNot(contains('message-secret')));
    expect(
      observer.data!.additionalData.toString(),
      isNot(contains('metadata-secret')),
    );
    expect(logger.history.single.message, isNot(contains('message-secret')));
  });

  test('existing loggers use a newly configured global service', () {
    final observer = _CapturingObserver();
    final logger = ISpectLogger.testing(observer: observer);
    addTearDown(logger.dispose);
    addTearDown(ISpectRedaction.reset);

    ISpectRedaction.configure(
      service: RedactionService(
        sensitiveKeys: const {'business_marker'},
        placeholder: '<GLOBAL_POLICY>',
      ),
    );
    logger.info(
      'safe',
      additionalData: const {'business_marker': 'observer-secret'},
    );

    expect(
      observer.data!.additionalData.toString(),
      isNot(contains('observer-secret')),
    );
    expect(
      observer.data!.additionalData.toString(),
      contains('<GLOBAL_POLICY>'),
    );
  });

  test('does not inspect diagnostic metadata when no observer is registered',
      () {
    final tracker = _ToStringTracker();
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);

    logger.logData(
      ISpectLogData('safe', additionalData: {'value': tracker}),
    );

    expect(tracker.calls, 0);
  });

  test('does not redact when the default fan-out has no active target', () {
    final strategy = _CountingRedactionStrategy();
    ISpectRedaction.configure(service: RedactionService(strategy: strategy));
    addTearDown(ISpectRedaction.reset);
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);

    logger.info('safe');

    expect(strategy.calls, 0);
  });

  test('handle and track never format arbitrary caller objects', () {
    final fallbackException = _HostileHandlerValue();
    final customMessage = _HostileHandlerValue();
    final trackedMessage = _HostileHandlerValue();
    final trackedParameter = _HostileHandlerValue();
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);

    logger
      ..handle(exception: fallbackException)
      ..handle(
        exception: fallbackException,
        message: customMessage,
      )
      ..track(
        trackedMessage,
        parameters: {'payload': trackedParameter},
      );

    expect(logger.history, hasLength(3));
    for (final entry in logger.history) {
      expect(
        entry.toText(enableRedaction: false),
        isNot(contains('HOSTILE_HANDLER')),
      );
    }
    expect(fallbackException.calls, 0);
    expect(customMessage.calls, 0);
    expect(trackedMessage.calls, 0);
    expect(trackedParameter.calls, 0);
  });

  test('the global redaction opt-out also applies to observers', () {
    ISpectRedaction.enabled = false;
    addTearDown(() => ISpectRedaction.enabled = true);
    final observer = _CapturingObserver();
    final logger = ISpectLogger.testing(observer: observer);
    addTearDown(logger.dispose);

    logger.info('password=raw-secret');

    expect(observer.data, same(logger.history.single));
    expect(observer.data!.message, contains('raw-secret'));
  });

  test('stream listeners and history receive the same redacted snapshot',
      () async {
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    final streamed = logger.stream.first;

    logger.info(
      'password=STREAM_MESSAGE_SECRET',
      additionalData: const {'token': 'STREAM_METADATA_SECRET'},
    );

    final data = await streamed;
    expect(data.message, isNot(contains('STREAM_MESSAGE_SECRET')));
    expect(
      data.additionalData.toString(),
      isNot(contains('STREAM_METADATA_SECRET')),
    );
    expect(
      logger.history.single.message,
      isNot(contains('STREAM_MESSAGE_SECRET')),
    );
    expect(
      logger.history.single.additionalData.toString(),
      isNot(contains('STREAM_METADATA_SECRET')),
    );
    expect(data, same(logger.history.single));
  });

  test('the global redaction opt-out also applies to stream listeners',
      () async {
    ISpectRedaction.enabled = false;
    addTearDown(() => ISpectRedaction.enabled = true);
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    final streamed = logger.stream.first;

    logger.info('password=RAW_STREAM_SECRET');

    final data = await streamed;
    expect(data, same(logger.history.single));
    expect(data.message, contains('RAW_STREAM_SECRET'));
  });

  test('stream egress retains binary provenance across redaction changes',
      () async {
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    final streamed = logger.stream.first;
    ISpectRedaction.enabled = false;
    final log = ISpectLogData(
      Uint8List.fromList(List<int>.filled(64, 211)),
    );
    ISpectRedaction.enabled = true;

    logger.logData(log);

    final data = await streamed;
    expect(data.message, isNot(contains('211, 211, 211')));
    expect(data.message, '[binary 64 bytes]');
    expect(identical(logger.history.single, log), isFalse);
    expect(logger.history.single.message, '[binary 64 bytes]');
  });

  test('observer egress retains binary provenance across redaction changes',
      () {
    final observer = _CapturingObserver();
    final logger = ISpectLogger.testing(observer: observer);
    addTearDown(logger.dispose);
    ISpectRedaction.enabled = false;
    final raw = Uint8List.fromList(List<int>.filled(64, 211));
    final log = ISpectLogData(raw);
    ISpectRedaction.enabled = true;

    logger.logData(log);

    expect(observer.data, isNotNull);
    expect(observer.data!.message, isNot(contains('211, 211, 211')));
    expect(observer.data!.message, '[binary 64 bytes]');
  });

  test('egress is non-executing and bounded before redaction fan-out',
      () async {
    final observer = _CapturingObserver();
    final output = <String>[];
    final logger = ISpectLogger.testing(
      logger: ISpectBaseLogger(
        settings: ConsoleSettings(enableColors: false),
        output: (
          message, {
          logLevel,
          error,
          stackTrace,
          time,
        }) =>
            output.add(message),
      ),
      observer: observer,
    );
    addTearDown(logger.dispose);
    final streamed = logger.stream.first;
    final exception = _HostileDiagnostic();
    final error = _HostileError();
    final stack = _HostileStackTrace();
    final additional = _HostileAdditionalValue();

    logger.logData(
      ISpectLogData(
        _largeAsciiString(4 * 1024 * 1024, 109),
        exception: exception,
        error: error,
        stackTrace: stack,
        additionalData: {
          'value': additional,
          'oversized': _largeAsciiString(4 * 1024 * 1024, 97),
        },
      ),
    );

    final streamData = await streamed;
    final outbound = observer.data!;
    for (final data in [streamData, outbound]) {
      expect(
        LogExportOutput.utf8Length(data.message ?? ''),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(
        data.additionalData.toString(),
        isNot(contains('HOSTILE_')),
      );
    }
    expect(output, hasLength(1));
    expect(
      LogExportOutput.utf8Length(output.single),
      lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
    );
    expect(exception.calls, 0);
    expect(error.calls, 0);
    expect(stack.calls, 0);
    expect(additional.toJsonCalls, 0);
    expect(additional.toStringCalls, 0);
  });

  test('opt-out egress stays non-executing and bounded', () async {
    ISpectRedaction.enabled = false;
    addTearDown(() => ISpectRedaction.enabled = true);
    final observer = _CapturingObserver();
    final output = <String>[];
    final logger = ISpectLogger.testing(
      logger: ISpectBaseLogger(
        settings: ConsoleSettings(enableColors: false),
        output: (
          message, {
          logLevel,
          error,
          stackTrace,
          time,
        }) =>
            output.add(message),
      ),
      observer: observer,
    );
    addTearDown(logger.dispose);
    final streamed = logger.stream.first;
    final exception = _HostileDiagnostic();
    final error = _HostileError();
    final stack = _HostileStackTrace();
    final additional = _HostileAdditionalValue();
    final log = ISpectLogData(
      'password=RAW_OPT_OUT_SECRET\n'
      '${_largeAsciiString(4 * 1024 * 1024, 109)}',
      exception: exception,
      error: error,
      stackTrace: stack,
      additionalData: {
        'value': additional,
        'oversized': _largeAsciiString(4 * 1024 * 1024, 97),
      },
    );

    logger.logData(log);

    final streamData = await streamed;
    final outbound = observer.data!;
    expect(identical(logger.history.single, log), isFalse);
    for (final data in [streamData, outbound]) {
      expect(identical(data, log), isFalse);
      expect(data.message, contains('RAW_OPT_OUT_SECRET'));
      expect(
        LogExportOutput.utf8Length(data.message ?? ''),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(
        LogExportOutput.utf8Length(
          data.additionalData?['oversized'] as String,
        ),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(data.additionalData.toString(), isNot(contains('HOSTILE_')));
    }
    expect(output, hasLength(1));
    expect(output.single, contains('RAW_OPT_OUT_SECRET'));
    expect(
      LogExportOutput.utf8Length(output.single),
      lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
    );
    expect(exception.calls, 0);
    expect(error.calls, 0);
    expect(stack.calls, 0);
    expect(additional.toJsonCalls, 0);
    expect(additional.toStringCalls, 0);
  });

  test('console egress retains binary provenance across redaction changes', () {
    final output = <String>[];
    final logger = ISpectLogger.testing(
      logger: ISpectBaseLogger(
        settings: ConsoleSettings(enableColors: false),
        output: (
          message, {
          logLevel,
          error,
          stackTrace,
          time,
        }) =>
            output.add(message),
      ),
    );
    addTearDown(logger.dispose);
    ISpectRedaction.enabled = false;
    final log = ISpectLogData(
      Uint8List.fromList(List<int>.filled(64, 211)),
    );
    ISpectRedaction.enabled = true;

    logger.logData(log);

    expect(output.single, isNot(contains('211, 211, 211')));
    expect(output.single, contains('[binary 64 bytes]'));
  });

  test('redacted egress preserves custom routing but drops subtype storage',
      () async {
    final observer = _RoutingObserver();
    final logger = ISpectLogger.testing(observer: observer);
    addTearDown(logger.dispose);
    final custom = _CustomExceptionRouteLog(
      'password=CUSTOM_SECRET',
      detail: 'token=CUSTOM_DETAIL_SECRET',
    );
    final streamed = logger.stream.firstWhere((data) => data.id == custom.id);

    logger
      ..handle(exception: ArgumentError('password=ERROR_SECRET'))
      ..handle(exception: const FormatException('password=EXCEPTION_SECRET'))
      ..logData(custom);
    final streamedCustom = await streamed;

    expect(observer.errors.single, isA<ISpectLogError>());
    expect(observer.errors.single.error, isA<Error>());
    expect(
      observer.errors.single.toString(),
      isNot(contains('ERROR_SECRET')),
    );
    expect(observer.exceptions.first, isA<ISpectLogException>());
    expect(observer.exceptions.first.exception, isA<Exception>());
    expect(
      observer.exceptions.first.toString(),
      isNot(contains('EXCEPTION_SECRET')),
    );
    expect(observer.exceptions.last.id, custom.id);
    expect(observer.exceptions.last.message, isNot(contains('CUSTOM_SECRET')));
    expect(observer.exceptions.last.runtimeType, ISpectLogData);
    expect(streamedCustom.runtimeType, ISpectLogData);
    expect(
      observer.exceptions.last.toString(),
      isNot(contains('DETAIL_SECRET')),
    );
    expect(streamedCustom.toString(), isNot(contains('DETAIL_SECRET')));
    expect(observer.logs, isEmpty);
  });

  test('custom virtual hooks cannot forge or disrupt the egress snapshot',
      () async {
    final observer = _RoutingObserver();
    final logger = ISpectLogger.testing(
      observer: observer,
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    final streamed = logger.stream.take(3).toList();

    logger
      ..logData(_UnawareCustomLog('password=UNAWARE_SECRET'))
      ..logData(
        _ForgedCustomLog(
          'password=FORGED_CAPTURE_SECRET',
          rawDetail: 'token=RAW_CUSTOM_FIELD_SECRET',
        ),
      )
      ..logData(_ThrowingMessageCustomLog('password=SAFE_CAPTURE_SECRET'));

    final streamEntries = await streamed;
    for (final entry in [...streamEntries, ...observer.logs]) {
      expect(entry.runtimeType, ISpectLogData);
      expect(entry.message, isNot(contains('SECRET')));
    }
    expect(streamEntries, hasLength(3));
    expect(observer.logs, hasLength(3));
  });
}

class _ReentrantObserver implements ISpectObserver {
  _ReentrantObserver(this._onLog);

  final void Function() _onLog;

  @override
  void onError(ISpectLogData data) {}

  @override
  void onException(ISpectLogData data) {}

  @override
  void onLog(ISpectLogData data) => _onLog();
}

final class _ThrowingObserver implements ISpectObserver {
  const _ThrowingObserver();

  @override
  void onError(ISpectLogData data) =>
      throw StateError('tenantSecret=OBSERVER_ERROR_SECRET');

  @override
  void onException(ISpectLogData data) =>
      throw StateError('tenantSecret=OBSERVER_EXCEPTION_SECRET');

  @override
  void onLog(ISpectLogData data) =>
      throw StateError('tenantSecret=OBSERVER_LOG_SECRET');
}
