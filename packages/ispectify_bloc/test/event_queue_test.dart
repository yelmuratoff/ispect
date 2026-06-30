import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:test/test.dart';

class _RecordingLogger extends ISpectLogger {
  final List<ISpectLogData> records = <ISpectLogData>[];

  @override
  void logData(ISpectLogData log) => records.add(log);

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

void main() {
  group('ISpectBlocObserver event queue invariants', () {
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

    test('bloc-pattern filter drops both onEvent and onDone for that bloc', () {
      // filters match the bloc type, so _shouldLog(bloc) returns false and
      // onEvent returns early before pushing to the queue. onDone also sees
      // `_isFiltered(bloc) == true` and returns early, so nothing is logged.
      ISpectBlocObserver(
        logger: logger,
        filters: ['_DummyBloc'],
      )
        ..onEvent(bloc, 'filtered')
        ..onDone(bloc, 'filtered');

      expect(logger.byOperation('event'), isEmpty);
      expect(logger.byOperation('done'), isEmpty);
    });

    test('filterPredicate drops both onEvent and onDone for matching bloc', () {
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

    test('eventFilter rejection does not push id onto queue', () {
      final observer = ISpectBlocObserver(
        logger: logger,
        settings: ISpectBlocSettings(
          eventFilter: (_, event) => event != 'skip',
        ),
      )
        ..onEvent(bloc, 'skip')
        ..onEvent(bloc, 'keep');

      final events = logger.byOperation('event');
      expect(events, hasLength(1));
      final keptId =
          events.single.additionalData?[TraceKeys.correlationId] as String;

      // The first onDone must correlate with the only enqueued event (keep),
      // not with the filtered-out 'skip'.
      observer.onDone(bloc, 'keep');
      final done = logger.byOperation('done');
      expect(done, hasLength(1));
      expect(
        done.single.additionalData?[TraceKeys.correlationId],
        keptId,
      );
    });

    test('onTransition peeks eventId without popping', () {
      final observer = ISpectBlocObserver(logger: logger)
        ..onEvent(bloc, 'start');

      final eventId = logger
          .byOperation('event')
          .single
          .additionalData?[TraceKeys.correlationId] as String;

      // Two transitions during the same event must share the same correlationId.
      observer
        ..onTransition(
          bloc,
          const Transition(currentState: 0, event: 'start', nextState: 1),
        )
        ..onTransition(
          bloc,
          const Transition(currentState: 1, event: 'start', nextState: 2),
        );

      final transitions = logger.byOperation('transition');
      expect(transitions, hasLength(2));
      for (final log in transitions) {
        expect(
          log.additionalData?[TraceKeys.correlationId],
          equals(eventId),
          reason: 'onTransition must peek without popping the queue',
        );
      }

      // onDone finally pops the id.
      observer.onDone(bloc, 'start');
      expect(
        logger
            .byOperation('done')
            .single
            .additionalData?[TraceKeys.correlationId],
        equals(eventId),
      );
    });

    test('onClose resets the queue so orphan onDone gets no correlationId', () {
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
  });
}
