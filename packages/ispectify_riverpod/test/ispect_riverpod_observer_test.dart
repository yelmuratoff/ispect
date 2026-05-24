import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

class RecordingLogger extends ISpectLogger {
  final List<ISpectLogData> records = <ISpectLogData>[];

  @override
  void logData(ISpectLogData log) {
    records.add(log);
  }

  @override
  void warning(
    Object? msg, {
    Map<String, dynamic>? additionalData,
    AnsiPen? pen,
  }) {
    records.add(
      ISpectLogData(
        msg?.toString(),
        additionalData: additionalData,
        pen: pen,
      ),
    );
  }

  List<ISpectLogData> byOperation(String op) => records
      .where((r) => r.additionalData?[TraceKeys.operation] == op)
      .toList();
}

final _counterProvider = StateProvider<int>(
  (ref) => 0,
  name: 'counter',
);

final _failingProvider = Provider<int>(
  (ref) => throw StateError('boom'),
  name: 'failing',
);

final _unnamedProvider = Provider<int>((ref) => 42);

void main() {
  group('ISpectRiverpodObserver', () {
    late RecordingLogger logger;
    late ProviderContainer container;

    setUp(() {
      logger = RecordingLogger();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // ------------------------------------------------------------------
    // didAddProvider
    // ------------------------------------------------------------------
    group('didAddProvider', () {
      test('logs provider initialization with riverpod-add key', () {
        ISpectRiverpodObserver(logger: logger)
            .didAddProvider(_counterProvider, 0, container);

        final logs = logger.byOperation('add');
        expect(logs, hasLength(1));
        expect(logs.single.key, ISpectLogType.riverpodAdd.key);
        final meta =
            logs.single.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[RiverpodJsonKeys.providerName], 'counter');
      });

      test('falls back to runtime type when provider has no name', () {
        ISpectRiverpodObserver(logger: logger)
            .didAddProvider(_unnamedProvider, 42, container);

        final meta = logger
            .byOperation('add')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[RiverpodJsonKeys.providerName], isNotEmpty);
        expect(meta[RiverpodJsonKeys.providerName], isNot('counter'));
      });

      test('skips add log when printAdds disabled', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: const ISpectRiverpodSettings(printAdds: false),
        ).didAddProvider(_counterProvider, 0, container);

        expect(logger.byOperation('add'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // didUpdateProvider
    // ------------------------------------------------------------------
    group('didUpdateProvider', () {
      test('logs provider updates with riverpod-update key', () {
        ISpectRiverpodObserver(logger: logger)
            .didUpdateProvider(_counterProvider, 0, 1, container);

        final logs = logger.byOperation('update');
        expect(logs, hasLength(1));
        expect(logs.single.key, ISpectLogType.riverpodUpdate.key);
        final meta =
            logs.single.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[RiverpodJsonKeys.providerName], 'counter');
      });

      test('skips update log when printUpdates disabled', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: ISpectRiverpodSettings.minimal,
        ).didUpdateProvider(_counterProvider, 0, 1, container);

        expect(logger.byOperation('update'), isEmpty);
      });

      test('respects updateFilter', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: ISpectRiverpodSettings(
            updateFilter: (provider, previous, next) => next != 99,
          ),
        )
          ..didUpdateProvider(_counterProvider, 0, 99, container)
          ..didUpdateProvider(_counterProvider, 0, 1, container);

        expect(logger.byOperation('update'), hasLength(1));
      });
    });

    // ------------------------------------------------------------------
    // didDisposeProvider
    // ------------------------------------------------------------------
    group('didDisposeProvider', () {
      test('logs provider disposal with riverpod-dispose key', () {
        ISpectRiverpodObserver(logger: logger)
            .didDisposeProvider(_counterProvider, container);

        final logs = logger.byOperation('dispose');
        expect(logs, hasLength(1));
        expect(logs.single.key, ISpectLogType.riverpodDispose.key);
      });

      test('skips dispose log when printDisposes disabled', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: const ISpectRiverpodSettings(printDisposes: false),
        ).didDisposeProvider(_counterProvider, container);

        expect(logger.byOperation('dispose'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // providerDidFail
    // ------------------------------------------------------------------
    group('providerDidFail', () {
      test('emits error trace with riverpod-fail key', () {
        final error = StateError('failed');
        ISpectRiverpodObserver(logger: logger).providerDidFail(
          _failingProvider,
          error,
          StackTrace.current,
          container,
        );

        final logs = logger.byOperation('fail');
        expect(logs, hasLength(1));
        expect(logs.single.key, ISpectLogType.riverpodFail.key);
        expect(logs.single.error, error);
        expect(
          logs.single.additionalData?[TraceKeys.success],
          isFalse,
        );
      });

      test('skips fail log when printFails disabled', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: const ISpectRiverpodSettings(printFails: false),
        ).providerDidFail(
          _failingProvider,
          StateError('boom'),
          StackTrace.current,
          container,
        );

        expect(logger.byOperation('fail'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // Callback error isolation
    // ------------------------------------------------------------------
    group('callback error isolation', () {
      test('observer continues when onProviderAdd callback throws', () {
        ISpectRiverpodObserver(
          logger: logger,
          onProviderAdd: (_, __, ___) => throw StateError('callback crash'),
        ).didAddProvider(_counterProvider, 0, container);

        expect(logger.byOperation('add'), hasLength(1));
        expect(
          logger.records.any(
            (r) =>
                r.message?.contains('onProviderAdd callback threw') ?? false,
          ),
          isTrue,
        );
      });

      test('observer continues when onProviderUpdate callback throws', () {
        ISpectRiverpodObserver(
          logger: logger,
          onProviderUpdate: (_, __, ___, ____) =>
              throw StateError('callback crash'),
        ).didUpdateProvider(_counterProvider, 0, 1, container);

        expect(logger.byOperation('update'), hasLength(1));
      });

      test('observer continues when onProviderDispose callback throws', () {
        ISpectRiverpodObserver(
          logger: logger,
          onProviderDispose: (_, __) => throw StateError('callback crash'),
        ).didDisposeProvider(_counterProvider, container);

        expect(logger.byOperation('dispose'), hasLength(1));
      });

      test('observer continues when onProviderFail callback throws', () {
        ISpectRiverpodObserver(
          logger: logger,
          onProviderFail: (_, __, ___, ____) =>
              throw StateError('callback crash'),
        ).providerDidFail(
          _failingProvider,
          StateError('boom'),
          StackTrace.current,
          container,
        );

        expect(logger.byOperation('fail'), hasLength(1));
      });
    });

    // ------------------------------------------------------------------
    // Filtering by provider name
    // ------------------------------------------------------------------
    group('provider name filtering', () {
      test('filters out provider matching regex pattern', () {
        ISpectRiverpodObserver(
          logger: logger,
          filters: [RegExp('counter')],
        ).didAddProvider(_counterProvider, 0, container);

        expect(logger.byOperation('add'), isEmpty);
      });

      test('does not filter out non-matching provider', () {
        ISpectRiverpodObserver(
          logger: logger,
          filters: [RegExp('something-else')],
        ).didAddProvider(_counterProvider, 0, container);

        expect(logger.byOperation('add'), hasLength(1));
      });

      test('filters by string pattern', () {
        ISpectRiverpodObserver(
          logger: logger,
          filters: ['counter'],
        ).didUpdateProvider(_counterProvider, 0, 1, container);

        expect(logger.byOperation('update'), isEmpty);
      });

      test('filterPredicate takes precedence', () {
        ISpectRiverpodObserver(
          logger: logger,
          filterPredicate: (candidate) =>
              candidate.toString().contains('counter'),
        ).didAddProvider(_counterProvider, 0, container);

        expect(logger.byOperation('add'), isEmpty);
      });

      test('providerFilter on settings suppresses matching providers', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: ISpectRiverpodSettings(
            providerFilter: (provider) => provider.name != 'counter',
          ),
        ).didAddProvider(_counterProvider, 0, container);

        expect(logger.byOperation('add'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // Value rendering — printValues toggle
    // ------------------------------------------------------------------
    group('value rendering', () {
      test('default settings include raw value in meta', () {
        ISpectRiverpodObserver(logger: logger)
            .didAddProvider(_counterProvider, 99, container);

        final meta = logger
            .byOperation('add')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[RiverpodJsonKeys.value], 99);
      });

      test('compact preset hides raw value', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: ISpectRiverpodSettings.compact,
        ).didAddProvider(_counterProvider, 99, container);

        final meta = logger
            .byOperation('add')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta.containsKey(RiverpodJsonKeys.value), isFalse);
        expect(meta[RiverpodJsonKeys.valueType], 'int');
      });

      test('compact preset records runtime types on update', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: ISpectRiverpodSettings.compact,
        ).didUpdateProvider(_counterProvider, 0, 1, container);

        final meta = logger
            .byOperation('update')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[RiverpodJsonKeys.previousValueType], 'int');
        expect(meta[RiverpodJsonKeys.newValueType], 'int');
        expect(meta.containsKey(RiverpodJsonKeys.previousValue), isFalse);
        expect(meta.containsKey(RiverpodJsonKeys.newValue), isFalse);
      });

      test('default update meta includes raw values', () {
        ISpectRiverpodObserver(logger: logger)
            .didUpdateProvider(_counterProvider, 0, 1, container);

        final meta = logger
            .byOperation('update')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[RiverpodJsonKeys.previousValue], 0);
        expect(meta[RiverpodJsonKeys.newValue], 1);
      });
    });

    // ------------------------------------------------------------------
    // Redaction
    // ------------------------------------------------------------------
    group('redaction', () {
      test('does not redact when enableRedaction is false', () {
        final redactor = RedactionService(
          sensitiveKeys: {RiverpodJsonKeys.providerName},
        );
        ISpectRiverpodObserver(
          logger: logger,
          settings: ISpectRiverpodSettings(
            enableRedaction: false,
            redactor: redactor,
          ),
        ).didAddProvider(_counterProvider, 0, container);

        final meta = logger
            .byOperation('add')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[RiverpodJsonKeys.providerName], 'counter');
      });

      test('redacts sensitive meta fields when redactor provided', () {
        final redactor = RedactionService(
          sensitiveKeys: {RiverpodJsonKeys.providerName},
        );
        ISpectRiverpodObserver(
          logger: logger,
          settings: ISpectRiverpodSettings(redactor: redactor),
        ).didAddProvider(_counterProvider, 0, container);

        final meta = logger
            .byOperation('add')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[RiverpodJsonKeys.providerName], isNot('counter'));
      });
    });

    // ------------------------------------------------------------------
    // Enabled toggle and presets
    // ------------------------------------------------------------------
    group('enabled toggle', () {
      test('no logs when enabled is false', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: ISpectRiverpodSettings.silent,
        )
          ..didAddProvider(_counterProvider, 0, container)
          ..didUpdateProvider(_counterProvider, 0, 1, container)
          ..didDisposeProvider(_counterProvider, container)
          ..providerDidFail(
            _failingProvider,
            StateError('boom'),
            StackTrace.current,
            container,
          );

        expect(logger.records, isEmpty);
      });

      test('minimal preset hides updates but keeps add/dispose/fail', () {
        ISpectRiverpodObserver(
          logger: logger,
          settings: ISpectRiverpodSettings.minimal,
        )
          ..didAddProvider(_counterProvider, 0, container)
          ..didUpdateProvider(_counterProvider, 0, 1, container)
          ..didDisposeProvider(_counterProvider, container);

        expect(logger.byOperation('add'), hasLength(1));
        expect(logger.byOperation('update'), isEmpty);
        expect(logger.byOperation('dispose'), hasLength(1));
      });
    });
  });
}
