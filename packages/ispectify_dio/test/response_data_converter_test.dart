import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

final class _ConsumingErrorInterceptorHandler extends ErrorInterceptorHandler {
  Future<void> consume() async {
    try {
      await future;
    } on Object {
      return;
    }
  }
}

Object? _decodeOrder(Response<dynamic> response) {
  final bytes = response.data as List<int>;
  return <String, Object?>{'orderId': bytes.first, 'token': 'tok-secret'};
}

void main() {
  group('ISpectDioInterceptorSettings.responseDataConverter', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
    });

    Response<dynamic> binaryResponse({int statusCode = 200}) =>
        Response<dynamic>(
          requestOptions: RequestOptions(
            path: 'https://api.example.com/orders/7',
          ),
          statusCode: statusCode,
          data: Uint8List.fromList([7, 0, 255]),
        );

    Map<String, dynamic> metaOf(ISpectLogData log) =>
        log.additionalData![TraceKeys.meta] as Map<String, dynamic>;

    test('logs the converted value instead of the raw bytes', () {
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          enableRedaction: false,
          responseDataConverter: _decodeOrder,
        ),
      ).onResponse(binaryResponse(), ResponseInterceptorHandler());

      final responseData = metaOf(logger.history.last)['response-data'] as Map;
      expect(responseData['data'], {'orderId': 7, 'token': 'tok-secret'});
    });

    test('redacts the converted value like any captured body', () {
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          responseDataConverter: _decodeOrder,
        ),
      ).onResponse(binaryResponse(), ResponseInterceptorHandler());

      final data =
          (metaOf(logger.history.last)['response-data'] as Map)['data'] as Map;
      expect(data['orderId'], 7);
      expect(data['token'], isNot('tok-secret'));
    });

    test('converts the response carried by a Dio error', () async {
      final response = binaryResponse(statusCode: 422);
      final handler = _ConsumingErrorInterceptorHandler();
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          enableRedaction: false,
          responseDataConverter: _decodeOrder,
        ),
      ).onError(
        DioException.badResponse(
          statusCode: 422,
          requestOptions: response.requestOptions,
          response: response,
        ),
        handler,
      );
      await handler.consume();

      final errorData = metaOf(logger.history.last)['error-data'] as Map;
      final errorResponse = errorData['response'] as Map;
      expect(errorResponse['data'], {'orderId': 7, 'token': 'tok-secret'});
    });

    ISpectDioInterceptorSettings throwingSettings() =>
        ISpectDioInterceptorSettings(
          responseDataConverter: (_) =>
              throw const FormatException('secret payload'),
        );

    void expectConverterWarning() {
      final warning = logger.history.singleWhere(
        (l) => l.logLevel == LogLevel.warning,
      );
      expect(warning.message, contains('FormatException'));
      expect(warning.message, isNot(contains('secret payload')));
    }

    test('a failing converter keeps the response with a placeholder body', () {
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: throwingSettings(),
      );

      expect(
        () => interceptor.onResponse(
          binaryResponse(),
          ResponseInterceptorHandler(),
        ),
        returnsNormally,
      );

      expectConverterWarning();
      final response = logger.history.singleWhere(
        (l) => l.key == ISpectLogType.httpResponse.key,
      );
      expect(
        (metaOf(response)['response-data'] as Map)['data'],
        LogExportOutput.truncatedMarker,
      );
    });

    test('a failing converter keeps the error log of a failed request',
        () async {
      final response = binaryResponse(statusCode: 502);
      final handler = _ConsumingErrorInterceptorHandler();
      ISpectDioInterceptor(
        logger: logger,
        settings: throwingSettings(),
      ).onError(
        DioException.badResponse(
          statusCode: 502,
          requestOptions: response.requestOptions,
          response: response,
        ),
        handler,
      );
      await handler.consume();

      expectConverterWarning();
      final error = logger.history.singleWhere(
        (l) => l.key == ISpectLogType.httpError.key,
      );
      final errorResponse =
          (metaOf(error)['error-data'] as Map)['response'] as Map;
      expect(errorResponse['data'], LogExportOutput.truncatedMarker);
    });

    test('the builder and copyWith carry the converter', () {
      final built = ISpectDioInterceptorSettingsBuilder()
          .withResponseDataConverter(_decodeOrder)
          .build();

      expect(built.responseDataConverter, same(_decodeOrder));
      expect(
        const ISpectDioInterceptorSettings()
            .copyWith(responseDataConverter: _decodeOrder)
            .responseDataConverter,
        same(_decodeOrder),
      );
    });
  });
}
