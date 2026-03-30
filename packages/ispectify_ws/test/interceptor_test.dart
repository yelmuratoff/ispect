import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:test/test.dart';

class _ThrowingRedactor extends RedactionService {
  @override
  Object? redact(
    Object? input, {
    Set<String>? ignoredKeys,
    Set<String>? ignoredValues,
    String? keyName,
  }) {
    throw StateError('redaction failed');
  }
}

void main() {
  group('ISpectWSInterceptor', () {
    late ISpectLogger logger;
    late ISpectWSInterceptor interceptor;

    setUp(() {
      logger = ISpectLogger();
      interceptor = ISpectWSInterceptor(
        logger: logger,
      );
    });

    test('logs sent data when enabled', () async {
      interceptor.onSend({'k': 'v'}, (obj) {});
      expect(
        logger.history.any((e) => e.key == ISpectLogType.wsSent.key),
        isTrue,
      );
    });

    test('logs sent without payload when printSentData=false', () async {
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          printSentData: false,
        ),
      )..onSend({'secret': 'value'}, (obj) {});

      final sent = logger.history
          .where((e) => e.key == ISpectLogType.wsSent.key)
          .toList();
      expect(sent, isNotEmpty);
      // Meta should not contain 'data' when printSentData=false
      final meta = sent.first.additionalData?[TraceKeys.meta];
      if (meta is Map) {
        expect(meta.containsKey('data'), isFalse);
      }
    });

    test('logs received without payload when printReceivedData=false',
        () async {
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          printReceivedData: false,
        ),
      )..onMessage({'foo': 'bar'}, (obj) {});

      final rec = logger.history
          .where((e) => e.key == ISpectLogType.wsReceived.key)
          .toList();
      expect(rec, isNotEmpty);
      final meta = rec.first.additionalData?[TraceKeys.meta];
      if (meta is Map) {
        expect(meta.containsKey('data'), isFalse);
      }
    });

    test('logs gracefully even when redactor throws', () async {
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          printErrorData: false,
        ),
        redactor: _ThrowingRedactor(),
      )..onSend({'boom': true}, (obj) {});

      expect(logger.history, isNotEmpty);
    });

    test('logs received data when enabled', () {
      interceptor.onMessage({'msg': 'hello'}, (obj) {});
      expect(
        logger.history.any(
          (e) => e.key == ISpectLogType.wsReceived.key,
        ),
        isTrue,
      );
    });

    test('passes data through to next callback', () {
      Object? forwarded;
      interceptor.onSend({'k': 'v'}, (obj) => forwarded = obj);
      expect(forwarded, isNotNull);
    });

    test('filters sent logs via sentFilter', () {
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: ISpectWSInterceptorSettings(
          sentFilter: (log) => false,
        ),
      )..onSend({'k': 'v'}, (obj) {});

      expect(
        logger.history.any(
          (e) => e.key == ISpectLogType.wsSent.key,
        ),
        isFalse,
      );
    });

    test('sentFilter receives actual ISpectLogData, not null', () {
      ISpectLogData? receivedData;
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: ISpectWSInterceptorSettings(
          sentFilter: (log) {
            receivedData = log;
            return true;
          },
        ),
      )..onSend({'k': 'v'}, (obj) {});

      expect(receivedData, isNotNull);
      expect(receivedData!.key, ISpectLogType.wsSent.key);
      expect(receivedData!.additionalData, isNotNull);
      expect(
        receivedData!.additionalData![TraceKeys.operation],
        'send',
      );
    });

    test('receivedFilter receives actual ISpectLogData, not null', () {
      ISpectLogData? receivedData;
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: ISpectWSInterceptorSettings(
          receivedFilter: (log) {
            receivedData = log;
            return true;
          },
        ),
      )..onMessage({'msg': 'hello'}, (obj) {});

      expect(receivedData, isNotNull);
      expect(receivedData!.key, ISpectLogType.wsReceived.key);
      expect(
        receivedData!.additionalData![TraceKeys.operation],
        'receive',
      );
    });

    test('filters received logs via receivedFilter', () {
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: ISpectWSInterceptorSettings(
          receivedFilter: (log) => false,
        ),
      )..onMessage({'k': 'v'}, (obj) {});

      expect(
        logger.history.any(
          (e) => e.key == ISpectLogType.wsReceived.key,
        ),
        isFalse,
      );
    });

    test('does not log when disabled', () {
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(enabled: false),
      )..onSend({'k': 'v'}, (obj) {});

      expect(
        logger.history.any(
          (e) => e.key == ISpectLogType.wsSent.key,
        ),
        isFalse,
      );
    });

    test('logs error data when log creation throws', () {
      interceptor = ISpectWSInterceptor(
        logger: logger,
        redactor: _ThrowingRedactor(),
      )..onSend({'trigger': 'error'}, (obj) {});

      expect(logger.history, isNotEmpty);
    });
  });
}
