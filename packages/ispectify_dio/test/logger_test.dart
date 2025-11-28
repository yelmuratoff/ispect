import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/models/_models.dart';
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
      final logMessage = '${options.uri}';
      interceptor.onRequest(options, RequestInterceptorHandler());
      expect(logger.history.last.message, logMessage);
    });

    test('onResponse method should log http response', () {
      final options = RequestOptions(path: '/test');
      final response =
          Response<dynamic>(requestOptions: options, statusCode: 200);
      final logMessage = '${response.requestOptions.uri}';
      interceptor.onResponse(response, ResponseInterceptorHandler());
      expect(logger.history.last.message, logMessage);
    });

    test('onError should log DioErrorLog', () async {
      final logger = ISpectLogger();
      final interceptor = ISpectDioInterceptor(logger: logger);
      final dio = Dio();
      dio.interceptors.add(interceptor);

      try {
        // ignore: inference_failure_on_function_invocation
        await dio.get('asdsada');
      } catch (_) {}
      expect(logger.history, isNotEmpty);
      expect(logger.history.last, isA<DioErrorLog>());
    });

    test('onResponse method should log http response headers', () {
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
      expect(
          logger.history.last.textMessage,
          '[http-response] [GET] /test\n'
          'Status: 200\n'
          'Headers: {\n'
          '  "HEADER": [\n'
          '    "VALUE"\n'
          '  ]\n'
          '}');
    });
  });
}
