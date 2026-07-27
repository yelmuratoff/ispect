import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:test/test.dart';

final class _CountingRedactor extends RedactionService {
  int calls = 0;

  @override
  String redactUrl(String url) {
    calls++;
    return super.redactUrl(url);
  }
}

void main() {
  test('disabled logger bypasses capture, filters, and redaction', () {
    var sentFilterCalls = 0;
    var receivedFilterCalls = 0;
    var errorFilterCalls = 0;
    final redactor = _CountingRedactor();
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(
        enabled: false,
        useConsoleLogs: false,
      ),
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
        {'password': 'secret'},
        url: 'wss://api.example.test?token=secret',
      )
      ..onReceived(
        {'password': 'secret'},
        url: 'wss://api.example.test?token=secret',
      )
      ..onStateChanged(
        WsConnectionState.open,
        url: 'wss://api.example.test?token=secret',
        raw: {'password': 'secret'},
      )
      ..onError(
        Exception('secret'),
        StackTrace.fromString('secret'),
        url: 'wss://api.example.test?token=secret',
      );

    expect(logger.history, isEmpty);
    expect(sentFilterCalls, 0);
    expect(receivedFilterCalls, 0);
    expect(errorFilterCalls, 0);
    expect(redactor.calls, 0);
  });

  test('enabled logger without consumers bypasses frame capture', () {
    var filterCalls = 0;
    final redactor = _CountingRedactor();
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);
    final diagnostics = WsDiagnostics(
      logger: logger,
      redactor: redactor,
      settings: ISpectWSInterceptorSettings(
        printSentData: true,
        sentChain: NetworkFilterChain<ISpectLogData>.fromPredicate((_) {
          filterCalls++;
          return true;
        }),
      ),
    );

    diagnostics.onSent(
      {'password': 'secret'},
      url: 'wss://api.example.test?token=secret',
    );

    expect(logger.history, isEmpty);
    expect(filterCalls, 0);
    expect(redactor.calls, 0);
  });

  test('disposed logger bypasses capture before inspecting frames', () async {
    var filterCalls = 0;
    final redactor = _CountingRedactor();
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final diagnostics = WsDiagnostics(
      logger: logger,
      redactor: redactor,
      settings: ISpectWSInterceptorSettings(
        sentChain: NetworkFilterChain<ISpectLogData>.fromPredicate((_) {
          filterCalls++;
          return true;
        }),
      ),
    );

    await logger.dispose();
    diagnostics.onSent(
      {'password': 'secret'},
      url: 'wss://api.example.test?token=secret',
    );

    expect(filterCalls, 0);
    expect(redactor.calls, 0);
  });
}
