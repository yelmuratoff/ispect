import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectDioInterceptor tests', () {
    late ISpectDioInterceptor interceptor;
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(
          useConsoleLogs: false,
        ),
      );
      interceptor = ISpectDioInterceptor(logger: logger);
    });

    test('configure method should update logger settings', () {
      interceptor.configure(printRequestData: true);
      expect(interceptor.settings.printRequestData, true);
    });

    test('onRequest method should log http request', () {
      final options = RequestOptions(path: '/test');
      interceptor.onRequest(options, RequestInterceptorHandler());
      final last = logger.history.last;
      expect(last.key, ISpectLogType.httpRequest.key);
      expect(
        last.additionalData?[TraceKeys.category],
        TraceCategoryIds.network,
      );
      expect(last.additionalData?[TraceKeys.source], 'dio');
    });

    test('onResponse method should log http response', () {
      final options = RequestOptions(path: '/test');
      final response =
          Response<dynamic>(requestOptions: options, statusCode: 200);
      interceptor.onResponse(response, ResponseInterceptorHandler());
      final last = logger.history.last;
      expect(last.key, ISpectLogType.httpResponse.key);
      expect(
        last.additionalData?[TraceKeys.category],
        TraceCategoryIds.network,
      );
    });

    test('onError should log error trace', () async {
      final logger = ISpectLogger();
      final interceptor = ISpectDioInterceptor(logger: logger);
      final dio = Dio();
      dio.interceptors.add(interceptor);

      try {
        // ignore: inference_failure_on_function_invocation
        await dio.get('asdsada');
      } catch (_) {
        // Expected: Dio throws on invalid URL.
      }
      expect(logger.history, isNotEmpty);
      expect(logger.history.last.key, ISpectLogType.httpError.key);
    });

    test('onResponse method should log http response with meta', () {
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings:
            const ISpectDioInterceptorSettings(printResponseHeaders: true),
      );

      final options = RequestOptions(path: '/test');
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        headers: Headers()..add('HEADER', 'VALUE'),
      );
      interceptor.onResponse(response, ResponseInterceptorHandler());
      final last = logger.history.last;
      expect(last.key, ISpectLogType.httpResponse.key);
      final meta = last.additionalData?[TraceKeys.meta];
      expect(meta, isA<Map<String, dynamic>>());
      expect((meta as Map<String, dynamic>)['statusCode'], 200);
    });
  });
}
