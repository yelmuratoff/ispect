import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:test/test.dart';

// Test helpers

class RecordingLogger extends ISpectLogger {
  RecordingLogger({super.options});

  final List<ISpectLogData> records = <ISpectLogData>[];

  @override
  void logData(ISpectLogData log, {bool redact = true}) {
    if (!options.enabled) return;
    records.add(log);
  }

  @override
  void warning(
    Object? msg, {
    Map<String, dynamic>? additionalData,
    AnsiPen? pen,
  }) {
    if (!options.enabled) return;
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

final class _HostileRuntimeTypeBloc extends Bloc<Object?, Object?> {
  _HostileRuntimeTypeBloc() : super(null);

  int runtimeTypeCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    throw StateError('tenantSecret=HOSTILE_BLOC_TYPE_SECRET');
  }
}

final class _HostileRuntimeTypeValue {
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    throw StateError('tenantSecret=HOSTILE_VALUE_TYPE_SECRET');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('tenantSecret=HOSTILE_VALUE_TEXT_SECRET');
  }
}

final class _IterableProbe extends IterableBase<Object?> {
  int iteratorCalls = 0;

  @override
  Iterator<Object?> get iterator {
    iteratorCalls++;
    return const <Object?>['private-value'].iterator;
  }
}

final class _ThrowingRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      throw StateError('tenantSecret=REDACTOR_FAILURE_SECRET');
}

final class _NullExportRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      null;
}

final class _ScalarExportRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      1;
}

final class _ExpandingRedactor extends RedactionService {
  _ExpandingRedactor()
      : expansion = List<String>.filled(2 * 1024 * 1024, 'x').join();

  final String expansion;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      <String, Object?>{'expansion': expansion};
}

final class _HostileMapRedactor extends RedactionService {
  _HostileMapRedactor(this.key, this.value);

  final Object key;
  final Object value;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      <Object, Object>{key: value};
}

final class _HostilePayload {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    throw StateError('tenantSecret=HOSTILE_PAYLOAD_JSON_SECRET');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('tenantSecret=HOSTILE_PAYLOAD_TEXT_SECRET');
  }
}

final class _ReadablePayload {
  _ReadablePayload({
    required this.label,
    required this.password,
  });

  final String label;
  final String password;
  int toJsonCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    return <String, Object?>{
      'label': label,
      'password': password,
    };
  }
}

final class _HostileException implements Exception {
  _HostileException({required this.throws});

  final bool throws;
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    if (throws) {
      throw StateError('tenantSecret=HOSTILE_EXCEPTION_SECRET');
    }
    return List<String>.filled(2 * 1024 * 1024, 'x').join();
  }
}

final class _HostileStackTrace implements StackTrace {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('tenantSecret=HOSTILE_STACK_SECRET');
  }
}

void main() {
  group(
    'ISpectBlocObserver',
    () {
      late RecordingLogger logger;
      late DummyBloc bloc;

      setUp(() {
        ISpectRedaction.reset();
        ISpectBlocObserver.debugEnabledOverride = true;
        logger = RecordingLogger();
        bloc = DummyBloc();
      });

      tearDown(() async {
        ISpectRedaction.reset();
        ISpectBlocObserver.debugEnabledOverride = null;
        await bloc.close();
      });

      group('onCreate', () {
        test('enabled logger without consumers bypasses observer work', () {
          var filterCalls = 0;
          final sinklessLogger = ISpectLogger(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
              useHistory: false,
            ),
          );
          addTearDown(sinklessLogger.dispose);

          ISpectBlocObserver(
            logger: sinklessLogger,
            filterPredicate: (_) {
              filterCalls++;
              return false;
            },
          ).onCreate(bloc);

          expect(filterCalls, 0);
          expect(sinklessLogger.history, isEmpty);
        });

        test('adapter callback remains active without a logger destination',
            () {
          var callbackCalls = 0;
          final sinklessLogger = ISpectLogger(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
              useHistory: false,
            ),
          );
          addTearDown(sinklessLogger.dispose);

          ISpectBlocObserver(
            logger: sinklessLogger,
            onBlocCreate: (_) => callbackCalls++,
          ).onCreate(bloc);

          expect(callbackCalls, 1);
          expect(sinklessLogger.history, isEmpty);
        });

        test('logs bloc creation', () {
          ISpectBlocObserver(logger: logger).onCreate(bloc);

          final logs = logger.byOperation('create');
          expect(logs, hasLength(1));
          final meta = logs.single.additionalData?[TraceKeys.meta]
              as Map<String, dynamic>;
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

      group('onClose', () {
        test('logs bloc close', () {
          ISpectBlocObserver(logger: logger).onClose(bloc);

          final logs = logger.byOperation('close');
          expect(logs, hasLength(1));
          final meta = logs.single.additionalData?[TraceKeys.meta]
              as Map<String, dynamic>;
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

      group('non-dispatching type labels', () {
        test('observer paths never invoke caller runtimeType getters', () {
          final hostileBloc = _HostileRuntimeTypeBloc();
          addTearDown(hostileBloc.close);
          final event = _HostileRuntimeTypeValue();
          final currentState = _HostileRuntimeTypeValue();
          final nextState = _HostileRuntimeTypeValue();
          final error = _HostileRuntimeTypeValue();
          final observer = ISpectBlocObserver(
            logger: logger,
            filters: const <Pattern>['never-match'],
            settings: const ISpectBlocSettings(
              captureMode: DiagnosticCaptureMode.strict,
            ),
          );

          expect(
            () {
              observer
                ..onCreate(hostileBloc)
                ..onEvent(hostileBloc, event)
                ..onTransition(
                  hostileBloc,
                  Transition<Object?, Object?>(
                    currentState: currentState,
                    event: event,
                    nextState: nextState,
                  ),
                )
                ..onChange(
                  hostileBloc,
                  Change<Object?>(
                    currentState: currentState,
                    nextState: nextState,
                  ),
                )
                ..onError(hostileBloc, error, StackTrace.empty)
                ..onDone(hostileBloc, event, error, StackTrace.empty)
                ..onClose(hostileBloc);
            },
            returnsNormally,
          );

          expect(observer.settings.formatEvent(event), same(event));
          expect(
            observer.settings.formatState(currentState),
            same(currentState),
          );
          expect(hostileBloc.runtimeTypeCalls, 0);
          for (final value in <_HostileRuntimeTypeValue>[
            event,
            currentState,
            nextState,
            error,
          ]) {
            expect(value.runtimeTypeCalls, 0);
            expect(value.toStringCalls, 0);
          }

          final eventMeta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(eventMeta[BlocJsonKeys.blocType], 'Bloc');
          expect(eventMeta[BlocJsonKeys.eventType], 'Object');
        });
      });

      group('onTransition', () {
        test('keeps transition callback active without a logger destination',
            () {
          var callbackCalls = 0;
          final sinklessLogger = ISpectLogger(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
              useHistory: false,
            ),
          );
          addTearDown(sinklessLogger.dispose);

          ISpectBlocObserver(
            logger: sinklessLogger,
            onBlocTransition: (_, __) => callbackCalls++,
          ).onTransition(
            bloc,
            const Transition(currentState: 0, event: 'x', nextState: 1),
          );

          expect(callbackCalls, 1);
          expect(sinklessLogger.history, isEmpty);
        });

        test('does not retain a sinkless event for a later consumer', () {
          var filterCalls = 0;
          final sinklessLogger = ISpectLogger(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
              useHistory: false,
            ),
          );
          addTearDown(sinklessLogger.dispose);
          final observer = ISpectBlocObserver(
            logger: sinklessLogger,
            filterPredicate: (_) {
              filterCalls++;
              return false;
            },
          );
          const transition = Transition(
            currentState: 0,
            event: 'increment',
            nextState: 1,
          );

          observer.onEvent(bloc, transition.event);
          expect(filterCalls, 0);
          sinklessLogger.configure(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
            ),
          );
          observer.onTransition(bloc, transition);

          expect(
            sinklessLogger.history.single.additionalData,
            isNot(contains(TraceKeys.correlationId)),
          );
        });

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
          final meta = logs.single.additionalData?[TraceKeys.meta]
              as Map<String, dynamic>;
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

      group('onChange', () {
        test('keeps change callback active without a logger destination', () {
          var callbackCalls = 0;
          final sinklessLogger = ISpectLogger(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
              useHistory: false,
            ),
          );
          addTearDown(sinklessLogger.dispose);

          ISpectBlocObserver(
            logger: sinklessLogger,
            onBlocChange: (_, __) => callbackCalls++,
          ).onChange(
            bloc,
            const Change(currentState: 0, nextState: 1),
          );

          expect(callbackCalls, 1);
          expect(sinklessLogger.history, isEmpty);
        });

        test('logs state changes', () {
          ISpectBlocObserver(logger: logger)
              .onChange(bloc, const Change(currentState: 0, nextState: 1));

          final logs = logger.byOperation('state');
          expect(logs, hasLength(1));
          final meta = logs.single.additionalData?[TraceKeys.meta]
              as Map<String, dynamic>;
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

      group('event correlation', () {
        test('links an event to its matching completion', () {
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

          observer.onDone(bloc, 'first');
          final doneLogs = logger.byOperation('done');
          expect(doneLogs, hasLength(1));
          expect(
            doneLogs.single.additionalData?[TraceKeys.correlationId],
            equals(firstEventId),
          );
        });
      });

      group('expando cleanup', () {
        test('onClose clears pending event correlations', () {
          final observer = ISpectBlocObserver(logger: logger)
            ..onEvent(bloc, 'orphan');
          expect(logger.byOperation('event'), hasLength(1));

          observer
            ..onClose(bloc)
            ..onDone(bloc, 'orphan');
          final doneLogs = logger.byOperation('done');
          expect(doneLogs, hasLength(1));
          expect(
            doneLogs.single.additionalData?[TraceKeys.correlationId],
            isNull,
          );
        });
      });

      group('onError', () {
        test('emits error trace when printErrors enabled', () {
          final exception = Exception('failure');
          Object? callbackError;
          ISpectBlocObserver(
            logger: logger,
            onBlocError: (_, error, __) => callbackError = error,
            settings: const ISpectBlocSettings(
              printEvents: false,
              printTransitions: false,
              printChanges: false,
            ),
          ).onError(bloc, exception, StackTrace.current);

          final errorLogs = logger.byOperation('error');
          expect(errorLogs, hasLength(1));
          expect(callbackError, same(exception));
          expect(errorLogs.single.exception, isNull);
          expect(errorLogs.single.error, isNull);
          expect(
            errorLogs.single.additionalData?[TraceKeys.error],
            isA<String>().having((value) => value, 'value', isNotEmpty),
          );
        });

        test('custom redactor scrubs error, stack, and trace text', () {
          const secret = 'CUSTOMER_CODE_SECRET';
          ISpectBlocObserver(
            logger: logger,
            settings: ISpectBlocSettings(
              redactor: RedactionService(
                sensitiveKeys: {'customerCode'},
              ),
            ),
          )
            ..onEvent(
              bloc,
              const <String, Object?>{'customerCode': secret},
            )
            ..onError(
              bloc,
              Exception('customerCode: $secret'),
              StackTrace.fromString('customerCode=$secret'),
            );

          final serialized = logger.records
              .map(
                (log) => <Object?>[
                  log.message,
                  log.additionalData,
                  log.exception,
                  log.error,
                  log.stackTrace,
                ].join('\n'),
              )
              .join('\n');

          expect(serialized, isNot(contains(secret)));
          expect(logger.byOperation('error').single.stackTrace, isNotNull);
        });

        test('redaction failures fail closed without retaining diagnostics',
            () {
          const secret = 'FAIL_CLOSED_PAYLOAD_SECRET';
          ISpectBlocObserver(
            logger: logger,
            settings: ISpectBlocSettings(redactor: _ThrowingRedactor()),
          )
            ..onEvent(
              bloc,
              const <String, Object?>{'tenantSecret': secret},
            )
            ..onError(
              bloc,
              Exception('tenantSecret=$secret'),
              StackTrace.fromString('tenantSecret=$secret'),
            );

          final serialized = logger.records.join('\n');
          expect(serialized, isNot(contains(secret)));
          expect(serialized, isNot(contains('REDACTOR_FAILURE_SECRET')));
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

      group('callback error isolation', () {
        test('observer continues when onBlocEvent callback throws', () {
          const secret = 'CALLBACK_SECRET';
          ISpectBlocObserver(
            logger: logger,
            onBlocEvent: (_, __) => throw StateError('tenantSecret=$secret'),
          ).onEvent(bloc, 'test');

          final eventLogs = logger.byOperation('event');
          expect(eventLogs, hasLength(1));
          expect(
            logger.records.any(
              (r) => r.message?.contains('onBlocEvent callback threw') ?? false,
            ),
            isTrue,
          );
          expect(logger.records.join('\n'), isNot(contains(secret)));
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
                  r.message?.contains('onBlocTransition callback threw') ??
                  false,
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

      group('bloc type filtering', () {
        test('filters out bloc matching regex pattern', () {
          ISpectBlocObserver(
            logger: logger,
            filters: [RegExp('Bloc')],
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
            filters: ['Bloc'],
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

        test('bloc pattern filtering suppresses errors without inspecting them',
            () {
          final error = _HostileRuntimeTypeValue();
          final stackTrace = _HostileStackTrace();
          var callbackInvoked = false;

          expect(
            () => ISpectBlocObserver(
              logger: logger,
              filters: const <Pattern>['Bloc'],
              onBlocError: (_, __, ___) => callbackInvoked = true,
            ).onError(bloc, error, stackTrace),
            returnsNormally,
          );

          expect(logger.byOperation('error'), isEmpty);
          expect(callbackInvoked, isFalse);
          expect(error.runtimeTypeCalls, 0);
          expect(error.toStringCalls, 0);
          expect(stackTrace.toStringCalls, 0);
        });

        test('typed bloc predicate suppresses errors without inspecting them',
            () {
          final error = _HostileRuntimeTypeValue();
          final stackTrace = _HostileStackTrace();
          Object? filteredCandidate;

          expect(
            () => ISpectBlocObserver(
              logger: logger,
              filterPredicate: (candidate) {
                filteredCandidate = candidate;
                return candidate is DummyBloc;
              },
            ).onError(bloc, error, stackTrace),
            returnsNormally,
          );

          expect(filteredCandidate, same(bloc));
          expect(logger.byOperation('error'), isEmpty);
          expect(error.runtimeTypeCalls, 0);
          expect(error.toStringCalls, 0);
          expect(stackTrace.toStringCalls, 0);
        });

        test('error filtering and egress never invoke hostile formatters', () {
          for (final throws in <bool>[true, false]) {
            logger.records.clear();
            final error = _HostileException(throws: throws);
            final stackTrace = _HostileStackTrace();

            expect(
              () => ISpectBlocObserver(
                logger: logger,
                filters: const <Pattern>['never-match'],
                settings: const ISpectBlocSettings(
                  captureMode: DiagnosticCaptureMode.strict,
                ),
              ).onError(bloc, error, stackTrace),
              returnsNormally,
            );

            expect(error.toStringCalls, 0);
            expect(stackTrace.toStringCalls, 0);
            final record = logger.byOperation('error').single;
            expect(
              LogExportOutput.utf8Length(
                jsonEncode(record.additionalData),
              ),
              lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
            );
          }
        });
      });

      group('transition filter', () {
        test('respects transitionFilter predicate', () {
          ISpectBlocObserver(
            logger: logger,
            settings: ISpectBlocSettings(
              transitionFilter: (bloc, transition) =>
                  transition.nextState != 99,
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

      group('redaction', () {
        test('compact preset opts into coarse event and state labels', () {
          expect(ISpectBlocSettings.compact.formatEvent('event'), 'String');
          expect(ISpectBlocSettings.compact.formatState(1), 'int');
          expect(
            ISpectBlocSettings.compact.captureMode,
            DiagnosticCaptureMode.strict,
          );
        });

        test('default settings activate redaction without a custom service',
            () {
          const settings = ISpectBlocSettings.verbose;
          final redacted = settings.redactAdditionalData(
            <String, dynamic>{'password': 'DEFAULT_REDACTION_SECRET'},
          );

          expect(settings.isRedactionActive, isTrue);
          expect(redacted?['password'], '[REDACTED]');
        });

        test('default settings use the globally configured service', () {
          ISpectRedaction.configure(
            service: RedactionService(
              sensitiveKeys: const {'business_marker'},
              placeholder: '<GLOBAL_BLOC>',
            ),
          );

          final redacted = ISpectBlocSettings.verbose.redactAdditionalData(
            <String, dynamic>{'business_marker': 'bloc-secret'},
          );

          expect(redacted?['business_marker'], contains('<GLOBAL_BLOC>'));
          expect(redacted?['business_marker'], isNot(contains('bloc-secret')));
        });

        test('default observer resolves global service for every event', () {
          ISpectRedaction.configure(
            service: RedactionService(
              sensitiveKeys: const {'business_marker'},
              placeholder: '<FIRST_BLOC>',
            ),
          );
          final observer = ISpectBlocObserver(
            logger: logger,
          )..onEvent(
              bloc,
              const <String, Object?>{'business_marker': 'first-secret'},
            );
          var meta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            (meta[BlocJsonKeys.event] as Map)['business_marker'],
            contains('<FIRST_BLOC>'),
          );

          logger.records.clear();
          ISpectRedaction.configure(
            service: RedactionService(
              sensitiveKeys: const {'business_marker'},
              placeholder: '<SECOND_BLOC>',
            ),
          );
          observer.onEvent(
            bloc,
            const <String, Object?>{'business_marker': 'second-secret'},
          );
          meta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;

          expect(
            (meta[BlocJsonKeys.event] as Map)['business_marker'],
            contains('<SECOND_BLOC>'),
          );
        });

        test('explicit observer redactor remains pinned', () {
          final observer = ISpectBlocObserver(
            logger: logger,
            settings: ISpectBlocSettings(
              redactor: RedactionService(
                sensitiveKeys: const {'business_marker'},
                placeholder: '<LOCAL_BLOC>',
              ),
            ),
          );
          ISpectRedaction.configure(
            service: RedactionService(
              sensitiveKeys: const {'business_marker'},
              placeholder: '<GLOBAL_BLOC>',
            ),
          );

          observer.onEvent(
            bloc,
            const <String, Object?>{'business_marker': 'bloc-secret'},
          );

          final meta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            (meta[BlocJsonKeys.event] as Map)['business_marker'],
            contains('<LOCAL_BLOC>'),
          );
          expect(
            (meta[BlocJsonKeys.event] as Map)['business_marker'],
            isNot(contains('<GLOBAL_BLOC>')),
          );
        });

        test('isRedactionActive reflects local and global gates', () {
          expect(ISpectBlocSettings.verbose.isRedactionActive, isTrue);
          expect(
            const ISpectBlocSettings(
              enableRedaction: false,
            ).isRedactionActive,
            isFalse,
          );

          ISpectRedaction.enabled = false;

          expect(ISpectBlocSettings.verbose.isRedactionActive, isFalse);
        });

        test('additionalData helper bounds active and opt-out strings', () {
          final payload = List<String>.filled(2 * 1024 * 1024, 'a').join();
          final redacted = ISpectBlocSettings.verbose.redactAdditionalData(
            <String, dynamic>{
              'payload': payload,
              'prebounded': 'PARTIAL_BLOC${LogExportOutput.truncatedMarker}',
            },
          );
          final unredacted = const ISpectBlocSettings(
            enableRedaction: false,
          ).redactAdditionalData(
            <String, dynamic>{'payload': payload},
          );

          expect(redacted?['payload'], LogExportOutput.truncatedMarker);
          expect(redacted?['prebounded'], LogExportOutput.truncatedMarker);
          expect(unredacted, isNotNull);
          expect(unredacted!['payload'], startsWith('a'));
          expect(
            unredacted['payload'],
            endsWith(LogExportOutput.truncatedMarker),
          );
          expect(
            LogExportOutput.utf8Length(jsonEncode(unredacted)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
        });

        test('additionalData helper bounds custom redactor expansion', () {
          final result = ISpectBlocSettings(
            redactor: _ExpandingRedactor(),
          ).redactAdditionalData(
            <String, dynamic>{'label': 'visible'},
          );

          expect(result?['expansion'], LogExportOutput.truncatedMarker);
          expect(
            LogExportOutput.utf8Length(jsonEncode(result)),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
        });

        test('additionalData helper never formats hostile keys or values', () {
          final hostileValue = _HostilePayload();
          final valueResult = const ISpectBlocSettings(
            captureMode: DiagnosticCaptureMode.strict,
          ).redactAdditionalData(
            <String, dynamic>{'payload': hostileValue},
          );
          final hostileKey = _HostilePayload();
          final hostileMap = <Object?, Object?>{
            hostileKey: 'visible',
          }.cast<String, dynamic>();
          final keyResult =
              ISpectBlocSettings.verbose.redactAdditionalData(hostileMap);
          final redactorKey = _HostilePayload();
          final redactorValue = _HostilePayload();
          final redactorResult = ISpectBlocSettings(
            redactor: _HostileMapRedactor(redactorKey, redactorValue),
          ).redactAdditionalData(
            <String, dynamic>{'label': 'visible'},
          );

          expect(valueResult?['payload'], isA<String>());
          expect(hostileValue.toJsonCalls, 0);
          expect(hostileValue.toStringCalls, 0);
          expect(hostileKey.toJsonCalls, 0);
          expect(hostileKey.toStringCalls, 0);
          expect(redactorKey.toJsonCalls, 0);
          expect(redactorKey.toStringCalls, 0);
          expect(redactorValue.toJsonCalls, 0);
          expect(redactorValue.toStringCalls, 0);
          expect(
            LogExportOutput.utf8Length(jsonEncode(keyResult)),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
          expect(
            LogExportOutput.utf8Length(jsonEncode(redactorResult)),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
        });

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
          expect(meta[BlocJsonKeys.blocType], 'DummyBloc');
        });

        test('bounds multi-megabyte diagnostics before redaction and logging',
            () {
          final payload = List<String>.filled(2 * 1024 * 1024, 's').join();
          ISpectBlocObserver(
            logger: logger,
          ).onEvent(
            bloc,
            <String, Object?>{
              'payload': payload,
              'prebounded': 'PARTIAL_BLOC${LogExportOutput.truncatedMarker}',
            },
          );

          final record = logger.byOperation('event').single;
          final meta =
              record.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            (meta[BlocJsonKeys.event] as Map)['payload'],
            LogExportOutput.truncatedMarker,
          );
          expect(
            (meta[BlocJsonKeys.event] as Map)['prebounded'],
            LogExportOutput.truncatedMarker,
          );
          expect(
            LogExportOutput.utf8Length(jsonEncode(record.additionalData)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
          expect(
            LogExportOutput.utf8Length(record.message ?? ''),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
        });

        test('bounds output from an expanding custom redactor', () {
          ISpectBlocObserver(
            logger: logger,
            settings: ISpectBlocSettings(
              redactor: _ExpandingRedactor(),
            ),
          ).onEvent(bloc, const {'label': 'visible'});

          final record = logger.byOperation('event').single;
          expect(
            LogExportOutput.utf8Length(jsonEncode(record.additionalData)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
          expect(
            LogExportOutput.utf8Length(record.message ?? ''),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
        });

        test('bounds binary output when custom redaction retains bytes', () {
          final payload = Uint8List(2 * 1024 * 1024);
          ISpectBlocObserver(
            logger: logger,
            settings: ISpectBlocSettings(
              redactor: RedactionService(redactBinary: false),
            ),
          ).onEvent(
            bloc,
            <String, Object?>{'payload': payload},
          );

          final record = logger.byOperation('event').single;
          final meta =
              record.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          final bounded = (meta[BlocJsonKeys.event] as Map)['payload'];
          expect(bounded, '[binary ${2 * 1024 * 1024} bytes]');
          expect(bounded, isNot(same(payload)));
          expect(
            LogExportOutput.utf8Length(jsonEncode(record.additionalData)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
        });

        test('redaction opt-out keeps a bounded raw string prefix', () {
          final payload = List<String>.filled(2 * 1024 * 1024, 'v').join();
          ISpectBlocObserver(
            logger: logger,
            settings: const ISpectBlocSettings(
              enableRedaction: false,
            ),
          ).onEvent(
            bloc,
            <String, Object?>{'payload': payload},
          );

          final record = logger.byOperation('event').single;
          final meta =
              record.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          final bounded =
              (meta[BlocJsonKeys.event] as Map)['payload'] as String;
          expect(bounded, startsWith('v'));
          expect(bounded, endsWith(LogExportOutput.truncatedMarker));
          expect(
            LogExportOutput.utf8Length(jsonEncode(record.additionalData)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
        });
      });

      group('disabled logger options', () {
        test('event filter shutdown aborts callbacks and payload traversal',
            () {
          final value = _IterableProbe();
          var callbackCalls = 0;
          ISpectBlocObserver(
            logger: logger,
            settings: ISpectBlocSettings(
              eventFilter: (_, __) {
                logger.disable();
                return true;
              },
            ),
            onBlocEvent: (_, __) => callbackCalls++,
          ).onEvent(bloc, value);

          expect(callbackCalls, 0);
          expect(value.iteratorCalls, 0);
          expect(logger.byOperation('event'), isEmpty);
        });

        test('event callback shutdown aborts payload traversal', () {
          final value = _IterableProbe();
          ISpectBlocObserver(
            logger: logger,
            onBlocEvent: (_, __) => logger.disable(),
          ).onEvent(bloc, value);

          expect(value.iteratorCalls, 0);
          expect(logger.byOperation('event'), isEmpty);
        });

        test('skip filters, callbacks, and caller-value inspection', () {
          final disabledLogger = ISpectLogger.testing(
            options: ISpectLoggerOptions(
              enabled: false,
              useConsoleLogs: false,
            ),
          );
          addTearDown(disabledLogger.dispose);
          var observerFilterCalls = 0;
          var settingsFilterCalls = 0;
          var callbackCalls = 0;
          final value = _HostileRuntimeTypeValue();
          final stackTrace = _HostileStackTrace();
          ISpectBlocObserver(
            logger: disabledLogger,
            settings: ISpectBlocSettings(
              eventFilter: (_, __) {
                settingsFilterCalls++;
                return true;
              },
              transitionFilter: (_, __) {
                settingsFilterCalls++;
                return true;
              },
              changeFilter: (_, __) {
                settingsFilterCalls++;
                return true;
              },
            ),
            filterPredicate: (_) {
              observerFilterCalls++;
              return false;
            },
            onBlocEvent: (_, __) => callbackCalls++,
            onBlocTransition: (_, __) => callbackCalls++,
            onBlocChange: (_, __) => callbackCalls++,
            onBlocError: (_, __, ___) => callbackCalls++,
            onBlocCreate: (_) => callbackCalls++,
            onBlocClose: (_) => callbackCalls++,
          )
            ..onCreate(bloc)
            ..onEvent(bloc, value)
            ..onTransition(
              bloc,
              Transition<Object?, Object?>(
                currentState: value,
                event: value,
                nextState: value,
              ),
            )
            ..onChange(
              bloc,
              Change<Object?>(
                currentState: value,
                nextState: value,
              ),
            )
            ..onError(bloc, value, stackTrace)
            ..onClose(bloc);

          expect(observerFilterCalls, 0);
          expect(settingsFilterCalls, 0);
          expect(callbackCalls, 0);
          expect(value.runtimeTypeCalls, 0);
          expect(value.toStringCalls, 0);
          expect(stackTrace.toStringCalls, 0);
          expect(disabledLogger.history, isEmpty);
        });

        test('does not retain event correlations', () {
          final disabledLogger = RecordingLogger(
            options: ISpectLoggerOptions(
              enabled: false,
              useConsoleLogs: false,
            ),
          );
          addTearDown(disabledLogger.dispose);
          final event = Object();
          final observer = ISpectBlocObserver(logger: disabledLogger)
            ..onEvent(bloc, event);
          disabledLogger.enable();
          observer.onDone(bloc, event);

          final done = disabledLogger.byOperation('done').single;
          expect(
            done.additionalData?[TraceKeys.correlationId],
            isNull,
          );
        });

        test('disposed logger skips filters and callbacks', () async {
          final disposedLogger = ISpectLogger.testing(
            options: ISpectLoggerOptions(useConsoleLogs: false),
          );
          await disposedLogger.dispose();
          var filterCalls = 0;
          var callbackCalls = 0;
          final value = _HostileRuntimeTypeValue();
          ISpectBlocObserver(
            logger: disposedLogger,
            filterPredicate: (_) {
              filterCalls++;
              return false;
            },
            onBlocEvent: (_, __) => callbackCalls++,
          ).onEvent(bloc, value);

          expect(filterCalls, 0);
          expect(callbackCalls, 0);
          expect(value.runtimeTypeCalls, 0);
          expect(value.toStringCalls, 0);
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

        test('shows redacted event fields in the console message by default',
            () {
          ISpectBlocObserver(logger: logger)
              .onEvent(bloc, <String, dynamic>{'password': secret});

          final message = logger.byOperation('event').single.message;
          expect(message, isNot(contains(secret)));
          expect(message, contains('password'));
          expect(message, contains('[REDACTED]'));
        });

        test('shows redacted state fields in the transition message by default',
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
          expect(message, contains('[REDACTED]'));
        });

        test(
            'keeps the raw event payload in the console when redaction disabled',
            () {
          ISpectBlocObserver(
            logger: logger,
            settings: const ISpectBlocSettings(
              enableRedaction: false,
            ),
          ).onEvent(bloc, <String, dynamic>{'password': secret});

          final message = logger.byOperation('event').single.message;
          expect(message, contains(secret));
        });
      });

      group('full data logging', () {
        test('default records the full redacted event payload', () {
          ISpectBlocObserver(logger: logger).onEvent(bloc, 'detailed_event');

          final meta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[BlocJsonKeys.event], 'detailed_event');
          expect(meta[BlocJsonKeys.eventType], 'String');
        });

        test('verbose preset includes event payload in meta', () {
          ISpectBlocObserver(
            logger: logger,
          ).onEvent(bloc, 'detailed_event');

          final meta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[BlocJsonKeys.event], 'detailed_event');
        });

        test('default shows full state values in transition', () {
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

        test('verbose preset shows full state in transition', () {
          ISpectBlocObserver(
            logger: logger,
          ).onTransition(
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

        test('verbose preset redacts structured event and state maps', () {
          const secret = 'violet-bloc-payload';
          const payload = <String, Object?>{
            'password': secret,
            'label': 'visible',
          };
          final observer = ISpectBlocObserver(
            logger: logger,
          )
            ..onEvent(bloc, payload)
            ..onTransition(
              bloc,
              const Transition<Object?, Object?>(
                currentState: payload,
                event: payload,
                nextState: payload,
              ),
            );

          final eventMeta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          final transitionMeta = logger
              .byOperation('transition')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            (eventMeta[BlocJsonKeys.event] as Map)['password'],
            '[REDACTED]',
          );
          expect(
            (transitionMeta[BlocJsonKeys.currentState] as Map)['password'],
            '[REDACTED]',
          );
          expect(
            (transitionMeta[BlocJsonKeys.nextState] as Map)['password'],
            '[REDACTED]',
          );
          expect(logger.records.toString(), isNot(contains(secret)));
          expect(observer.settings.printStateFullData, isTrue);
        });

        test('verbose captures and redacts typed payloads by default', () {
          const secret = 'TYPED_BLOC_PASSWORD';
          final payload = _ReadablePayload(
            label: 'ready',
            password: secret,
          );

          ISpectBlocObserver(logger: logger).onEvent(bloc, payload);

          final meta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[BlocJsonKeys.event], {
            'label': 'ready',
            'password': '[REDACTED]',
          });
          expect(payload.toJsonCalls, 1);
          expect(logger.records.toString(), isNot(contains(secret)));
        });

        test('strict mode snapshots custom payloads without executing them',
            () {
          final payload = _HostilePayload();
          ISpectBlocObserver(
            logger: logger,
            settings: const ISpectBlocSettings(
              captureMode: DiagnosticCaptureMode.strict,
            ),
          )
            ..onEvent(bloc, payload)
            ..onTransition(
              bloc,
              Transition<Object?, Object?>(
                currentState: payload,
                event: payload,
                nextState: payload,
              ),
            );

          final eventMeta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          final transitionMeta = logger
              .byOperation('transition')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            eventMeta[BlocJsonKeys.event],
            isA<String>(),
          );
          expect(
            transitionMeta[BlocJsonKeys.currentState],
            isA<String>(),
          );
          expect(
            transitionMeta[BlocJsonKeys.nextState],
            isA<String>(),
          );
          expect(payload.toJsonCalls, 0);
          expect(payload.toStringCalls, 0);
          expect(
            logger.records.toString(),
            isNot(contains('HOSTILE_PAYLOAD')),
          );
        });

        test('verbose custom redactor cannot restore raw event or state data',
            () {
          const secret = 'CUSTOM_BLOC_REDACTOR_SECRET';

          for (final redactor in [
            _NullExportRedactor(),
            _ScalarExportRedactor(),
          ]) {
            logger.records.clear();
            ISpectBlocObserver(
              logger: logger,
              settings: ISpectBlocSettings(
                redactor: redactor,
              ),
            )
              ..onEvent(bloc, const {'tenantSecret': secret})
              ..onTransition(
                bloc,
                const Transition<Object?, Object?>(
                  currentState: {'tenantSecret': secret},
                  event: {'tenantSecret': secret},
                  nextState: {'tenantSecret': secret},
                ),
              );

            for (final record in logger.records) {
              expect(record.textMessage, isNot(contains(secret)));
              expect(record.additionalData.toString(), isNot(contains(secret)));
            }
            expect(
              logger
                  .byOperation('event')
                  .single
                  .additionalData?[TraceKeys.meta],
              isEmpty,
            );
            expect(
              logger
                  .byOperation('transition')
                  .single
                  .additionalData?[TraceKeys.meta],
              isEmpty,
            );
          }
        });

        test('redaction opt-out preserves ordinary event and state values', () {
          const payload = <String, Object?>{
            'password': 'violet-raw-bloc-payload',
            'label': 'visible',
          };
          ISpectBlocObserver(
            logger: logger,
            settings: const ISpectBlocSettings(
              enableRedaction: false,
            ),
          )
            ..onEvent(bloc, payload)
            ..onTransition(
              bloc,
              const Transition<Object?, Object?>(
                currentState: payload,
                event: payload,
                nextState: payload,
              ),
            );

          final eventMeta = logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          final transitionMeta = logger
              .byOperation('transition')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(eventMeta[BlocJsonKeys.event], equals(payload));
          expect(
            transitionMeta[BlocJsonKeys.currentState],
            equals(payload),
          );
          expect(transitionMeta[BlocJsonKeys.nextState], equals(payload));
        });
      });

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

      group('cubit support', () {
        test('onChange works for cubit without bloc-specific methods', () {
          final cubit = CounterCubit();
          ISpectBlocObserver(logger: logger)
              .onChange(cubit, const Change(currentState: 0, nextState: 1));

          final logs = logger.byOperation('state');
          expect(logs, hasLength(1));
          final meta = logs.single.additionalData?[TraceKeys.meta]
              as Map<String, dynamic>;
          expect(meta[BlocJsonKeys.blocType], 'CounterCubit');

          cubit.close();
        });

        test('strict capture keeps the coarse family label', () {
          final cubit = CounterCubit();
          ISpectBlocObserver(
            logger: logger,
            settings: const ISpectBlocSettings(
              captureMode: DiagnosticCaptureMode.strict,
            ),
          ).onChange(cubit, const Change(currentState: 0, nextState: 1));

          final meta = logger
              .byOperation('state')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[BlocJsonKeys.blocType], 'Cubit');

          cubit.close();
        });

        test('the compact preset keeps coarse event and state labels', () {
          ISpectBlocObserver(
            logger: logger,
            settings: ISpectBlocSettings.compact,
          ).onTransition(
            bloc,
            const Transition(currentState: 0, event: 'go', nextState: 1),
          );

          final meta = logger
              .byOperation('transition')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[BlocJsonKeys.blocType], 'Bloc');
          expect(meta[BlocJsonKeys.currentState], 'int');
          expect(meta[BlocJsonKeys.nextState], 'int');
        });
      });

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

        test('minimal preset logs creations and transitions but not changes',
            () {
          ISpectBlocObserver(
            logger: logger,
            settings: ISpectBlocSettings.minimal,
          )
            ..onCreate(bloc)
            ..onChange(bloc, const Change(currentState: 0, nextState: 1));

          expect(logger.byOperation('create'), hasLength(1));
          expect(logger.byOperation('state'), isEmpty);
        });

        test('copyWith preserves and replaces local resource limits', () {
          const original = ISpectBlocSettings(
            resourceLimits: DiagnosticResourceLimits.constrained,
          );

          expect(
            original.copyWith().resourceLimits,
            same(DiagnosticResourceLimits.constrained),
          );
          expect(
            original
                .copyWith(resourceLimits: DiagnosticResourceLimits.extended)
                .resourceLimits,
            same(DiagnosticResourceLimits.extended),
          );
        });

        test('observer rejects an invalid local resource policy', () {
          expect(
            () => ISpectBlocObserver(
              logger: logger,
              settings: const ISpectBlocSettings(
                resourceLimits: DiagnosticResourceLimits(
                  maxPendingCorrelations: 0,
                ),
              ),
            ),
            throwsArgumentError,
          );
        });
      });
    },
    skip: !kISpectEnabled,
  );
}
