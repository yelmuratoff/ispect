import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  tearDown(() async {
    await ISpect.dispose();
    ISpectRedaction.reset();
  });

  test('ISpect.dispose restores host Flutter and platform handlers', () async {
    await ISpect.dispose();
    final originalPresent = FlutterError.presentError;
    final originalFlutter = FlutterError.onError;
    final originalPlatform = PlatformDispatcher.instance.onError;
    void hostPresent(FlutterErrorDetails _) {}
    void hostFlutter(FlutterErrorDetails _) {}
    bool hostPlatform(Object _, StackTrace __) => false;
    FlutterError.presentError = hostPresent;
    FlutterError.onError = hostFlutter;
    PlatformDispatcher.instance.onError = hostPlatform;
    addTearDown(() {
      FlutterError.presentError = originalPresent;
      FlutterError.onError = originalFlutter;
      PlatformDispatcher.instance.onError = originalPlatform;
    });

    ISpect.run(
      () {},
      logger: ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false)),
    );

    expect(identical(FlutterError.presentError, hostPresent), isFalse);
    expect(identical(FlutterError.onError, hostFlutter), isFalse);
    expect(
      identical(PlatformDispatcher.instance.onError, hostPlatform),
      isFalse,
    );

    await ISpect.dispose();

    expect(identical(FlutterError.presentError, hostPresent), isTrue);
    expect(identical(FlutterError.onError, hostFlutter), isTrue);
    expect(
      identical(PlatformDispatcher.instance.onError, hostPlatform),
      isTrue,
    );
  });

  test('dispose resets global state when file-history flush fails', () async {
    await ISpect.dispose();
    final history = _ThrowingFileLogHistory();
    final failedLogger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
      history: history,
    );
    expect(ISpect.initialize(failedLogger), isTrue);

    await expectLater(
      ISpect.dispose(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'flush failed',
        ),
      ),
    );

    expect(failedLogger.isDisposed, isTrue);
    expect(history.disposed, isTrue);
    final replacement = ISpect.logger;
    expect(replacement, isNot(same(failedLogger)));
    expect(replacement.isDisposed, isFalse);
  });

  test('an ISpect zone delegates errors and print after disposal', () async {
    await ISpect.dispose();
    late Zone ispectZone;
    final hostErrors = <Object>[];
    final hostPrints = <String>[];

    runZonedGuarded(
      () {
        ISpect.run(
          () => ispectZone = Zone.current,
          logger: ISpectLogger(
            options: ISpectLoggerOptions(useConsoleLogs: false),
          ),
        );
      },
      (error, _) => hostErrors.add(error),
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) => hostPrints.add(line),
      ),
    );
    await ISpect.dispose();

    ispectZone
      ..run(() {
        // ignore: avoid_print
        print('host print after dispose');
      })
      ..runGuarded(() => throw StateError('host error after dispose'));
    await Future<void>.delayed(Duration.zero);

    expect(hostPrints, contains('host print after dispose'));
    expect(
      hostErrors.whereType<StateError>().single.message,
      'host error after dispose',
    );
  });

  test('dispose restores a run-scoped redaction override', () async {
    await ISpect.dispose();
    ISpectRedaction.enabled = true;

    ISpect.run(
      () {},
      logger: ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false)),
      redactionEnabled: false,
    );
    expect(ISpectRedaction.enabled, isFalse);

    await ISpect.dispose();
    expect(ISpectRedaction.enabled, isTrue);

    ISpect.run(
      () {},
      logger: ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false)),
    );
    expect(ISpectRedaction.enabled, isTrue);
  });

  test('dispose restores the run-scoped redaction policy', () async {
    await ISpect.dispose();
    final hostService = RedactionService(
      sensitiveKeys: const {'host_field'},
      placeholder: '<host>',
    );
    final runService = RedactionService(
      sensitiveKeys: const {'run_field'},
      placeholder: '<run>',
    );
    ISpectRedaction.configure(service: hostService);

    ISpect.run(
      () {},
      logger: ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false)),
      redactionEnabled: false,
      redactionService: runService,
    );

    expect(ISpectRedaction.enabled, isFalse);
    expect(ISpectRedaction.service, same(runService));

    await ISpect.dispose();

    expect(ISpectRedaction.enabled, isTrue);
    expect(ISpectRedaction.service, same(hostService));
  });

  test(
    'dispose restores the redaction policy when logger disposal fails',
    () async {
      await ISpect.dispose();
      final hostService = RedactionService(
        sensitiveKeys: const {'host_field'},
        placeholder: '<host>',
      );
      final runService = RedactionService(
        sensitiveKeys: const {'run_field'},
        placeholder: '<run>',
      );
      ISpectRedaction.configure(service: hostService);
      final history = _ThrowingFileLogHistory();
      final failedLogger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        history: history,
      );

      ISpect.run(() {}, logger: failedLogger, redactionService: runService);
      expect(ISpectRedaction.service, same(runService));

      await expectLater(ISpect.dispose(), throwsA(isA<StateError>()));

      expect(history.serviceDuringSave, same(runService));
      expect(ISpectRedaction.enabled, isTrue);
      expect(ISpectRedaction.service, same(hostService));
    },
  );

  test(
    'repeated run flushes the retired logger with its original policy',
    () async {
      await ISpect.dispose();
      final runService = RedactionService(
        sensitiveKeys: const {'run_field'},
        placeholder: '<run>',
      );
      final history = _DelayedFileLogHistory();
      addTearDown(history.unblock);
      final original = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        history: history,
      );

      ISpect.run(() {}, logger: original, redactionService: runService);
      ISpect.run(
        () {},
        logger: ISpectLogger(
          options: ISpectLoggerOptions(useConsoleLogs: false),
        ),
        redactionEnabled: false,
      );

      await history.started.future;
      history.unblock();
      await history.finished.future;

      expect(history.enabledDuringSave, isTrue);
      expect(history.serviceDuringSave, same(runService));
    },
  );

  test(
    'dispose waits for retired loggers and surfaces their flush failure',
    () async {
      await ISpect.dispose();
      final history = _DelayedFileLogHistory(
        error: StateError('retired flush failed'),
      );
      addTearDown(history.unblock);
      final original = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        history: history,
      );
      final replacement = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      expect(ISpect.initialize(original), isTrue);
      expect(ISpect.initialize(replacement, force: true), isTrue);
      await history.started.future;

      final disposal = ISpect.dispose();
      history.unblock();

      await expectLater(
        disposal,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'retired flush failed',
          ),
        ),
      );
    },
  );

  test('concurrent dispose calls join and reject initialization', () async {
    await ISpect.dispose();
    final history = _DelayedFileLogHistory();
    addTearDown(history.unblock);
    final original = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
      history: history,
    );
    expect(ISpect.initialize(original), isTrue);

    final first = ISpect.dispose();
    await history.started.future;
    final second = ISpect.dispose();
    final replacement = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );

    expect(identical(first, second), isTrue);
    expect(ISpect.initialize(replacement, force: true), isFalse);
    expect(() => ISpect.run(() {}, logger: replacement), throwsStateError);

    history.unblock();
    await Future.wait([first, second]);
    expect(replacement.isDisposed, isFalse);
  });

  test('reentrant global disposal joins the published operation', () async {
    await ISpect.dispose();
    final history = _ReentrantFileLogHistory();
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
      history: history,
    );
    expect(ISpect.initialize(logger), isTrue);

    final disposal = ISpect.dispose();
    await disposal;

    expect(history.saveCalls, 1);
    expect(identical(disposal, history.reentrantDisposal), isTrue);
  });
}

final class _DelayedFileLogHistory implements FileLogHistory {
  _DelayedFileLogHistory({this.error});

  final Error? error;
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  final Completer<void> finished = Completer<void>();
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
    if (!started.isCompleted) started.complete();
    await release.future;
    enabledDuringSave = ISpectRedaction.enabled;
    serviceDuringSave = ISpectRedaction.service;
    if (!finished.isCompleted) finished.complete();
    if (error case final Error failure) throw failure;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ThrowingFileLogHistory implements FileLogHistory {
  final List<ISpectLogData> _entries = <ISpectLogData>[];
  bool disposed = false;
  RedactionService? serviceDuringSave;

  @override
  List<ISpectLogData> get history => List<ISpectLogData>.unmodifiable(_entries);

  @override
  void add(ISpectLogData data) => _entries.add(data);

  @override
  void clear() => _entries.clear();

  @override
  void dispose() {
    disposed = true;
    _entries.clear();
  }

  @override
  Future<void> saveToDailyFile() async {
    serviceDuringSave = ISpectRedaction.service;
    throw StateError('flush failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ReentrantFileLogHistory implements FileLogHistory {
  int saveCalls = 0;
  Future<void>? reentrantDisposal;

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
    reentrantDisposal = ISpect.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
