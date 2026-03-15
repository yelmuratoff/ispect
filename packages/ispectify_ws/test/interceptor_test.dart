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
      // No client set; interceptor should still log
    });

    test('logs sent data when enabled', () async {
      interceptor.onSend({'k': 'v'}, (obj) {});
      expect(
        logger.history.any(
          (e) => e.key == 'ws-sent' && e.textMessage.contains('Data: {'),
        ),
        isTrue,
      );
    });

    test('logs sent without payload when printSentData=false', () async {
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          printSentData: false,
        ),
      )
        // No client set; interceptor should still log (without payload)

        ..onSend({'secret': 'value'}, (obj) {});

      final sent = logger.history.where((e) => e.key == 'ws-sent').toList();
      expect(sent, isNotEmpty);
      expect(sent.first.textMessage.contains('Data: {'), isFalse);
      // Still includes URL line prefix even if empty
      expect(sent.first.textMessage.startsWith('URL:'), isTrue);
      // Payload should not contain data when printSentData=false
      final body = sent.first.additionalData?['body'] as Map<String, dynamic>?;
      if (body != null) {
        expect(body.containsKey('data'), isFalse);
      }
    });

    test('logs received without payload when printReceivedData=false',
        () async {
      interceptor = ISpectWSInterceptor(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          printReceivedData: false,
        ),
      )
        // No client set; interceptor should still log (without payload)

        ..onMessage({'foo': 'bar'}, (obj) {});

      final rec = logger.history.where((e) => e.key == 'ws-received').toList();
      expect(rec, isNotEmpty);
      expect(rec.first.textMessage.contains('Data: {'), isFalse);
      // Payload should not contain data when printReceivedData=false
      final body = rec.first.additionalData?['body'] as Map<String, dynamic>?;
      if (body != null) {
        expect(body.containsKey('data'), isFalse);
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

      // Even with a broken redactor, logging should still work
      expect(logger.history, isNotEmpty);
    });
  });
}
