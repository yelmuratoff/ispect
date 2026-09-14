import 'package:http/http.dart' as http;
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

final class _ThrowingFilter<T> extends NetworkFilter<T> {
  const _ThrowingFilter();

  @override
  bool apply(T value) => throw StateError('tenantSecret=FILTER_SECRET');
}

void main() {
  group('logging failures never break the host request', () {
    late ISpectLogger logger;
    late ISpectHttpInterceptor interceptor;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          requestChain: NetworkFilterChain([_ThrowingFilter()]),
          responseChain: NetworkFilterChain([_ThrowingFilter()]),
          errorChain: NetworkFilterChain([_ThrowingFilter()]),
        ),
      );
    });

    tearDown(() => logger.dispose());

    List<String?> warnings() => logger.history
        .where((log) => log.logLevel == LogLevel.warning)
        .map((log) => log.message)
        .toList();

    test('a throwing request filter still returns the request', () async {
      final request = http.Request('GET', Uri.parse('https://api.test/users'));

      final returned = await interceptor.interceptRequest(request: request);

      expect(returned, same(request));
      expect(warnings(), ['http request capture failed safely: StateError']);
      expect(warnings().join(), isNot(contains('FILTER_SECRET')));
    });

    for (final statusCode in const [200, 500]) {
      test('a throwing filter still returns the $statusCode response',
          () async {
        final request =
            http.Request('GET', Uri.parse('https://api.test/users'));
        final response = http.Response('{}', statusCode, request: request);

        final returned =
            await interceptor.interceptResponse(response: response);

        expect(returned, same(response));
        expect(
          warnings(),
          ['http response capture failed safely: StateError'],
        );
      });
    }
  });
}
