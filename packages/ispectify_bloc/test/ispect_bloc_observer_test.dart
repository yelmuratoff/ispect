import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:test/test.dart';

class RecordingLogger extends ISpectify {
  final List<ISpectifyData> records = <ISpectifyData>[];

  @override
  void logCustom(ISpectifyData data) {
    records.add(data);
  }

  @override
  void error(
    Object? msg, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    records.add(
      ISpectifyData(
        msg?.toString(),
        exception: exception,
        stackTrace: stackTrace,
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

      final events = logger.records.whereType<BlocEventLog>().toList();
      expect(events, hasLength(1));
      expect(events.single.event, 'keep');
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

      final completion = logger.records.whereType<BlocDoneLog>().single;
      expect(completion.hasError, isTrue);
      expect(completion.additionalData?['completedWithError'], isTrue);
    });

    test('emits BlocErrorLog when errors occur and printErrors enabled', () {
      final exception = Exception('failure');
      final _ = ISpectBlocObserver(
        logger: logger,
        settings: const ISpectBlocSettings(
          printEvents: false,
          printTransitions: false,
          printChanges: false,
        ),
      )..onError(bloc, exception, StackTrace.current);

      final errorLogs = logger.records.whereType<BlocErrorLog>().toList();
      expect(errorLogs, hasLength(1));
      expect(errorLogs.single.thrown, exception);
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

      expect(logger.records.whereType<BlocErrorLog>(), isEmpty);
    });
  });
}
