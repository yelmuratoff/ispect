import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:test/test.dart';

class _RecordingLogger extends ISpectLogger {
  final List<ISpectLogData> records = <ISpectLogData>[];

  @override
  void logData(ISpectLogData log, {bool redact = true}) => records.add(log);

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

class _DummyBloc extends Bloc<String, int> {
  _DummyBloc() : super(0) {
    on<String>((event, emit) {
      if (event == 'inc') emit(state + 1);
    });
  }
}

final class _TestEvent {
  const _TestEvent(this.name);

  final String name;
}

void main() {
  group(
    'ISpectBlocObserver event correlation invariants',
    () {
      late _RecordingLogger logger;
      late _DummyBloc bloc;

      setUp(() {
        ISpectBlocObserver.debugEnabledOverride = true;
        logger = _RecordingLogger();
        bloc = _DummyBloc();
      });

      tearDown(() async {
        ISpectBlocObserver.debugEnabledOverride = null;
        await bloc.close();
      });

      test('bloc-pattern filter drops both onEvent and onDone for that bloc',
          () {
        ISpectBlocObserver(
          logger: logger,
          filters: ['Bloc'],
        )
          ..onEvent(bloc, 'filtered')
          ..onDone(bloc, 'filtered');

        expect(logger.byOperation('event'), isEmpty);
        expect(logger.byOperation('done'), isEmpty);
      });

      test('filterPredicate drops both onEvent and onDone for matching bloc',
          () {
        ISpectBlocObserver(
          logger: logger,
          filterPredicate: (candidate) =>
              candidate.toString().contains('_DummyBloc'),
        )
          ..onEvent(bloc, 'filtered')
          ..onDone(bloc, 'filtered');

        expect(logger.byOperation('event'), isEmpty);
        expect(logger.byOperation('done'), isEmpty);
      });

      test('filtered completion cannot consume an accepted correlation', () {
        const filteredEvent = _TestEvent('filtered');
        const acceptedEvent = _TestEvent('accepted');
        final observer = ISpectBlocObserver(
          logger: logger,
          settings: ISpectBlocSettings(
            eventFilter: (_, event) => !identical(event, filteredEvent),
          ),
        )
          ..onEvent(bloc, filteredEvent)
          ..onEvent(bloc, acceptedEvent);

        final events = logger.byOperation('event');
        expect(events, hasLength(1));
        final acceptedId =
            events.single.additionalData?[TraceKeys.correlationId] as String;

        observer
          ..onDone(bloc, filteredEvent)
          ..onDone(bloc, acceptedEvent);

        final done = logger.byOperation('done');
        expect(done, hasLength(2));
        expect(done.first.additionalData?[TraceKeys.correlationId], isNull);
        expect(
          done.last.additionalData?[TraceKeys.correlationId],
          acceptedId,
        );
      });

      test('reverse completion removes the matching event correlation', () {
        const firstEvent = _TestEvent('first');
        const secondEvent = _TestEvent('second');
        final observer = ISpectBlocObserver(logger: logger)
          ..onEvent(bloc, firstEvent)
          ..onEvent(bloc, secondEvent);

        final eventIds = logger
            .byOperation('event')
            .map(
              (log) => log.additionalData?[TraceKeys.correlationId] as String,
            )
            .toList(growable: false);

        observer
          ..onDone(bloc, secondEvent)
          ..onDone(bloc, firstEvent);

        final doneIds = logger
            .byOperation('done')
            .map((log) => log.additionalData?[TraceKeys.correlationId])
            .toList(growable: false);
        expect(doneIds, <Object?>[eventIds[1], eventIds[0]]);
      });

      test('transition and its synchronous change use the matching event', () {
        const firstEvent = _TestEvent('first');
        const secondEvent = _TestEvent('second');
        final observer = ISpectBlocObserver(logger: logger)
          ..onEvent(bloc, firstEvent)
          ..onEvent(bloc, secondEvent);

        final eventIds = logger
            .byOperation('event')
            .map(
              (log) => log.additionalData?[TraceKeys.correlationId] as String,
            )
            .toList(growable: false);

        observer
          ..onTransition(
            bloc,
            const Transition(
              currentState: 0,
              event: secondEvent,
              nextState: 1,
            ),
          )
          ..onChange(bloc, const Change(currentState: 0, nextState: 1))
          ..onTransition(
            bloc,
            const Transition(
              currentState: 1,
              event: firstEvent,
              nextState: 2,
            ),
          )
          ..onChange(bloc, const Change(currentState: 1, nextState: 2));

        final transitionIds = logger
            .byOperation('transition')
            .map((log) => log.additionalData?[TraceKeys.correlationId])
            .toList(growable: false);
        final changeIds = logger
            .byOperation('state')
            .map((log) => log.additionalData?[TraceKeys.correlationId])
            .toList(growable: false);

        expect(transitionIds, <Object?>[eventIds[1], eventIds[0]]);
        expect(changeIds, <Object?>[eventIds[1], eventIds[0]]);
      });

      test('disabled transition cannot leak an event id into a later change',
          () {
        const event = _TestEvent('disable-between-hooks');
        final observer = ISpectBlocObserver(logger: logger)
          ..onEvent(bloc, event);

        logger.disable();
        observer.onTransition(
          bloc,
          const Transition(currentState: 0, event: event, nextState: 1),
        );
        logger.enable();
        observer.onChange(
          bloc,
          const Change(currentState: 0, nextState: 1),
        );

        expect(
          logger
              .byOperation('state')
              .single
              .additionalData?[TraceKeys.correlationId],
          isNull,
        );
      });

      test('change without a transition never borrows a pending event id', () {
        const event = _TestEvent('pending');
        final observer = ISpectBlocObserver(logger: logger)
          ..onEvent(bloc, event)
          ..onChange(bloc, const Change(currentState: 0, nextState: 1));

        expect(
          logger
              .byOperation('state')
              .single
              .additionalData?[TraceKeys.correlationId],
          isNull,
        );

        observer.onDone(bloc, event);
        expect(
          logger
              .byOperation('done')
              .single
              .additionalData?[TraceKeys.correlationId],
          logger
              .byOperation('event')
              .single
              .additionalData?[TraceKeys.correlationId],
        );
      });

      test('repeated identical event objects fail closed', () {
        const event = _TestEvent('repeated');
        ISpectBlocObserver(logger: logger)
          ..onEvent(bloc, event)
          ..onEvent(bloc, event)
          ..onTransition(
            bloc,
            const Transition(currentState: 0, event: event, nextState: 1),
          )
          ..onChange(bloc, const Change(currentState: 0, nextState: 1))
          ..onDone(bloc, event)
          ..onDone(bloc, event);

        final eventIds = logger
            .byOperation('event')
            .map((log) => log.additionalData?[TraceKeys.correlationId])
            .toSet();
        expect(eventIds, hasLength(2));

        for (final operation in const <String>[
          'transition',
          'state',
          'done',
        ]) {
          expect(
            logger
                .byOperation(operation)
                .map((log) => log.additionalData?[TraceKeys.correlationId]),
            everyElement(isNull),
          );
        }
      });

      test('onClose clears correlations so orphan onDone gets no correlationId',
          () {
        final observer = ISpectBlocObserver(logger: logger)
          ..onEvent(bloc, 'orphan');

        expect(logger.byOperation('event'), hasLength(1));

        observer
          ..onClose(bloc)
          ..onDone(bloc, 'orphan');

        final done = logger.byOperation('done');
        expect(done, hasLength(1));
        expect(done.single.additionalData?[TraceKeys.correlationId], isNull);
      });

      test('onClose still clears correlations when close logging is disabled',
          () {
        const event = _TestEvent('orphan');
        ISpectBlocObserver(
          logger: logger,
          settings: const ISpectBlocSettings(printClosings: false),
        )
          ..onEvent(bloc, event)
          ..onClose(bloc)
          ..onDone(bloc, event);

        expect(logger.byOperation('close'), isEmpty);
        expect(
          logger
              .byOperation('done')
              .single
              .additionalData?[TraceKeys.correlationId],
          isNull,
        );
      });

      test('bounds pending identities and recovers after overflow', () {
        const correlationCapacity = 1000;
        final observer = ISpectBlocObserver(logger: logger);
        final events = List<_TestEvent>.generate(
          correlationCapacity + 1,
          (index) => _TestEvent('event-$index'),
        );

        for (final event in events) {
          observer.onEvent(bloc, event);
        }
        final eventIds = logger
            .byOperation('event')
            .map(
              (log) => log.additionalData?[TraceKeys.correlationId] as String,
            )
            .toList(growable: false);

        for (var index = 0; index < correlationCapacity; index++) {
          observer.onDone(bloc, events[index]);
        }
        const eventAfterOverflow = _TestEvent('event-after-overflow');
        observer
          ..onEvent(bloc, eventAfterOverflow)
          ..onDone(bloc, events[correlationCapacity])
          ..onDone(bloc, eventAfterOverflow);

        final doneIds = logger
            .byOperation('done')
            .map((log) => log.additionalData?[TraceKeys.correlationId])
            .toList(growable: false);

        expect(
          doneIds.take(correlationCapacity),
          eventIds.take(correlationCapacity),
        );
        expect(doneIds.skip(correlationCapacity), everyElement(isNull));

        const recoveredEvent = _TestEvent('event-after-recovery');
        observer
          ..onEvent(bloc, recoveredEvent)
          ..onDone(bloc, recoveredEvent);

        final recoveredEventId = logger
            .byOperation('event')
            .last
            .additionalData?[TraceKeys.correlationId];
        final recoveredDoneId = logger
            .byOperation('done')
            .last
            .additionalData?[TraceKeys.correlationId];
        expect(recoveredDoneId, recoveredEventId);
      });
    },
    skip: !kISpectEnabled,
  );
}
