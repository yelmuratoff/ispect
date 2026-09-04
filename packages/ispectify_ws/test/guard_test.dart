import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:test/test.dart';

final class _ThrowingFilter<T> extends NetworkFilter<T> {
  const _ThrowingFilter();

  @override
  bool apply(T value) => throw StateError('tenantSecret=FILTER_SECRET');
}

void main() {
  group('logging failures never break the host socket', () {
    late ISpectLogger logger;
    late WsDiagnostics diagnostics;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      diagnostics = WsDiagnostics(
        logger: logger,
        settings: const ISpectWSInterceptorSettings(
          sentChain: NetworkFilterChain([_ThrowingFilter()]),
          receivedChain: NetworkFilterChain([_ThrowingFilter()]),
          errorChain: NetworkFilterChain([_ThrowingFilter()]),
        ),
      );
    });

    tearDown(() => logger.dispose());

    List<String?> warnings() => logger.history
        .where((log) => log.logLevel == LogLevel.warning)
        .map((log) => log.message)
        .toList();

    test('a throwing frame filter returns normally', () {
      expect(() => diagnostics.onSent({'k': 'v'}), returnsNormally);
      expect(() => diagnostics.onReceived({'k': 'v'}), returnsNormally);

      expect(
        warnings(),
        [
          'WebSocket send capture failed safely: StateError',
          'WebSocket receive capture failed safely: StateError',
        ],
      );
      expect(warnings().join(), isNot(contains('FILTER_SECRET')));
    });

    test('a message id correlates a frame instead of the session', () {
      final plain = WsDiagnostics(logger: logger)
        ..onSent({'k': 'v'})
        ..onSent({'k': 'v'}, messageId: 'rpc-42')
        ..onReceived({'k': 'v'}, messageId: 'rpc-42');
      addTearDown(plain.newConnection);

      final ids = logger.history
          .map((log) => log.additionalData?[TraceKeys.correlationId])
          .toList();
      expect(ids[1], 'rpc-42');
      expect(ids[2], 'rpc-42');
      expect(ids[0], isNot('rpc-42'));
    });

    test('a throwing error filter returns normally', () {
      expect(
        () => diagnostics.onError(StateError('socket'), StackTrace.current),
        returnsNormally,
      );

      expect(warnings(), ['WebSocket error capture failed safely: StateError']);
    });
  });
}
