// Integration tests: BLoC observer -> ISpectLogger -> history.
//
// Uses a real `Bloc`, a real `ISpectLogger` (no mocking of `logData`) and
// the global `Bloc.observer` hook, so the full pipeline is exercised as it
// would be in a Flutter app.

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:test/test.dart';

class _CounterBloc extends Bloc<String, int> {
  _CounterBloc() : super(0) {
    on<String>((event, emit) {
      if (event == 'inc') emit(state + 1);
      if (event == 'boom') throw StateError('boom');
    });
  }
}

void main() {
  group('BLoC integration: observer -> logger -> history', () {
    late ISpectLogger logger;
    late BlocObserver previous;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      previous = Bloc.observer;
      Bloc.observer = ISpectBlocObserver(logger: logger);
    });

    tearDown(() {
      Bloc.observer = previous;
    });

    test('create + event + transition + state + close flow is captured',
        () async {
      final bloc = _CounterBloc()..add('inc');
      await bloc.stream.firstWhere((s) => s == 1);
      await bloc.close();

      Map<String, Object?>? find(String op) {
        for (final r in logger.history) {
          if (r.additionalData?[TraceKeys.operation] == op) {
            return r.additionalData;
          }
        }
        return null;
      }

      expect(find('create'), isNotNull, reason: 'onCreate should hit history');
      expect(find('event'), isNotNull, reason: 'onEvent should hit history');
      expect(
        find('transition'),
        isNotNull,
        reason: 'onTransition should hit history',
      );
      expect(find('state'), isNotNull, reason: 'onChange should hit history');
      expect(find('close'), isNotNull, reason: 'onClose should hit history');

      final stateLogs = logger.history.where(
        (r) => r.additionalData?[TraceKeys.category] == TraceCategoryIds.state,
      );
      expect(stateLogs, isNotEmpty);
    });

    test('correlation id links event to its done record', () async {
      final bloc = _CounterBloc()..add('inc');
      await bloc.stream.firstWhere((s) => s == 1);
      // Give BLoC stream time to emit onDone for the event.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await bloc.close();

      final eventLog = logger.history
          .firstWhere((r) => r.additionalData?[TraceKeys.operation] == 'event');
      final doneLog = logger.history.firstWhere(
        (r) => r.additionalData?[TraceKeys.operation] == 'done',
        orElse: () => ISpectLogData(null),
      );

      final eventCid = eventLog.additionalData?[TraceKeys.correlationId];
      expect(eventCid, isA<String>());
      if (doneLog.additionalData != null) {
        expect(
          doneLog.additionalData?[TraceKeys.correlationId],
          equals(eventCid),
        );
      }
    });

    test('handler exception produces an error record', () async {
      // The bloc's handler throws; BlocObserver should log it. Wrap in a
      // guarded zone so the rethrown error does not fail the test.
      await runZonedGuarded(
        () async {
          final bloc = _CounterBloc()..add('boom');
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await bloc.close();
        },
        (_, __) {},
      );

      final errors = logger.history
          .where((r) => r.additionalData?[TraceKeys.operation] == 'error');
      expect(errors, isNotEmpty);
    });

    test('stream mirrors history for bloc events', () async {
      final streamed = <ISpectLogData>[];
      final sub = logger.stream.listen(streamed.add);

      final bloc = _CounterBloc()..add('inc');
      await bloc.stream.firstWhere((s) => s == 1);
      await bloc.close();
      await Future<void>.delayed(Duration.zero);

      expect(
        streamed.map((d) => d.additionalData?[TraceKeys.operation]).toList(),
        equals(
          logger.history
              .map((d) => d.additionalData?[TraceKeys.operation])
              .toList(),
        ),
      );

      await sub.cancel();
    });
  });
}
