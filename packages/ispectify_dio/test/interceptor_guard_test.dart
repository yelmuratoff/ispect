import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

final class _ThrowingFilter<T> extends NetworkFilter<T> {
  const _ThrowingFilter();

  @override
  bool apply(T value) => throw StateError('tenantSecret=FILTER_SECRET');
}

final class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        '{"ok":true}',
        statusCode,
        headers: {
          'content-type': ['application/json'],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  group('logging failures never break the host request', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
    });

    tearDown(() => logger.dispose());

    Dio dioWith(int statusCode) => Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _StatusAdapter(statusCode)
      ..interceptors.add(
        ISpectDioInterceptor(
          logger: logger,
          settings: const ISpectDioInterceptorSettings(
            requestChain: NetworkFilterChain([_ThrowingFilter()]),
            responseChain: NetworkFilterChain([_ThrowingFilter()]),
            errorChain: NetworkFilterChain([_ThrowingFilter()]),
          ),
        ),
      );

    List<String?> warnings() => logger.history
        .where((log) => log.logLevel == LogLevel.warning)
        .map((log) => log.message)
        .toList();

    test('a throwing request or response filter still completes the call',
        () async {
      final response = await dioWith(200).get<dynamic>('/users');

      expect(response.statusCode, 200);
      expect(
        warnings(),
        containsAll([
          'Dio request capture failed safely: StateError',
          'Dio response capture failed safely: StateError',
        ]),
      );
      expect(warnings().join(), isNot(contains('FILTER_SECRET')));
    });

    test('a throwing error filter still surfaces the original DioException',
        () async {
      await expectLater(
        dioWith(500).get<dynamic>('/users'),
        throwsA(isA<DioException>()),
      );

      expect(
        warnings(),
        contains('Dio error capture failed safely: StateError'),
      );
    });
  });
}
