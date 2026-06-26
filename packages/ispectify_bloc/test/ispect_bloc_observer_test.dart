import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
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

class DummyBloc extends Bloc<String, int> {
  DummyBloc() : super(0) {
    on<String>((event, emit) {
      if (event == 'increment') emit(state + 1);
      if (event == 'error') throw StateError('handler error');
    });
  }
}

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
}

void main() {
  group('ISpectBlocObserver', () {
    late RecordingLogger logger;
    late DummyBloc bloc;

    setUp(() {
      ISpectBlocObserver.debugEnabledOverride = true;
      logger = RecordingLogger();
      bloc = DummyBloc();
    });

    tearDown(() async {
      ISpectBlocObserver.debugEnabledOverride = null;
      await bloc.close();
    });

    // ------------------------------------------------------------------
    // Lifecycle: onCreate
    // ------------------------------------------------------------------
    group('onCreate', () {
      test('logs bloc creation', () {
        ISpectBlocObserver(logger: logger).onCreate(bloc);

        final logs = logger.byOperation('create');
        expect(logs, hasLength(1));
        final meta =
            logs.single.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.blocType], 'DummyBloc');
      });

      test('skips creation log when printCreations disabled', () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(printCreations: false),
        ).onCreate(bloc);

        expect(logger.byOperation('create'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // Lifecycle: onClose
    // ------------------------------------------------------------------
    group('onClose', () {
      test('logs bloc close', () {
        ISpectBlocObserver(logger: logger).onClose(bloc);

        final logs = logger.byOperation('close');
        expect(logs, hasLength(1));
        final meta =
            logs.single.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.blocType], 'DummyBloc');
      });

      test('skips close log when printClosings disabled', () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(printClosings: false),
        ).onClose(bloc);

        expect(logger.byOperation('close'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // onTransition
    // ------------------------------------------------------------------
    group('onTransition', () {
      test('logs state transitions with correct trace output', () {
        final observer = ISpectBlocObserver(logger: logger);
        const transition = Transition(
          currentState: 0,
          event: 'increment',
          nextState: 1,
        );
        observer.onTransition(bloc, transition);

        final logs = logger.byOperation('transition');
        expect(logs, hasLength(1));
        final meta =
            logs.single.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.blocType], 'DummyBloc');
        expect(meta[BlocJsonKeys.eventType], 'String');
      });

      test('skips transition log when printTransitions disabled', () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(printTransitions: false),
        ).onTransition(
          bloc,
          const Transition(currentState: 0, event: 'x', nextState: 1),
        );

        expect(logger.byOperation('transition'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // onChange
    // ------------------------------------------------------------------
    group('onChange', () {
      test('logs state changes', () {
        ISpectBlocObserver(logger: logger)
            .onChange(bloc, const Change(currentState: 0, nextState: 1));

        final logs = logger.byOperation('state');
        expect(logs, hasLength(1));
        final meta =
            logs.single.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.blocType], 'DummyBloc');
      });

      test('skips change log when printChanges disabled', () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(printChanges: false),
        ).onChange(bloc, const Change(currentState: 0, nextState: 1));

        expect(logger.byOperation('state'), isEmpty);
      });

      test('respects changeFilter', () {
        ISpectBlocObserver(
          logger: logger,
          settings: ISpectBlocSettings(
            changeFilter: (bloc, change) => change.nextState != 99,
          ),
        )
          ..onChange(bloc, const Change(currentState: 0, nextState: 99))
          ..onChange(bloc, const Change(currentState: 0, nextState: 1));

        expect(logger.byOperation('state'), hasLength(1));
      });
    });

    // ------------------------------------------------------------------
    // onDone — completion & event correlation
    // ------------------------------------------------------------------
    group('onDone', () {
      test('logs completion metadata with error flag', () {
        final exception = Exception('boom');
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(
            printEvents: false,
            printTransitions: false,
            printChanges: false,
          ),
        ).onDone(bloc, 'event', exception, StackTrace.current);

        final doneLog = logger.byOperation('done').single;
        final meta =
            doneLog.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.hasError], isTrue);
      });

      test('logs successful completion without error', () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(
            printEvents: false,
            printTransitions: false,
            printChanges: false,
          ),
        ).onDone(bloc, 'event');

        final doneLog = logger.byOperation('done').single;
        final meta =
            doneLog.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.hasError], isFalse);
        expect(
          doneLog.additionalData?[TraceKeys.success],
          isTrue,
        );
      });

      test('skips completion log when printCompletions disabled', () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(
            printCompletions: false,
            printEvents: false,
            printTransitions: false,
            printChanges: false,
          ),
        ).onDone(bloc, 'event');

        expect(logger.byOperation('done'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // Event correlation ID: FIFO queue
    // ------------------------------------------------------------------
    group('event correlation', () {
      test('enqueues eventId in onEvent and dequeues in onDone', () {
        final observer = ISpectBlocObserver(logger: logger)
          ..onEvent(bloc, 'first')
          ..onEvent(bloc, 'second');

        final eventLogs = logger.byOperation('event');
        expect(eventLogs, hasLength(2));

        final firstEventId =
            eventLogs[0].additionalData?[TraceKeys.correlationId] as String;
        final secondEventId =
            eventLogs[1].additionalData?[TraceKeys.correlationId] as String;
        expect(firstEventId, isNot(equals(secondEventId)));

        // First onDone should correlate with first event (FIFO).
        observer.onDone(bloc, 'first');
        final doneLogs = logger.byOperation('done');
        expect(doneLogs, hasLength(1));
        expect(
          doneLogs.single.additionalData?[TraceKeys.correlationId],
          equals(firstEventId),
        );
      });
    });

    // ------------------------------------------------------------------
    // Expando cleanup after onClose
    // ------------------------------------------------------------------
    group('expando cleanup', () {
      test('onClose clears pending event queue', () {
        final observer = ISpectBlocObserver(logger: logger)

          // Enqueue an event.
          ..onEvent(bloc, 'orphan');
        expect(logger.byOperation('event'), hasLength(1));

        // Close clears the queue.
        observer
          ..onClose(bloc)

          // A subsequent onDone should have no correlationId from the old queue.
          ..onDone(bloc, 'orphan');
        final doneLogs = logger.byOperation('done');
        expect(doneLogs, hasLength(1));
        expect(
          doneLogs.single.additionalData?[TraceKeys.correlationId],
          isNull,
        );
      });
    });

    // ------------------------------------------------------------------
    // onError
    // ------------------------------------------------------------------
    group('onError', () {
      test('emits error trace when printErrors enabled', () {
        final exception = Exception('failure');
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(
            printEvents: false,
            printTransitions: false,
            printChanges: false,
          ),
        ).onError(bloc, exception, StackTrace.current);

        final errorLogs = logger.byOperation('error');
        expect(errorLogs, hasLength(1));
        expect(errorLogs.single.exception, exception);
      });

      test('skips error logs when printErrors disabled', () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(
            printEvents: false,
            printTransitions: false,
            printChanges: false,
            printErrors: false,
          ),
        ).onError(bloc, Exception('failure'), StackTrace.current);

        expect(logger.byOperation('error'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // Callback error isolation
    // ------------------------------------------------------------------
    group('callback error isolation', () {
      test('observer continues when onBlocEvent callback throws', () {
        ISpectBlocObserver(
          logger: logger,
          onBlocEvent: (_, __) => throw StateError('callback crash'),
        ).onEvent(bloc, 'test');

        // Event should still be logged despite callback failure.
        final eventLogs = logger.byOperation('event');
        expect(eventLogs, hasLength(1));
        // Warning about the callback error should be logged.
        expect(
          logger.records.any(
            (r) => r.message?.contains('onBlocEvent callback threw') ?? false,
          ),
          isTrue,
        );
      });

      test('observer continues when onBlocTransition callback throws', () {
        ISpectBlocObserver(
          logger: logger,
          onBlocTransition: (_, __) => throw StateError('callback crash'),
        ).onTransition(
          bloc,
          const Transition(currentState: 0, event: 'x', nextState: 1),
        );

        expect(logger.byOperation('transition'), hasLength(1));
        expect(
          logger.records.any(
            (r) =>
                r.message?.contains('onBlocTransition callback threw') ?? false,
          ),
          isTrue,
        );
      });

      test('observer continues when onBlocChange callback throws', () {
        ISpectBlocObserver(
          logger: logger,
          onBlocChange: (_, __) => throw StateError('callback crash'),
        ).onChange(bloc, const Change(currentState: 0, nextState: 1));

        expect(logger.byOperation('state'), hasLength(1));
      });

      test('observer continues when onBlocError callback throws', () {
        ISpectBlocObserver(
          logger: logger,
          onBlocError: (_, __, ___) => throw StateError('callback crash'),
        ).onError(bloc, Exception('fail'), StackTrace.current);

        expect(logger.byOperation('error'), hasLength(1));
      });

      test('observer continues when onBlocCreate callback throws', () {
        ISpectBlocObserver(
          logger: logger,
          onBlocCreate: (_) => throw StateError('callback crash'),
        ).onCreate(bloc);

        expect(logger.byOperation('create'), hasLength(1));
      });

      test('observer continues when onBlocClose callback throws', () {
        ISpectBlocObserver(
          logger: logger,
          onBlocClose: (_) => throw StateError('callback crash'),
        ).onClose(bloc);

        expect(logger.byOperation('close'), hasLength(1));
      });
    });

    // ------------------------------------------------------------------
    // Filtering by bloc type (regex pattern)
    // ------------------------------------------------------------------
    group('bloc type filtering', () {
      test('filters out bloc matching regex pattern', () {
        ISpectBlocObserver(
          logger: logger,
          filters: [RegExp('Dummy')],
        ).onCreate(bloc);

        expect(logger.byOperation('create'), isEmpty);
      });

      test('does not filter out non-matching bloc', () {
        ISpectBlocObserver(
          logger: logger,
          filters: [RegExp('NonExistent')],
        ).onCreate(bloc);

        expect(logger.byOperation('create'), hasLength(1));
      });

      test('filters by string pattern', () {
        ISpectBlocObserver(
          logger: logger,
          filters: ['DummyBloc'],
        ).onEvent(bloc, 'test');

        expect(logger.byOperation('event'), isEmpty);
      });

      test('filterPredicate takes precedence', () {
        ISpectBlocObserver(
          logger: logger,
          filterPredicate: (candidate) =>
              candidate.toString().contains('DummyBloc'),
        ).onCreate(bloc);

        expect(logger.byOperation('create'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // Transition filter
    // ------------------------------------------------------------------
    group('transition filter', () {
      test('respects transitionFilter predicate', () {
        ISpectBlocObserver(
          logger: logger,
          settings: ISpectBlocSettings(
            transitionFilter: (bloc, transition) => transition.nextState != 99,
          ),
        )
          ..onTransition(
            bloc,
            const Transition(currentState: 0, event: 'x', nextState: 99),
          )
          ..onTransition(
            bloc,
            const Transition(currentState: 0, event: 'y', nextState: 1),
          );

        expect(logger.byOperation('transition'), hasLength(1));
      });
    });

    // ------------------------------------------------------------------
    // Event filter
    // ------------------------------------------------------------------
    group('event filter', () {
      test('respects event filter predicate', () {
        ISpectBlocObserver(
          logger: logger,
          settings: ISpectBlocSettings(
            printChanges: false,
            printTransitions: false,
            printCompletions: false,
            eventFilter: (candidateBloc, event) => event != 'skip',
          ),
        )
          ..onEvent(bloc, 'skip')
          ..onEvent(bloc, 'keep');

        final events = logger.byOperation('event');
        expect(events, hasLength(1));
      });
    });

    // ------------------------------------------------------------------
    // Redaction of meta-data
    // ------------------------------------------------------------------
    group('redaction', () {
      test('redacts sensitive fields in meta when redactor provided', () {
        final redactor = RedactionService(
          sensitiveKeys: {'password', 'token'},
        );
        ISpectBlocObserver(
          logger: logger,
          settings: ISpectBlocSettings(redactor: redactor),
        ).onEvent(bloc, 'test');

        final eventLogs = logger.byOperation('event');
        expect(eventLogs, hasLength(1));
        // Meta should be present (redaction applied but no sensitive keys
        // in this case, so values should pass through).
        final meta = eventLogs.single.additionalData?[TraceKeys.meta]
            as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.blocType], 'DummyBloc');
      });

      test('does not redact when enableRedaction is false', () {
        final redactor = RedactionService(
          sensitiveKeys: {BlocJsonKeys.blocType},
        );
        ISpectBlocObserver(
          logger: logger,
          settings: ISpectBlocSettings(
            enableRedaction: false,
            redactor: redactor,
          ),
        ).onCreate(bloc);

        final meta = logger
            .byOperation('create')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        // Should NOT be redacted because enableRedaction is false.
        expect(meta[BlocJsonKeys.blocType], 'DummyBloc');
      });
    });

    group('kISpectEnabled gate', () {
      test('emits nothing when ISpect is disabled at build time', () {
        ISpectBlocObserver.debugEnabledOverride = false;
        ISpectBlocObserver(logger: logger)
          ..onCreate(bloc)
          ..onEvent(bloc, 'test')
          ..onTransition(
            bloc,
            const Transition(currentState: 0, event: 'x', nextState: 1),
          )
          ..onChange(bloc, const Change(currentState: 0, nextState: 1))
          ..onError(bloc, Exception('fail'), StackTrace.current)
          ..onDone(bloc, 'test')
          ..onClose(bloc);

        expect(logger.records, isEmpty);
      });
    });

    group('console message redaction', () {
      const secret = 'sk-live-super-secret-value-1234567890';

      test('masks sensitive event fields in the console message by default',
          () {
        ISpectBlocObserver(logger: logger)
            .onEvent(bloc, <String, dynamic>{'password': secret});

        final message = logger.byOperation('event').single.message;
        expect(message, isNot(contains(secret)));
        expect(message, contains('password'));
      });

      test('masks sensitive state fields in the transition console message',
          () {
        ISpectBlocObserver(logger: logger).onTransition(
          bloc,
          const Transition<String, Object>(
            currentState: 0,
            event: 'x',
            nextState: <String, dynamic>{'token': secret},
          ),
        );

        final message = logger.byOperation('transition').single.message;
        expect(message, isNot(contains(secret)));
        expect(message, contains('token'));
      });

      test('keeps the raw event payload in the console when redaction disabled',
          () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(enableRedaction: false),
        ).onEvent(bloc, <String, dynamic>{'password': secret});

        final message = logger.byOperation('event').single.message;
        expect(message, contains(secret));
      });
    });

    // ------------------------------------------------------------------
    // printEventFullData / printStateFullData
    // ------------------------------------------------------------------
    group('full data logging', () {
      test('default includes event payload in meta', () {
        ISpectBlocObserver(logger: logger).onEvent(bloc, 'detailed_event');

        final meta = logger
            .byOperation('event')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.event], 'detailed_event');
      });

      test('printEventFullData: false excludes event payload from meta', () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(printEventFullData: false),
        ).onEvent(bloc, 'detailed_event');

        final meta = logger
            .byOperation('event')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta.containsKey(BlocJsonKeys.event), isFalse);
      });

      test('default shows full state in transition', () {
        ISpectBlocObserver(logger: logger).onTransition(
          bloc,
          const Transition(currentState: 0, event: 'x', nextState: 42),
        );

        final meta = logger
            .byOperation('transition')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.currentState], 0);
        expect(meta[BlocJsonKeys.nextState], 42);
      });

      test('printStateFullData: false shows runtime type', () {
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(printStateFullData: false),
        ).onTransition(
          bloc,
          const Transition(currentState: 0, event: 'x', nextState: 42),
        );

        final meta = logger
            .byOperation('transition')
            .single
            .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.currentState], isA<Type>());
        expect(meta[BlocJsonKeys.nextState], isA<Type>());
      });
    });

    // ------------------------------------------------------------------
    // Concurrent bloc instances
    // ------------------------------------------------------------------
    group('concurrent bloc instances', () {
      test('tracks events independently across multiple blocs', () {
        final bloc2 = DummyBloc();
        final observer = ISpectBlocObserver(logger: logger)
          ..onEvent(bloc, 'event_a')
          ..onEvent(bloc2, 'event_b');

        final events = logger.byOperation('event');
        expect(events, hasLength(2));

        final idA = events[0].additionalData?[TraceKeys.correlationId];
        final idB = events[1].additionalData?[TraceKeys.correlationId];
        expect(idA, isNot(equals(idB)));

        // Closing bloc should not affect bloc2's queue.
        observer
          ..onClose(bloc)
          ..onDone(bloc2, 'event_b');

        final doneLogs = logger.byOperation('done');
        expect(doneLogs, hasLength(1));
        expect(
          doneLogs.single.additionalData?[TraceKeys.correlationId],
          equals(idB),
        );

        bloc2.close();
      });
    });

    // ------------------------------------------------------------------
    // Cubit support (onChange without onEvent/onTransition)
    // ------------------------------------------------------------------
    group('cubit support', () {
      test('onChange works for cubit without bloc-specific methods', () {
        final cubit = CounterCubit();
        ISpectBlocObserver(logger: logger)
            .onChange(cubit, const Change(currentState: 0, nextState: 1));

        final logs = logger.byOperation('state');
        expect(logs, hasLength(1));
        final meta =
            logs.single.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
        expect(meta[BlocJsonKeys.blocType], 'CounterCubit');

        cubit.close();
      });
    });

    // ------------------------------------------------------------------
    // Enabled toggle
    // ------------------------------------------------------------------
    group('enabled toggle', () {
      test('no logs when enabled is false', () {
        ISpectBlocObserver(
          logger: logger,
          settings: ISpectBlocSettings.silent,
        )
          ..onCreate(bloc)
          ..onEvent(bloc, 'test')
          ..onTransition(
            bloc,
            const Transition(currentState: 0, event: 'x', nextState: 1),
          )
          ..onChange(bloc, const Change(currentState: 0, nextState: 1))
          ..onError(bloc, Exception('fail'), StackTrace.current)
          ..onClose(bloc);

        expect(logger.byOperation('create'), isEmpty);
        expect(logger.byOperation('event'), isEmpty);
        expect(logger.byOperation('transition'), isEmpty);
        expect(logger.byOperation('state'), isEmpty);
        expect(logger.byOperation('error'), isEmpty);
        expect(logger.byOperation('close'), isEmpty);
      });
    });

    // ------------------------------------------------------------------
    // Named settings presets
    // ------------------------------------------------------------------
    group('settings presets', () {
      test('silent preset disables all logging', () {
        ISpectBlocObserver(
          logger: logger,
          settings: ISpectBlocSettings.silent,
        )
          ..onCreate(bloc)
          ..onEvent(bloc, 'test');

        expect(logger.records, isEmpty);
      });

      test('minimal preset logs creations and transitions but not changes', () {
        ISpectBlocObserver(
          logger: logger,
          settings: ISpectBlocSettings.minimal,
        )
          ..onCreate(bloc)
          ..onChange(bloc, const Change(currentState: 0, nextState: 1));

        expect(logger.byOperation('create'), hasLength(1));
        expect(logger.byOperation('state'), isEmpty);
      });
    });
  });
}
