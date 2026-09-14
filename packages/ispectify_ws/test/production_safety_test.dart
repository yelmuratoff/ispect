import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:test/test.dart';

final class _SerializationProbe {
  _SerializationProbe(this.onSerialize);

  final void Function() onSerialize;

  Map<String, Object?> toJson() {
    onSerialize();
    return const {'password': 'synthetic-secret'};
  }
}

final class _CountingRedactor extends RedactionService {
  int calls = 0;

  @override
  String redactUrl(String url) {
    calls++;
    return super.redactUrl(url);
  }
}

void main() {
  test(
    'omitted flag bypasses capture, filters, and serialization',
    () {
      var serialized = false;
      var sentFilterCalls = 0;
      var receivedFilterCalls = 0;
      var errorFilterCalls = 0;
      final redactor = _CountingRedactor();
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      WsDiagnostics(
        logger: logger,
        redactor: redactor,
        settings: ISpectWSInterceptorSettings(
          sentChain: NetworkFilterChain<ISpectLogData>.fromPredicate((_) {
            sentFilterCalls++;
            return true;
          }),
          receivedChain: NetworkFilterChain<ISpectLogData>.fromPredicate((_) {
            receivedFilterCalls++;
            return true;
          }),
          errorChain: NetworkFilterChain<ISpectLogData>.fromPredicate((_) {
            errorFilterCalls++;
            return true;
          }),
        ),
      )
        ..newConnection()
        ..onSent(
          _SerializationProbe(() => serialized = true),
          url: 'wss://api.example.com?token=synthetic-secret',
        )
        ..onReceived({'password': 'synthetic-secret'})
        ..onStateChanged(
          WsConnectionState.open,
          raw: {'password': 'synthetic-secret'},
        )
        ..onError(
          Exception('synthetic-secret'),
          StackTrace.fromString('synthetic-secret'),
        );

      expect(logger.history, isEmpty);
      expect(serialized, isFalse);
      expect(sentFilterCalls, 0);
      expect(receivedFilterCalls, 0);
      expect(errorFilterCalls, 0);
      expect(redactor.calls, 0);
    },
    skip: kISpectEnabled
        ? 'This regression test must run without ISPECT_ENABLED.'
        : false,
  );
}
