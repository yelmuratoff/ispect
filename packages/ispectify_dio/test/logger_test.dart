import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import '../lib/dio_logs.dart';
import '../lib/ispectify_dio.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectifyDioLogger tests', () {
    late ISpectifyDioLogger logger;
    late ISpectiy iSpectify;

    setUp(() {
      iSpectify = ISpectiy(settings: ISpectifyOptions(useConsoleLogs: false));
      logger = ISpectifyDioLogger(iSpectify: iSpectify);
    });

    test('configure method should update logger settings', () {
      logger.configure(printRequestData: true);
      expect(logger.settings.printRequestData, true);
    });

    test('onRequest method should log http request', () {
      final options = RequestOptions(path: '/test');
      final logMessage = '${options.uri}';
      logger.onRequest(options, RequestInterceptorHandler());
      expect(iSpectify.history.last.message, logMessage);
    });

    test('onResponse method should log http response', () {
      final options = RequestOptions(path: '/test');
      final response = Response(requestOptions: options, statusCode: 200);
      final logMessage = '${response.requestOptions.uri}';
      logger.onResponse(response, ResponseInterceptorHandler());
      expect(iSpectify.history.last.message, logMessage);
    });

    test('onError should log DioErrorLog', () async {
      final iSpectify = ISpectiy();
      final logger = ISpectifyDioLogger(iSpectify: iSpectify);
      final dio = Dio();
      dio.interceptors.add(logger);

      try {
        await dio.get('asdsada');
      } catch (_) {}
      expect(iSpectify.history, isNotEmpty);
      expect(iSpectify.history.last, isA<DioErrorLog>());
    });

    test('onResponse method should log http response headers', () {
      final logger =
          ISpectifyDioLogger(iSpectify: iSpectify, settings: ISpectifyDioLoggerSettings(printResponseHeaders: true));

      final options = RequestOptions(path: '/test');
      final response = Response(requestOptions: options, statusCode: 200, headers: Headers()..add("HEADER", "VALUE"));
      logger.onResponse(response, ResponseInterceptorHandler());
      expect(
          iSpectify.history.last.generateTextMessage(),
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
