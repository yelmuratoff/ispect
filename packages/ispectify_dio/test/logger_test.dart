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

    test('configure updates every shared capture setting', () {
      interceptor.configure(
        enabled: false,
        enableRedaction: false,
        captureMode: DiagnosticCaptureMode.strict,
        resourceLimits: DiagnosticResourceLimits.constrained,
        logRequests: false,
        logResponses: false,
        printRequestData: false,
        printRequestHeaders: false,
        printResponseData: false,
        printResponseHeaders: false,
        printResponseMessage: false,
        printErrorData: false,
        printErrorHeaders: false,
        printErrorMessage: false,
      );

      final settings = interceptor.settings;
      expect(settings.enabled, isFalse);
      expect(settings.enableRedaction, isFalse);
      expect(settings.captureMode, DiagnosticCaptureMode.strict);
      expect(
        settings.resourceLimits,
        same(DiagnosticResourceLimits.constrained),
      );
      expect(settings.logRequests, isFalse);
      expect(settings.logResponses, isFalse);
      expect(settings.printRequestData, isFalse);
      expect(settings.printRequestHeaders, isFalse);
      expect(settings.printResponseData, isFalse);
      expect(settings.printResponseHeaders, isFalse);
      expect(settings.printResponseMessage, isFalse);
      expect(settings.printErrorData, isFalse);
      expect(settings.printErrorHeaders, isFalse);
      expect(settings.printErrorMessage, isFalse);
    });

    test('configure can restore logger-owned resource limits', () {
      interceptor
        ..configure(
          resourceLimits: DiagnosticResourceLimits.constrained,
        )
        ..configure(inheritResourceLimits: true);

      expect(interceptor.settings.resourceLimits, isNull);
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
      expect((meta as Map<String, dynamic>)['status-code'], 200);
    });
  });
}
