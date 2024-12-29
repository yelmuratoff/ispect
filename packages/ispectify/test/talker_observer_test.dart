import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final _logsStore = <ISpectiyData>[];
final _errorsStore = <TalkerError>[];
final _exceptionsStore = <TalkerException>[];

class MockTalkerObserver extends ISpectifyObserver {
  @override
  void onError(TalkerError err) => _errorsStore.add(err);

  @override
  void onException(TalkerException e) => _exceptionsStore.add(e);

  @override
  void onLog(ISpectiyData log) => _logsStore.add(log);
}

void main() {
  group('ISpectifyObserver', () {
    final mockObserver = MockTalkerObserver();

    setUp(() {
      _logsStore.clear();
      _errorsStore.clear();
      _exceptionsStore.clear();
    });
    test('onError', () {
      mockObserver.onError.call(TalkerError(ArgumentError()));
      expect(_errorsStore, isNotEmpty);
      expect(_logsStore, isEmpty);
      expect(_exceptionsStore, isEmpty);
    });

    test('onException', () {
      mockObserver.onException.call(TalkerException(Exception()));
      expect(_errorsStore, isEmpty);
      expect(_logsStore, isEmpty);
      expect(_exceptionsStore, isNotEmpty);
    });

    test('onLog', () {
      mockObserver.onLog.call(ISpectifyLog('msg'));
      expect(_errorsStore, isEmpty);
      expect(_logsStore, isNotEmpty);
      expect(_exceptionsStore, isEmpty);
    });
  });

  group('Test observer\'s log method invoked with the correct log', () {
    late ISpectiy iSpectify;
    final mockObserver = MockTalkerObserver();

    setUp(() {
      iSpectify = ISpectiy(observer: mockObserver);
      iSpectify.clearHistory();
      _logsStore.clear();
      _errorsStore.clear();
      _exceptionsStore.clear();
    });

    test('info method logs correct message, exception, and stack trace', () {
      final exception = "Test exception";
      final stack = StackTrace.fromString('Test stack');
      final logMessage = 'log';
      iSpectify.info(logMessage, exception, stack);

      expect(_logsStore.last.message, equals(logMessage));
      expect(_logsStore.last.exception.toString(), equals(exception));
      expect(_logsStore.last.stackTrace, equals(stack));

      expect(_logsStore, isNotEmpty);
      expect(_errorsStore, isEmpty);
      expect(_exceptionsStore, isEmpty);
    });

    test('error method logs correct message, exception, and stack trace', () {
      final exception = "Test exception";
      final stack = StackTrace.fromString("Test stack");
      final logMessage = 'log';
      iSpectify.error(logMessage, exception, stack);

      expect(_logsStore.last.message, equals(logMessage));
      expect(_logsStore.last.exception.toString(), equals(exception));
      expect(_logsStore.last.stackTrace, equals(stack));

      expect(_logsStore, isNotEmpty);
      expect(_errorsStore, isEmpty);
      expect(_exceptionsStore, isEmpty);
    });

    test('verbose method logs correct message, exception, and stack trace', () {
      final exception = "Test exception";
      final stack = StackTrace.fromString("Test stack");
      final logMessage = 'log';
      iSpectify.verbose(logMessage, exception, stack);

      expect(_logsStore.last.message, equals(logMessage));
      expect(_logsStore.last.exception.toString(), equals(exception));
      expect(_logsStore.last.stackTrace, equals(stack));

      expect(_logsStore, isNotEmpty);
      expect(_errorsStore, isEmpty);
      expect(_exceptionsStore, isEmpty);
    });

    test('warning method logs correct message, exception, and stack trace', () {
      final exception = "Test exception";
      final stack = StackTrace.fromString("Test stack");
      final logMessage = 'log';
      iSpectify.warning(logMessage, exception, stack);

      expect(_logsStore.last.message, equals(logMessage));
      expect(_logsStore.last.exception.toString(), equals(exception));
      expect(_logsStore.last.stackTrace, equals(stack));

      expect(_logsStore, isNotEmpty);
      expect(_errorsStore, isEmpty);
      expect(_exceptionsStore, isEmpty);
    });

    test('debug method logs correct message, exception, and stack trace', () {
      final exception = "Test exception";
      final stack = StackTrace.fromString("Test stack");
      final logMessage = 'log';
      iSpectify.debug(logMessage, exception, stack);

      expect(_logsStore.last.message, equals(logMessage));
      expect(_logsStore.last.exception.toString(), equals(exception));
      expect(_logsStore.last.stackTrace, equals(stack));

      expect(_logsStore, isNotEmpty);
      expect(_errorsStore, isEmpty);
      expect(_exceptionsStore, isEmpty);
    });

    test('critical method logs correct message, exception, and stack trace', () {
      final exception = "Test exception";
      final stack = StackTrace.fromString("Test stack");
      final logMessage = 'log';
      iSpectify.critical(logMessage, exception, stack);

      expect(_logsStore.last.message, equals(logMessage));
      expect(_logsStore.last.exception.toString(), equals(exception));
      expect(_logsStore.last.stackTrace, equals(stack));

      expect(_logsStore, isNotEmpty);
      expect(_errorsStore, isEmpty);
      expect(_exceptionsStore, isEmpty);
    });

    test('custom log level method logs correct message, exception, and stack trace', () {
      final exception = "Test exception";
      final stack = StackTrace.fromString("Test stack");
      final logMessage = 'log';
      iSpectify.log(logMessage, logLevel: LogLevel.debug, exception: exception, stackTrace: stack);

      expect(_logsStore.last.message, equals(logMessage));
      expect(_logsStore.last.exception.toString(), equals(exception));
      expect(_logsStore.last.stackTrace, equals(stack));

      expect(_logsStore, isNotEmpty);
      expect(_errorsStore, isEmpty);
      expect(_exceptionsStore, isEmpty);
    });
  });
}
