import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:test/test.dart';

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
}

class DummyBloc extends Bloc<String, int> {
  DummyBloc() : super(0) {
    on<String>((event, emit) {});
  }
}

void main() {
  group('ISpectBlocObserver', () {
    late RecordingLogger logger;
    late DummyBloc bloc;

    setUp(() {
      logger = RecordingLogger();
      bloc = DummyBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

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

      final events = logger.records
          .where((r) => r.key == ISpectLogType.stateChange.key)
          .where(
            (r) => r.additionalData?[TraceKeys.operation] == 'event',
          )
          .toList();
      expect(events, hasLength(1));
    });

    test('logs completion metadata with error flag', () {
      final exception = Exception('boom');
      final _ = ISpectBlocObserver(
        logger: logger,
        settings: const ISpectBlocSettings(
          printEvents: false,
          printTransitions: false,
          printChanges: false,
        ),
      )..onDone(bloc, 'event', exception, StackTrace.current);

      final doneLog = logger.records.firstWhere(
        (r) => r.additionalData?[TraceKeys.operation] == 'done',
      );
      final meta = doneLog.additionalData?[TraceKeys.meta];
      expect(meta, isA<Map<String, dynamic>>());
      expect((meta as Map<String, dynamic>)['hasError'], isTrue);
    });

    test('emits error trace when errors occur and printErrors enabled', () {
      final exception = Exception('failure');
      final _ = ISpectBlocObserver(
        logger: logger,
        settings: const ISpectBlocSettings(
          printEvents: false,
          printTransitions: false,
          printChanges: false,
        ),
      )..onError(bloc, exception, StackTrace.current);

      final errorLogs = logger.records
          .where(
            (r) => r.additionalData?[TraceKeys.operation] == 'error',
          )
          .toList();
      expect(errorLogs, hasLength(1));
      expect(errorLogs.single.exception, exception);
    });

    test('skips error logs when printErrors disabled', () {
      final _ = ISpectBlocObserver(
        logger: logger,
        settings: const ISpectBlocSettings(
          printEvents: false,
          printTransitions: false,
          printChanges: false,
          printErrors: false,
        ),
      )..onError(bloc, Exception('failure'), StackTrace.current);

      final errorLogs = logger.records.where(
        (r) => r.additionalData?[TraceKeys.operation] == 'error',
      );
      expect(errorLogs, isEmpty);
    });
  });
}
